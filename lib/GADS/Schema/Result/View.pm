use utf8;

package GADS::Schema::Result::View;

=head1 NAME

GADS::Schema::Result::View

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

=head1 TABLE: C<view>

=cut

__PACKAGE__->table("view");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 global

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 is_admin

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 is_limit_extra

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 filter

  data_type: 'text'
  is_nullable: 1

=head2 instance_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
    "user_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "group_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "name",
    { data_type => "varchar", is_nullable => 1, size => 128 },
    "global",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
    "is_admin",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
    "is_limit_extra",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
    "filter",
    { data_type => "text", is_nullable => 1 },
    "instance_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "created",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 1
    },
    "createdby",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
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
    { "foreign.view_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

=head2 alerts

Type: has_many

Related object: L<GADS::Schema::Result::Alert>

=cut

__PACKAGE__->has_many(
    "alerts", "GADS::Schema::Result::Alert",
    { "foreign.view_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

=head2 filters

Type: has_many

Related object: L<GADS::Schema::Result::Filter>

=cut

__PACKAGE__->has_many(
    "filters",
    "GADS::Schema::Result::Filter",
    { "foreign.view_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
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

=head2 sorts

Type: has_many

Related object: L<GADS::Schema::Result::Sort>

=cut

__PACKAGE__->has_many(
    "sorts", "GADS::Schema::Result::Sort",
    { "foreign.view_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

=head2 view_groups

Type: has_many

Related object: L<GADS::Schema::Result::ViewGroup>

=cut

__PACKAGE__->has_many(
    "view_groups",
    "GADS::Schema::Result::ViewGroup",
    { "foreign.view_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
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
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

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

=head2 group

Type: belongs_to

Related object: L<GADS::Schema::Result::Group>

=cut

__PACKAGE__->belongs_to(
    "group",
    "GADS::Schema::Result::Group",
    { id => "group_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

=head2 user_limits_to_view

Type: has_many

Related object: L<GADS::Schema::Result::User>

=cut

__PACKAGE__->has_many(
    "user_limits_to_view", "GADS::Schema::Result::User",
    { "foreign.limit_to_view" => "self.id" },
    { cascade_copy            => 0, cascade_delete => 0 },
);

=head2 users

Type: has_many

Related object: L<GADS::Schema::Result::User>

=cut

__PACKAGE__->has_many(
    "users", "GADS::Schema::Result::User",
    { "foreign.lastview" => "self.id" },
    { cascade_copy       => 0, cascade_delete => 0 },
);

=head2 view_layouts

Type: has_many

Related object: L<GADS::Schema::Result::ViewLayout>

=cut

__PACKAGE__->has_many(
    "view_layouts",
    "GADS::Schema::Result::ViewLayout",
    { "foreign.view_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

=head2 view_limits

Type: has_many

Related object: L<GADS::Schema::Result::ViewLimit>

=cut

__PACKAGE__->has_many(
    "view_limits",
    "GADS::Schema::Result::ViewLimit",
    { "foreign.view_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

1;
