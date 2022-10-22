use utf8;
package GADS::Schema::Result::InstanceRag;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("instance_rag");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "instance_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "rag",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "enabled",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint(
  "instance_rag_ux_instance_rag",
  ["instance_id", "rag"],
);

__PACKAGE__->belongs_to(
  "instance",
  "GADS::Schema::Result::Instance",
  { id => "instance_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
