use utf8;

package GADS::Schema::Result::Team;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Log::Report 'linkspace';

__PACKAGE__->load_components("+GADS::DBIC");

__PACKAGE__->table("team");

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "varchar", is_nullable => 1, size => 128 },
    "site_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "deleted",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
    "users", "GADS::Schema::Result::User",
    { "foreign.team_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
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

sub delete_team
{   my $self   = shift;
    my $schema = $self->result_source->schema;
    my $count  = $schema->resultset('User')->active->search({
        team_id => $self->id,
    })->count;
    if ($count)
    {
        error __xn
"This {name} cannot be deleted as it is in use by 1 user on the system",
"This {name} cannot be deleted as it is in use by {count} users on the system",
            $count,
            name  => $schema->resultset('Site')->next->team_name,
            count => $count;
    }
    my $count_deleted = $schema->resultset('User')->search({
        deleted => { '!=' => undef },
        team_id => $self->id,
    })->count;
    if ($count_deleted)
    {
        $self->update({ deleted => 1 });
    }
    else
    {
        $self->delete;
    }
}

1;
