package GADS::Schema::ResultSet::User;

use strict;
use warnings;

use base qw(DBIx::Class::ResultSet);

sub active
{   my ($self, %search) = @_;

    $self->search({
        account_request => 0,
        deleted         => undef,
        %search,
    });
}

1;
