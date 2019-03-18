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

package GADS::Column::Date;

use DateTime::Format::CLDR;
use GADS::View;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

has '+return_type' => (
    builder => sub { 'date' },
);

has '+addable' => (
    default => 1,
);

has '+can_multivalue' => (
    default => 1,
);

has '+has_multivalue_plus' => (
    default => 1,
);

has '+option_names' => (
    default => sub { [qw/show_datepicker default_today/] },
);

has include_time => (
    is      => 'ro',
    default => 0,
);

has show_datepicker => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub {
        my $self = shift;
        return 1 unless $self->has_options;
        $self->options->{show_datepicker};
    },
    trigger => sub { $_[0]->reset_options },
);

has default_today => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub {
        my $self = shift;
        return 0 unless $self->has_options;
        $self->options->{default_today};
    },
    trigger => sub { $_[0]->reset_options },
);

sub validate
{   my ($self, $value, %options) = @_;
    return 1 if !$value;
    if (!$self->parse_date($value))
    {
        return 0 unless $options{fatal};
        error __x"Invalid date '{value}' for {col}. Please enter as {format}.",
            value => $value, col => $self->name, format => $self->dateformat;
    }
    1;
}

sub validate_search
{   my $self = shift;
    my ($value, %options) = @_;
    if (!$value)
    {
        return 0 unless $options{fatal};
        error __x"Date cannot be blank for {col}.",
            col => $self->name;
    }
    GADS::View->parse_date_filter($value) and return 1;
    $self->validate(@_);
}

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Date')->search({ layout_id => $id })->delete;
}

1;

