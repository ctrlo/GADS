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

use GADS::Email;
use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
schema->storage->debug(1);
use Ouch;
use Scalar::Util qw(looks_like_number);
use List::MoreUtils qw/ uniq /;

sub _create_cache
{   my ($alert, @current_ids) = @_;

    my $view_id = $alert->view_id;

    unless (@current_ids)
    {
        @current_ids = map {$_->current_id} GADS::Record->current({ view_id => $view_id });
    }
    my $columns = GADS::View->columns({ view_id => $view_id });
    my @caches;
    foreach my $current_id (@current_ids)
    {
        foreach my $column (@$columns)
        {
            push @caches, {
                layout_id  => $column->{id},
                view_id    => $view_id,
                current_id => $current_id,
            };
        }
    }
    rset('AlertCache')->populate(\@caches);
}

sub alert
{
    my ($self, $view_id, $frequency, $user) = @_;

    # Check that user has access to this view (borks on no access)
    my $view = GADS::View->view($view_id, $user);

    if (looks_like_number $frequency)
    {
        ouch 'badparam', "Frequency value of $frequency is invalid"
            unless $frequency == 0 || $frequency == 24;
    }
    else {
        ouch 'badparam', "Frequency value of $frequency is invalid"
            unless !$frequency;
    }
        
    my ($alert) = rset('Alert')->search({
        view_id => $view_id,
        user_id => $user->{id},
    });

    if ($alert)
    {
        if ($frequency)
        {
            $alert->update({ frequency => $frequency });
        }
        else {
            # Any other alerts using the same view?
            unless (rset('Alert')->search({ view_id => $alert->view_id })->count > 1)
            {
                # Delete cache if not
                rset('AlertCache')->search({ view_id => $alert->view_id })->delete;
            }
            $alert->delete;
        }
    }
    else {
        # Check whether this view already has alerts. No need for another
        # cache if so.
        my $exists = rset('Alert')->search({ view_id => $view_id })->count;

        my $alert = rset('Alert')->create({
            view_id   => $view_id,
            user_id   => $user->{id},
            frequency => $frequency,
        });
        _create_cache $alert unless $exists;
    }
}

sub process
{   my ($self, $current_id, $columns) = @_;

    my @col_ids = keys %$columns or return;

    my @caches = rset('View')->search({
        'alert_caches.current_id' => $current_id,
        'alert_caches.layout_id'  => \@col_ids,
    }, {
        prefetch => ['alert_caches', {'alerts' => 'user'} ],
        collapse => 1,
    })->all;

    my @view_ids;
    foreach my $cache (@caches)
    {
        # Note which views we know have changed, so we don't search them later
        push @view_ids, $cache->id;

        # Any emails that need to be sent instantly
        my @emails = map { $_->user->email } grep { $_->frequency == 0 } $cache->alerts;
        if (@emails)
        {
            my @cids;
            foreach my $i ($cache->alert_caches)
            {
                push @cids, $i->current_id;
            }
            send_alert(\@cids, $cache, \@emails, $columns);
        }

        # And those to be sent later
        my @cuid = ref $current_id eq 'ARRAY' ? @$current_id : ($current_id);
        foreach my $cuid (@cuid)
        {
            my @later = map { {alert_id => $_->id, current_id => $cuid} } grep { $_->frequency > 0 } $cache->alerts;
            foreach my $later (@later)
            {
                foreach my $col_id (@col_ids)
                {
                    $later->{layout_id} = $col_id;
                    # Unique constraint. Catch any exceptions. This is also
                    # why we probably can't do all these with one call to populate()
                    eval { rset('AlertSend')->create($later) }
                }
            }
        }
    }

    # Look at any view that has filters containing changed values,
    # and that aren't already in the notification queue.
    my $search->{'filters.layout_id'} = \@col_ids;
    $search->{'alerts.id'} = { '!=' => undef };
    $search->{'me.id'} = { '!=' => [ -and => @view_ids ] } if @view_ids;
    my @new = rset('View')->search($search,{
        join => ['filters', 'alerts']
    });

    # See if the new data has cropped-up in any other views
    my @now_in = GADS::Record->search_views($current_id, @new);
    foreach my $found (@now_in)
    {
        my $v = $found->{view};
        my @emails;
        foreach my $alert ($v->alerts)
        {
            if ($alert->frequency)
            {
                # send later
                foreach my $cuid ($found->{ids})
                {
                    eval {
                        # Unique constraint on table. Catch
                        # any exceptions
                        rset('AlertSend')->create({
                            alert_id   => $alert->id,
                            current_id => $cuid,
                        });
                    }
                }
            }
            else {
                # send now
                push @emails, $alert->user->email;
            }
            _create_cache $alert, @{$found->{ids}};
        }
        send_alert($found->{ids}, $v, \@emails) if @emails;
    }
}

sub send_alert
{   my ($current_id, $view, $emails, $columns) = @_;

    my $view_name = $view->name;

    if ($columns)
    {
        # Individual fields to notify
        my %cnames;
        foreach my $col ($view->alert_caches)
        {
            $cnames{$columns->{$col->layout_id}->{name}} = 1;
        }
        my $cnames = join ', ', keys %cnames;
        my $text;
        if (ref $current_id eq 'ARRAY')
        {
            my $ids = join ', ', uniq @$current_id;
            $text   = "The following items were changed for record IDs $ids: $cnames";
        }
        else {
            $text   = "The following items were changed for record ID $current_id: $cnames";
        }
        GADS::Email->send({ emails => $emails, subject => qq(Changes in view "$view_name"), text => $text });
    }
    else {
        my $text;
        if (ref $current_id eq 'ARRAY')
        {
            $text   = "The following new items have appeared in the view $view_name: ".join(', ', @$current_id);
        }
        else {
            $text   = "A new item (ID $current_id) has appeared in the view $view_name.";
        }
        GADS::Email->send({ emails => $emails, subject => qq(Changes in view "$view_name"), text => $text });
    }
}

sub all
{   my ($self, $user_id) = @_;

    my @alerts_rs = rset('Alert')->search({
        user_id => $user_id,
    })->all;

    my $alerts;
    foreach my $alert (@alerts_rs)
    {
        $alerts->{$alert->view_id} = {
            id => $alert->id,
            view_id => $alert->view_id,
            frequency => $alert->frequency,
        };
    };
    $alerts;
}

1;

