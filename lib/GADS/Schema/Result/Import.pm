use utf8;

package GADS::Schema::Result::Import;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("import");

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "site_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "instance_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "user_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
    "type",
    { data_type => "varchar", is_nullable => 1, size => 45 },
    "row_count",
    { data_type => "integer", default_value => 0, is_nullable => 0 },
    "started",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 1
    },
    "completed",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 1
    },
    "written_count",
    { data_type => "integer", default_value => 0, is_nullable => 0 },
    "error_count",
    { data_type => "integer", default_value => 0, is_nullable => 0 },
    "skipped_count",
    { data_type => "integer", default_value => 0, is_nullable => 0 },
    "result",
    { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    "instance",
    "GADS::Schema::Result::Instance",
    { id => "instance_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

__PACKAGE__->belongs_to(
    "user",
    "GADS::Schema::Result::User",
    { id => "user_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

__PACKAGE__->belongs_to(
    "site",
    "GADS::Schema::Result::Site",
    { id => "site_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

__PACKAGE__->has_many(
    "import_rows",
    "GADS::Schema::Result::ImportRow",
    { "foreign.import_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 1 },
);

1;
