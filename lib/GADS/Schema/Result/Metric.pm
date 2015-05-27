use utf8;
package GADS::Schema::Result::Metric;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::Metric

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

=head1 TABLE: C<metric>

=cut

__PACKAGE__->table("metric");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 metric_group_id

  data_type: 'integer'
  is_nullable: 0

=head2 x_axis_field

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 y_axis_field

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 target

  data_type: 'integer'
  is_nullable: 1

=head2 y_axis_value

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "metric_group_id",
  { data_type => "integer", is_nullable => 0 },
  "x_axis_field",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "y_axis_field",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "target",
  { data_type => "integer", is_nullable => 1 },
  "y_axis_value",
  { data_type => "varchar", is_nullable => 1, size => 256 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 x_axis_field

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->belongs_to(
  "x_axis_field",
  "GADS::Schema::Result::Layout",
  { id => "x_axis_field" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 y_axis_field

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

__PACKAGE__->belongs_to(
  "y_axis_field",
  "GADS::Schema::Result::Layout",
  { id => "y_axis_field" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-05-27 12:17:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E3ycQEZQu76b7Pi1q11VsA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
