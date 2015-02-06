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

package GADS::AlertSend;

use Array::Utils qw(:all);
use GADS::Email;
use GADS::Util qw(:all);
use List::MoreUtils qw/ uniq /;
use Log::Report;
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

has current_ids => (
    is       => 'rw',
    isa      => ArrayRef,
    required => 1,
);

has base_url => (
    is       => 'rw',
    required => 1,
);

has columns => (
    is       => 'rw',
    required => 1,
);

sub process
{   my $self = shift;

    my @col_ids = map {$_->id} @{$self->columns} or return;

    # First see what views this record should be in. We use this to
    # see if it's dropped out or been added to any views
    my @all_views = $self->schema->resultset('View')->search({
        'view_layouts.layout_id' => \@col_ids,
    },{
        prefetch => 'view_layouts',
    })->all;

    # See what views the records are in
    my $records = GADS::Records->new(
        schema => $self->schema,
        layout => $self->layout,
        user   => $self->user,
    );
    # All the views the record is now in
    my @now_in = $records->search_views($self->current_ids, @all_views);
    my %now_in_views = map { $_->{view}->id => $_ } @now_in;

    # Compare that to the cache of what it was in before
    my @original = $self->schema->resultset('View')->search({
        'alert_caches.current_id' => $self->current_ids,
    },{
        select   => [ 'me.id', 'me.name', { max => 'alert_caches.current_id' } ],
        as       => [ 'me.id', 'me.name', 'alert_caches.current_id' ],
        prefetch => ['alert_caches', {'alerts' => 'user'} ],
        group_by => 'alert_caches.current_id',
    })->all;

    # Look at all the views it was in
    my @gone; my @to_delete;
    foreach my $view (@original)
    {
        my @current_ids;
        foreach my $cache ($view->alert_caches)
        {
            # See if it's still in the views
            my $found = grep { $cache->current_id } @{$now_in_views{$view->id}->{ids}};
            if (!$found)
            {
                push @current_ids, $cache->current_id;
            }
        }
        # Needed in different formats for different uses
        if (@current_ids)
        {
            push @gone, {
                view        => $view,
                current_ids => \@current_ids,
            };
            push @to_delete, {
                view_id    => $view->id,
                current_id => \@current_ids,
            };
        }
    }
    $self->schema->resultset('AlertCache')->search(\@to_delete)->delete if @to_delete;

    my @caches = $self->schema->resultset('View')->search({
        'alert_caches.current_id' => $self->current_ids,
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
            $self->_send_alert('changed', \@cids, $cache, \@emails, $self->columns);
        }

        # And those to be sent later
        foreach my $cuid (@{$self->current_ids})
        {
            my @later = map { {alert_id => $_->id, current_id => $cuid} } grep { $_->frequency > 0 } $cache->alerts;
            foreach my $later (@later)
            {
                foreach my $col_id (@col_ids)
                {
                    $later->{layout_id} = $col_id;
                    # Unique constraint. Catch any exceptions. This is also
                    # why we probably can't do all these with one call to populate()
                    eval { $self->schema->resultset('AlertSend')->create($later) }
                }
            }
        }
    }

    # Now see what views it is new in
    my @arrived; my @to_add;
    foreach my $found (@now_in)
    {
        my @current_ids;
        my $view = $found->{view};

        # Get all the columns for this view. Can't use current view object
        # as it only contains the filtered columns
        my ($vrs) = $self->schema->resultset('View')->search({
            'me.id' => $view->id,
        },{
            prefetch => 'view_layouts',
        })->all;
        my @view_columns = map { $_->layout_id } $vrs->view_layouts;
        foreach my $current_id (@{$found->{ids}})
        {
            # See if it was originally in the views
            my @acs = $now_in_views{$view->id}->{view}->alert_caches;
            my $found = grep { $_->current_id == $current_id } @acs;
            if (!$found)
            {
                push @current_ids, $current_id;
                foreach my $col_id (@view_columns)
                {
                    push @to_add, {
                        layout_id  => $col_id,
                        view_id    => $view->id,
                        current_id => $current_id,
                    };
                }
            }
        }
        push @arrived, {
            view        => $view,
            current_ids => \@current_ids,
        } if @current_ids;
    }
    $self->schema->resultset('AlertCache')->populate(\@to_add) if @to_add;

    $self->_gone_arrived('gone', @gone);
    $self->_gone_arrived('arrived', @arrived);
}

sub _gone_arrived
{   my ($self, $action, @items) = @_;

    foreach my $item (@items)
    {
        my @emails;
        foreach my $alert ($item->{view}->alerts)
        {
            if ($alert->frequency)
            {
                # send later
                foreach my $cuid ($item->{current_ids})
                {
                    eval {
                        # Unique constraint on table. Catch
                        # any exceptions
                        $self->schema->resultset('AlertSend')->create({
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
        }
        $self->_send_alert($action, $item->{current_ids}, $item->{view}, \@emails) if @emails;
    }
}

sub _send_alert
{   my ($self, $action, $current_ids, $view, $emails, $columns) = @_;

    my $view_name = $view->name;
    my @current_ids = @{$current_ids};

    my $text;
    if ($action eq "changed")
    {
        # Individual fields to notify
        my $cnames = join ', ', map { $_->name } @{$columns};
        if (@current_ids > 1)
        {
            my $ids = join ', ', uniq @current_ids;
            $text   = "The following items were changed for record IDs $ids: $cnames\n\n";
            $text  .= "Links to the records are as follows:\n";
        }
        else {
            $text   = "The following items were changed for record ID @current_ids: $cnames\n\n";
            $text  .= "Please use the following link to access the record:\n";
        }
    }
    elsif($action eq "arrived") {
        if (@current_ids > 1)
        {
            $text   = "New items have appeared in the view $view_name, with the following IDs: ".join(', ', @current_ids)."\n\n";
            $text  .= "Links to the new items are as follows:\n";
        }
        else {
            $text   = qq(A new item (ID @current_ids) has appeared in the view "$view_name".\n\n);
            $text  .= "Please use the following link to access the record:\n";
        }
    }
    elsif($action eq "gone") {
        if (@current_ids > 1)
        {
            $text   = "Items have disappeared from the view $view_name, with the following IDs: ".join(', ', @current_ids)."\n\n";
            $text  .= "Links to the removed items are as follows:\n";
        }
        else {
            $text   = qq(An item (ID @current_ids) has disappeared from the view "$view_name".\n\n);
            $text  .= "Please use the following link to access the original record:\n";
        }
    }
    foreach my $cid (@current_ids)
    {
        my $base = $self->base_url;
        $text  .= "$base$cid\n";
    }
    my $email = GADS::Email->new;
    $email->send({
        subject => qq(Changes in view "$view_name"),
        emails  => $emails,
        text    => $text,
    });
}

1;

