use utf8;
package GADS::Schema::Result::Metric;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("metric");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "metric_group",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "x_axis_value",
  { data_type => "text", is_nullable => 1 },
  "target",
  { data_type => "bigint", is_nullable => 1 },
  "y_axis_grouping_value",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "metric_group",
  "GADS::Schema::Result::MetricGroup",
  { id => "metric_group" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
