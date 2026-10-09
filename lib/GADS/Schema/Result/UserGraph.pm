use utf8;
package GADS::Schema::Result::UserGraph;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("user_graph");

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "graph_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "graph",
  "GADS::Schema::Result::Graph",
  { id => "graph_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "user",
  "GADS::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
