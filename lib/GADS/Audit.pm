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

package GADS::Audit;

use DateTime;
use GADS::Datum::Person;
use Moo;

has schema => (
    is       => 'rw',
    required => 1,
);

has user => (
    is => 'rw',
);

sub audit_types{ [qw/user_action login_change login_success logout login_failure/] };

sub user_action
{   my ($self, %options) = @_;

    $self->schema->resultset('Audit')->create({
        user_id     => $self->user->{id},
        description => $options{description},
        type        => 'user_action',
        method      => $options{method},
        url         => $options{url},
        datetime    => DateTime->now,
    });
}

sub login_change
{   my ($self, $description) = @_;

    my $user_id = $self->user ? $self->user->{id} : undef;
    $self->schema->resultset('Audit')->create({
        user_id     => $user_id,
        description => $description,
        type        => 'login_change',
        datetime    => DateTime->now,
    });
}

sub login_success
{   my $self = shift;

    $self->schema->resultset('Audit')->create({
        user_id     => $self->user->{id},
        description => "Successful login by username ".$self->user->{username},
        type        => 'login_success',
        datetime    => DateTime->now,
    });
}

sub logout
{   my ($self, $username) = @_;

    $self->schema->resultset('Audit')->create({
        user_id     => $self->user->{id},
        description => "Logout by username $username",
        type        => 'logout',
        datetime    => DateTime->now,
    });
}

sub login_failure
{   my ($self, $username) = @_;

    $self->schema->resultset('Audit')->create({
        description => "Login failure using username $username",
        type        => 'login_failure',
        datetime    => DateTime->now,
    });
}

sub logs
{   my ($self, $filtering) = @_;

    my $format = DateTime::Format::Strptime->new(
         pattern   => '%Y-%m-%d',
         time_zone => 'local',
    );

    my $dtf  = $self->schema->storage->datetime_parser;
    my $to   = $filtering->{to} ? $format->parse_datetime($filtering->{to}) : DateTime->now;
    my $from = $filtering->{from} ? $format->parse_datetime($filtering->{from}) : $to->clone->subtract(days => 7);

    my $search = {
        datetime => {
            -between => [
                $dtf->format_datetime($from),
                $dtf->format_datetime($to),
            ],
        },
    };

    $search->{method}  = uc $filtering->{method} if $filtering->{method};
    $search->{type}    = $filtering->{type} if $filtering->{type};
    $search->{user_id} = $filtering->{user} if $filtering->{user};

    my $rs   = $self->schema->resultset('Audit')->search($search,{
        prefetch => 'user',
        order_by => {
            -desc => 'datetime',
        },
    });
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @logs = $rs->all;
    $_->{user} = GADS::Datum::Person->new(schema => $self->schema, set_value => $_)
        foreach @logs;
    \@logs;
}

1;


