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

package GADS::Datum::Daterange;

use DateTime;
use DateTime::Span;
use Log::Report;
use Moo;
use namespace::clean;

use overload '""' => \&as_string;

extends 'GADS::Datum';

has datetime_parser => (
    is       => 'rw',
    required => 1,
);

has set_value => (
    is       => 'rw',
    required => 1,
    trigger  => sub {
        my ($self, $value) = @_;

        if ($self->value_done)
        {

            my $oldvalue = $self->value; # Not set with new value yet
            $self->oldvalue($oldvalue);
            my $newvalue = $self->_parse_dt($value); # DB parser needed for this. Will be set second time
            my $from_old = $oldvalue ? $oldvalue->start->epoch : 0;
            my $to_old   = $oldvalue ? $oldvalue->end->epoch   : 0;
            my $from_new = $newvalue ? $newvalue->start->epoch : 0;
            my $to_new   = $newvalue ? $newvalue->end->epoch   : 0;
            $self->changed(1) if $from_old != $from_new || $to_old != $to_new;
            $self->value($newvalue);
        }
        else {
            $self->_init_value($value);
            $self->value_done(1);
        }
    },
);

has value => (
    is       => 'rw',
    lazy     => 1,
    builder   => sub {
        my ($self) = @_;
        $self->_parse_dt($self->_init_value);
    },
);

around blank => sub {
    my ($orig, $self) = @_;
    $self->from_dt && $self->to_dt ? 0 : 1;
};

# The initial value, as a raw date
has _init_value => (
    is => 'rw',
);

has from_form => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->value && $_[0]->value->start->ymd },
);

has to_form => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->value && $_[0]->value->end->ymd },
);

has from_dt => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->value && $_[0]->value->start },
);

has to_dt => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->value && $_[0]->value->end },
);

has schema => (
    is       => 'rw',
    required => 1,
);

# Can't use predicate, as value may not have been built on
# second time it's set
has value_done => (
    is => 'rw',
);

sub _parse_dt
{   my ($self, $original) = @_;
    my $db_parser = $self->datetime_parser;

    # Array ref will be received from form
    if (ref $original eq 'ARRAY')
    {
        $original = {
            from => $original->[0],
            to   => $original->[1],
        };
    }
    # Otherwise assume it's a hashref: { from => .., to => .. }
    my $from = $original->{from} ? $db_parser->parse_date($original->{from}) : undef;
    my $to   = $original->{to}   ? $db_parser->parse_date($original->{to}) : undef;

    error __x"Please enter 2 date values for '{col}'", col => $self->column->name
        if $from xor $to;

    return unless $from && $to;
    my $return = DateTime::Span->from_datetimes(start => $from, end => $to);

    my $string = $self->_as_string($return);
    $return;
}

sub as_string
{   my $self = shift;
    $self->value; # Force update of values
    $self->_as_string($self->value);
}

sub _as_string
{   my ($self, $range) = @_;
    return "" unless $range;
    return "" unless $range->start && $range->end;
    $range->start->ymd . " to " . $range->end->ymd;
}

1;

