use utf8;

package GADS::Schema::Result::ReportLayout;

=head1 NAME
GADS::Schema::Result::ReportLayout
=cut

use Moo;

extends 'DBIx::Class::Core';
sub BUILDARGS { $_[2] || {} }

=head1 COMPONENTS LOADED
=over 4
=item * L<DBIx::Class::InflateColumn::DateTime>
=back
=cut

__PACKAGE__->load_components( "InflateColumn::DateTime", "+GADS::DBIC" );

=head1 TABLE: C<report_instance>
=cut

__PACKAGE__->table("report_layout");

=head1 ACCESSORS
=head2 id
  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
=head2 report_id
  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
=head2 layout_id
  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0
=head2 order
  data_type: 'integer'
  is_nullable: 1
=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "report_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "layout_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
    "order",
    { data_type => "integer", is_nullable => 1 },
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
Related object: L<GADS::Schema::Result::Report>
=cut

__PACKAGE__->belongs_to(
    "report",
    "GADS::Schema::Result::Report",
    { id            => "report_id" },
    { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 view
Type: belongs_to
Related object: L<GADS::Schema::Result::Layout>
=cut

__PACKAGE__->belongs_to(
    "layout",
    "GADS::Schema::Result::Layout",
    { id            => "layout_id" },
    { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;