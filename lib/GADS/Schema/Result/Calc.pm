use utf8;

package GADS::Schema::Result::Calc;

=head1 NAME

GADS::Schema::Result::Calc

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

=head1 TABLE: C<calc>

=cut

__PACKAGE__->table("calc");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 layout_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 calc (legacy)

  data_type: 'mediumtext'
  is_nullable: 1

=head2 code

  data_type: 'mediumtext'
  is_nullable: 1

=head2 return_format

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 decimal_places

  data_type: 'smallint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "layout_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "calc",
    { data_type => "mediumtext", is_nullable => 1 },
    "code",
    { data_type => "mediumtext", is_nullable => 1 },
    "return_format",
    { data_type => "varchar", is_nullable => 1, size => 45 },
    "decimal_places",
    { data_type => "smallint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

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

# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-02-09 12:55:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yV5t0vwxrKR+oEnA4SPYBA

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
