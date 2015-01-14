use utf8;
package GADS::Schema::Result::Enumval;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::Enumval

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

=head1 TABLE: C<enumval>

=cut

__PACKAGE__->table("enumval");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 enum_id

  data_type: 'integer'
  is_nullable: 1

=head2 value

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 layout_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 deleted

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 parent

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "enum_id",
  { data_type => "integer", is_nullable => 1 },
  "value",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "deleted",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "parent",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 enums

Type: has_many

Related object: L<GADS::Schema::Result::Enum>

=cut

__PACKAGE__->has_many(
  "enums",
  "GADS::Schema::Result::Enum",
  { "foreign.value" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 enumvals

Type: has_many

Related object: L<GADS::Schema::Result::Enumval>

=cut

__PACKAGE__->has_many(
  "enumvals",
  "GADS::Schema::Result::Enumval",
  { "foreign.parent" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

=head2 parent

Type: belongs_to

Related object: L<GADS::Schema::Result::Enumval>

=cut

__PACKAGE__->belongs_to(
  "parent",
  "GADS::Schema::Result::Enumval",
  { id => "parent" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-01-06 03:17:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zOgWKJvXSgwTUPlzuaXpzA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
