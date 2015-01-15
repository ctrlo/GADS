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

package GADS::User;

use Crypt::SaltedHash;
use Email::Valid;
use GADS::Schema;
use GADS::Util         qw(:all);
use Log::Report;
use String::Random;

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use Dancer2::Plugin::Auth::Complete;

sub titles
{
    my @titles = rset('Title')->search(
        {},
        {
            order_by => 'name',
        }
    )->all;
    \@titles;
}

sub title_new
{
    my ($class, $params) = @_;
    rset('Title')->create({ name => $params->{name} });
}

sub organisations
{
    my @organisations = rset('Organisation')->search(
        {},
        {
            order_by => 'name',
        }
    )->all;
    \@organisations;
}

sub organisation_new
{
    my ($class, $params) = @_;
    rset('Organisation')->create({ name => $params->{name} });
}

sub graphs
{
    my ($class, $user, $graphs) = @_;

    # Will be a scalar if only one value submitted. If so,
    # convert to array
    my @graphs = !$graphs
               ? ()
               : ref $graphs eq 'ARRAY'
               ? @$graphs
               : ( $graphs );

    foreach my $g (@graphs)
    {
        my $item = {
            user_id  => $user->{id},
            graph_id => $g,
        };

        unless(rset('UserGraph')->search($item)->count)
        {
            rset('UserGraph')->create($item);
        }
    }

    # Delete any graphs that no longer exist
    my $search = { user_id => $user->{id} };
    $search->{graph_id} = {
        '!=' => [ -and => @graphs ]
    } if @graphs;
    rset('UserGraph')->search($search)->delete;
}

sub delete
{
    my ($self, $user_id) = @_;

    my $user = user 'get' => id => $user_id, account_request => [0, 1]
        or error __x"User {id} not found", id => $user_id;

    if ($user->{account_request})
    {
        user 'delete' => id => $user_id;

        my ($instance) = rset('Instance')->all;
        my $email = GADS::Email->new;
        $email->send({
            subject => $instance->email_reject_subject,
            emails  => [$user->{email}],
            text    => $instance->email_reject_text,
        });

        return;
    }

    rset('UserGraph')->search({ user_id => $user_id })->delete;
    rset('Alert')->search({ user_id => $user_id })->delete;

    my $views = rset('View')->search({ user_id => $user_id });
    my @views;
    foreach my $v ($views->all)
    {
        push @views, $v->id;
    }
    rset('Filter')->search({ view_id => \@views })->delete;
    rset('ViewLayout')->search({ view_id => \@views })->delete;
    rset('Sort')->search({ view_id => \@views })->delete;
    rset('AlertCache')->search({ view_id => \@views })->delete;
    $views->delete;

    user 'update' => (
        id      => $user_id,
        deleted => 1,
    );

    my ($instance) = rset('Instance')->all;
    my $msg        = $instance->email_delete_text;
    my $email = GADS::Email->new;
    $email->send({
        subject => $instance->email_delete_subject,
        emails  => [$user->{email}],
        text    => $instance->email_delete_text,
    });
}

sub all
{
    my ($self, $args) = @_;
    my @search = (
        deleted         => 0,
        account_request => 0,
    );
    my $adminval = config->{plugins}->{'Auth::Complete'}->{permissions}->{useradmin}->{value};
    push @search, \[ "permission & ? > 0", $adminval ] if $args->{admins};
    my @users = rset('User')->search({ -and => \@search }, { order_by => 'surname' })->all;
    \@users;
}

sub register_requests
{
    my @users = rset('User')->search({ account_request => 1 })->all;
    \@users;
}

sub register
{
    my ($self, $params) = @_;

    my %new;
    my %params = %$params;

    # Prevent "email exists" errors for security
    return if user get => ( email => $params->{email} );

    my @fields = qw(firstname surname email telephone title organisation account_request_notes);
    @new{@fields} = @params{@fields};
    $new{username} = $params->{email};
    $new{account_request} = 1;
    $new{telephone} or delete $new{telephone};
    $new{title} or delete $new{title};
    $new{organisation} or delete $new{organisation};
    my $newuser = user update => %new;

    # Email admins with account request
    my $admins = $self->all({ admins => 1 });
    my @emails = map { $_->email } @$admins;
    my $text = "A new account request has been received from the following person:\n\n";
    $text .= "First name: $newuser->{firstname}, ";
    $text .= "surname: $newuser->{surname}, ";
    $text .= "email: $newuser->{email}, ";
    $text .= "title: ".$newuser->{title}->name.", " if $newuser->{title};
    $text .= "telephone: $newuser->{telephone}, " if $newuser->{telephone};
    $text .= "organisation: ".$newuser->{organisation}->name.", " if $newuser->{organisation};
    $text .= "\n\n";
    $text .= "User notes: $newuser->{account_request_notes}\n";
    my $email = GADS::Email->new;
    $email->send({
        emails  => \@emails,
        subject => "New account request",
        text    => $text,
    });
}

sub register_text
{
    my ($instance) = rset('Instance')->all;
    $instance->register_text;
}

1;

