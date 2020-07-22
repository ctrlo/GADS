package GADS::Schema::ResultSet::Organisation;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use Log::Report 'linkspace';

sub ordered
{   shift->search({},
    {
        order_by => 'me.name',
    });
}

1;
