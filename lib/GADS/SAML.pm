package GADS::SAML;

use Log::Report 'linkspace';

use Moo;

use Net::SAML2 0.67;
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
use File::Temp qw/ tempfile /;

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

    my $cacert_fh;

    # Save CA cert locally if configured
    if (my $cacert = $params{cacert})
    {
        $cacert_fh = File::Temp->new;
        print $cacert_fh $cacert;
        $cacert_fh->close
    }

    my $post = Net::SAML2::Binding::POST->new(
            $cacert_fh ? (cacert => $cacert_fh->filename) : (),
    );

    my $saml_response = $params{saml_response};

    if (my $return = $post->handle_response($saml_response))
    {
        my $key_fh;
        if (defined $params{sp_key}) {
            $key_fh = File::Temp->new;
            print $key_fh $params{sp_key};
            $key_fh->close;
        }

        my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
                xml => decode_base64($saml_response),
                $key_fh ? (key_file => $key_fh->filename) : (),
                $cacert_fh ? (cacert => $cacert_fh->filename) : (),
        );

        error __x"Invalid SSO assertion received. Expected request ID {request_id} Status: {status} SubStatus: {substatus}",
            request_id => $self->request_id,
            status => $assertion->response_status,
            substatus => $assertion->response_substatus
                if !$assertion->valid($self->sso_xml, $self->request_id);
        return {
            nameid     => $assertion->nameid,
            attributes => $assertion->attributes,
        }
    }
    unlink $cacert_fh->filename;

};

has redirect => (
    is => 'rw',
);

has authentication => (
    is => 'ro',
);

sub initiate
{   my ($self, %params) = @_;

    my $cacert_fh;
    if (my $cacert = $self->authentication->cacert)
    {
         $cacert_fh = File::Temp->new;
         print $cacert_fh $cacert;
         $cacert_fh->close;
    }

    error __"Missing Provider Metadata. Please upload to Authentication Settings"
        if !$self->authentication->xml;

    my $idp = Net::SAML2::IdP->new_from_xml(
        xml => $self->authentication->xml,
        $cacert_fh ? (cacert => $cacert_fh->filename) : (),
    );

    my $sso_url = $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');

    my $authnreq = Net::SAML2::Protocol::AuthnRequest->new(
        issuer      => $self->sso_xml,
        destination => $sso_url,
        nameid_format => $idp->format('emailAddress') || undef,
        # assertion_url => "https://$www/app/saml",
    );

    $self->request_id($authnreq->id);
    my $x = $authnreq->as_xml;

    my $key_fh;
    if (defined $self->authentication->sp_key and $self->authentication->sp_key ne ''){
        my $sp_key = $self->authentication->sp_key;
        $key_fh = File::Temp->new;
        print $key_fh $sp_key;
        $key_fh->close;
    }

    # FIXME: Requires a key in the database
    my $redirect = Net::SAML2::Binding::Redirect->new(
        $key_fh ? (key => $key_fh->filename) : (),
        url      => $sso_url,
        param    => 'SAMLRequest',
        $key_fh ? (insecure => 0) : (insecure => 1),
        sig_hash => 'sha256', # Hard coded - may want allow as an option
    );

    my $url = $redirect->get_redirect_uri($x);
    $self->redirect("$url");
};

1;
