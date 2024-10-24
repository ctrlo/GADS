package GADS::Schema::ResultSet::Authentication;

use strict;
use warnings;

use GADS::SAML;
use GADS::Util;
use Session::Token;

use parent 'DBIx::Class::ResultSet';

use Log::Report 'linkspace';

__PACKAGE__->load_components(qw(Helper::ResultSet::CorrelateRelationship));

sub providers
{   shift->search({
    });
}

sub enabled
{   shift->search({
        'me.enabled' => 1,
    });
}

sub saml2_provider
{   my $self = shift;
    $self->enabled->search({
        'me.type' => 'saml2',
    })->next;
}

1;
