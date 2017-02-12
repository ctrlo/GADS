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

package GADS::Users;

use Email::Valid;
use GADS::Email;
use GADS::Instance;
use GADS::Site;
use Log::Report;
use Text::CSV::Encoded;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'ro',
    required => 1,
);

has config => (
    is       => 'ro',
);

has all => (
    is  => 'lazy',
    isa => ArrayRef,
);

has all_admins => (
    is  => 'lazy',
    isa => ArrayRef,
);

has titles => (
    is  => 'lazy',
    isa => ArrayRef,
);

has organisations => (
    is  => 'lazy',
    isa => ArrayRef,
);

has permissions => (
    is  => 'lazy',
    isa => ArrayRef,
);

has register_requests => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_all
{   my $self = shift;
    my $search = {
        deleted         => undef,
        account_request => 0,
    };
    my @users = $self->schema->resultset('User')->search($search,{
        join     => { user_permissions => 'permission' },
        order_by => 'surname',
        collapse => 1,
    })->all;
    \@users;
}

sub all_in_org
{   my ($self, $org_id) = @_;
    my $search = {
    };
    my @users = $self->schema->resultset('User')->search({
        deleted         => undef,
        account_request => 0,
        organisation    => $org_id,
    })->all;
    \@users;
}

sub _build_all_admins
{   my $self = shift;
    my $search = {
        deleted           => undef,
        account_request   => 0,
        'permission.name' => 'useradmin',
    };
    my @users = $self->schema->resultset('User')->search($search,{
        join     => { user_permissions => 'permission' },
        order_by => 'surname',
        collapse => 1,
    })->all;
    \@users;
}

sub _build_titles
{   my $self = shift;
    my @titles = $self->schema->resultset('Title')->search(
        {},
        {
            order_by => 'name',
        }
    )->all;
    \@titles;
}

sub _build_organisations
{   my $self = shift;
    my @organisations = $self->schema->resultset('Organisation')->search(
        {},
        {
            order_by => 'name',
        }
    )->all;
    \@organisations;
}

sub _build_permissions
{   my $self = shift;
    my @permissions = $self->schema->resultset('Permission')->search({},{
        order_by => 'order',
    })->all;
    \@permissions;
}

sub _build_register_requests
{   my $self = shift;
    my @users = $self->schema->resultset('User')->search({ account_request => 1 })->all;
    \@users;
}

sub title_new
{   my ($self, $params) = @_;
    $self->schema->resultset('Title')->create({ name => $params->{name} });
}

sub organisation_new
{   my ($self, $params) = @_;
    $self->schema->resultset('Organisation')->create({ name => $params->{name} });
}

sub register
{   my ($self, $params) = @_;

    my %new;
    my %params = %$params;

    my $site = GADS::Site->instance->site;

    error __"Please enter a valid email address"
        unless Email::Valid->address($params{email});

    my @fields = qw(firstname surname email account_request_notes);
    push @fields, 'organisation' if $site->register_show_organisation;
    push @fields, 'title' if $site->register_show_title;
    push @fields, 'freetext1' if $site->register_freetext1_name;
    push @fields, 'freetext2' if $site->register_freetext2_name;
    @new{@fields} = @params{@fields};
    $new{firstname} = ucfirst $new{firstname};
    $new{surname} = ucfirst $new{surname};
    $new{username} = $params->{email};
    $new{account_request} = 1;
    $new{freetext1} or delete $new{freetext1};
    $new{freetext2} or delete $new{freetext2};
    $new{title} or delete $new{title};
    $new{organisation} or delete $new{organisation};
    my $user = $self->schema->resultset('User')->create(\%new);

    # Email admins with account request
    my $admins = $self->all_admins;
    my @emails = map { $_->email } @$admins;
    my $text = "A new account request has been received from the following person:\n\n";
    $text .= "First name: $new{firstname}, ";
    $text .= "surname: $new{surname}, ";
    $text .= "email: $new{email}, ";
    $text .= "title: ".$user->title->name.", " if $user->title;
    $text .= $site->register_freetext1_name.": $new{freetext1}, " if $new{freetext1};
    $text .= $site->register_freetext2_name.": $new{freetext2}, " if $new{freetext2};
    $text .= $site->register_organisation_name.": ".$user->organisation->name.", " if $user->organisation;
    $text .= "\n\n";
    $text .= "User notes: $new{account_request_notes}\n";
    my $config = $self->config
        or panic "Config needs to be defined";
    my $email = GADS::Email->instance;
    $email->send({
        emails  => \@emails,
        subject => "New account request",
        text    => $text,
    });
}

sub csv
{   my $self = shift;
    my $csv  = Text::CSV::Encoded->new({ encoding  => undef });

    my $site = GADS::Site->instance->site;
    # Column names
    my @columns = qw/ID Surname Forename Email Lastlogin/;
    push @columns, $site->register_freetext1_name if $site->register_freetext1_name;
    push @columns, $site->register_freetext2_name if $site->register_freetext2_name;
    push @columns, 'Organisation' if $site->register_show_organisation;
    push @columns, 'Title' if $site->register_show_title;
    $csv->combine(@columns)
        or error __x"An error occurred producing the CSV headings: {err}", err => $csv->error_input;
    my $csvout = $csv->string."\n";

    # All the data values
    foreach my $user (@{$self->all})
    {
        $csv->combine($user->id, $user->surname, $user->firstname, ($user->title && $user->title->name || ''),
            $user->email, ($user->organisation && $user->organisation->name || ''), $user->telephone, $user->lastlogin
        )
            or error __x"An error occurred producing a line of CSV: {err}",
                err => "".$csv->error_diag;
        $csvout .= $csv->string."\n";
    }
    $csvout;
}

1;

