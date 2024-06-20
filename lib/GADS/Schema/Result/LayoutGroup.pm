use utf8;

package GADS::Schema::Result::LayoutGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::LayoutGroup

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

=head1 TABLE: C<layout_group>

=cut

__PACKAGE__->table("layout_group");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 layout_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 permission

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "layout_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "group_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "permission",
    { data_type => "varchar", is_nullable => 0, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<layout_group_ux_layout_group_permission>

=over 4

=item * L</layout_id>

=item * L</group_id>

=item * L</permission>

=back

=cut

__PACKAGE__->add_unique_constraint(
    "layout_group_ux_layout_group_permission",
    [ "layout_id", "group_id", "permission" ],
);

=head1 RELATIONS

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

# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-13 16:02:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F/n5ytAM5PEEe2fAezIJbg

sub sqlt_deploy_hook
{   my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(
        name   => 'layout_group_idx_permission',
        fields => ['permission']
    );
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
