use utf8;
package GADS::Schema::Result::MetricGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::MetricGroup

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<metric_group>

=cut

__PACKAGE__->table("metric_group");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 instance_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "instance_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 graphs

Type: has_many

Related object: L<GADS::Schema::Result::Graph>

=cut

__PACKAGE__->has_many(
  "graphs",
  "GADS::Schema::Result::Graph",
  { "foreign.metric_group" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 instance

Type: belongs_to

Related object: L<GADS::Schema::Result::Instance>

=cut

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

=head2 metrics

Type: has_many

Related object: L<GADS::Schema::Result::Metric>

=cut

__PACKAGE__->has_many(
  "metrics",
  "GADS::Schema::Result::Metric",
  { "foreign.metric_group" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-07-24 21:26:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l1aL7wQuyFNonrDS0ywGSg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
