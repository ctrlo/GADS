use utf8;
package GADS::Schema::Result::Layout;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::Layout

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

=head1 TABLE: C<layout>

=cut

__PACKAGE__->table("layout");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 permission

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 optional

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 remember

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "permission",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "optional",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "remember",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 calcs

Type: has_many

Related object: L<GADS::Schema::Result::Calc>

=cut

__PACKAGE__->has_many(
  "calcs",
  "GADS::Schema::Result::Calc",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 dates

Type: has_many

Related object: L<GADS::Schema::Result::Date>

=cut

__PACKAGE__->has_many(
  "dates",
  "GADS::Schema::Result::Date",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 enums

Type: has_many

Related object: L<GADS::Schema::Result::Enum>

=cut

__PACKAGE__->has_many(
  "enums",
  "GADS::Schema::Result::Enum",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 enumvals

Type: has_many

Related object: L<GADS::Schema::Result::Enumval>

=cut

__PACKAGE__->has_many(
  "enumvals",
  "GADS::Schema::Result::Enumval",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 filters

Type: has_many

Related object: L<GADS::Schema::Result::Filter>

=cut

__PACKAGE__->has_many(
  "filters",
  "GADS::Schema::Result::Filter",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 graph_layout_id2s

Type: has_many

Related object: L<GADS::Schema::Result::Graph>

=cut

__PACKAGE__->has_many(
  "graph_layout_id2s",
  "GADS::Schema::Result::Graph",
  { "foreign.layout_id2" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 graph_layouts

Type: has_many

Related object: L<GADS::Schema::Result::Graph>

=cut

__PACKAGE__->has_many(
  "graph_layouts",
  "GADS::Schema::Result::Graph",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 intgrs

Type: has_many

Related object: L<GADS::Schema::Result::Intgr>

=cut

__PACKAGE__->has_many(
  "intgrs",
  "GADS::Schema::Result::Intgr",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 people

Type: has_many

Related object: L<GADS::Schema::Result::Person>

=cut

__PACKAGE__->has_many(
  "people",
  "GADS::Schema::Result::Person",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rags

Type: has_many

Related object: L<GADS::Schema::Result::Rag>

=cut

__PACKAGE__->has_many(
  "rags",
  "GADS::Schema::Result::Rag",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 strings

Type: has_many

Related object: L<GADS::Schema::Result::String>

=cut

__PACKAGE__->has_many(
  "strings",
  "GADS::Schema::Result::String",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 view_layouts

Type: has_many

Related object: L<GADS::Schema::Result::ViewLayout>

=cut

__PACKAGE__->has_many(
  "view_layouts",
  "GADS::Schema::Result::ViewLayout",
  { "foreign.layout_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-09 09:28:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:upC1q6J9LF1PWl84nzIkhQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
