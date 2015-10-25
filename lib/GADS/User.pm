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

use DateTime;
use Email::Valid;
use GADS::Email;
use GADS::Instance;
use Log::Report;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'ro',
    required => 1,
);

has instance => (
    is => 'lazy',
);

has id => (
    is        => 'lazy',
    isa       => Maybe[Int],
    predicate => 1,
);

sub _build_id
{   my $self = shift;
    my @params = grep {my $h = "has_$_"; $self->$h} qw/username email account_request/;
    my %search = map { "me.".$_ => $_ } @params;
    $search{deleted} = undef;
    my @users = $self->schema->resultset('User')->search(\%search, {
        prefetch => ['user_permissions', 'user_groups'],
    })->all;
    @users == 1 or return;
    $users[0]->id;
}

has username => (
    is        => 'ro',
    usa       => Str,
    predicate => 1,
);

has email => (
    is        => 'ro',
    usa       => Str,
    predicate => 1,
);

has account_request => (
    is        => 'ro',
    usa       => Bool,
    predicate => 1,
);

sub _build_instance
{   my $self = shift;
    my $config = GADS::Config->instance;
    GADS::Instance->new(
        id     => $config->login_instance,
        schema => $self->schema,
    );
}

sub graphs
{   my ($self, $graphs) = @_;

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
            user_id  => $self->id,
            graph_id => $g,
        };

        unless($self->schema->resultset('UserGraph')->search($item)->count)
        {
            $self->schema->resultset('UserGraph')->create($item);
        }
    }

    # Delete any graphs that no longer exist
    my $search = { user_id => $self->id };
    $search->{graph_id} = {
        '!=' => [ -and => @graphs ]
    } if @graphs;
    $self->schema->resultset('UserGraph')->search($search)->delete;
}

sub groups
{   my ($self, $groups) = @_;

    foreach my $g (@$groups)
    {
        my $item = {
            user_id  => $self->id,
            group_id => $g,
        };

        unless($self->schema->resultset('UserGroup')->search($item)->count)
        {
            $self->schema->resultset('UserGroup')->create($item);
        }
    }

    # Delete any groups that no longer exist
    my $search = { user_id => $self->id };
    $search->{group_id} = {
        '!=' => [ -and => @$groups ]
    } if @$groups;
    $self->schema->resultset('UserGroup')->search($search)->delete;
}

sub delete
{   my ($self, %options) = @_;

    my ($user) = $self->schema->resultset('User')->search({
        id      => $self->id,
        deleted => undef,
    })->all;
    $user or error __x"User {id} not found", id => $self->id;

    if ($user->account_request)
    {
        $user->delete;

        return unless $options{send_reject_email};
        my $email = GADS::Email->instance;
        $email->send({
            subject => $self->instance->email_reject_subject,
            emails  => [$user->email],
            text    => $self->instance->email_reject_text,
        });

        return;
    }

    $self->schema->resultset('UserGraph')->search({ user_id => $self->id })->delete;
    my $alerts = $self->schema->resultset('Alert')->search({ user_id => $self->id });
    my @alert_sends = map { $_->id } $alerts->all;
    $self->schema->resultset('AlertSend')->search({ alert_id => \@alert_sends })->delete;
    $alerts->delete;

    $user->update({ lastview => undef });
    my $views = $self->schema->resultset('View')->search({ user_id => $self->id });
    my @views;
    foreach my $v ($views->all)
    {
        push @views, $v->id;
    }
    $self->schema->resultset('Filter')->search({ view_id => \@views })->delete;
    $self->schema->resultset('ViewLayout')->search({ view_id => \@views })->delete;
    $self->schema->resultset('Sort')->search({ view_id => \@views })->delete;
    $self->schema->resultset('AlertCache')->search({ view_id => \@views })->delete;
    $views->delete;

    $user->update({ deleted => DateTime->now });

    if (my $msg = $self->instance->email_delete_text)
    {
        my $email = GADS::Email->instance;
        $email->send({
            subject => $self->instance->email_delete_subject || "Account deleted",
            emails  => [$user->email],
            text    => $msg,
        });
    }
}

# XXX Possible temporary function, until available in DPAE
sub get_user
{   my $self = shift;
    $self->id or return;
    my $user = $self->schema->resultset('User')->find($self->id)
        or return;
    my $return = {
        id                    => $user->id,
        firstname             => $user->firstname,
        surname               => $user->surname,
        email                 => $user->email,
        username              => $user->username,
        title                 => $user->title ? $user->title->id : undef,
        organisation          => $user->organisation ? $user->organisation->id : undef,
        telephone             => $user->telephone,
        account_request       => $user->account_request,
        account_request_notes => $user->account_request_notes,
    };
    if ($user->user_permissions)
    {
        my %perms = map { $_->permission->name => 1 } $user->user_permissions;
        $return->{permission} = \%perms;
    }
    if ($user->user_groups)
    {
        my %groups = map { $_->group->id => 1 } $user->user_groups;
        $return->{groups} = \%groups;
    }
    $return;
}

1;

