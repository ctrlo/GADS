use utf8;
package GADS::Schema::Result::AlertSend;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("alert_send");

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "alert_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "current_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "status",
  { data_type => "char", is_nullable => 1, size => 7 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint(
  "alert_send_all",
  ["layout_id", "alert_id", "current_id", "status"],
);

__PACKAGE__->belongs_to(
  "alert",
  "GADS::Schema::Result::Alert",
  { id => "alert_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "current",
  "GADS::Schema::Result::Current",
  { id => "current_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "layout",
  "GADS::Schema::Result::Layout",
  { id => "layout_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

1;
