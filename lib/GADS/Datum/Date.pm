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

use GADS::SchemaInstance;
use DateTime;
use Log::Report;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use namespace::clean;

extends 'GADS::Datum';

has schema => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        GADS::SchemaInstance->instance;
    },
);

# Set datum value with value from user
has set_value => (
    is       => 'rw',
    trigger  => sub {
        my ($self, $value) = @_;
        $self->oldvalue($self->clone);
        ($value) = @$value if ref $value eq 'ARRAY';
        my $newvalue = $self->_to_dt($value, 'user');
        my $old = $self->oldvalue && $self->oldvalue->value ? $self->oldvalue->value->epoch : 0;
        my $new = $newvalue ? $newvalue->epoch : 0;
        $self->changed(1) if $old != $new;
        $self->value($newvalue);
    }
);

has value => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $value = $self->init_value && $self->init_value->[0];
        my $v = $self->_to_dt($value, 'db');
        $self->has_value(1) if defined $value || $self->init_no_value;
        $v;
    },
);

sub blank
{   my $self = shift;
    $self->value ? 0 : 1;
};

# Can't use predicate, as value may not have been built on
# second time it's set
has has_value => (
    is => 'rw',
);

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self, value => $self->value);
};

sub _to_dt
{   my ($self, $value, $source) = @_;
    $value = $value->{value} if ref $value eq 'HASH';
    return unless $value;
    if (ref $value eq 'DateTime')
    {
        return $value;
    }
    elsif ($source eq 'db')
    {
        return $self->schema->storage->datetime_parser->parse_date($value);
    }
    else { # Assume 'user'
        $self->column->validate($value, fatal => 1);
        $self->column->parse_date($value);
    }
}

sub as_string
{   my $self = shift;
    return "" unless $self->value;
    $self->value->format_cldr($self->column->dateformat);
}

sub as_integer
{   my $self = shift;
    return 0 unless $self->value;
    $self->value->epoch;
}

sub html_form
{   my $self = shift;
    [$self->as_string];
}

sub for_code
{   my $self = shift;
    $self->_date_for_code($self->value);
}

1;

