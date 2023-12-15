use utf8;

package GADS::Schema::Result::Report;

=head1 NAME
GADS::Schema::Result::Report
=cut

use strict;
use warnings;

use Log::Report 'linkspace';
use CtrlO::PDF 0.06;
use GADS::Config;
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
=head2 title
    data_type: 'varchar'
    is_nullable: 1
    size: 128
=head2 description
    data_type: 'varchar'
    is_nullable: 1
    size: 128
=head2 security_marking
    data_type: 'varchar'
    is_nullable: 1
    size: 128
=head2 security_marking_extra
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
    data_type: 'datetime'
    is_nullable: 1
=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "title",
    { data_type => "varchar", is_nullable => 1, size => 128, default=>'Untitled' },
    "description",
    { data_type => "varchar", is_nullable => 1, size => 128 },
    "security_marking",
    { data_type => "varchar", is_nullable => 1, size => 128 },
    "security_marking_extra",
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
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 1
    }
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

sub validate {
    my ( $self, $value, %options ) = @_;

    my $name        = $self->name;
    my $title       = $self->title;
    my $instance_id = $self->instance_id;
    my $layouts     = $self->report_layouts;

    error __ "No name given" unless $name;
    error __ "No title given" unless $title;
    error __ "You must provide at least one row to display in the report"
      unless $layouts;

    0;
}

=head2 Record ID
This is the ID of the Record in the Instance to display the report for
=cut

has record_id => (
    is       => 'rw',
    required => 0,
);

has default_marking => (
    is => 'lazy',
);

has site =>(
    is=>'ro',
);

sub _build_default_marking {
    my $self = shift;
    return $self->site->security_marking;
}

=head2 _data
This is the data for the report as pulled from the instance record identfied by the Record Id
=cut

sub _data
{   my ($self, $record) = @_;

    my $result = [];

    my $layouts = $self->report_layouts;
    my $user    = $self->user;

    my $gads_layout = $record->layout;

    while ( my $layout = $layouts->next ) {
        my $column = $gads_layout->column( $layout->layout_id, permission => 'read' ) or next;
        my $datum  = $record->get_field_value($column);
        my $data   = { 'name' => $layout->layout->name, 'value' => $datum || '' };
        push( @{$result}, $data );
    }

    return $result;
}

=head1 Object functions
=head2 Update Report
Function to update a report - it requires the schema and any updated fields to be passed in and will return a report object
=cut

sub update_report {
    my ( $self, $args ) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    $self->update( { 
        name => $args->{name},
        description => $args->{description},
        title => $args->{title},
        security_marking => $args->{security_marking} eq '' ? undef : $args->{security_marking},
        security_marking_extra => $args->{security_marking_extra} eq '' ? undef : $args->{security_marking_extra},
    } );

    my $layouts = $args->{layouts};

    foreach my $layout (@$layouts) {
        $self->find_or_create_related( 'report_layouts',
            { layout_id => $layout } );
    }

    my $search = {};

    $search->{layout_id} = { '!=' => [ -and => @$layouts ], }
      if @$layouts;
    $self->search_related( 'report_layouts', $search )->delete;

    $guard->commit;

    return $self;
}

=head2 Remove
Function to delete a report - it requires the schema to be passed in and will return nothing.
If the ID is invalid, or there's nothing to delete, it will do nothing.
=cut

sub remove {
    my $self = shift;

    return if !$self->in_storage || $self->deleted;

    my $guard = $self->result_source->schema->txn_scope_guard;

    $self->update( { deleted => DateTime->now } );

    $guard->commit;
}

=head2 Create PDF
Function to create a PDF of the report - it will return a PDF object
=cut

sub create_pdf
{   my ($self, $record) = @_;

    my $marking = $self->security_marking;
    $marking = $self->settings->load_string('security_marking') unless $marking && $marking ne '';
    my $security_marking_extra = $self->security_marking_extra;
    $marking = "$marking - $security_marking_extra" if $security_marking_extra;
    my $background = $self->settings->load_string('background') || '#007C88';
    my $foreground = $self->settings->load_string('foreground') || '#FFFFFF';

    my $pdf    = CtrlO::PDF->new(
        header => $marking,
        footer => $marking,
    );

    $pdf->add_page;
    $pdf->heading( $self->title || $self->name, size => 16 );
    $pdf->heading( $self->description, size => 14) if $self->description;

    my $fields = [ [ 'Field', 'Value' ] ];

    my $data = $self->_data($record);

    push( @{$fields}, [ $_->{name}, $_->{value} ] ) foreach (@$data);

    my $hdr_props = {
        repeat    => 1,
        justify   => 'center',
        font_size => 12,
        bg_color  => $background,
        fg_color  => $foreground,
    };

    $pdf->table(
        data         => $fields,
        header_props => $hdr_props,
        border_c     => $background,
        h_border_w   => 1,
    );

    $pdf;
}

=head2 Get fields for render
Function to get the fields for the report - it will return an array of fields
=cut

sub fields_for_render {
    my $self   = shift;
    my $layout = shift;

    my %checked = map { $_->layout_id => 1 } $self->report_layouts;

    my @fields = map {
        +{
            id         => $_->id,
            name       => $_->name,
            is_checked => $checked{ $_->id },
        }
    } $layout->all( user_can_read => 1 );

    return \@fields;
}

has settings => (
    is=> 'lazy',
);

1;
