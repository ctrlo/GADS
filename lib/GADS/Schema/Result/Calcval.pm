use utf8;
package GADS::Schema::Result::Calcval;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::Calcval

=cut

use strict;
use warnings;

use Moo;

extends 'DBIx::Class::Core';
sub BUILDARGS { $_[2] || {} }

with 'GADS::Role::Purgable';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<calcval>

=cut

__PACKAGE__->table("calcval");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 record_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 layout_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value_text

  data_type: 'text'
  is_nullable: 1

=head2 value_int

  data_type: 'bigint'
  is_nullable: 1

=head2 value_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 value_numeric

  data_type: 'decimal'
  is_nullable: 1
  size: [20,5]

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "record_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value_text",
  { data_type => "text", is_nullable => 1 },
  "value_int",
  { data_type => "bigint", is_nullable => 1 },
  "value_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "value_numeric",
  { data_type => "decimal", is_nullable => 1, size => [20, 5] },
  "value_date_from",
  { data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "value_date_to",
  { data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
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

=head2 record

Type: belongs_to

Related object: L<GADS::Schema::Result::Record>

=cut

__PACKAGE__->belongs_to(
  "record",
  "GADS::Schema::Result::Record",
  { id => "record_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-02-09 12:55:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yVFUGNM0ceG5Lf2KyimIvA

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'calcval_idx_value_text', fields => [ { name => 'value_text', prefix_length => 64 } ]);
    $sqlt_table->add_index(name => 'calcval_idx_value_numeric', fields => [ 'value_numeric' ]);
    $sqlt_table->add_index(name => 'calcval_idx_value_int', fields => [ 'value_int' ]);
    $sqlt_table->add_index(name => 'calcval_idx_value_date', fields => [ 'value_date' ]);
}

sub _build_recordsource { 'Calcval'; }

sub _build_valuefield { ('value_text','value_numeric','value_int','value_date','value_date_from','value_date_to'); }

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
