use utf8;
package GADS::Schema::Result::FileOption;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::FileOption

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

=head1 TABLE: C<file_option>

=cut

__PACKAGE__->table("file_option");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 layout_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 filesize

  data_type: 'integer'
  is_nullable: 1

=head2 extra_values

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "filesize",
  { data_type => "integer", is_nullable => 1 },
  # Could use a one to many, but for the amount it will be used, I feel storing as a JSON string would be best here
  "extra_values",
  { data_type => "text", is_nullable=>1 },
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
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-01-06 03:17:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nW7tXpBu0ucf1+nHsOSdqQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
