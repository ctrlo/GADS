use utf8;
package GADS::Schema::Result::GraphColor;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("graph_color");

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "color",
  { data_type => "char", is_nullable => 1, size => 6 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("ux_graph_color_name", ["name"]);

1;
