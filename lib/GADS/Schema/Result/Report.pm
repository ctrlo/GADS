use utf8;

package GADS::Schema::Result::Report;

=head1 NAME

GADS::Schema::Result::Report

=cut

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

#TODO: need to work out how to implement this properly
sub validate {
    my ( $self, $value, %options ) = @_;
    return 1 if !$value;

    my $name = $self->name;
    my $instance_id = $self->instance_id;
    my $layouts = $self->report_layouts;

    return 0 unless $options{fatal};
    return 1;
}

has _is_new => (
    is      => 'rwp',
    default => 1,
    builder => sub {
        my $self = shift;
        return 0 if $self->id;
        return 1;
    },
);

has schema => (
    is       => 'rw',
    required => 0,
);

has record_id => (
    is       => 'rw',
    required => 0,
);

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

sub load_all_reports {
    my $instance_id = shift;
    my $schema      = shift;

    die "Invalid layout provided"
      unless $instance_id && $instance_id =~ /^\d+$/;

    my $items = $schema->resultset('Report')->search(
        {
            instance_id => $instance_id,
        }
    );

    my $result = [];

    while ( my $next = $items->next ) {
        $next->schema($schema) if !$next->schema;
        push( @{$result}, $next );
    }

    return $result;
}

# sub add_layout {
#     my $self      = shift;
#     my $layout_id = shift;

#     die "You aren't doing it right" unless ref($self) eq __PACKAGE__;
#     die "No layout id provided"     unless $layout_id;

#     if ( !$self->layout_ids ) {
#         $self->layout_ids( [] );
#     }

#     push @{ $self->layout_ids }, $layout_id;
# }

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

    my $column = $self->_find_column( $layout->layout->name, $gads_layout->columns );

    my $datum = $record->get_field_value($column);

    return { 'name' => $layout->layout->name, 'value' => $datum };
}

sub _find_column {
    my $self        = shift;
    my $column_name = shift;
    my $columns     = shift;

#TODO: I know I could probably do this with a grep, but for some reason, I can't get said grep to work
#grep { $_->name eq $column_name } @{$columns};
    foreach my $col ( @{$columns} ) {
        if ( $col->name eq $column_name ) {
            return $col;
        }
    }

    return undef;
}

sub load {
    my $id        = shift;
    my $record_id = shift;
    my $schema    = shift;

    die "Invalid report id provided"
      unless $id && $id =~ /^\d+$/;

    my $result = $schema->resultset('Report')->find($id)
      or die "No report found for id $id";
    $result->schema($schema) if !$result->schema;
    $result->record_id($record_id)
      if $record_id
      && !$result->record_id;

    return $result;
}

1;
