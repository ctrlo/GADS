use utf8;

package GADS::Schema::Result::LayoutDepend;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::LayoutDepend

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

=head1 TABLE: C<layout_depend>

=cut

__PACKAGE__->table("layout_depend");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 layout_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 depends_on

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "layout_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "depends_on",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 depend_on

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->belongs_to(
    "depend_on",
    "GADS::Schema::Result::Layout",
    { id => "depends_on" },
    {
        is_deferrable => 1,
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION"
    },
);

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
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION"
    },
);

# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-01-18 11:44:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:auJiRD5IthTVmBPeAGgrrg

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
