package GADS::Schema::ResultSet::Dashboard;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use JSON qw/encode_json/;
use Log::Report 'linkspace';

sub dashboards_json
{   my ($self, %params) = @_;

    $self->_all_user(%params);
    return encode_json [
        map {
            +{
                id   => $_->id,
                url  => $_->url,
                name => $_->name,
            }
        } $self->_all_user(%params)
    ];
}

sub _all_user
{   my ($self, %params) = @_;

    my $user   = $params{user};
    my $layout = $params{layout};

    # A user should have at least a personal dashboard and a shared dashboard.
    # If they don't have a personal dashboard, then create a copy of the shared
    # dashboard.

    my $schema = $self->result_source->schema;
    my $guard = $schema->txn_scope_guard;

    my @dashboards = ($self->_shared_dashboard(%params));

    my $dashboard = $self->search({
        'me.instance_id' => $layout && $layout->instance_id,
        'me.user_id'     => $user->id,
    })->next;

    $dashboard = $self->create_dashboard(%params, type => 'personal')
        if !$dashboard;

    push @dashboards, $dashboard;

    $guard->commit;

    return @dashboards;
}

sub _shared_dashboard
{   my ($self, %params) = @_;
    my $dashboard = $self->search({
        'me.instance_id' => $params{layout} && $params{layout}->instance_id,
        'me.user_id'     => undef,
    })->next;
    $dashboard = $self->create_dashboard(%params, type => 'shared')
        if !$dashboard;

    return $dashboard;
}

sub dashboard
{   my ($self, %params) = @_;

    my $id = $params{id}
        || $self->_shared_dashboard(%params)->id;

    my $user   = $params{user};
    my $layout = $params{layout};

    my $dashboard_rs = $self->search({
        'me.id'          => $id,
        'me.instance_id' => $layout && $layout->instance_id,
        'me.user_id'     => [undef, $user->id],
    },{
        prefetch => 'widgets',
    });

    if ($dashboard_rs->count)
    {
        my $dashboard = $dashboard_rs->next;
        $dashboard->layout($layout);
        return $dashboard;
    }

    error __x"Dashboard {id} not found for this user", id => $id;
}

sub create_dashboard
{   my ($self, %params) = @_;

    my $type   = $params{type};
    my $user   = $params{user};
    my $layout = $params{layout};
    my $site   = $params{site};

    my $schema = $self->result_source->schema;
    my $guard = $schema->txn_scope_guard;

    my $dashboard;

    if ($type eq 'shared')
    {
        # First time this has been called. Create default dashboard using legacy
        # homepage text if it exists
        $dashboard = $self->create({
            instance_id => $layout && $layout->instance_id,
        });

        my $homepage_text  = $layout ? $layout->homepage_text  : $site->homepage_text;
        my $homepage_text2 = $layout ? $layout->homepage_text2 : $site->homepage_text2;

        if ($homepage_text2) # Assume 2 columns of homepage
        {
            $dashboard->create_related('widgets', {
                type    => 'notice',
                h       => 6,
                w       => 6,
                x       => 6,
                y       => 0,
                content => $homepage_text2,
            });
        }
        # Ensure empty dashboard if no existing homepages. This allows an empty
        # dashboard to be detected and different dashboards rendered
        # accordingly
        if ($homepage_text)
        {
            $dashboard->create_related('widgets', {
                type    => 'notice',
                h       => 6,
                w       => $homepage_text2 ? 6 : 12,
                x       => 0,
                y       => 0,
                content => $homepage_text,
            });
        }
    }
    elsif ($type eq 'personal')
    {
        $dashboard = $self->create({
            instance_id => $layout && $layout->instance_id,
            user_id     => $user->id,
        });

        my $content = "<p>Welcome to your personal dashboard</p>
            <p>Create widgets using the Add Widget menu. Edit widgets using their
            edit button (including this one). Drag and resize widgets as required.</p>";

        $dashboard->create_related('widgets', {
            type    => 'notice',
            h       => 6,
            w       => 6,
            x       => 0,
            y       => 0,
            content => $content,
        });
    }
    else {
        panic "Unexpected dashboard type: $type";
    }

    $guard->commit;

    return $dashboard; 
}

1;
