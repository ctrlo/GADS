package GADS::Schema::ResultSet::Oauthtoken;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

sub access_token
{   my ($self, $token) = @_;
    my $tok = $self->find($token)
        or return undef;
    $tok->type eq 'access' or return undef;
    $tok;
}

sub refresh_token
{   my ($self, $token) = @_;
    my $tok = $self->find($token)
        or return undef;
    $tok->type eq 'refresh' or return undef;
    $tok;
}

1;
