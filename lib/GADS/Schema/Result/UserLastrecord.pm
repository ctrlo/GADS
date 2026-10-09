use utf8;
package GADS::Schema::Result::UserLastrecord;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("user_lastrecord");

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "record_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "instance_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "user_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "instance",
  "GADS::Schema::Result::Instance",
  { id => "instance_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "record",
  "GADS::Schema::Result::Record",
  { id => "record_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "user",
  "GADS::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
