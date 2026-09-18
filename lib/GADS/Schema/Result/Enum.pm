use utf8;
package GADS::Schema::Result::Enum;

use strict;
use warnings;

use Moo;

extends 'DBIx::Class::Core';
sub BUILDARGS { $_[2] || {} }

with 'GADS::Role::Purgable';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("enum");

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "record_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "child_unique",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "value",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "purged_by",
  { data_type => "bigint", is_nullable => 1, is_foreign_key => 1 },
  "purged_on",
  { data_type => "datetime", is_nullable => 1, datetime_undef_if_invalid => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "layout",
  "GADS::Schema::Result::Layout",
  { id => "layout_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "record",
  "GADS::Schema::Result::Record",
  { id => "record_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "value",
  "GADS::Schema::Result::Enumval",
  { id => "value" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "value_alternative",
  "GADS::Schema::Result::Enumval",
  { id => "value" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "purged_by",
  "GADS::Schema::Result::User",
  { id => "purged_by" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

sub export_hash
{   my $self = shift;
    +{
        layout_id    => $self->layout_id,
        child_unique => $self->child_unique,
        value        => $self->value && $self->value->id,
    };
}

1;
