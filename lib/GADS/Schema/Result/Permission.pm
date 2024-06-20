use utf8;

package GADS::Schema::Result::Permission;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::Permission

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

=head1 TABLE: C<permission>

=cut

__PACKAGE__->table("permission");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 order

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "description",
    { data_type => "text", is_nullable => 1 },
    "order",
    { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 user_permissions

Type: has_many

Related object: L<GADS::Schema::Result::UserPermission>

=cut

__PACKAGE__->has_many(
    "user_permissions",
    "GADS::Schema::Result::UserPermission",
    { "foreign.permission_id" => "self.id" },
    { cascade_copy            => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-09-18 12:17:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JcI4rvB0yPlTuJx1AcVVSA

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
