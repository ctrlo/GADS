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
        $user = rset('User')->find($args->{id});
    }
    elsif ($args->{username})
    {
        ($user) = rset('User')->search(
            {
                username => $args->{username},
                deleted  => 0,
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
    $retuser->{id}          = $user->id;
    $retuser->{firstname}   = $user->firstname;
    $retuser->{surname}     = $user->surname;
    $retuser->{email}       = $user->email;
    $retuser->{username}    = $user->username;
    $retuser->{views}       = GADS::View->all($user->id);
    $retuser->{permission}  = $user->permission;
    $retuser->{permissions} = {
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
    my ($class, $u, $args) = @_;
    my $user;
    $user->{firstname}  = $u->{firstname} or ouch 'badname', "Please enter a firstname";
    $user->{surname}    = $u->{surname}   or ouch 'badname', "Please enter a surname";
    $user->{email}      = Email::Valid->address($u->{email}) or ouch 'bademail', "Please enter a valid email address";
    # Check if email already exists
    !$u->{id} && rset('User')->search({ email => $user->{email}, deleted => 0 })->count
        and ouch 'bademail', "Email address $user->{email} already exists";
    $user->{username}   = $user->{email};
    $user->{permission} = 0;
    $user->{permission} = $user->{permission} | UPDATE                 if $u->{update};
    $user->{permission} = $user->{permission} | UPDATE_NONEED_APPROVAL if $u->{update_noneed_approval};
    $user->{permission} = $user->{permission} | CREATE                 if $u->{create};
    $user->{permission} = $user->{permission} | CREATE_NONEED_APPROVAL if $u->{create_noneed_approval};
    $user->{permission} = $user->{permission} | APPROVER               if $u->{approver};
    $user->{permission} = $user->{permission} | ADMIN                  if $u->{admin};
    if ($u->{id})
    {
        my $old = rset('User')->find($u->{id})
            or ouch 'notfound', "User $u->{id} not found to update";
        $old->update($user);
    }
    else {
        my $url = $args->{url}
            or ouch 'nourl', "Please provide a URL when creating a user";
        my $user     = rset('User')->create($user)
            or ouch 'dbfail', "Database error when creating new user";
        my $reset    = $class->resetpwreq($user->id);
        my $gadsname = config->{gads}->{name};
        my $msg      = "A new account for $gadsname has been created for you. ";
        $msg .= "Please use the following link to set your password:\n\n";
        $msg .= $url."resetpw/$reset\n\n";
        $msg .= "To access $gadsname in the future you will need to use the following link: $url - ";
        $msg .= "please save it for future reference.\n";
        my $email = {
            subject => "New account details",
            emails  => [$user->email],
            text    => $msg,
        };
        GADS::Email->send($email);
    }
}

sub delete
{
    my ($self, $user_id) = @_;
    my $user = rset('User')->find($user_id)
        or ouch 'notfound', "User $user_id not found";
    $user->update({ deleted => 1 })
        or ouch 'dbfail', "Database error when deleting user";
}

sub all
{
    my @users = rset('User')->search({ deleted => 0 })->all;
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

    my $user = rset('User')->find($user_id)
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
    my $user = rset('User')->find($user_id)
        or ouch 'notfound', "User ID $user_id not found in database when generating password reset request";
    $user->update({ resetpw => $reset })
        or ouch 'dbfail', "Database error when updating user with password reset code";
    $reset;
}

sub resetpwreq_email
{
    my ($class, $email, $url) = @_;

    my ($user) = rset('User')->search({ email => $email })->all;
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

1;

