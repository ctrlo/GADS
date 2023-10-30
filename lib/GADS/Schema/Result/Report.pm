use utf8;

package GADS::Schema::Result::Report;

=head1 NAME

GADS::Schema::Result::Report

=cut

use CtrlO::PDF 0.06;
use GADS::Config;
use Data::Dumper;
use Moo;

extends 'DBIx::Class::Core';
sub BUILDARGS { $_[2] || {} }

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components( "InflateColumn::DateTime", "+GADS::DBIC" );

=head1 TABLE: C<report>

=cut

__PACKAGE__->table("report");

=head1 ACCESSORS

=head2 id

    data_type: 'bigint'
    is_auto_increment: 1
    is_nullable: 0

=head2 name

    data_type: 'varchar'
    is_nullable: 0
    size: 128

=head2 description

    data_type: 'varchar'
    is_nullable: 1
    size: 128

=head2 user_id

    data_type: 'bigint'
    is_foreign_key: 1
    is_nullable: 1

=head2 createdby

    data_type: 'bigint'
    is_foreign_key: 1
    is_nullable: 1

=head2 created

    data_type: 'datetime'
    datetime_undef_if_invalid: 1
    is_nullable: 1

=head2 instance_id

    data_type: 'bigint'
    is_foreign_key: 1
    is_nullable: 1

=head2 deleted

    data_type: 'tinyint'
    is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "description",
    { data_type => "varchar", is_nullable => 1, size => 128 },
    "user_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "createdby",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "created",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 1
    },
    "instance_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "deleted",
    { data_type => "tinyint", is_nullable => 1 }
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<GADS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
    "user",
    "GADS::Schema::Result::User",
    { id => "user_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION"
    },
);

__PACKAGE__->belongs_to(
    "createdby",
    "GADS::Schema::Result::User",
    { id => "createdby" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION"
    },
);

=head2 instance

Type: belongs_to

Related object: L<GADS::Schema::Result::Instance>

=cut

__PACKAGE__->belongs_to(
    "instance",
    "GADS::Schema::Result::Instance",
    { id => "instance_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION"
    },
);

=head2 report_layouts

Type: has_many

Related object: L<GADS::Schema::Result::ReportLayout>

=cut

