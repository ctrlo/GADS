use utf8;
package GADS::Schema::Result::LayoutDepend;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("layout_depend");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "depends_on",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "depend_on",
  "GADS::Schema::Result::Layout",
  { id => "depends_on" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "layout",
  "GADS::Schema::Result::Layout",
  { id => "layout_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
