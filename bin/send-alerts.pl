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

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use GADS::Schema;
use GADS::Alert;
use GADS::Email;

sub _send
{   my ($email, @notifications) = @_;

    @notifications or return;

    my $text = "This email contains details of any changes in views that you have asked to be alerted to.\n\n";
    $text .= join "\n\n", @notifications; # <sigh> 2 CRs to fix Outlook piss-poor wrapping
    my $email_send = GADS::Email->new;
    $email_send->send({
        emails  => [$email],
        subject => "Changes in your views",
        text    => $text,
    });
}

sub _do_columns
{   my ($current_id, $columns) = @_;
    my $notification = "* The following columns have changed in record $current_id: ".join(', ',@$columns)
        if @$columns;
    @$columns = ();
    $notification;
}

my @rows = rset('AlertSend')->search({}, {
    join     => { alert => 'user' },
    order_by => qw/ user.id alert_id current_id /
})->all;

my ($last_current_id, $last_alert_id, $last_user);
my @notifications; my @columns;
foreach my $row (@rows)
{
    my $current_id = $row->current_id;

    if (defined $last_user && $last_user->id != $row->alert->user_id)
    {
        push @notifications, _do_columns $last_current_id, \@columns if @columns;
        _send $last_user->email, @notifications;
        @notifications = ();
    }

    if (!defined $last_alert_id || $last_alert_id != $row->alert_id)
    {
        push @notifications, _do_columns $last_current_id, \@columns if @columns;
        push @notifications, '' if @notifications; # blank line separater
        my $view_name = $row->alert->view->name;
        push @notifications, qq(The following are changes in the view "$view_name":);
    }

    if (my $lid = $row->layout_id)
    {
        if (defined $last_current_id && $last_current_id != $row->current_id && @columns)
        {
            my $current_id = $row->current_id;
            push @notifications, _do_columns $last_current_id, \@columns if @columns;
        }
        else {
            push @columns, $row->layout->name;
        }
    }
    elsif ($row->status eq 'gone')
    {
        push @notifications, _do_columns $last_current_id, \@columns if @columns;
        push @notifications, "* Record $current_id has now disappeared from the view";
    }
    elsif ($row->status eq 'arrived') {
        push @notifications, _do_columns $last_current_id, \@columns if @columns;
        push @notifications, "* Record $current_id is now in the view";
    }
    else {
        # XXX Throw error
    }

    $last_alert_id   = $row->alert_id;
    $last_user       = $row->alert->user;
    $last_current_id = $row->current_id;

    $row->delete;
}

push @notifications, _do_columns $last_current_id, \@columns if @columns;
_send $last_user->email, @notifications if $last_user;

