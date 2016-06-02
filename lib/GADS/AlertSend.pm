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

use GADS::Email;
use GADS::Records;
use GADS::Util qw(:all);
use GADS::Views;
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

# Whether this is a brand new record
has current_new => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
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

    # First see what views this record should be in. We use this to see if it's
    # dropped out or been added to any views.

    # Firstly, search on the views that may have been affected. This is all the
    # ones that have a filter with the changed columns. If this is a brand new
    # record, however, then it doesn't matter what columns have changed, so get
    # all the views.
    my $search = {
        'alerts.id' => { '!=' => undef },
    };
    $search->{'filters.layout_id'} = $self->columns
        unless $self->current_new;
    my @view_ids = $self->schema->resultset('View')->search($search,{
        join     => ['alerts', 'filters'],
    })->get_column('id')->all;

    # We now have all the views that may have been affected by this update.
    # Convert them into GADS::View objects
    my $views = GADS::Views->new(
        # Current user may not have access to all fields in view,
        # permissions are managed when sending the alerts
        user        => undef,
        schema      => $self->schema,
        layout      => $self->layout,
        instance_id => $self->layout->instance_id,
    );

    my $records = GADS::Records->new(
        columns => [], # Otherwise all columns retrieved during search construct
        schema  => $self->schema,
        layout  => $self->layout,
        user    => $self->user,
    );

    my @to_add; # Items to add to the cache later
    if (my @views = map { $views->view($_) } @view_ids)
    {
        # See which of those views the new/changed records are in.
        #
        # All the views the record is *now* in
        my $now_in_views; my $now_in_views2;
        foreach my $now_in ($records->search_views($self->current_ids, @views))
        {
            # Create an easy to search hash for each view, user and record
            my $view_id = $now_in->{view}->id;
            my $user_id = $now_in->{user_id} || '';
            my $cid     = $now_in->{id};
            $now_in_views
                ->{$view_id}
                ->{$user_id}
                ->{$cid} = 1;
            # The same, in a slightly different format
            $now_in_views2->{"${view_id}_${user_id}_${cid}"} = $now_in;
        }

        # Compare that to the cache, so as to find the views that the record *was*
        # in. Chunk the searches, otherwise we risk overrunning the allowed number
        # of search queries in the database
        my $i = 0; my @original;
        # Only search on views we know may have been affected, as per records search
        $search = {
            'view.id' => \@view_ids,
        };
        while ($i < @{$self->current_ids})
        {
            # If the number of current_ids that we have been given is the same as the
            # number that exist in the database, then assume that we are searching
            # all records. Therefore don't specify (the potentially thousands) current_ids.
            unless (@{$self->current_ids} == $records->count)
            {
                my $max = $i + 499;
                $max = @{$self->current_ids}-1 if $max >= @{$self->current_ids};
                $search->{'me.current_id'} = [@{$self->current_ids}[$i..$max]];
            }

            push @original, $self->schema->resultset('AlertCache')->search($search,{
                select => [
                    { max => 'me.current_id' },
                    { max => 'me.user_id' },
                    { max => 'me.view_id' },
                ],
                as => [qw/
                    me.current_id
                    me.user_id
                    me.view_id
                /],
                join     => 'view',
                group_by => ['me.view_id', 'me.user_id', 'me.current_id'], # Remove column information
                order_by => ['me.view_id', 'me.user_id', 'me.current_id'],
            })->all;
            last unless $search->{'me.current_id'}; # All current_ids
            $i += 500;
        }

        # Now go through each of the views/alerts that the records *were* in, and
        # work out whether the record has disappeared from any.
        my @gone;
        foreach my $alert (@original)
        {
            # See if it's still in the views. We use the previously created hash
            # that contains all the views that the records are now in.
            my $view_id = $alert->view_id;
            my $user_id = $alert->user_id || '';
            my $cid     = $alert->current_id;
            if (!$now_in_views
                ->{$view_id}
                ->{$user_id}
                ->{$cid}
            )
            {
                # The row we're processing doesn't exist in the hash, so it's disappeared
                my $view = $views->view($view_id);
                push @gone, {
                    view       => $view,
                    current_id => $cid,
                    user_id    => $user_id,
                };
                $self->schema->resultset('AlertCache')->search({
                    view_id    => $view_id,
                    user_id    => ($user_id || undef),
                    current_id => $cid,
                })->delete;
            }
            else {
                # The row we're processing does appear in the hash, so no change. Flag
                # this in our second cache. Anything left in the second hash is therefore
                # something that is new in the view.
                delete $now_in_views2->{"${view_id}_${user_id}_${cid}"};
            }
        }

        # Now see what views it is new in, using the second hash
        my @arrived;
        foreach my $item (values %$now_in_views2)
        {
            my $view = $item->{view};

            push @to_add, {
                user_id    => $item->{user_id},
                view_id    => $view->id,
                layout_id  => $_,
                current_id => $item->{id},
            } foreach @{$view->columns};

            # Add it to a hash suitable for emailing alerts with
            push @arrived, {
                view        => $view,
                user_id     => $item->{user_id},
                current_id  => $item->{id},
            };
        }

        # Send the gone and arrived notifications
        $self->_gone_arrived('gone', @gone);
        $self->_gone_arrived('arrived', @arrived);
    }

    # Now find out which values have changed in each view. We simply take the list
    # of changed columns and records, and search the cache.
    my $i = 0; my @caches;
    $search = {
        'alert_caches.layout_id' => $self->columns, # Columns that have changed
    };
    while ($i < @{$self->current_ids})
    {
        # See above comments about searching current_ids
        unless (@{$self->current_ids} == $records->count)
        {
            my $max = $i + 499;
            $max = @{$self->current_ids}-1 if $max >= @{$self->current_ids};
            $search->{'alert_caches.current_id'} = [@{$self->current_ids}[$i..$max]];
        }
        push @caches, $self->schema->resultset('View')->search($search,{
            prefetch => ['alert_caches', {'alerts' => 'user'} ],
        })->all;
        last unless $search->{'alert_caches.current_id'}; # All current_ids
        $i += 500;
    }

    # We now have a list of views that have changed
    foreach my $view (@caches)
    {
        # Now construct an alerts hash for each view. This will contain either
        # one value, in the case of a normal view, or several values, in the
        # case of a view with a CURUSER field.
        # We iterate through each of the alert's caches. If we find a null value,
        # we know that this is a standard view, so we go no further. Otherwise,
        # we have to go through all the caches and assign them to the relevant user.
        #
        my $alerts; # The hash
        my $has_curuser; # Flag true if this is a curuser view
        foreach my $alert_cache ($view->alert_caches)
        {
            if (my $key = $alert_cache->user_id)
            {
                $alerts->{$key} ||= [];
                push @{$alerts->{$key}}, $alert_cache;
                $has_curuser = 1;
            }
            else {
                last;
            }
        }
        foreach my $alert ($view->alerts)
        {
            # For each user of this alert, check they have read access
            # to the field in question, and send accordingly
            my $user = $alert->user;
            my @cids;
            my @alerts = $has_curuser ? @{$alerts->{$user->id}} : $view->alert_caches;
            foreach my $i (@alerts)
            {
                my $col_id = $i->layout_id;
                next unless $self->layout->column($col_id)->user_id_can($user->id, 'read');
                push @cids, $i->current_id;
            }
            if ($alert->frequency) # send later
            {
                foreach my $col_id (@{$self->columns})
                {
                    foreach my $cid (@cids)
                    {
                        my $write = {
                            alert_id   => $alert->id,
                            layout_id  => $col_id,
                            current_id => $cid,
                            status     => 'changed',
                        };
                        # Unique constraint. Catch any exceptions. This is also
                        # why we probably can't do all these with one call to populate()
                        try { $self->schema->resultset('AlertSend')->create($write) };
                        # Log any messages from try block, but only as trace
                        $@->reportAll(reason => 'TRACE');
                    }
                }
            }
            else {
                my @colnames = map { $self->layout->column($_)->name } @{$self->columns};
                $self->_send_alert('changed', \@cids, $view, [$user->email], \@colnames)
                    if @cids;
            }
        }
    }

    # Finally update the alert cache. We don't do this earlier, otherwise a new
    # record will be flagged as a change.
    $self->schema->resultset('AlertCache')->populate(\@to_add) if @to_add;
}

