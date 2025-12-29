use utf8;
package GADS::Schema::Result::Calcval;

use strict;
use warnings;

use Moo;

extends 'DBIx::Class::Core';
sub BUILDARGS { $_[2] || {} }

with 'GADS::Role::Purgable';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("calcval");

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "record_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value_text",
  { data_type => "text", is_nullable => 1 },
  "value_int",
  { data_type => "bigint", is_nullable => 1 },
  "value_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "value_numeric",
  { data_type => "decimal", is_nullable => 1, size => [20, 5] },
  "value_date_from",
  { data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "value_date_to",
  { data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "purged_by",
  { data_type => "bigint", is_nullable => 1, is_foreign_key => 1 },
  "purged_on",
  { data_type => "datetime", is_nullable => 1, datetime_undef_if_invalid => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "layout",
  "GADS::Schema::Result::Layout",
  { id => "layout_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "record",
  "GADS::Schema::Result::Record",
  { id => "record_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "purged_by",
  "GADS::Schema::Result::User",
  { id => "purged_by" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'calcval_idx_value_text', fields => [ { name => 'value_text', prefix_length => 64 } ]);
    $sqlt_table->add_index(name => 'calcval_idx_value_numeric', fields => [ 'value_numeric' ]);
    $sqlt_table->add_index(name => 'calcval_idx_value_int', fields => [ 'value_int' ]);
    $sqlt_table->add_index(name => 'calcval_idx_value_date', fields => [ 'value_date' ]);
}

sub _build_valuefield { ('value_text','value_numeric','value_int','value_date','value_date_from','value_date_to'); }

1;
