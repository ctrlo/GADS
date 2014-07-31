use utf8;
package GADS::Schema::Result::Record;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::Record

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

=head1 TABLE: C<record>

=cut

__PACKAGE__->table("record");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 created

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 current_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 createdby

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 approvedby

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 record_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 approval

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "created",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "current_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "createdby",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "approvedby",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "record_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "approval",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 approvedby

Type: belongs_to

Related object: L<GADS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "approvedby",
  "GADS::Schema::Result::User",
  { id => "approvedby" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 calcvals

Type: has_many

Related object: L<GADS::Schema::Result::Calcval>

=cut

__PACKAGE__->has_many(
  "calcvals",
  "GADS::Schema::Result::Calcval",
  { "foreign.record_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 createdby

Type: belongs_to

Related object: L<GADS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "createdby",
  "GADS::Schema::Result::User",
  { id => "createdby" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 current

Type: belongs_to

Related object: L<GADS::Schema::Result::Current>

=cut

__PACKAGE__->belongs_to(
  "current",
  "GADS::Schema::Result::Current",
  { id => "current_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 dates

Type: has_many

Related object: L<GADS::Schema::Result::Date>

=cut

__PACKAGE__->has_many(
  "dates",
  "GADS::Schema::Result::Date",
  { "foreign.record_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 enums

Type: has_many

Related object: L<GADS::Schema::Result::Enum>

=cut

__PACKAGE__->has_many(
  "enums",
  "GADS::Schema::Result::Enum",
  { "foreign.record_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 intgrs

Type: has_many

Related object: L<GADS::Schema::Result::Intgr>

=cut

__PACKAGE__->has_many(
  "intgrs",
  "GADS::Schema::Result::Intgr",
  { "foreign.record_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 people

Type: has_many

Related object: L<GADS::Schema::Result::Person>

=cut

__PACKAGE__->has_many(
  "people",
  "GADS::Schema::Result::Person",
  { "foreign.record_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ragvals

Type: has_many

Related object: L<GADS::Schema::Result::Ragval>

=cut

__PACKAGE__->has_many(
  "ragvals",
  "GADS::Schema::Result::Ragval",
  { "foreign.record_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 record

Type: belongs_to

Related object: L<GADS::Schema::Result::Record>

=cut

__PACKAGE__->belongs_to(
  "record",
  "GADS::Schema::Result::Record",
  { id => "record_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 records

Type: has_many

Related object: L<GADS::Schema::Result::Record>

=cut

__PACKAGE__->has_many(
  "records",
  "GADS::Schema::Result::Record",
  { "foreign.record_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 strings

Type: has_many

Related object: L<GADS::Schema::Result::String>

=cut

__PACKAGE__->has_many(
  "strings",
  "GADS::Schema::Result::String",
  { "foreign.record_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 users

Type: has_many

Related object: L<GADS::Schema::Result::User>

=cut

__PACKAGE__->has_many(
  "users",
  "GADS::Schema::Result::User",
  { "foreign.lastrecord" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-31 12:47:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NVzBD2BpnsYKbe6j5zuG7w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
