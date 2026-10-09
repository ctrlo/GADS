use utf8;
package GADS::Schema::Result::MetricGroup;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("metric_group");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "instance_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "graphs",
  "GADS::Schema::Result::Graph",
  { "foreign.metric_group" => "self.id" },
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

__PACKAGE__->has_many(
  "metrics",
  "GADS::Schema::Result::Metric",
  { "foreign.metric_group" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
