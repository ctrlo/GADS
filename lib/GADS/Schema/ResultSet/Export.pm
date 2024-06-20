package GADS::Schema::ResultSet::Export;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use Log::Report 'linkspace';

sub user
{   my ($self, $user_id) = @_;

    $self->search_rs(
        {
            'me.user_id' => $user_id,
        },
        {
            order_by => { -desc => 'me.completed' },
        },
    );
}

1;
