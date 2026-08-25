use utf8;
package GADS::Schema::Result::Layout;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("layout");

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

__PACKAGE__->set_primary_key("id");

# name_short should actually be unique across a whole site, but this at least
# stops multiple internal columns being inserted into the same table
__PACKAGE__->add_unique_constraint("layout_ux_instance_name_short", ["instance_id", "name_short"]);

__PACKAGE__->has_many(
  "alert_caches",
  "GADS::Schema::Result::AlertCache",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "alerts_send",
  "GADS::Schema::Result::AlertSend",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "alert_columns",
  "GADS::Schema::Result::AlertColumn",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "calcs",
  "GADS::Schema::Result::Calc",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "calcvals",
  "GADS::Schema::Result::Calcval",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "curval_fields_children",
  "GADS::Schema::Result::CurvalField",
  { "foreign.child_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "curval_fields_parents",
  "GADS::Schema::Result::CurvalField",
  { "foreign.parent_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "curvals",
  "GADS::Schema::Result::Curval",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "dateranges",
  "GADS::Schema::Result::Daterange",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "dates",
  "GADS::Schema::Result::Date",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

__PACKAGE__->has_many(
  "display_fields",
  "GADS::Schema::Result::DisplayField",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "enums",
  "GADS::Schema::Result::Enum",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "enumvals",
  "GADS::Schema::Result::Enumval",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "files",
  "GADS::Schema::Result::File",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "filters",
  "GADS::Schema::Result::Filter",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "graph_groups_by",
  "GADS::Schema::Result::Graph",
  { "foreign.group_by" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "graph_y_axes",
  "GADS::Schema::Result::Graph",
  { "foreign.y_axis" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "graphs_x_axis",
  "GADS::Schema::Result::Graph",
  { "foreign.x_axis" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

__PACKAGE__->has_many(
  "instances",
  "GADS::Schema::Result::Instance",
  { "foreign.sort_layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "intgrs",
  "GADS::Schema::Result::Intgr",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "layout_depend_layouts",
  "GADS::Schema::Result::LayoutDepend",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "layout_groups",
  "GADS::Schema::Result::LayoutGroup",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "layout_link_parents",
  "GADS::Schema::Result::Layout",
  { "foreign.link_parent" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "layouts",
  "GADS::Schema::Result::Layout",
  { "foreign.display_field" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "layouts_depend_depends_on",
  "GADS::Schema::Result::LayoutDepend",
  { "foreign.depends_on" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

__PACKAGE__->has_many(
  "people",
  "GADS::Schema::Result::Person",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "rags",
  "GADS::Schema::Result::Rag",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "ragvals",
  "GADS::Schema::Result::Ragval",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "sorts",
  "GADS::Schema::Result::Sort",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "strings",
  "GADS::Schema::Result::String",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "view_layouts",
  "GADS::Schema::Result::ViewLayout",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "report_layouts",
  "GADS::Schema::Result::ReportLayout",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
