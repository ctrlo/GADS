use utf8;
package GADS::Schema::Result::View;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

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

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

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

=head2 filter

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "global",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "filter",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 filters

Type: has_many

Related object: L<GADS::Schema::Result::Filter>

=cut

__PACKAGE__->has_many(
  "filters",
  "GADS::Schema::Result::Filter",
  { "foreign.view_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 instances

Type: has_many

Related object: L<GADS::Schema::Result::Instance>

=cut

__PACKAGE__->has_many(
  "instances",
  "GADS::Schema::Result::Instance",
  { "foreign.sort_view_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sorts

Type: has_many

Related object: L<GADS::Schema::Result::Sort>

=cut

__PACKAGE__->has_many(
  "sorts",
  "GADS::Schema::Result::Sort",
  { "foreign.view_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 view_layouts

Type: has_many

Related object: L<GADS::Schema::Result::ViewLayout>

=cut

__PACKAGE__->has_many(
  "view_layouts",
  "GADS::Schema::Result::ViewLayout",
  { "foreign.view_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-09-10 12:02:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+elHiE1jSuxkrHuBLbHkuQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
