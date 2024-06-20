use utf8;

package GADS::Schema::Result::CalcUnique;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("calc_unique");

__PACKAGE__->add_columns(
    "id",
    { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
    "layout_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "value_text",
    { data_type => "text", is_nullable => 1 },
    "value_int",
    { data_type => "bigint", is_nullable => 1 },
    "value_date",
    {
        data_type                 => "date",
        datetime_undef_if_invalid => 1,
        is_nullable               => 1
    },
    "value_numeric",
    { data_type => "decimal", is_nullable => 1, size => [ 20, 5 ] },
    "value_date_from",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 1
    },
    "value_date_to",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 1
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("calc_unique_ux_layout_text",
    [ "layout_id", "value_text" ]);
__PACKAGE__->add_unique_constraint("calc_unique_ux_layout_int",
    [ "layout_id", "value_int" ]);
__PACKAGE__->add_unique_constraint("calc_unique_ux_layout_date",
    [ "layout_id", "value_date" ]);
__PACKAGE__->add_unique_constraint("calc_unique_ux_layout_numeric",
    [ "layout_id", "value_numeric" ]);
__PACKAGE__->add_unique_constraint("calc_unique_ux_layout_daterange",
    [ "layout_id", "value_date_from", "value_date_to" ]);

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

1;
