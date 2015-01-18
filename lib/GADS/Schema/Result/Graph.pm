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

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 5012

=head2 y_axis

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 y_axis_stack

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 y_axis_label

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 x_axis

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

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 5012 },
  "y_axis",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "y_axis_stack",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "y_axis_label",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "x_axis",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "x_axis_grouping",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "group_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "stackseries",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-01-06 03:17:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2o9Cx9cXe4LNr7U5Fd59Kw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
