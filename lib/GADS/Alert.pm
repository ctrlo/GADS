=pod
GADS - Globally Accessible Data Store
Copyright (C) 2014 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

package GADS::Alert;

use GADS::Views;
use Log::Report 'linkspace';
use Scalar::Util qw(looks_like_number);

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

has layout => (
    is       => 'rw',
    required => 1,
);

has schema => (
    is       => 'rw',
    required => 1,
);

has user => (
    is       => 'rw',
    required => 1,
);

has id => (
    is      => 'rwp',
    isa     => Int,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my ($alert) = $self->schema->resultset('Alert')->search({
            view_id => $self->view_id,
            user_id => $self->user->id,
        });
        $alert->id;
    },
);

has frequency => (
    is  => 'rw',
    isa => sub {
        my $frequency = shift;
        if (looks_like_number $frequency)
        {
            error __x "Frequency value of {frequency} is invalid", frequency => $frequency
                unless $frequency == 0 || $frequency == 24;
        }
        else {
            # Will be empty string from form submission
            error __x "Frequency value of {frequency} is invalid", frequency => $frequency
                if $frequency;
        }
    },
    coerce => sub {
        # Will be empty string from form submission
        $_[0] || $_[0] =~ /0/ ? $_[0] : undef;
    },
);

has view_id => (
    is      => 'rw',
    isa     => Int,
    trigger => sub {
        my ($self, $view_id) = @_;
        # Check that user has access to this view (borks on no access)
        my $view    = GADS::View->new(
            user        => $self->user,
            id          => $view_id,
            schema      => $self->schema,
            layout      => $self->layout,
            instance_id => $self->layout->instance_id,
        );
    },
);

has all => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;

        my @alerts_rs = $self->schema->resultset('Alert')->search({
            user_id => $self->user->id,
        })->all;

        my $alerts;
        foreach my $alert (@alerts_rs)
        {
            $alerts->{$alert->view_id} = {
                id        => $alert->id,
                view_id   => $alert->view_id,
                frequency => $alert->frequency,
            };
        };
        $alerts;
    },
);

has view => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_view
{   my $self = shift;
    my $views   = GADS::Views->new(
        # Current user may not have access to all fields in view,
        # permissions are managed when sending the alerts
        user        => undef,
        schema      => $self->schema,
        layout      => $self->layout,
        instance_id => $self->layout->instance_id,
    );
    $views->view($self->view_id);
}

sub update_cache
{   my ($self, %options) = @_;

    my $guard = $self->schema->txn_scope_guard;

    my $view = $self->view;

    if (!$view->has_alerts)
    {
        $self->schema->resultset('AlertCache')->search({
            view_id => $view->id,
        })->delete;
        return;
    }

    # If the view contains a CURUSER filter, we need separate
    # alert caches for each user that has this alert. Only need
    # to worry about this if all_users flag is set
    my @users = $view->has_curuser && $options{all_users}
        ? map $_->user, $self->schema->resultset('Alert')->search({
            view_id => $view->id
        }, {
            prefetch => 'user'
        })->all : ($self->user);

    foreach my $user (@users)
    {
        my $u = $view->has_curuser && $user;

        my $records = GADS::Records->new(
            # We generally want to generate a view's alert_cache without user
            # defined permissions limiting it, otherwise multiple users on a
            # single global view will have different things to alert on.
            # The only exception is when the view has a CURUSER, in which
            # case we generate them individually.
            user   => $u,
            layout => $self->layout,
            schema => $self->schema,
            view   => $view,
        );

        my $user_id = $view->has_curuser ? $u->id : undef;

        my %exists;
        # For each item in this view, see if it exists in the cache. If it doesn't,
        # create it.
        # Wrap in a LR try block so that we can disard the thousands of trace
        # messages that are generated during record retrieval, otherwise this
        # function will use a lot of memory. Only collect messages at warning
        # or higher and then report on completion.
        try {
            while (my $record = $records->single)
            {
                my $current_id = $record->current_id;
                foreach my $column (@{$view->columns})
                {
                    my $a = {
                        layout_id  => $column,
                        view_id    => $view->id,
                        current_id => $current_id,
                        user_id    => $user_id,
                    };
                    my ($a_rs) = $self->schema->resultset('AlertCache')->search($a);
                    $a_rs ||= $self->schema->resultset('AlertCache')->create($a);
                    # Keep track of all those that should be in the cache
                    $exists{$a_rs->id} = undef;
                }
            }
        } accept => 'WARNING-';
        $@->reportFatal;

        # Now iterate through all of them and delete any that shouldn't exist
        my $rs = $self->schema->resultset('AlertCache')->search({
            view_id => $view->id,
            user_id => $user_id,
        });
        while (my $existing = $rs->next)
        {
            $existing->delete unless exists $exists{$existing->id};
        }
    }

    # Now delete any alerts that should not be there that are applicable to our update
    if ($view->has_curuser)
    {
        # Possibly just changed to curuser, cleanup any
        # undef user rows from previous alert
        $self->schema->resultset('AlertCache')->search({
            view_id => $view->id,
            user_id => undef,
        })->delete;
        # Cleanup any user_id alerts for users that no longer have this alert
        if ($options{all_users})
        {
            $self->schema->resultset('AlertCache')->search({
                view_id => $view->id,
                user_id => [ '-and', [map { +{ '!=' => $_->id } } @users] ],
            })->delete;
        }
    }
    else {
        # Cleanup specific user_id alerts for (now) non-curuser alert
        $self->schema->resultset('AlertCache')->search({
            view_id => $view->id,
            user_id => { '!=' => undef },
        })->delete;
    }

    $guard->commit;
}

sub write
{
    my $self = shift;

    error __"It is not possible to configure an alert on a view containing groups"
        if $self->view->is_group;
    # Need to clear view for it to be rebuilt once the alert has been written,
    # otherwise update_cache will think that the view does not contain an alert
    $self->clear_view;

    my ($alert) = $self->schema->resultset('Alert')->search({
        view_id => $self->view_id,
        user_id => $self->user->id,
    });

    if ($alert)
    {
        if (defined $self->frequency)
        {
            $alert->update({ frequency => $self->frequency });
        }
        else {
            my $guard = $self->schema->txn_scope_guard;

            # Any other alerts using the same view? Delete cache if not
            $self->schema->resultset('AlertCache')->search({ view_id => $alert->view_id })->delete
                unless $self->schema->resultset('Alert')->search({ view_id => $alert->view_id })->count > 1;
            # Delete any queued alerts
            $self->schema->resultset('AlertSend')->search({ alert_id => $alert->id })->delete;
            $alert->delete;

            $guard->commit;
        }
    }
    elsif(defined $self->frequency) {
        # Check whether this view already has alerts. No need for another
        # cache if so, unless view contains CURUSER
        my $exists = $self->schema->resultset('Alert')->search({ view_id => $self->view_id })->count;

        my $alert = $self->schema->resultset('Alert')->create({
            view_id   => $self->view_id,
            user_id   => $self->user->id,
            frequency => $self->frequency,
        });
        $self->_set_id($alert->id);
        $self->update_cache if !$exists || $self->view->has_curuser;
    }
}

1;

