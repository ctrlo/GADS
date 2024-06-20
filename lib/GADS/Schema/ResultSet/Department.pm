package GADS::Schema::ResultSet::Department;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use Log::Report 'linkspace';

sub ordered
{   shift->search(
        {
            'me.deleted' => 0,
        },
        {
            order_by => 'me.name',
        },
    );
}

1;
