use utf8;
package GADS::Schema::Result::LayoutGroup;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("layout_group");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "permission",
  { data_type => "varchar", is_nullable => 0, size => 45 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint(
  "layout_group_ux_layout_group_permission",
  ["layout_id", "group_id", "permission"],
);

__PACKAGE__->belongs_to(
  "group",
  "GADS::Schema::Result::Group",
  { id => "group_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "layout",
  "GADS::Schema::Result::Layout",
  { id => "layout_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'layout_group_idx_permission', fields => ['permission']);
}

1;
