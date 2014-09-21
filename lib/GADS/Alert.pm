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

sub _create_cache
{   my ($alert, $user, $view_id) = @_;

    my @records = GADS::Record->current({ view_id => $view_id, user => $user });
    my $columns = GADS::View->columns({ view_id => $view_id, user => $user });
    my @caches;
    foreach my $record (@records)
    {
        foreach my $column (@$columns)
        {
            push @caches, {
                layout_id  => $column->{id},
                view_id    => $view_id,
                current_id => $record->current_id,
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
        _create_cache $alert, $user, $view_id unless $exists;
    }
}

sub send
{   my ($self, $current_id, $columns) = @_;

    my @col_ids = keys %$columns;

    my @caches = rset('View')->search({
        'alert_caches.current_id' => $current_id,
        'alert_caches.layout_id'  => \@col_ids,
    }, {
        prefetch => ['alert_caches', {'alerts' => 'user'} ],
        collapse => 1,
    })->all;

    foreach my $cache (@caches)
    {
        my $view_name = $cache->name;
        my @cnames = map { $columns->{$_->layout_id}->{name} } $cache->alert_caches;
        my $cnames = join ',', @cnames;
        my $text   = "The following items were changed for record ID $current_id: $cnames";
        my @emails = map { $_->user->email } $cache->alerts;
        GADS::Email->send({ emails => \@emails, subject => qq(Changes in view "$view_name"), text => $text });
    }
}

1;

