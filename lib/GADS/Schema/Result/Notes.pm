use utf8;

package GADS::Schema::Result::Notes;

=head1 NAME

GADS::Schema::Result::Notes

=cut

use strict;
use warnings;

use DateTime;
use Log::Report;
use Moo;

extends 'DBIx::Class::Core';

sub BUILDARGS { $_[2] || {} }

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);

=head1 TABLE: C<notes>

=cut

__PACKAGE__->table('notes');

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0
  primary_key: 1

=head2 instance_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 note

  data_type: 'text'
  is_nullable: 0

=head2 lasteditedby

    data_type: 'integer'
    is_foreign_key: 1
    is_nullable: 0

=head2 lastediteddate

    data_type: 'datetime'
    is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_nullable => 0, primary_key => 1 },
    "instance_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "note",
    { data_type => "text", is_nullable => 0 },
    "lasteditedby",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key('id');

=head1 RELATIONS

=head2 instance

Type: belongs_to
Related object: L<GADS::Schema::Result::Instance>

=cut

__PACKAGE__->belongs_to(
    "instance",
    "GADS::Schema::Result::Instance",
    { id => "instance_id" },
    { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lasteditedby

Type: belongs_to
Related object: L<GADS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
    "lasteditedby",
    "GADS::Schema::Result::User",
    { id => "lasteditedby" },
    { cascade_copy => 0, cascade_delete => 0 },
);

sub validate() {
    #not required - the note field can be empty
}
