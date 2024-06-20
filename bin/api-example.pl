#!/usr/bin/perl

use strict;
use warnings;

use Net::OAuth2::Profile::Password;

my $auth = Net::OAuth2::Profile::Password->new(
    client_id        => 'xxx',        # From application at /clientcredentials/
    client_secret    => 'xxx',
    grant_type       => 'password',
    site             => 'https://xxx.linkspace.uk',
    access_token_url => '/api/token',

    #token_scheme       Net::OAuth2::Profile  'auth-header:Bearer'
);
my $token = $auth->get_access_token(
    username => 'user@example.com',    # Linkspace user account
    password => 'xxx',
);
my $resp = $token->get('/api/table12/records/view/12011');
say STDERR Dumper $resp;
