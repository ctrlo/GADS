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

use GADS::AlertDescription;
use GADS::Config;
use GADS::Email;
use GADS::Records;
use GADS::Views;
use List::Util qw/ uniq /;
use Log::Report 'linkspace';
use Scalar::Util qw(looks_like_number);

use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef Bool);
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
    is => 'lazy',
);

sub _build_base_url
{   my $self = shift;
    my $config = GADS::Config->instance;
    $config->gads->{url}
        or panic "URL not configured in application config";
}

has columns => (
    is       => 'rw',
    required => 1,
);

sub process
{   my $self = shift;

    # First the direct layout
    $self->_process_instance($self->layout, $self->current_ids);

    local $GADS::Schema::IGNORE_PERMISSIONS = 1;

    # Now see if the column changes in this layout may have changed views in
    # other layouts.
    # First, are there any views not in the main layout that contain these fields?
    my @instance_ids = $self->schema->resultset('View')->search({
        'alerts.id'         => { '!=' => undef },
        instance_id         => { '!=' => $self->layout->instance_id},
        'filters.layout_id' => $self->columns,
    },{
        join     => ['alerts', 'filters'],
        group_by => 'me.instance_id',
    })->get_column('instance_id')->all;

    # If there are, process each one
    foreach my $instance_id (@instance_ids)
    {
        my $layout = GADS::Layout->new(
            user        => undef,
            schema      => $self->schema,
            instance_id => $instance_id,
        );
        # Get any current IDs that may have been affected, including historical
        # versions (in case a filter has been set using previous values)
        my @current_ids = $self->schema->resultset('Curval')->search({
            'layout.instance_id' => $instance_id,
            value                => $self->current_ids,
        }, {
            join     => ['layout', 'record'],
            group_by => 'record.current_id',
        })->get_column('record.current_id')->all;

        $self->_process_instance($layout, \@current_ids);
    }
}

