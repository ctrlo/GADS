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
use Ouch;
use String::Random;
use Crypt::SaltedHash;
use Email::Valid;
schema->storage->debug(1);

use GADS::Schema;
use GADS::Util         qw(:all);

sub user($)
{   my ($class, $args) = @_;
    my $user;
    if ($args->{id})
    {
        ($user) = rset('User')->search({
            'me.id'  => $args->{id},
        },{
            prefetch => ['title', 'organisation'],
        }) or return;
        return if $user->deleted;
    }
    elsif ($args->{username})
    {
        ($user) = rset('User')->search(
            {
                username        => $args->{username},
                deleted         => 0,
                account_request => 0,
            }
        );
        return unless $user;
        Crypt::SaltedHash->validate($user->password, $args->{password})
            or return;
    }
    else
    {
        return;
    }
    my $retuser;
    $retuser->{id}              = $user->id;
    $retuser->{firstname}       = $user->firstname;
    $retuser->{surname}         = $user->surname;
    $retuser->{email}           = $user->email;
    $retuser->{title}           = $user->title;
    $retuser->{account_request} = $user->account_request;
    $retuser->{value}           = GADS::Record->person_update_value($user);
    $retuser->{organisation}    = $user->organisation;
    $retuser->{username}        = $user->username;
    $retuser->{views}           = GADS::View->all($user->id);
    $retuser->{lastrecord}      = $user->lastrecord ? $user->lastrecord->id : undef;
    $retuser->{permission}      = $user->permission;
    $retuser->{permissions}     = {
        update                 => $user->permission & UPDATE,
        update_noneed_approval => $user->permission & UPDATE_NONEED_APPROVAL,
        create                 => $user->permission & CREATE,
        create_noneed_approval => $user->permission & CREATE_NONEED_APPROVAL,
        approver               => $user->permission & APPROVER,
        admin                  => $user->permission & ADMIN,
    };
    $retuser;
}

sub update
{
    my ($self, $u, $args) = @_;
    my $user;
    $user->{firstname}    = $u->{firstname} or ouch 'badname', "Please enter a firstname";
    $user->{surname}      = $u->{surname}   or ouch 'badname', "Please enter a surname";
    $user->{email}        = Email::Valid->address($u->{email}) or ouch 'bademail', "Please enter a valid email address";
    # Check if email already exists, but not if account registration for security reasons
    if ($args->{register})
    {
        $user->{account_request}       = 1;
        $user->{account_request_notes} = $u->{account_request_notes};
    }
    else {
        !$u->{id} && rset('User')->search({ email => $user->{email}, deleted => 0, account_request => 0 })->count
            and ouch 'bademail', "Email address $user->{email} already exists";
        $user->{username}   = $user->{email};
        $user->{organisation} = $u->{organisation} || undef;
        $user->{title}        = $u->{title} || undef;
        $user->{permission} = 0;
        $user->{permission} = $user->{permission} | UPDATE                 if $u->{update};
        $user->{permission} = $user->{permission} | UPDATE_NONEED_APPROVAL if $u->{update_noneed_approval};
        $user->{permission} = $user->{permission} | CREATE                 if $u->{create};
        $user->{permission} = $user->{permission} | CREATE_NONEED_APPROVAL if $u->{create_noneed_approval};
        $user->{permission} = $user->{permission} | APPROVER               if $u->{approver};
        $user->{permission} = $user->{permission} | ADMIN                  if $u->{admin};
    }
    if ($u->{id})
    {
        my $old = rset('User')->find($u->{id})
            or ouch 'notfound', "User $u->{id} not found to update";
        $old->update($user);
    }
    else {
        my $u = rset('User')->create($user)
            or ouch 'dbfail', "Database error when creating new user";
        if ($args->{register})
        {
            # Email admins with account request
            my $admins = $self->all({ admins => 1 });
            my @emails = map { $_->email } @$admins;
            my $text = "A new account request has been received from the following person:\n\n";
            $text .= "First name: $user->{firstname}, ";
            $text .= "surname: $user->{surname}, ";
            $text .= "email: $user->{email}\n";
            my $msg = {
                emails  => \@emails,
                subject => "New account request",
                text    => $text,
            };
            GADS::Email->send($msg);
        }
        else {
            my $url = $args->{url}
                or ouch 'nourl', "Please provide a URL when creating a user";
            # By default, add all graphs to the user
            my $graphs = GADS::Graph->all;
            foreach my $graph (@$graphs)
            {
                rset('UserGraph')->create({ user_id => $u->id, graph_id => $graph->id })
                    or ouch 'dbfail', "Database error when creating new user";
            }
            my $reset      = $self->resetpwreq($u->id);
            my $gadsname   = config->{gads}->{name};
            my ($instance) = rset('Instance')->all;
            my $msg        = $instance->email_welcome_text;
            my $pwdurl     = $url."resetpw/$reset";
            $msg =~ s/\$PWDURL/$pwdurl/g;
            my $email = {
                subject => $instance->email_welcome_subject,
                emails  => [$u->email],
                text    => $msg,
            };
            GADS::Email->send($email);
        }
    }
}

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
    my $user = rset('User')->find($user_id)
        or ouch 'notfound', "User $user_id not found";

    if ($user->account_request)
    {
        $user->delete or ouch 'dbfail', "There was a database error deleting the request";
        return;
    }

    rset('UserGraph')->search({ user_id => $user->id })->delete
        or ouch 'dbfail', "There was a database error when removing old user graphs";

    # We want to remove all views for the user, but some may have been
    # used for graphs. For these ones, set the view to global
    rset('View')->search({
        user_id     => $user->id,
        'graphs.id' => {-not => undef},
    },{
        join => 'graphs',
    })->update({
        global => 1,
        user_id => undef,
    });

    my $views = rset('View')->search({ user_id => $user->id });
    my @views;
    foreach my $v ($views->all)
    {
        push @views, $v->id;
    }
    rset('ViewLayout')->search({ view_id => \@views })->delete
        or ouch 'dbfail', "There was a database error removing old user view layouts";
    $views->delete
        or ouch 'dbfail', "There was a database error removing old user views";

    $user->update({ deleted => 1 })
        or ouch 'dbfail', "Database error when deleting user";

    my ($instance) = rset('Instance')->all;
    my $msg        = $instance->email_delete_text;
    my $email = {
        subject => $instance->email_delete_subject,
        emails  => [$user->email],
        text    => $instance->email_delete_text,
    };
    GADS::Email->send($email);
}

