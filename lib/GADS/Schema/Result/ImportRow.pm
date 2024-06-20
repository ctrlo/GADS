use utf8;

package GADS::Schema::Result::ImportRow;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("import_row");

__PACKAGE__->add_columns(
    "id",
    { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
    "import_id",
    { data_type => "int", is_foreign_key => 1, is_nullable => 0 },
    "status",
    { data_type => "varchar", is_nullable => 1, size => 45 },
    "content",
    { data_type => "text", is_nullable => 1 },
    "errors",
    { data_type => "text", is_nullable => 1 },
    "changes",
    { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    "import",
    "GADS::Schema::Result::Import",
    { id => "import_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "CASCADE",
        on_update     => "NO ACTION",
    },
);

1;
