use utf8;

package GADS::Schema::Result::FilteredValue;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("filtered_value");

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "submission_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "layout_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "current_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("ux_submission_layout_current",
    [ "submission_id", "layout_id", "current_id" ]);

__PACKAGE__->belongs_to(
    "submission",
    "GADS::Schema::Result::Submission",
    { id => "submission_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

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
    "current",
    "GADS::Schema::Result::Current",
    { id => "current_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

1;