sub _process_instance
{   my ($self, $layout, $current_ids) = @_;

    # First see what views this record should be in. We use this to see if it's
    # dropped out or been added to any views.

    # Firstly, search on the views that may have been affected. This is all the
    # ones that have a filter with the changed columns. If this is a brand new
    # record, however, then it doesn't matter what columns have changed, so get
    # all the views.
    my $search = {
        'alerts.id' => { '!=' => undef },
        instance_id => $layout->instance_id,
    };
    $search->{'filters.layout_id'} = $self->columns
        unless $self->current_new;
    my @view_ids = $self->schema->resultset('View')->search($search,{
        join     => ['alerts', 'filters'],
        group_by => 'me.id', # Remove same view ID across multiple alerts
    })->get_column('id')->all;

    # We now have all the views that may have been affected by this update.
    # Convert them into GADS::View objects
    my $views = GADS::Views->new(
        # Current user may not have access to all fields in view,
        # permissions are managed when sending the alerts
        user_permission_override => 1,
        schema                   => $self->schema,
        layout                   => $layout,
        instance_id              => $layout->instance_id,
    );

    my $records_count = GADS::Records->new(
        columns => [], # Otherwise all columns retrieved during search construct
        schema  => $self->schema,
        layout  => $layout,
        user    => undef, # Alerts should not be affected by current user
    );

    my $total_records = $records_count->count;

    my @to_add; # Items to add to the cache later
    if (my @views = map { $views->view($_) } @view_ids)
    {
        # See which of those views the new/changed records are in.
        #
        # All the views the record is *now* in
        my $now_in_views; my $now_in_views2;
        my @foundin;
        foreach my $view (@views)
        {
            my $records = GADS::Records->new(
                columns => [], # Otherwise all columns retrieved during search construct
                schema  => $self->schema,
                layout  => $layout,
                user    => undef, # Alerts should not be affected by current user
            );
            push @foundin, $records->search_view($current_ids, $view);
        }
        foreach my $now_in (@foundin)
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
        while ($i < @$current_ids)
        {
            # If the number of current_ids that we have been given is the same as the
            # number that exist in the database, then assume that we are searching
            # all records. Therefore don't specify (the potentially thousands) current_ids.
            unless (@$current_ids == $total_records)
            {
                my $max = $i + 499;
                $max = @$current_ids-1 if $max >= @$current_ids;
                $search->{'me.current_id'} = [@$current_ids[$i..$max]];
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
        'me.instance_id'         => $layout->instance_id,
    };
    while ($i < @$current_ids)
    {
        # See above comments about searching current_ids
        unless (@$current_ids == $total_records)
        {
            my $max = $i + 499;
            $max = @$current_ids-1 if $max >= @$current_ids;
            $search->{'alert_caches.current_id'} = [@$current_ids[$i..$max]];
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
        # We iterate through each of the alert's caches, sending alerts where required
        my $send_now; # Used for immediate send to amalgamate columns and IDs
        foreach my $alert_cache ($view->alert_caches)
        {
            my $col_id = $alert_cache->layout_id;
            my @alerts = $alert_cache->user ? $self->schema->resultset('Alert')->search({
                view_id => $alert_cache->view_id,
                user_id => $alert_cache->user_id,
            })->all : $alert_cache->view->alerts;
            foreach my $alert (@alerts)
            {
                # For each user of this alert, check they have read access
                # to the field in question, and send accordingly
                next unless $layout->column($col_id)->user_id_can($alert->user_id, 'read');
                if ($alert->frequency) # send later
                {
                    my $write = {
                        alert_id   => $alert->id,
                        layout_id  => $col_id,
                        current_id => $alert_cache->current_id,
                        status     => 'changed',
                    };
                    # Unique constraint. Catch any exceptions. This is also
                    # why we probably can't do all these with one call to populate()
                    try { $self->schema->resultset('AlertSend')->create($write) };
                    # Log any messages from try block, but only as trace
                    $@->reportAll(reason => 'TRACE');
                }
                else {
                    $send_now->{$alert->user_id} ||= {
                        user    => $alert->user,
                        cids    => [],
                        col_ids => [],
                    };
                    push @{$send_now->{$alert->user_id}->{col_ids}}, $col_id;
                    push @{$send_now->{$alert->user_id}->{cids}}, $alert_cache->current_id;
                }
            }
        }
        foreach my $a (values %$send_now)
        {
            my @colnames = map { $layout->column($_)->name } @{$a->{col_ids}};
            my @cids = @{$a->{cids}};
            $self->_send_alert('changed', \@cids, $view, [$a->{user}], \@colnames);
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
        my @users;
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
                push @users, $alert->user;
            }
        }
        $self->_send_alert($action, [$item->{current_id}], $item->{view}, \@users) if @users;
    }
}

sub _current_id_links
{   my ($base, @current_ids) = @_;
    my @links = map { qq(<a href="${base}record/$_">$_</a>) } @current_ids;
    wantarray ? @links : $links[0];
}

has alert_description => (
    is => 'lazy',
);

sub _build_alert_description
{   my $self = shift;
    GADS::AlertDescription->new(
        schema => $self->schema,
    );
}

sub _send_alert
{   my ($self, $action, $current_ids, $view, $users, $columns) = @_;

    foreach my $user (@$users)
    {
        my $view_name = $view->name;
        my @current_ids = uniq @{$current_ids};
        my $base = $self->base_url;

        my $alert_description = $self->alert_description;

        my $text; my $html;
        my $description = $alert_description->description(
            instance_id => $self->layout->instance_id,
            current_ids => \@current_ids,
            user        => $user,
        );
        my $link = $alert_description->link(
            instance_id => $self->layout->instance_id,
            current_ids => \@current_ids,
            user        => $user,
        );
        if ($action eq "changed")
        {
            # Individual fields to notify
            my $cnames = join ', ', uniq @{$columns};
            $text   = "The following items were changed for $description: $cnames\n\n";
            $text  .= "Links to the records are as follows:\n";
            $html   = "<p>The following items were changed for $link: $cnames</p>";
        }
        elsif($action eq "arrived") {
            $text   = qq(New items as follows have appeared in the view "$view_name": $description\n\n);
            $text  .= "Links to the new items are as follows:\n";
            $html   = "<p>New items as follows have appeared in the view &quot;$view_name&quot;: $link</p>";
        }
        elsif($action eq "gone") {
            $text   = qq(Items as follows have disappeared from the view "$view_name": $description\n\n);
            $text  .= "Links to the removed items are as follows:\n";
            $html   = "<p>Items as follows have disappeared from the view &quot;$view_name&quot;: $link</p>";
        }
        foreach my $cid (@current_ids)
        {
            $text  .= $base."record/$cid\n";
        }
        my $email = GADS::Email->instance;
        $email->send({
            subject => qq(Changes in view "$view_name"),
            emails  => [$user->email],
            text    => $text,
            html    => $html,
        });
    }
}

1;

