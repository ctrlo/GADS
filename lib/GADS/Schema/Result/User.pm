use utf8;
package GADS::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::User

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

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 firstname

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 surname

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 title

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 organisation

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 permission

  data_type: 'smallint'
  is_nullable: 1

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 pwchanged

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 resetpw

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 deleted

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 lastlogin

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 lastrecord

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 value

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=head2 account_request

  data_type: 'smallint'
  default_value: 0
  is_nullable: 1

=head2 account_request_notes

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "firstname",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "surname",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "title",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "organisation",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "permission",
  { data_type => "smallint", is_nullable => 1 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "pwchanged",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "resetpw",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "deleted",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "lastlogin",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "lastrecord",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "value",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "account_request",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "account_request_notes",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 lastrecord

Type: belongs_to

Related object: L<GADS::Schema::Result::Record>

=cut

__PACKAGE__->belongs_to(
  "lastrecord",
  "GADS::Schema::Result::Record",
  { id => "lastrecord" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 organisation

Type: belongs_to

Related object: L<GADS::Schema::Result::Organisation>

=cut

__PACKAGE__->belongs_to(
  "organisation",
  "GADS::Schema::Result::Organisation",
  { id => "organisation" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 people

Type: has_many

Related object: L<GADS::Schema::Result::Person>

=cut

__PACKAGE__->has_many(
  "people",
  "GADS::Schema::Result::Person",
  { "foreign.value" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 record_approvedbies

Type: has_many

Related object: L<GADS::Schema::Result::Record>

=cut

__PACKAGE__->has_many(
  "record_approvedbies",
  "GADS::Schema::Result::Record",
  { "foreign.approvedby" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 record_createdbies

Type: has_many

Related object: L<GADS::Schema::Result::Record>

=cut

__PACKAGE__->has_many(
  "record_createdbies",
  "GADS::Schema::Result::Record",
  { "foreign.createdby" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 title

Type: belongs_to

Related object: L<GADS::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title",
  "GADS::Schema::Result::Title",
  { id => "title" },
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
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 views

Type: has_many

Related object: L<GADS::Schema::Result::View>

=cut

__PACKAGE__->has_many(
  "views",
  "GADS::Schema::Result::View",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-08-12 16:50:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FTUh4rK20gm667fM7GVaHg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
