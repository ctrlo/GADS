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
        'me.type'    => 0,
    });
}

sub by_id
{
    my $self = shift;
    my $id = shift;
    $self->search({
        'me.id' => $id,
        'me.enabled' => 1,
    });
}

sub saml2_provider
{   my $self = shift;
    $self->enabled->search({
        'me.type' => 1,
    })->next;
}

sub ordered
{   shift->search({
		},{
        order_by => 'me.name',
    });
}

sub create_provider
{   my ($self, %params) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    # This should already be set by `resultset` sub in GADS::Schema so shouldn't be needed here
    my $site = $self->result_source->schema->resultset('Site')->next; # I don't think this will work for Multi?

    error __"A name must be specified for the provider"
        if !$params{name};

    error __x"Provider {name} already exists", name => $params{name}
        if $self->providers(name => $params{name})->count;

    my $code         = Session::Token->new( length => 32 )->get;
    my $request_base = $params{request_base};

    my $provider = $self->create({
        name                  => $params{name},
        type                  => $params{type},
        enabled               => defined $params{enabled} ? $params{enabled} : 0,
        saml2_firstname       => $params{saml2_firstname},
        saml2_surname         => $params{saml2_surname},
        xml                   => $params{xml},
        cacert                => $params{cacert},
        sp_cert               => $params{sp_cert},
        sp_key                => $params{sp_key},
        saml2_unique_id       => $params{saml2_unique_id},
        saml2_relaystate      => $params{saml2_relaystate},
        saml2_groupname       => $params{saml2_groupname},
        saml2_nameid          => $params{saml2_nameid},
    });

    my $audit = GADS::Audit->new(schema => $self->result_source->schema, user => $params{auth_provider_change});

    $audit->login_change(
        __x"Provider created, id: {id}, provider: {provider}",
            id => $provider->id, provider => $params{name}
    );

    $guard->commit;

    return $provider;
}

sub create_default_provider {
    my $self = shift;

    my $schema = $self->result_source->schema;

    $schema->storage->ensure_connected;
    my $txn = $self->result_source->schema->txn_scope_guard;
    $schema->storage->svp_begin ('create_default_provider');
    my $exists = $self->search({
        type => 0,
        name => 'builtin',
    })->count;
    if ($exists) {
        $schema->storage->svp_release ('create_default_provider');
        return;
    }
    my $provider = $self->create({
        type    => 0,
        name    => 'builtin',
        enabled => 1,
    });
    $schema->storage->svp_release ('create_default_provider');
    $txn->commit;
}

1;
