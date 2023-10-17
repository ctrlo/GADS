use utf8;
package GADS::Schema::Result::ReportLayout;

=head1 NAME

GADS::Schema::Result::ReportLayout

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

=head1 TABLE: C<report_layout>

=cut

__PACKAGE__->table("report_layout");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 view_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 report_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 order

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "view_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "report_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
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
  { id => "report_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 view

Type: belongs_to

Related object: L<GADS::Schema::Result::View>

=cut

__PACKAGE__->belongs_to(
  "view",
  "GADS::Schema::Result::View",
  { id => "view_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
