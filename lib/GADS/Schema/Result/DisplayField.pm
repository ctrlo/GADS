use utf8;

package GADS::Schema::Result::DisplayField;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("display_field");

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "layout_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "display_field_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "regex",
    { data_type => "text", is_nullable => 1 },
    "operator",
    { data_type => "varchar", is_nullable => 1, size => 16 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    "layout",
    "GADS::Schema::Result::Layout",
    { id => "layout_id" },
    {
        is_deferrable => 1,
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION"
    },
);

__PACKAGE__->belongs_to(
    "display_field",
    "GADS::Schema::Result::Layout",
    { id => "display_field_id" },
    {
        is_deferrable => 1,
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION"
    },
);

1;
