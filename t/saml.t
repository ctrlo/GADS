#!perl

use Test::More;

use_ok 'GADS::SAML';
my $saml = GADS::SAML->new( base_url => "http://www.example.com/" );
isa_ok $saml, 'GADS::SAML';

done_testing();