__PACKAGE__->has_many(
    "report_layouts",
    "GADS::Schema::Result::ReportLayout",
    { "foreign.report_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 validation

This will return 0 if the report satisfies the following:
=over 2
- Has a name
- Has an instance it is linked to
- Has at least one layout associated with it
- There is no other report with the same name and instance id that is active (i.e. not deleted)
=back

=cut

#TODO: need to work out how to implement this properly - Will ask AB on Tuesday
sub validate {
    my ( $self, $value, %options ) = @_;
    return 1 if !$value;

    my $name        = $self->name;
    my $instance_id = $self->instance_id;
    my $layouts     = $self->report_layouts;

    return 0 unless $name;
    return 0 unless $instance_id;
    return 0 unless $layouts->count;

    return 0
      if $self->schema->resultset('Report')->search(
        {
            name        => $name,
            instance_id => $instance_id,
            deleted     => 0,
        }
    )->count;

    return 0 unless $options{fatal};
    return 1;
}

#Will return 1 if the report is new, 0 if it is not - this is done via the ID being 0 for a new report.
#This is a private field
#Not sure if this is needed due to the app erroring if I try to create a report by creating a Report object and then calling create on it
has _is_new => (
    is      => 'rwp',
    default => 1,
    builder => sub {
        my $self = shift;
        return 0 if $self->id;
        return 1;
    },
);

=head2 schema

The schema object used for the report

=cut

has schema => (
    is       => 'rw',
    required => 0,
);

=head2 Record ID

This is the ID of the Record in the Instance to display the report for

=cut

has record_id => (
    is       => 'rw',
    required => 0,
);

=head2 Data

This is the data for the report as pulled from the instance record identfied by the Record Id

=cut

has data => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub {
        my $self = shift;

        my $result = [];

        my $layouts = $self->report_layouts;

        while ( my $layout = $layouts->next ) {
            my $data = $self->_load_record_data($layout);
            push( @{$result}, $data );
        }

        return $result;
    },
);

#helper function to load record data
sub _load_record_data {
    my $self      = shift;
    my $layout    = shift;
    my $record_id = $self->record_id;
    my $user      = $self->user;

    die "No report id given" if !$record_id;

    my $gads_layout = GADS::Layout->new(
        schema      => $self->schema,
        user        => $user,
        instance_id => $self->instance_id,
    );

    my $record = GADS::Record->new(
        schema => $self->schema,
        user   => $user,
        layout => $gads_layout,
    );

    $record->find_current_id($record_id);

    my $column =
      $self->_find_column( $layout->layout->name, $gads_layout->columns );

    my $datum = $record->get_field_value($column);

    return { 'name' => $layout->layout->name, 'value' => $datum };
}

#helper function to find a column in a list of columns
sub _find_column {
    my $self        = shift;
    my $column_name = shift;
    my $columns     = shift;

#I know I could probably do this with a grep, but for some reason, I can't get said grep to work
#grep { $_->name eq $column_name } @{$columns};
    foreach my $col ( @{$columns} ) {
        if ( $col->name eq $column_name ) {
            return $col;
        }
    }

    return undef;
}

=head1 Object functions

=head2 Update Report

Function to update a report - it requires the schema to be passed in and will return a report object

=cut

sub update_report {
    my ( $self, $args ) = @_;

    my $guard = $self->schema->txn_scope_guard;

    $self->update( { name => $args->{name} } )
      if $args->{name} && $args->{name} ne $self->name;
    $self->update( { description => $args->{description} } )
      if $args->{description} && $args->{description} ne $self->description;

    my $layouts        = $self->report_layouts;
    my $report_layouts = [];

    while ( my $layout = $layouts->next ) {
        push( @{$report_layouts}, $layout->layout_id );
    }

    #we grep for less writes
    foreach my $layout (@$report_layouts) {
        $self->schema->resultset('ReportLayout')
          ->find( { report_id => $self->id, layout_id => $layout } )->delete
          if !grep { $_ == $layout->id } @{ $args->{layouts} };
    }

    #we grep for less writes
    foreach my $layout ( @{ $args->{layouts} } ) {
        $self->schema->resultset('ReportLayout')->create(
            {
                report_id => $self->id,
                layout_id => $layout,
            }
        ) if !grep { $_ == $layout } @{$report_layouts};
    }

    $guard->commit;

    return $self;
}

=head2 Delete

Function to delete a report - it requires the schema to be passed in and will return nothing.
If the ID is invalid, or there's nothing to delete, it will do nothing.

=cut

sub delete {
    my $self = shift;

    return if !$self || $self->_is_new || $self->deleted;

    my $guard = $self->schema->txn_scope_guard;

    $self->update( { deleted => 1 } );

    $guard->commit;
}

=head2 Create PDF

Function to create a PDF of the report - it requires the schema to be passed in and will return a PDF object

=cut

sub create_pdf {
    my $self = shift;

    my $dateformat = GADS::Config->instance->dateformat;
    my $now        = DateTime->now;
    $now->set_time_zone('Europe/London');
    my $now_formatted = $now->format_cldr($dateformat) . " at " . $now->hms;
    my $updated =
      $self->created->format_cldr($dateformat) . " at " . $self->created->hms;

    my $config = GADS::Config->instance;
    my $header = $config && $config->gads && $config->gads->{header};
    my $pdf    = CtrlO::PDF->new(
        header => $header,
        footer => "Downloaded by " . $self->user->value . " on $now_formatted",
    );

    $pdf->add_page;
    $pdf->heading( $self->name );
    $pdf->heading( $self->description, size => 14 ) if $self->description;

    my $fields = [ [ 'Field', 'Value' ] ];

    my $data = $self->data;

    push( @{$fields}, [ $_->{name}, $_->{value} ] ) foreach (@$data);

    my $hdr_props = {
        repeat    => 1,
        justify   => 'center',
        font_size => 12,
    };

    $pdf->table(
        data         => $fields,
        header_props => $hdr_props,
    );

    $pdf;
}

=head1 Package functions

=head2 Load

Function to load a report for a given id - it requires the report id and the schema to be passed in and will return a report object

=cut

sub load {
    my $id        = shift;
    my $record_id = shift;
    my $schema    = shift;

    die "Invalid report id provided"
      unless $id && $id =~ /^\d+$/;

    my $result =
      $schema->resultset('Report')
      ->find( { id => $id }, { prefetch => 'report_layouts' } )
      or die "No report found for id $id";
    $result->schema($schema) if !$result->schema;
    $result->record_id($record_id)
      if $record_id
      && !$result->record_id;

    return $result if !$result->deleted || $result->deleted == 0;
    return undef;
}

=head2 Load for Edit

Function to load a report for a given id - it requires the report id and the schema to be passed in and will return a report object for editing

=cut

sub load_for_edit {
    my $id     = shift;
    my $schema = shift;

    die "Invalid report id provided"
      unless $id && $id =~ /^\d+$/;

    my $result =
      $schema->resultset('Report')
      ->find( { id => $id }, { prefetch => 'report_layouts' } )
      or die "No report found for id $id";
    $result->schema($schema) if !$result->schema;

    return $result if !$result->deleted || $result->deleted == 0;
    return undef;
}

=head2

Function to load all reports for a given instance - it requires the instance id and the schema to be passed in and will return an array of report objects

=cut

sub load_all_reports {
    my $instance_id = shift;
    my $schema      = shift;

    die "Invalid layout provided"
      unless $instance_id && $instance_id =~ /^\d+$/;

    my $items = $schema->resultset('Report')->search(
        {
            instance_id => $instance_id,
        },
        {
            prefetch => 'report_layouts',
        }
    );

    my $result = [];

    while ( my $next = $items->next ) {
        $next->schema($schema)    if !$next->schema;
        push( @{$result}, $next ) if !$next->deleted || $next->deleted == 0;
    }

    return $result;
}

=head2 Create

Function to create a new report - it requires the schema and a hash of the report data to be passed in and will return a report object

=cut

sub create {
    my ($args) = @_;

    my $schema = $args->{schema}
      or die "No schema provided";

    my $guard = $schema->txn_scope_guard;

    my $report = $schema->resultset('Report')->create(
        {
            user        => $args->{user},
            name        => $args->{name},
            description => $args->{description},
            instance_id => $args->{instance_id},
            createdby   => $args->{user},
            created     => DateTime->now,
            deleted     => 0,
        }
    );

    foreach my $layout ( @{ $args->{layouts} } ) {
        $schema->resultset('ReportLayout')->create(
            {
                report_id => $report->id,
                layout_id => $layout,
            }
        );
    }

    $guard->commit;

    $report->schema($schema) if !$report->schema;

    return $report;
}

1;
