use utf8;
package GADS::Schema::Result::Fileval;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::Fileval

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

=head1 TABLE: C<fileval>

=cut

__PACKAGE__->table("fileval");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 mimetype

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 content

  data_type: 'longblob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "mimetype",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "content",
  { data_type => "longblob", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 files

Type: has_many

Related object: L<GADS::Schema::Result::File>

=cut

__PACKAGE__->has_many(
  "files",
  "GADS::Schema::Result::File",
  { "foreign.value" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-08-05 10:59:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VVxCWjBxRcms5Jfs78ei3w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
