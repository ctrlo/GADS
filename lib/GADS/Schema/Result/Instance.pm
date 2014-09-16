use utf8;
package GADS::Schema::Result::Instance;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::Instance

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

=head1 TABLE: C<instance>

=cut

__PACKAGE__->table("instance");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 email_welcome_text

  data_type: 'text'
  is_nullable: 1

=head2 email_welcome_subject

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 email_delete_text

  data_type: 'text'
  is_nullable: 1

=head2 email_delete_subject

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 register_text

  data_type: 'text'
  is_nullable: 1

=head2 sort_view_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 homepage_text

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "email_welcome_text",
  { data_type => "text", is_nullable => 1 },
  "email_welcome_subject",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "email_delete_text",
  { data_type => "text", is_nullable => 1 },
  "email_delete_subject",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "register_text",
  { data_type => "text", is_nullable => 1 },
  "sort_view_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "homepage_text",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 currents

Type: has_many

Related object: L<GADS::Schema::Result::Current>

=cut

__PACKAGE__->has_many(
  "currents",
  "GADS::Schema::Result::Current",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sort_view

Type: belongs_to

Related object: L<GADS::Schema::Result::View>

=cut

__PACKAGE__->belongs_to(
  "sort_view",
  "GADS::Schema::Result::View",
  { id => "sort_view_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-09-16 19:12:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wSmfLl1jFAEfwHskrn14Nw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
