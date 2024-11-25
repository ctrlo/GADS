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
{   my ($self, %search) = @_;

    $self->search({
        %search,
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

sub create_provider
{   my ($self, %params) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    my $site = $self->result_source->schema->resultset('Site')->next;

    error __"A name must be specified for the provider"
        if !$params{name};

    error __x"Provider {name} already exists", name => $params{name}
        if $self->providers(name => $params{name})->count;

    my $code         = Session::Token->new( length => 32 )->get;
    my $request_base = $params{request_base};

    my $provider = $self->create({
        name                  => $params{name},
        type                  => $params{type},
        saml2_firstname       => $params{saml2_firstname},
        saml2_surname         => $params{saml2_surname},
        xml                   => $params{xml},
        cacert                => $params{cacert},
        sp_cert               => $params{sp_cert},
        sp_key                => $params{sp_key},
        saml2_relaystate      => $params{saml2_relaystate},
        saml2_groupname       => $params{saml2_groupname},
    });

    my $audit = GADS::Audit->new(schema => $self->result_source->schema, user => $params{auth_provider_change});

    $audit->login_change(
        __x"Provider created, id: {id}, provider: {provider}",
            id => $provider->id, provider => $params{name}
    );

    $provider->update_provider(%params);

    $guard->commit;

    return $provider;
}

1;
