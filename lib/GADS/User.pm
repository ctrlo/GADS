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

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use Dancer2::Plugin::Auth::Complete;
use Ouch;
use String::Random;
use Crypt::SaltedHash;
use Email::Valid;
schema->storage->debug(1);

use GADS::Schema;
use GADS::Util         qw(:all);

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
    rset('Title')->create({ name => $params->{name} })
        or ouch 'dbfail', "There was a database error when creating the title";
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
    rset('Organisation')->create({ name => $params->{name} })
        or ouch 'dbfail', "There was a database error when creating the organisation";
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
    rset('UserGraph')->search($search)->delete
        or ouch 'dbfail', "There was a database error deleting old graphs";
}

sub delete
{
    my ($self, $user_id) = @_;

    my $user = user 'get' => id => $user_id, account_request => [0, 1]
        or ouch 'notfound', "User $user_id not found";

    if ($user->{account_request})
    {
        user 'delete' => id => $user_id;
        return;
    }

    rset('UserGraph')->search({ user_id => $user_id })->delete
        or ouch 'dbfail', "There was a database error when removing old user graphs";

    my $views = rset('View')->search({ user_id => $user_id });
    my @views;
    foreach my $v ($views->all)
    {
        push @views, $v->id;
    }
    rset('ViewLayout')->search({ view_id => \@views })->delete
        or ouch 'dbfail', "There was a database error removing old user view layouts";
    $views->delete
        or ouch 'dbfail', "There was a database error removing old user views";

    user 'update' => (
        id      => $user_id,
        deleted => 1,
    );

    my ($instance) = rset('Instance')->all;
    my $msg        = $instance->email_delete_text;
    my $email = {
        subject => $instance->email_delete_subject,
        emails  => [$user->{email}],
        text    => $instance->email_delete_text,
    };
    GADS::Email->send($email);
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
    my @users = rset('User')->search({ -and => \@search })->all;
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

    my @fields = qw(firstname surname email account_request_notes);
    @new{@fields} = @params{@fields};
    $new{username} = $params->{email};
    $new{account_request} = 1;
    my $newuser = user update => %new;

    # Email admins with account request
    my $admins = $self->all({ admins => 1 });
    my @emails = map { $_->email } @$admins;
    my $text = "A new account request has been received from the following person:\n\n";
    $text .= "First name: $newuser->{firstname}, ";
    $text .= "surname: $newuser->{surname}, ";
    $text .= "email: $newuser->{email}\n";
    my $msg = {
        emails  => \@emails,
        subject => "New account request",
        text    => $text,
    };
    GADS::Email->send($msg);
}

sub register_text
{
    my ($instance) = rset('Instance')->all;
    $instance->register_text;
}

1;

