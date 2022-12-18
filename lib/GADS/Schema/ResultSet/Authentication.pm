package GADS::Schema::ResultSet::Authentication;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use Log::Report 'linkspace';

sub enabled
{   shift->search({
        'me.enabled' => 1,
    });
}

sub saml2_provider
{   my $self = shift;
    $self->enabled->search({
        type => 'saml2',
    })->next;
}

1;
