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

=head2 view_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 yaxis

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 layout_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 layout_id_group

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 layout_id2

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
  "view_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "yaxis",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "layout_id_group",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "layout_id2",
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

=head2 layout

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

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

=head2 layout_id2

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->belongs_to(
  "layout_id2",
  "GADS::Schema::Result::Layout",
  { id => "layout_id2" },
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

=head2 view

Type: belongs_to

Related object: L<GADS::Schema::Result::View>

=cut

__PACKAGE__->belongs_to(
  "view",
  "GADS::Schema::Result::View",
  { id => "view_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-08 16:16:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WTS/olJLJpOg6uoH+0Cd5A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