sub _gone_arrived
{   my ($self, $action, @items) = @_;

    foreach my $item (@items)
    {
        my @emails;
        foreach my $alert (@{$item->{view}->all_alerts})
        {
            if ($alert->frequency)
            {
                # send later
                try {
                    # Unique constraint on table. Catch
                    # any exceptions
                    $self->schema->resultset('AlertSend')->create({
                        alert_id   => $alert->id,
                        current_id => $item->{current_id},
                        status     => $action,
                    });
                };
                # Log any messages from try block, but only as trace
                $@->reportAll(reason => 'TRACE');
            }
            else {
                # send now
                push @emails, $alert->user->email;
            }
        }
        $self->_send_alert($action, [$item->{current_id}], $item->{view}, \@emails) if @emails;
    }
}

sub _current_id_links
{   my ($base, @current_ids) = @_;
    my @links = map { qq(<a href="${base}record/$_">$_</a>) } uniq @current_ids;
    wantarray ? @links : $links[0];
}

sub _send_alert
{   my ($self, $action, $current_ids, $view, $emails, $columns) = @_;

    my $view_name = $view->name;
    my @current_ids = @{$current_ids};
    my $base = $self->base_url;

    my $text; my $html;
    if ($action eq "changed")
    {
        # Individual fields to notify
        my $cnames = join ', ', uniq @{$columns};
        if (@current_ids > 1)
        {
            my $ids = join ', ', uniq @current_ids;
            $text   = "The following items were changed for record IDs $ids: $cnames\n\n";
            $text  .= "Links to the records are as follows:\n";
            my $ids_html = join ', ', _current_id_links($base, @current_ids);
            $html   = "<p>The following items were changed for record IDs $ids_html: $cnames</p>";
        }
        else {
            $text   = "The following items were changed for record ID @current_ids: $cnames\n\n";
            $text  .= "Please use the following link to access the record:\n";
            my $id_html = _current_id_links($base, @current_ids);
            $html   = "<p>The following items were changed for record ID $id_html: $cnames</p>";
        }
    }
    elsif($action eq "arrived") {
        if (@current_ids > 1)
        {
            $text   = qq(New items have appeared in the view "$view_name", with the following IDs: ).join(', ', @current_ids)."\n\n";
            $text  .= "Links to the new items are as follows:\n";
            my $ids_html = join ', ', _current_id_links($base, @current_ids);
            $html   = "<p>New items have appeared in the view &quot;$view_name&quot;, with the following IDs: $ids_html</p>";
        }
        else {
            $text   = qq(A new item (ID @current_ids) has appeared in the view "$view_name".\n\n);
            $text  .= "Please use the following link to access the record:\n";
            my $id_html = _current_id_links($base, @current_ids);
            $html   = qq(A new item (ID $id_html) has appeared in the view &quot;$view_name&quot;.</p>);
        }
    }
    elsif($action eq "gone") {
        if (@current_ids > 1)
        {
            $text   = qq(Items have disappeared from the view "$view_name", with the following IDs: ).join(', ', @current_ids)."\n\n";
            $text  .= "Links to the removed items are as follows:\n";
            my $ids_html = join ', ', _current_id_links($base, @current_ids);
            $html   = "<p>Items have disappeared from the view &quot;$view_name&quot;, with the following IDs: $ids_html</p>";
        }
        else {
            $text   = qq(An item (ID @current_ids) has disappeared from the view "$view_name".\n\n);
            $text  .= "Please use the following link to access the original record:\n";
            my $id_html = _current_id_links($base, @current_ids);
            $html   = qq(<p>An item (ID $id_html) has disappeared from the view &quot;$view_name&quot;</p>);
        }
    }
    foreach my $cid (@current_ids)
    {
        $text  .= $base."record/$cid\n";
    }
    my $email = GADS::Email->instance;
    $email->send({
        subject => qq(Changes in view "$view_name"),
        emails  => $emails,
        text    => $text,
        html    => $html,
    });
}

1;

