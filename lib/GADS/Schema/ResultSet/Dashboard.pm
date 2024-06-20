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
        map { +{ id => $_->id, url => $_->url, name => $_->name, } }
            $self->_all_user(%params)
    ];
}

sub _all_user
{   my ($self, %params) = @_;

    my $user   = $params{user};
    my $layout = $params{layout};

    # A user should have at least a personal dashboard, a table shared
    # dashboard and a site dashboard.
    # If they don't have a personal dashboard, then create a copy of the shared
    # dashboard.

    my $schema = $self->result_source->schema;
    my $guard  = $schema->txn_scope_guard;

    my @dashboards;
    my $dash;

    # Table shared
    if ($layout)
    {
        $dash = $self->shared_dashboard(%params);
        push @dashboards, $dash
            if !$dash->is_empty || $layout->user_can('layout');

        $dash = $self->search({
            'me.instance_id' => $layout->instance_id,
            'me.user_id'     => $user->id,
        })->next;
        $dash ||= $self->create_dashboard(%params, type => 'personal');

        push @dashboards, $dash;
    }
    else
    {
        # Site shared, only show if populated or superadmin
        $dash = $self->shared_dashboard(%params, layout => undef);
        push @dashboards, $dash
            if !$dash->is_empty || $user->permission->{superadmin};

        # Site personal
        $dash = $self->search({
            'me.instance_id' => undef,
            'me.user_id'     => $user->id,
        })->next;
        $dash ||= $self->create_dashboard(
            %params,
            layout => undef,
            type   => 'personal'
        );
        push @dashboards, $dash;
    }

    $guard->commit;

    return @dashboards;
}

sub shared_dashboard
{   my ($self, %params) = @_;
    my $dashboard = $self->search({
        'me.instance_id' => $params{layout} && $params{layout}->instance_id,
        'me.user_id'     => undef,
    })->next;
    $dashboard = $self->create_dashboard(%params, type => 'shared')
        if !$dashboard;
    $dashboard->layout($params{layout});

    return $dashboard;
}

sub dashboard
{   my ($self, %params) = @_;

    my $id = $params{id};

    return undef if !$id || !$self->find($params{id});

    my $user   = $params{user};
    my $layout = $params{layout};

    my $dashboard_rs = $self->search(
        {
            'me.id'      => $id,
            'me.user_id' => [ undef, $user->id ],
        },
        {
            prefetch => 'widgets',
        },
    );

    if ($dashboard_rs->count)
    {
        my $dashboard = $dashboard_rs->next;
        $dashboard->layout($layout);
        return $dashboard;
    }

    error __x "Dashboard {id} not found for this user", id => $id;
}

sub create_dashboard
{   my ($self, %params) = @_;

    my $type   = $params{type};
    my $user   = $params{user};
    my $layout = $params{layout};
    my $site   = $params{site};

    my $schema = $self->result_source->schema;
    my $guard  = $schema->txn_scope_guard;

    my $dashboard;

    if ($type eq 'shared')
    {
        # First time this has been called. Create default dashboard using legacy
        # homepage text if it exists
        $dashboard = $self->create({
            instance_id => $layout && $layout->instance_id,
        });

        my $homepage_text =
            $layout ? $layout->homepage_text : $site->homepage_text;
        my $homepage_text2 =
            $layout ? $layout->homepage_text2 : $site->homepage_text2;

        if ($homepage_text2)    # Assume 2 columns of homepage
        {
            $dashboard->create_related(
                'widgets',
                {
                    type    => 'notice',
                    h       => 6,
                    w       => 6,
                    x       => 6,
                    y       => 0,
                    content => $homepage_text2,
                },
            );
        }

        # Ensure empty dashboard if no existing homepages. This allows an empty
        # dashboard to be detected and different dashboards rendered
        # accordingly
        if ($homepage_text)
        {
            $dashboard->create_related(
                'widgets',
                {
                    type    => 'notice',
                    h       => 6,
                    w       => $homepage_text2 ? 6 : 12,
                    x       => 0,
                    y       => 0,
                    content => $homepage_text,
                },
            );
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

        $dashboard->create_related(
            'widgets',
            {
                type    => 'notice',
                h       => 6,
                w       => 6,
                x       => 0,
                y       => 0,
                content => $content,
            },
        );
    }
    else
    {
        panic "Unexpected dashboard type: $type";
    }

    $guard->commit;

    return $dashboard;
}

1;
