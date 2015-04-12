use utf8;
package GADS::Schema::Result::Group;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::Group

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

=head1 TABLE: C<group>

=cut

__PACKAGE__->table("group");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 layout_groups

Type: has_many

Related object: L<GADS::Schema::Result::LayoutGroup>

=cut

__PACKAGE__->has_many(
  "layout_groups",
  "GADS::Schema::Result::LayoutGroup",
  { "foreign.group_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_groups

Type: has_many

Related object: L<GADS::Schema::Result::UserGroup>

=cut

__PACKAGE__->has_many(
  "user_groups",
  "GADS::Schema::Result::UserGroup",
  { "foreign.group_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-02-15 11:41:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jofia4P4SMX470Xy+CNKWA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
