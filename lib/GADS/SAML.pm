package GADS::SAML;

use Log::Report 'linkspace';

use Moo;

use Net::SAML2::Binding::POST;
use Net::SAML2::Binding::Redirect;
use Net::SAML2::IdP;
use Net::SAML2::Protocol::Assertion;
use Net::SAML2::Protocol::AuthnRequest;
use MIME::Base64;

use IO::Compress::RawDeflate qw/rawdeflate/;
use URI;
use URI::QueryParam;
use URL::Encode qw/url_encode/;

has request_id => (
    is => 'rw',
);

has base_url => (
    is       => 'ro',
    required => 1,
);

has sso_url => (
    is => 'lazy',
);

sub _build_sso_url
{   my $self = shift;
    $self->base_url.'saml';
}

has sso_xml => (
    is => 'lazy',
);

sub _build_sso_xml
{   my $self = shift;
    $self->base_url.'saml/xml';
}

sub callback
{   my ($self, %params) = @_;

    my $post = Net::SAML2::Binding::POST->new;
    my $saml_response = $params{saml_response};

    if (my $return = $post->handle_response($saml_response))
    {
        my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
            xml => decode_base64($saml_response)
        );
        error __x"Invalid SSO assertion received. Expected request ID {request_id}",
            request_id => $self->request_id
                if !$assertion->valid($self->sso_xml, $self->request_id);
        return {
            nameid     => $assertion->nameid,
            attributes => $assertion->attributes,
        }
    }
};

has redirect => (
    is => 'rw',
);

has authentication => (
    is => 'ro',
);

sub initiate
{   my ($self, %params) = @_;

    my $idp = Net::SAML2::IdP->new_from_xml(
        xml => $self->authentication->xml,
    );

    my $sso_url = $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');

    my $authnreq = Net::SAML2::Protocol::AuthnRequest->new(
        issuer      => $self->sso_xml,
        destination => $sso_url,
    );

    $self->request_id($authnreq->id);
    my $x = $authnreq->as_xml;

    my $redirect = Net::SAML2::Binding::Redirect->new(
          url      => $sso_url,
          param    => 'SAMLRequest',
          insecure => 1,
    );

    my $url = $redirect->get_redirect_uri($x);
    $self->redirect("$url");
};

1;
