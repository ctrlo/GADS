use utf8;

package GADS::Schema::Result::Oauthtoken;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("oauthtoken");

__PACKAGE__->add_columns(
    "token",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "related_token",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "oauthclient_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "user_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
    "type",
    { data_type => "varchar", is_nullable => 0, size => 12 },
    "expires",
    { data_type => "integer", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("token");

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
    "oauthclient",
    "GADS::Schema::Result::Oauthclient",
    { id => "oauthclient_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

1;
