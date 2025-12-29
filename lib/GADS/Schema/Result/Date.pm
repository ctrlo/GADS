use utf8;
package GADS::Schema::Result::Date;

use strict;
use warnings;

use Moo;

extends 'DBIx::Class::Core';
with 'GADS::Role::Purgable';
sub BUILDARGS { $_[2] || {} }

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("date");

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
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "purged_by",
  { data_type => "bigint", is_nullable => 1, is_foreign_key => 1 },
  "purged_on",
  { data_type => "timestamp", datetime_undef_if_invalid => 1, is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "layout",
  "GADS::Schema::Result::Layout",
  { id => "layout_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "record",
  "GADS::Schema::Result::Record",
  { id => "record_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "purged_by",
  "GADS::Schema::Result::User",
  { id => "purged_by" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'date_idx_value', fields => ['value']);
}

sub export_hash
{   my $self = shift;
    +{
        layout_id    => $self->layout_id,
        child_unique => $self->child_unique,
        value        => $self->value && $self->value->datetime,
    };
}

1;
