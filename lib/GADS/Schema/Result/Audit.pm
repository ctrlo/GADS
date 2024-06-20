use utf8;

package GADS::Schema::Result::Audit;

=head1 NAME

GADS::Schema::Result::Audit

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

=head1 TABLE: C<audit>

=cut

__PACKAGE__->table("audit");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  date_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 user_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 datetime

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 method

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 url

  data_type: 'text'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
    "site_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "user_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "type",
    { data_type => "varchar", is_nullable => 1, size => 45 },
    "datetime",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 1,
    },
    "method",
    { data_type => "varchar", is_nullable => 1, size => 45 },
    "url",
    { data_type => "text", is_nullable => 1 },
    "description",
    { data_type => "text", is_nullable => 1 },
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
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

=head2 site

Type: belongs_to

Related object: L<GADS::Schema::Result::Site>

=cut

__PACKAGE__->belongs_to(
    "site",
    "GADS::Schema::Result::Site",
    { id => "site_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

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

sub sqlt_deploy_hook
{   my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(
        name   => 'audit_idx_datetime',
        fields => ['datetime']
    );
    $sqlt_table->add_index(
        name   => 'audit_idx_user_instance_datetime',
        fields => [qw/user_id instance_id datetime/]
    );
}

1;
