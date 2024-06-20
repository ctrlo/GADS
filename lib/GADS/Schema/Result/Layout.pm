use utf8;

package GADS::Schema::Result::Layout;

=head1 NAME

GADS::Schema::Result::Layout

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<layout>

=cut

__PACKAGE__->table("layout");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 name_short

  data_type: 'text'
  is_nullable: 1

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 permission

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 optional

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 remember

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 isunique

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 textbox

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 typeahead

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 force_regex

  data_type: 'text'
  is_nullable: 1

=head2 position

  data_type: 'integer'
  is_nullable: 1

=head2 ordering

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 end_node_only

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 multivalue

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 helptext

  data_type: 'text'
  is_nullable: 1

=head2 options

  data_type: 'text'
  is_nullable: 1

=head2 display_field

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 display_regex

  data_type: 'text'
  is_nullable: 1

=head2 instance_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 link_parent

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 related_field

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 topic_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 aggregate

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 group_display

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 notes

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "text", is_nullable => 1 },
    "name_short",
    { data_type => "varchar", is_nullable => 1, size => 64 },
    "type",
    { data_type => "varchar", is_nullable => 1, size => 45 },
    "permission",
    { data_type => "integer", default_value => 0, is_nullable => 0 },
    "optional",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
    "remember",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
    "isunique",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
    "textbox",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
    "typeahead",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
    "force_regex",
    { data_type => "text", is_nullable => 1 },
    "position",
    { data_type => "integer", is_nullable => 1 },
    "ordering",
    { data_type => "varchar", is_nullable => 1, size => 45 },
    "end_node_only",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
    "multivalue",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
    "can_child",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
    "internal",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
    "description",
    { data_type => "text", is_nullable => 1 },
    "helptext",
    { data_type => "text", is_nullable => 1 },
    "options",
    { data_type => "text", is_nullable => 1 },
    "display_field",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "display_regex",
    { data_type => "text", is_nullable => 1 },
    "display_condition",
    { data_type => "char", is_nullable => 1, size => 3 },
    "display_matchtype",
    { data_type => "text", is_nullable => 1 },
    "instance_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "link_parent",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "related_field",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "width",
    { data_type => "integer", is_nullable => 0, default_value => 50 },
    "filter",
    { data_type => "text", is_nullable => 1 },
    "topic_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "aggregate",
    { data_type => "varchar", is_nullable => 1, size => 45 },
    "group_display",
    { data_type => "varchar", is_nullable => 1, size => 45 },
    "lookup_endpoint",
    { data_type => "text", is_nullable => 1 },
    "lookup_group",
    { data_type => "smallint", is_nullable => 1 },
    "notes",
    { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<layout_ux_instance_name_short>

=over 4

=item * L</record_id>

=item * L</layout_id>

=back

=cut

# name_short should actually be unique across a whole site, but this at least
# stops multiple internal columns being inserted into the same table
__PACKAGE__->add_unique_constraint("layout_ux_instance_name_short",
    [ "instance_id", "name_short" ]);

=head1 RELATIONS

=head2 alert_caches

Type: has_many

Related object: L<GADS::Schema::Result::AlertCache>

=cut

__PACKAGE__->has_many(
    "alert_caches",
    "GADS::Schema::Result::AlertCache",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 alerts_send

Type: has_many

Related object: L<GADS::Schema::Result::AlertSend>

=cut

__PACKAGE__->has_many(
    "alerts_send",
    "GADS::Schema::Result::AlertSend",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 alert_columns

Type: has_many

Related object: L<GADS::Schema::Result::AlertColumn>

=cut

__PACKAGE__->has_many(
    "alert_columns",
    "GADS::Schema::Result::AlertColumn",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 calcs

Type: has_many

Related object: L<GADS::Schema::Result::Calc>

=cut

__PACKAGE__->has_many(
    "calcs", "GADS::Schema::Result::Calc",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 calcvals

Type: has_many

Related object: L<GADS::Schema::Result::Calcval>

=cut

__PACKAGE__->has_many(
    "calcvals",
    "GADS::Schema::Result::Calcval",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 curval_fields_children

Type: has_many

Related object: L<GADS::Schema::Result::CurvalField>

=cut

__PACKAGE__->has_many(
    "curval_fields_children",
    "GADS::Schema::Result::CurvalField",
    { "foreign.child_id" => "self.id" },
    { cascade_copy       => 0, cascade_delete => 0 },
);

=head2 curval_fields_parents

Type: has_many

Related object: L<GADS::Schema::Result::CurvalField>

=cut

__PACKAGE__->has_many(
    "curval_fields_parents",
    "GADS::Schema::Result::CurvalField",
    { "foreign.parent_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 curvals

Type: has_many

Related object: L<GADS::Schema::Result::Curval>

=cut

__PACKAGE__->has_many(
    "curvals",
    "GADS::Schema::Result::Curval",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 dateranges

Type: has_many

Related object: L<GADS::Schema::Result::Daterange>

=cut

__PACKAGE__->has_many(
    "dateranges",
    "GADS::Schema::Result::Daterange",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 dates

Type: has_many

Related object: L<GADS::Schema::Result::Date>

=cut

__PACKAGE__->has_many(
    "dates", "GADS::Schema::Result::Date",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 display_field

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->belongs_to(
    "display_field",
    "GADS::Schema::Result::Layout",
    { id => "display_field" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

=head2 display_fields

Type: has_many

Related object: L<GADS::Schema::Result::DisplayField>

=cut

__PACKAGE__->has_many(
    "display_fields",
    "GADS::Schema::Result::DisplayField",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 enums

Type: has_many

Related object: L<GADS::Schema::Result::Enum>

=cut

__PACKAGE__->has_many(
    "enums", "GADS::Schema::Result::Enum",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 enumvals

Type: has_many

Related object: L<GADS::Schema::Result::Enumval>

=cut

__PACKAGE__->has_many(
    "enumvals",
    "GADS::Schema::Result::Enumval",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 file_options

Type: has_many

Related object: L<GADS::Schema::Result::FileOption>

=cut

__PACKAGE__->has_many(
    "file_options",
    "GADS::Schema::Result::FileOption",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 files

Type: has_many

Related object: L<GADS::Schema::Result::File>

=cut

__PACKAGE__->has_many(
    "files", "GADS::Schema::Result::File",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 filters

Type: has_many

Related object: L<GADS::Schema::Result::Filter>

=cut

__PACKAGE__->has_many(
    "filters",
    "GADS::Schema::Result::Filter",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 graph_groups_by

Type: has_many

Related object: L<GADS::Schema::Result::Graph>

=cut

__PACKAGE__->has_many(
    "graph_groups_by", "GADS::Schema::Result::Graph",
    { "foreign.group_by" => "self.id" },
    { cascade_copy       => 0, cascade_delete => 0 },
);

=head2 graph_y_axes

Type: has_many

Related object: L<GADS::Schema::Result::Graph>

=cut

__PACKAGE__->has_many(
    "graph_y_axes", "GADS::Schema::Result::Graph",
    { "foreign.y_axis" => "self.id" },
    { cascade_copy     => 0, cascade_delete => 0 },
);

=head2 graphs_x_axis

Type: has_many

Related object: L<GADS::Schema::Result::Graph>

=cut

__PACKAGE__->has_many(
    "graphs_x_axis", "GADS::Schema::Result::Graph",
    { "foreign.x_axis" => "self.id" },
    { cascade_copy     => 0, cascade_delete => 0 },
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

=head2 topic

Type: belongs_to

Related object: L<GADS::Schema::Result::Topic>

=cut

__PACKAGE__->belongs_to(
    "topic",
    "GADS::Schema::Result::Topic",
    { id => "topic_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

=head2 instances

Type: has_many

Related object: L<GADS::Schema::Result::Instance>

=cut

__PACKAGE__->has_many(
    "instances",
    "GADS::Schema::Result::Instance",
    { "foreign.sort_layout_id" => "self.id" },
    { cascade_copy             => 0, cascade_delete => 0 },
);

=head2 intgrs

Type: has_many

Related object: L<GADS::Schema::Result::Intgr>

=cut

__PACKAGE__->has_many(
    "intgrs", "GADS::Schema::Result::Intgr",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 layout_depend_layouts

Type: has_many

Related object: L<GADS::Schema::Result::LayoutDepend>

=cut

__PACKAGE__->has_many(
    "layout_depend_layouts",
    "GADS::Schema::Result::LayoutDepend",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 layout_groups

Type: has_many

Related object: L<GADS::Schema::Result::LayoutGroup>

=cut

__PACKAGE__->has_many(
    "layout_groups",
    "GADS::Schema::Result::LayoutGroup",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 layout_link_parents

Type: has_many

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->has_many(
    "layout_link_parents",
    "GADS::Schema::Result::Layout",
    { "foreign.link_parent" => "self.id" },
    { cascade_copy          => 0, cascade_delete => 0 },
);

=head2 layouts

Type: has_many

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->has_many(
    "layouts",
    "GADS::Schema::Result::Layout",
    { "foreign.display_field" => "self.id" },
    { cascade_copy            => 0, cascade_delete => 0 },
);

=head2 layouts_depend_depends_on

Type: has_many

Related object: L<GADS::Schema::Result::LayoutDepend>

=cut

__PACKAGE__->has_many(
    "layouts_depend_depends_on",
    "GADS::Schema::Result::LayoutDepend",
    { "foreign.depends_on" => "self.id" },
    { cascade_copy         => 0, cascade_delete => 0 },
);

=head2 link_parent

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->belongs_to(
    "link_parent",
    "GADS::Schema::Result::Layout",
    { id => "link_parent" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

=head2 related_field

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->belongs_to(
    "related_field",
    "GADS::Schema::Result::Layout",
    { id => "related_field" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

=head2 people

Type: has_many

Related object: L<GADS::Schema::Result::Person>

=cut

__PACKAGE__->has_many(
    "people",
    "GADS::Schema::Result::Person",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 rags

Type: has_many

Related object: L<GADS::Schema::Result::Rag>

=cut

__PACKAGE__->has_many(
    "rags", "GADS::Schema::Result::Rag",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 ragvals

Type: has_many

Related object: L<GADS::Schema::Result::Ragval>

=cut

__PACKAGE__->has_many(
    "ragvals",
    "GADS::Schema::Result::Ragval",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 sorts

Type: has_many

Related object: L<GADS::Schema::Result::Sort>

=cut

__PACKAGE__->has_many(
    "sorts", "GADS::Schema::Result::Sort",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 strings

Type: has_many

Related object: L<GADS::Schema::Result::String>

=cut

__PACKAGE__->has_many(
    "strings",
    "GADS::Schema::Result::String",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 view_layouts

Type: has_many

Related object: L<GADS::Schema::Result::ViewLayout>

=cut

__PACKAGE__->has_many(
    "view_layouts",
    "GADS::Schema::Result::ViewLayout",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 report_layouts
Type: has_many
Related object: L<GADS::Schema::Result::ReportLayout>
=cut

__PACKAGE__->has_many(
    "report_layouts",
    "GADS::Schema::Result::ReportLayout",
    { "foreign.layout_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

1;
