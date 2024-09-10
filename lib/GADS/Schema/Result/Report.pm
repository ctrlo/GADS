use utf8;

package GADS::Schema::Result::Report;

=head1 NAME
GADS::Schema::Result::Report
=cut

use strict;
use warnings;

use Log::Report 'linkspace';
use CtrlO::PDF 0.06;
use PDF::Table 1.006;    # Needed for colspan feature
use GADS::Config;
use Moo;

extends 'DBIx::Class::Core';
sub BUILDARGS { $_[2] || {} }

=head1 COMPONENTS LOADED
=over 4
=item * L<DBIx::Class::InflateColumn::DateTime>
=back
=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "+GADS::DBIC");

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
    data_type: 'text'
    is_nullable: 1
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
    data_type: 'datetime'
    is_nullable: 1
=head2 security_marking
    data_type: 'text'
    is_nullable: 1
=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "text", is_nullable => 0, size => 128 },
    "title",
    { data_type => "text", is_nullable => 1 },
    "description",
    { data_type => "text", is_nullable => 1, size => 128 },
    "user_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "createdby",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "created",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 1,
    },
    "instance_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "deleted",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 1,
    },
    "security_marking",
    { data_type => "text", is_nullable => 1 },
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
        on_update     => "NO ACTION",
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
        on_update     => "NO ACTION",
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
        on_update     => "NO ACTION",
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

=head2 report_groups
Type: has_many
Related object: L<GADS::Schema::Result::ReportGroup>
=cut

__PACKAGE__->has_many(
    "report_groups",
    "GADS::Schema::Result::ReportGroup",
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

sub validate
{   my ($self, $value, %options) = @_;

    my $name        = $self->name;
    my $title       = $self->title;
    my $instance_id = $self->instance_id;
    my $layouts     = $self->report_layouts;

    error __ "No name given"  unless $name;
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

=head1 Object functions
=head2 Update Report
Function to update a report - it requires the schema and any updated fields to be passed in and will return a report object
=cut

sub update_report
{   my ($self, $args) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    $self->update({
        name             => $args->{name},
        title            => $args->{title},
        description      => $args->{description},
        security_marking => $args->{security_marking},
    });

    my $layouts = $args->{layouts};

    foreach my $layout (@$layouts)
    {
        $self->find_or_create_related('report_layouts',
            { layout_id => $layout });
    }

    my $search = {};

    $search->{layout_id} = { '!=' => [ -and => @$layouts ] }
        if @$layouts;
    $self->search_related('report_layouts', $search)->delete;

    my $groups = $args->{groups};

    foreach my $group (@$groups)
    {
        $self->find_or_create_related('report_groups',
            { group_id => $group });
    }

    my $search_groups = {};

    $search_groups->{group_id} = { '!=' => [ -and => @$groups ] }
        if @$groups;
    $self->search_related('report_groups', $search_groups)->delete;

    $guard->commit;

    return $self;
}

=head2 Remove
Function to delete a report - it requires the schema to be passed in and will return nothing.
If the ID is invalid, or there's nothing to delete, it will do nothing.
=cut

sub remove
{   my $self = shift;

    return if !$self->in_storage || $self->deleted;

    my $guard = $self->result_source->schema->txn_scope_guard;

    $self->update({ deleted => DateTime->now });

    $guard->commit;
}

=head2 Create PDF
Function to create a PDF of the report - it will return a PDF object
=cut

sub create_pdf
{   my ($self, $record, $user) = @_;

    my $marking = $self->_read_security_marking;
    my $logo    = $self->instance->site->create_temp_logo;

    my $pdf;
    my $topmargin = 0;

    if ($logo)
    {
        $pdf = CtrlO::PDF->new(
            header => $marking,
            footer => $marking,
            logo   => $logo,
        );

# Adjust the top margin to allow for the logo - 30px allows the table (below the logo) to not encroach on the logo when rendered
# This is used rather than overcomplicating and using image size to centre the header, and then having to "drop" the table down to avoid the logo
        $topmargin = -30;
    }
    else
    {
        $pdf = CtrlO::PDF->new(
            header => $marking,
            footer => $marking,
        );
    }

    $pdf->add_page;
    $pdf->heading($self->title || $self->name, topmargin => $topmargin);
    $pdf->text($self->description, size => 14) if $self->description;

    my $hdr_props = {
        repeat    => 0,
        justify   => 'center',
        font_size => 12,
        bg_color  => '#007c88',
        fg_color  => '#ffffff',
    };

    my %include = map { $_->layout_id => 1 } $self->report_layouts;
    my $result  = [ grep $include{ $_->id }, @{ $record->columns_render } ];

    my @cols   = $record->presentation_map_columns(columns => $result);
    my @topics = $record->get_topics(\@cols);

    my $i = 0;
    foreach my $topic (@topics)
    {
        my $topic_name = $topic->{topic} ? $topic->{topic}->name : 'Other';
        my $fields     = [ [$topic_name] ];

        my $width = 0;
        foreach my $col (@{ $topic->{columns} })
        {
            if ($col->{data}->{selected_values})
            {
                my $first = 1;
                foreach my $c (@{ $col->{data}->{selected_values} })
                {
                    my $values = $c->{values};
                    $width =
                        $width < (scalar(@$values) + 1)
                        ? scalar(@$values) + 1
                        : $width;
                    push @$fields, [ $first ? $col->{name} : '', @$values ];
                    $first = 0;
                }
            }
            else
            {
                if ($col->{data}->{value})
                {
                    push @$fields,
                        [ $col->{name}, $col->{data}->{value} || "" ];
                }
                else
                {
                    push @$fields, [ $col->{name}, $col->{data}->{grade} ];
                }
                $width = 2 if $width < 2;
            }
        }

        my $cell_props = [];
        foreach my $d (@$fields)
        {
            my $has = @$d;

            # $max_fields does not include field name
            my $gap = $width - $has + 1;
            push @$d, undef for (1 .. $gap);
            push @$cell_props,
                [ (undef) x ($has - 1), { colspan => $gap + 1 }, ];
        }

        $pdf->table(
            data         => $fields,
            header_props => $hdr_props,
            border_c     => '#007C88',
            h_border_w   => 1,
            cell_props   => $cell_props,
            size         => '4cm *',
        );
    }

    my $now    = DateTime->now;
    my $format = GADS::Config->instance->dateformat;
    $pdf->text(
        'Last edited by '
            . $self->edited_user->value . ' on '
            . $record->created->format_cldr($format) . ' at '
            . $record->created->hms,
        size => 10
    );
    $pdf->text(
        'Report generated by '
            . $user->value . ' on '
            . $now->format_cldr($format) . ' at '
            . $now->hms,
        size => 10
    );

    $pdf;
}

=head2 Get fields for render
Function to get the fields for the report - it will return an array of fields
=cut

sub fields_for_render
{   my $self   = shift;
    my $layout = shift;

    my %checked = map { $_->layout_id => 1 } $self->report_layouts;

    my @fields = map {
        +{
            id         => $_->id,
            name       => $_->name,
            is_checked => $checked{ $_->id },
        }
    } $layout->all(user_can_read => 1);

    return \@fields;
}

sub _read_security_marking
{   my $self = shift;

    return $self->security_marking || $self->instance->read_security_marking;
}

sub group_ids
{   my $self = shift;

    my @groups = $self->report_groups;

    my @result = map {$_->group_id} @groups;

    return \@result;
}

1;
