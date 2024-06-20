use utf8;

package GADS::Schema::Result::Export;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("export");

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "site_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "user_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
    "type",
    { data_type => "varchar", is_nullable => 1, size => 45 },
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
    "result",
    { data_type => "text", is_nullable => 1 },
    "result_internal",
    { data_type => "text", is_nullable => 1 },
    "mimetype",
    { data_type => "text", is_nullable => 1 },
    "content",
    { data_type => "longblob", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

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

sub success
{   my $self = shift;
    $self->completed && $self->content;
}

1;
