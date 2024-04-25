use utf8;
package GADS::Schema::Result::String;

=head1 NAME

GADS::Schema::Result::String

=cut

use strict;
use warnings;

use Moo;

extends 'DBIx::Class::Core';
sub BUILDARGS { $_[2] || {} }

with 'GADS::Role::Purge::StringPurgable';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<string>

=cut

__PACKAGE__->table("string");

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

=head2 child_unique

  data_type: 'smallint'
  default_value: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 value_index

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "record_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "child_unique",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "value_index",
  { data_type => "varchar", is_nullable => 1, size => 128 },
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


sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'string_idx_value_index', fields => [ 'value_index' ]);
}

sub export_hash
{   my $self = shift;
    +{
        layout_id    => $self->layout_id,
        child_unique => $self->child_unique,
        value        => $self->value,
        value_index  => $self->value_index,
    };
}

1;
