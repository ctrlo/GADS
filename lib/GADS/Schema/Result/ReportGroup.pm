use utf8;

package GADS::Schema::Result::ReportGroup;

=head1 NAME
GADS::Schema::Result::ReportLayout
=cut

use Moo;

extends 'DBIx::Class::Core';
sub BUILDARGS { $_[2] || {} }

=head1 TABLE: C<report_group>
=cut

__PACKAGE__->table("report_group");

=head1 ACCESSORS
=head2 id
  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
=head2 report_id
  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
=head2 group_id
  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "report_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "group_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY
=over 4
=item * L</id>
=back
=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS
=head2 report
Type: belongs_to
Related object: L<GADS::Schema::Result::Report>
=cut

__PACKAGE__->belongs_to(
    "report",
    "GADS::Schema::Result::Report",
    { id            => "report_id" },
    { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 group
Type: belongs_to
Related object: L<GADS::Schema::Result::Group>
=cut

__PACKAGE__->belongs_to(
    "group",
    "GADS::Schema::Result::Group",
    { id            => "group_id" },
    { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
