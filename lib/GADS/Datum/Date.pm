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

package GADS::Datum::Date;

use DateTime;
use Log::Report;
use Moo;
use namespace::clean;

extends 'GADS::Datum';

has datetime_parser => (
    is       => 'rw',
    required => 1,
);

# This is a bit messy. We would normally work using the
# trigger alone, but we can't, because the first time
# round the datetime parser will not be available, so
# that needs to be done at build stage as a lazy
has set_value => (
    is       => 'rw',
    trigger  => sub {
        my ($self, $value) = @_;

        if ($self->has_value)
        {
            $self->oldvalue($self->clone);
            my $newvalue = $self->_to_dt($value); # DB parser needed for this. Will be set second time
            my $old = $self->oldvalue && $self->oldvalue->value ? $self->oldvalue->value->epoch : 0;
            my $new = $newvalue ? $newvalue->epoch : 0; 
            $self->changed(1) if $old != $new;
            $self->value($newvalue);
        }
        else {
            # Parse now if we have a parser. Better to check for invalid values whilst
            # we're setting values, so that they are caught and displayed to the user.
            # We don't have a parser if setting the value on instantiation from the
            # database, but in that case we know we have a valid value.
            if ($self->datetime_parser)
            {
                my $v = $self->_to_dt($value);
                $self->value($v);
            }
            else {
                $self->_init_value($value);
            }
            $self->has_value(1) if defined $value || $self->init_no_value;
        }
    },
);

has value => (
    is        => 'rw',
    lazy      => 1,
    builder   => sub {
        my ($self) = @_;
        $self->_to_dt($self->_init_value);
    },
);

around blank => sub
{   my ($orig, $self) = @_;
    $self->value ? 0 : 1;
};

# The initial value, as a raw date
has _init_value => (
    is => 'rw',
);

# Can't use predicate, as value may not have been built on
# second time it's set
has has_value => (
    is => 'rw',
);

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self, 'datetime_parser' => $self->datetime_parser, value => $self->value);
};

sub _to_dt
{   my ($self, $value) = @_;
    $value = $value->{value} if ref $value eq 'HASH';
    return unless $value;
    if (ref $value ne 'DateTime')
    {
        error __x"Invalid date {value} for {col}. Please enter as yyyy-mm-dd.", value => $value, col => $self->column->name,
            unless $self->column->validate($value);
        my $db_parser = $self->datetime_parser;
        $value && $db_parser->parse_date($value);
    }
    else {
        $value;
    }
}

sub as_string
{   my $self = shift;
    return "" unless $self->value;
    $self->value->ymd;
}

sub as_integer
{   my $self = shift;
    return 0 unless $self->value;
    $self->value->epoch;
}

1;

