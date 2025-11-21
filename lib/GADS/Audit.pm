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
use GADS::DateTime;
use GADS::Datum::Person;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/ArrayRef HashRef/;

use Data::Dump qw/pp/;

has schema => (
    is       => 'rw',
    required => 1,
);

has user => (
    is => 'rw',
);

sub user_id
{   my $self = shift;
    $self->user or return undef;
    $self->user->id;
}

sub username
{   my $self = shift;
    $self->user or return undef;
    $self->user->username;
}

has filtering => (
    is      => 'rw',
    isa     => HashRef,
    coerce  => sub {
        my $value = shift;
        my $format = DateTime::Format::Strptime->new(
             pattern   => '%Y-%m-%d',
             time_zone => 'local',
        );
        if ($value->{from} && ref $value->{from} ne 'DateTime')
        {
            $value->{from} = GADS::DateTime::parse_datetime(undef, $value->{from});
        }
        if ($value->{to} && ref $value->{to} ne 'DateTime')
        {
            $value->{to} = GADS::DateTime::parse_datetime(undef, $value->{to});
        }
        $value->{from} ||= DateTime->now->subtract(hours => 24);
        $value->{to}   ||= DateTime->now;
        return $value;
    },
    builder => sub { +{} },
);

sub audit_types{ [qw/user_action login_change login_success logout login_failure script_error/] };

sub script_error
{
    my ($self, %options) = @_;

    my $description = $options{description} || 'Script error';
    my $method      = $options{method} || 'unknown';
    my $url         = $options{url} || 'unknown';

    $self->schema->resultset('Audit')->create({
        user_id     => $self->user_id,
        description => $description,
        type        => 'script_error',
        method      => $method,
        url         => $url,
        datetime    => DateTime->now,
        instance_id => $options{instance_id},
    });
}

sub user_action
{   my ($self, %options) = @_;

    my $layout = $options{layout};
    $self->schema->resultset('Audit')->create({
        user_id     => $self->user_id,
        description => $options{description},
        type        => 'user_action',
        method      => $options{method},
        url         => $options{url},
        datetime    => DateTime->now,
        instance_id => $layout && $layout->instance_id,
    });
}

sub login_change
{   my ($self, $description) = @_;

    $self->schema->resultset('Audit')->create({
        user_id     => $self->user_id,
        description => $description,
        type        => 'login_change',
        datetime    => DateTime->now,
    });
}

sub login_success
{   my $self = shift;

    $self->schema->resultset('Audit')->create({
        user_id     => $self->user_id,
        description => "Successful login by username ".$self->username,
        type        => 'login_success',
        datetime    => DateTime->now,
    });
}

sub logout
{   my ($self, $username) = @_;

    $self->schema->resultset('Audit')->create({
        user_id     => $self->user_id,
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
{   my $self = shift;

    my $filtering = $self->filtering;
    my $dtf  = $self->schema->storage->datetime_parser;

    my $search = {
        datetime => {
            -between => [
                $dtf->format_datetime($filtering->{from}),
                $dtf->format_datetime($filtering->{to}),
            ],
        },
    };

    $search->{method}  = uc $filtering->{method} if $filtering->{method};
    $search->{type}    = $filtering->{type} if $filtering->{type};
    if (my $user_id = $filtering->{user})
    {
        $user_id =~ /^[0-9]+$/
            or error __x"Invalid user ID {id}", id => $user_id;
        $search->{user_id} = $filtering->{user};
    }

    my $rs   = $self->schema->resultset('Audit')->search($search,{
        prefetch => 'user',
        order_by => {
            -desc => 'datetime',
        },
    });
    
    my @logs = $rs->all;
    my $site = $self->schema->resultset('Site')->next;
    
    my @result = map {
        +{
            id          => $_->id,
            type        => $_->type,
            datetime    => $_->datetime->gads_time,
            description => $_->description,
            user        => $_->user,
        }
    } @logs;

    \@result;
}

sub csv
{   my $self = shift;
    my $csv  = Text::CSV::Encoded->new({ encoding  => undef });

    # Column names
    $csv->combine(qw/ID Username Type Time Description/)
        or error __x"An error occurred producing the CSV headings: {err}", err => $csv->error_input;
    my $csvout = $csv->string."\n";

    # All the data values
    foreach my $row (@{$self->logs})
    {
        $csv->combine($row->{id}, $row->{user}->{text}, $row->{type}, $row->{datetime}, $row->{description})
            or error __x"An error occurred producing a line of CSV: {err}",
                err => "".$csv->error_diag;
        $csvout .= $csv->string."\n";
    }
    $csvout;
}

1;
