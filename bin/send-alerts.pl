#!/usr/bin/perl

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

use FindBin;
use lib "$FindBin::Bin/../lib";

use GADS::DB;
use GADS::Schema;
use GADS::Alert;
use GADS::Email;
use GADS::AlertDescription;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport 'linkspace', mode => 'NORMAL';

GADS::DB->setup(schema);

GADS::Config->instance(config => config,);

my $alert_description = GADS::AlertDescription->new(schema => schema,);

sub _send
{   my ($email, @notifications) = @_;

    @notifications or return;

    my $text =
"This email contains details of any changes in views that you have asked to be alerted to.\n\n";
    my $html =
"<p>This email contains details of any changes in views that you have asked to be alerted to.</p>";
    $text .= join "\n", map { $_->{text} } @notifications;
    $html .= join "\n", map { $_->{html} } @notifications;
    my $email_send = GADS::Email->new;

    $email_send->send({
        emails  => [$email],
        subject => "Changes in your views",
        text    => $text,
        html    => $html,
    });
}

sub record_description
{   my (%params) = @_;
}

sub _do_columns
{   my ($current, $user, @columns) = @_;
    @columns or return;
    my $cols        = join ', ', @columns;
    my $description = $alert_description->description(
        instance_id => $current->instance_id,
        current_ids => $current->id,
        user        => $user,
    );
    my $link = $alert_description->link(
        instance_id => $current->instance_id,
        current_ids => $current->id,
        user        => $user,
    );
    my $notification =
        "* The following columns have changed in $description: $cols";
    my $notification_html =
        qq(<li>The following columns have changed in $link: $cols</li>);
    {
        text => $notification,
        html => $notification_html,
    };
}

my @rows = rset('AlertSend')->search(
    {},
    {
        join     => { alert => 'user' },
        order_by => [qw/ user.id alert_id current_id /],
    },
)->all;

my ($last_current, $last_alert_id, $last_user);
my @notifications;
my @columns;
foreach my $row (@rows)
{
    my $current_id = $row->current_id;

    if (defined $last_user && $last_user->id != $row->alert->user_id)
    {
        push @notifications, _do_columns($last_current, $last_user, @columns);
        @columns = ();
        _send $last_user->email, @notifications;
        @notifications = ();
    }

    if (!defined $last_alert_id || $last_alert_id != $row->alert_id)
    {
        push @notifications, _do_columns($last_current, $last_user, @columns);
        @columns = ();
        push @notifications, { text => '', html => '</ul><p></p>' }
            if @notifications;    # blank line separater
        my $view_name = $row->alert->view->name;
        push @notifications,
            {
                text => qq(The following are changes in the view "$view_name":),
                html =>
qq(<p>The following are changes in the view "$view_name":</p><ul>),
            };
    }

    if (   defined $last_current
        && $last_current->id != $row->current_id
        && @columns)
    {
        my $current_id = $row->current_id;
        push @notifications, _do_columns($last_current, $last_user, @columns);
        @columns = ();
    }

    my $current     = $row->current;
    my $description = $alert_description->description(
        instance_id => $current->instance_id,
        current_ids => $current->id,
        user        => $row->alert->user,
    );
    my $link = $alert_description->link(
        instance_id => $current->instance_id,
        current_ids => $current->id,
        user        => $row->alert->user,
    );
    if ($row->status eq 'changed')
    {
        push @columns, $row->layout->name;
    }
    elsif ($row->status =~
        /^gone/)    # XXX Fixed with CHAR field pads 4 letter word
    {
        push @notifications,
            {
                text => "* $description has now disappeared from the view",
                html => "<li>$link has disappeared from the view</li>",
            };
    }
    elsif ($row->status eq 'arrived')
    {
        push @notifications,
            {
                text => "* $description is now in the view",
                html => "<li>$link is now in the view</li>",
            };
    }
    else
    {
        panic __x "I don't know what to do with alert status of '{status}'",
            status => $row->status;
    }

    $last_alert_id = $row->alert_id;
    $last_user     = $row->alert->user;
    $last_current  = $row->current;

    $row->delete;
}

push @notifications, _do_columns($last_current, $last_user, @columns);
push @notifications, { text => '', html => '</ul><p></p>' }
    if @notifications;    # blank line separater
_send $last_user->email, @notifications if $last_user;

