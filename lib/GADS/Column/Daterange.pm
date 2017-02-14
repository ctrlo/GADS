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

package GADS::Column::Daterange;

use DateTime;
use Log::Report;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

has '+return_type' => (
    builder => sub { 'daterange' },
);

has '+addable' => (
    default => 1,
);

has '+option_names' => (
    default => sub { [qw/show_datepicker/] },
);

has show_datepicker => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub { defined $_[0]->options->{show_datepicker} ? $_[0]->options->{show_datepicker} : 1 },
    trigger => sub { $_[0]->options->{show_datepicker} = $_[1] ? 1 : 0 },
);

sub validate
{   my ($self, $value, %options) = @_;

    return 1 if !$value;
    return 1 if !$value->{from} && !$value->{to};

    if ($value->{from} xor $value->{to})
    {
        return 0 unless $options{fatal};
        error __x"Please enter 2 date values for '{col}'", col => $self->name;
    }
    my $from;
    if ($value->{from} && !($from = $self->parse_date($value->{from})))
    {
        return 0 unless $options{fatal};
        error __x"Invalid start date {value} for {col}. Please enter as {format}.",
            value => $value->{from}, col => $self->name, format => $self->dateformat;
    }
    my $to;
    if ($value->{to} && !($to = $self->parse_date($value->{to})))
    {
        return 0 unless $options{fatal};
        error __x"Invalid end date {value} for {col}. Please enter as {format}.",
            value => $value->{to}, col => $self->name, format => $self->dateformat;
    }

    if (DateTime->compare($from, $to) == 1)
    {
        return 0 unless $options{fatal};
        error __x"Start date must be before the end date for '{col}'", col => $self->name;
    }

    1;
}

sub validate_search
{   my ($self, $value, %options) = @_;
    return 1 if !$value;
    if ($options{single_only})
    {
        return 1 if $self->parse_date($value);
        return 0 unless $options{fatal};
        error __x"Invalid single date format {value} for {name}",
            value => $value, name => $self->name;
    }
    if ($options{full_only})
    {
        if (my $hash = $self->split($value))
        {
            return $self->validate($hash, %options);
        }
        # Unable to split
        return 0 unless $options{fatal};
        error __x"Invalid full date format {value} for {name}",
            value => $value, name => $self->name;
    }
    # Accept both formats. Normal date format used to validate searches
    return 1 if $self->parse_date($value) || $self->validate($self->split($value));
    return 0 unless $options{fatal};
    error "Invalid format {value} for {name}",
        value => $value, name => $self->name;
}

sub split
{   my ($self, $value) = @_;
    if ($value =~ /(.+) to (.+)/)
    {
        my $from = $1; my $to = $2;
        $self->parse_date($from) && $self->parse_date($to)
            or return;
        return {
            from => $from,
            to   => $to,
        };
    }
}

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Daterange')->search({ layout_id => $id })->delete;
}

1;

