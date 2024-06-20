package GADS::Schema::ResultSet::Fileval;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use Log::Report 'linkspace';

sub independent
{   shift->search_rs(
        {
            is_independent => 1,
        },
        {
            order_by => 'me.id',
        },
    );
}

1;
