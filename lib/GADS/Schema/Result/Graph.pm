use utf8;
package GADS::Schema::Result::Graph;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::Graph

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

=head1 TABLE: C<graph>

=cut

__PACKAGE__->table("graph");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 y_axis

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 y_axis_stack

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 y_axis_label

  data_type: 'text'
  is_nullable: 1

=head2 x_axis

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 x_axis_link

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 x_axis_grouping

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 group_by

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 stackseries

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 as_percent

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 metric_group

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 instance_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "y_axis",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "y_axis_stack",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "y_axis_label",
  { data_type => "text", is_nullable => 1 },
  "x_axis",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "x_axis_link",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "x_axis_grouping",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "group_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "stackseries",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "as_percent",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "metric_group",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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

=head2 group_by

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->belongs_to(
  "group_by",
  "GADS::Schema::Result::Layout",
  { id => "group_by" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
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

=head2 metric_group

Type: belongs_to

Related object: L<GADS::Schema::Result::MetricGroup>

=cut

__PACKAGE__->belongs_to(
  "metric_group",
  "GADS::Schema::Result::MetricGroup",
  { id => "metric_group" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 user_graphs

Type: has_many

Related object: L<GADS::Schema::Result::UserGraph>

=cut

__PACKAGE__->has_many(
  "user_graphs",
  "GADS::Schema::Result::UserGraph",
  { "foreign.graph_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 x_axis

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->belongs_to(
  "x_axis",
  "GADS::Schema::Result::Layout",
  { id => "x_axis" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 x_axis_link

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->belongs_to(
  "x_axis_link",
  "GADS::Schema::Result::Layout",
  { id => "x_axis_link" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 y_axis

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->belongs_to(
  "y_axis",
  "GADS::Schema::Result::Layout",
  { id => "y_axis" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-13 16:02:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oopGdIbM/BeViDcYja0kXg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