sub all
{
    my ($self, $args) = @_;
    my $search = {
        deleted         => 0,
        account_request => 0,
    };
    $search->{permission} = { '&' => ADMIN } if $args->{admins};
    my @users = rset('User')->search($search)->all;
    \@users;
}

sub register_requests
{
    my @users = rset('User')->search({ account_request => 1 })->all;
    \@users;
}

sub permissions
{
    {
        update                 => UPDATE,
        update_noneed_approval => UPDATE_NONEED_APPROVAL,
        create                 => CREATE,
        create_noneed_approval => CREATE_NONEED_APPROVAL,
        approver               => APPROVER,
        admin                  => ADMIN,
    }
}

sub randompw
{   my $foo = new String::Random;
    $foo->{'v'} = [ 'a', 'e', 'i', 'o', 'u' ];
    $foo->{'i'} = [ 'b'..'d', 'f'..'h', 'j'..'n', 'p'..'t', 'v'..'z' ];
    scalar $foo->randpattern("iviiviivi");
}

sub resetpw
{   my ($self, $user_id) = @_;

    my $pw = randompw;
    my $crypt = Crypt::SaltedHash->new(algorithm=>'SHA-512');
    $crypt->add($pw);
    my $coded = $crypt->generate;

    my $user = _user({ id => $user_id })
        or ouch 'notfound', "User ID $user_id not found in database when generating password reset";

    $user->update({
        password  => $coded,
        pwchanged => \'UTC_TIMESTAMP()',
    }) or ouch 'dbfail', "There was a database error updating the user password";

    $pw;
}

sub resetpwreq
{
    my ($self, $user_id) = @_;

    my $gen = String::Random->new;
    $gen->{'A'} = [ 'A'..'Z', 'a'..'z' ];
    my $reset = scalar $gen->randregex('\w{32}');
    my $user = _user({ id => $user_id })
        or ouch 'notfound', "User ID $user_id not found in database when generating password reset request";
    $user->update({ resetpw => $reset })
        or ouch 'dbfail', "Database error when updating user with password reset code";
    $reset;
}

sub _user
{
    my $search = shift;
    $search->{deleted}         = 0;
    $search->{account_request} = 0;
    my ($user) = rset('User')->search($search);
    $user;
}

sub resetpwreq_email
{
    my ($class, $email, $url) = @_;

    my $user = _user({ email => $email });
    $user or return 1; # We return success so that people cannot test for valid logins
    my $reset    = $class->resetpwreq($user->id);
    my $gadsname = config->{gads}->{name};
    my $msg = "Please use the link below to set your password for $gadsname:\n\n";
    $msg .= $url."resetpw/$reset\n";
    my $send = {
        subject => "Reset password request",
        emails  => [$user->email],
        text    => $msg,
    };
    GADS::Email->send($send);
    1;
}

sub resetpwdo
{
    my ($self, $code) = @_;

    my ($user) = rset('User')->search({ resetpw => $code })
        or ouch 'notfound', "Requested reset code not found";
    my $reset = $self->resetpw($user->id)
        or ouch 'resetfail', "Failed to produce a reset password";
    $user->update({ resetpw => undef })
        or ouch 'resetfail', "Failed to remove old password reset code";
    $reset;
}

sub register
{
    my ($class, $params) = @_;
    $class->update($params, {register => 1});
}

sub register_text
{
    my ($instance) = rset('Instance')->all;
    $instance->register_text;
}

1;

