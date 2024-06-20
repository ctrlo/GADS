use utf8;

package GADS::Schema::Result::UserLastrecord;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::UserLastrecord

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

=head1 TABLE: C<user_lastrecord>

=cut

__PACKAGE__->table("user_lastrecord");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 record_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 instance_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 user_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
    "record_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
    "instance_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "user_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

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
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION"
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
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION"
    },
);

=head2 user

Type: belongs_to

Related object: L<GADS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
    "user",
    "GADS::Schema::Result::User",
    { id => "user_id" },
    {
        is_deferrable => 1,
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION"
    },
);

# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-03-07 16:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:X9JQYMQft1qCEuTuCFkeOQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
