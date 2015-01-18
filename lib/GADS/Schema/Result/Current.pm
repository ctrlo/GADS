use utf8;
package GADS::Schema::Result::Current;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::Current

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

=head1 TABLE: C<current>

=cut

__PACKAGE__->table("current");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 serial

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 record_id

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
  "serial",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "record_id",
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

=head2 alert_caches

Type: has_many

Related object: L<GADS::Schema::Result::AlertCache>

=cut

__PACKAGE__->has_many(
  "alert_caches",
  "GADS::Schema::Result::AlertCache",
  { "foreign.current_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 alerts_send

Type: has_many

Related object: L<GADS::Schema::Result::AlertSend>

=cut

__PACKAGE__->has_many(
  "alerts_send",
  "GADS::Schema::Result::AlertSend",
  { "foreign.current_id" => "self.id" },
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
  { "foreign.current_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-01-06 03:17:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fcbU80LBohrb4SBhsWaSCQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
