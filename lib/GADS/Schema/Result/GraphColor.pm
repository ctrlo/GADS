use utf8;

package GADS::Schema::Result::GraphColor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::GraphColor

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

=head1 TABLE: C<graph_color>

=cut

__PACKAGE__->table("graph_color");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 color

  data_type: 'char'
  is_nullable: 1
  size: 6

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "varchar", is_nullable => 1, size => 128 },
    "color",
    { data_type => "char", is_nullable => 1, size => 6 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<ux_graph_color_name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("ux_graph_color_name", ["name"]);

# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-13 16:02:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aRr5YUya/kCSD7xss/4Yvw

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
