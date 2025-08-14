package GADS::SAML;

use Log::Report 'linkspace';

use Moo;

use Net::SAML2 0.67;
use Net::SAML2::Binding::POST;
use Net::SAML2::Binding::Redirect;
use Net::SAML2::IdP;
use Net::SAML2::SP;
use Net::SAML2::Protocol::Assertion;
use Net::SAML2::Protocol::AuthnRequest;
use URN::OASIS::SAML2 qw(:bindings :urn);

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

has sp_key => (
    is => 'lazy',
);

sub _build_sp_key
{   my $self = shift;
    my $key_fh = File::Temp->new;
    print $key_fh $self->authentication->sp_key;
    $key_fh->close;
    $key_fh;
}

has sp_cert => (
    is => 'lazy',
);

sub _build_sp_cert
{   my $self = shift;
    my $cert_fh = File::Temp->new;
    print $cert_fh $self->authentication->sp_cert;
    $cert_fh->close;
    $cert_fh;
}

sub _build_sso_xml
{   my $self = shift;
    $self->base_url.'saml/xml';
}

sub callback
{   my ($self, %params) = @_;

    my $cacert_fh;
    my $relaystate = $params{relaystate} if defined $params{relaystate};

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

    my $return;
    eval {
	$return = $post->handle_response($saml_response);
    };
    if ($@) {
        my $msg = "Error validating SAML response";
        $msg = "Could not verify CA Certificate" if ($@ =~ "Could not verify CA certificate");
	warn $@;
        GADS::forwardHome({ danger => __x($msg)}, 'saml_login' );
    }

    if ($return)
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

        if (!$assertion->valid($self->authentication->sso_xml, $self->request_id)) {
            my $auth = $self->authentication;

            my $msg = $auth->saml_assertion_invalid_error;
            GADS::forwardHome(
                { danger => __x($msg,
                                saml_request_id => $self->request_id,
                                status          => $assertion->response_status,
                                substatus       => $assertion->response_substatus,
                            ) }, 'saml_login' );
        }
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

    unlink $cacert_fh->filename;
    my $sso_url = $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');

    my $authnreq = Net::SAML2::Protocol::AuthnRequest->new(
        issuer      => $self->authentication->sso_xml,
        destination => $sso_url,
        nameid_format => $idp->format('emailAddress') || undef,
        assertion_url => $self->authentication->sso_url,
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

sub metadata
{   my $self = shift;
    my $sign = shift;

    my $sp = $self->_sp;

    $sp->{sign_metadata} = $sign;
    # Appears to be a Net::SAML2 bug.  I would likely wrap this in a version check
    my $version = $Net::SAML2::VERSION;
    my $metadata;
    if ($version gt "0.69" ) {
        $metadata = $sp->metadata;
    } else {
        $metadata = $sign ? '' : '<?xml version="1.0"?>' . "\n";
        $metadata .= $sp->metadata;
    }

    return $metadata->stringify();
}

sub _sp
{   my $self = shift;
    my $host = $self->{base_url}->host;
    my $url  = "$self->{base_url}";
    $url =~ s/\/$//;

    my $key_fh = $self->sp_key;
    my $cert_fh = $self->sp_cert;

    my $sp = Net::SAML2::SP->new(
        id             => $self->authentication->sso_xml,
        url            => $url,
        $cert_fh ? (cert => $cert_fh->filename) : (),
        encryption_key => $cert_fh->filename,
        $key_fh ? (key => $key_fh->filename) : (),
        #cacert         => "XXX",
        single_logout_service => [
        {
            Binding   => BINDING_HTTP_REDIRECT,
            Location  => $self->authentication->sso_url,
            isDefault => 'true',
            index     => 1,
        },
        {
            Binding   => BINDING_HTTP_POST,
            Location  => $self->authentication->sso_url,
            isDefault => 'false',
            index     => 2,
        }],
        assertion_consumer_service => [
        {
            Binding   => BINDING_HTTP_POST,
            Location  => $self->authentication->sso_url,
            isDefault => 'true',
            # optionally
            index     => 1,
        }],
        error_url => "$url/support",

        org_name         => $host,
        org_display_name => $host,
        org_contact      => "admin\@$host",
        authnreq_signed  => 1,
    );

    $sp;
}

1;
