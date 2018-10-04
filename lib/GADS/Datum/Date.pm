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
use DateTime::Format::DateManip;
use Log::Report 'linkspace';
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
after set_value => sub {
    my ($self, $value, %options) = @_;
    $self->oldvalue($self->clone);
    ($value) = @$value if ref $value eq 'ARRAY';
    my $newvalue = $self->_to_dt($value, source => 'user', %options);
    my $old = $self->oldvalue && $self->oldvalue->value ? $self->oldvalue->value->epoch : 0;
    my $new = $newvalue ? $newvalue->epoch : 0;
    $self->changed(1) if $old != $new;
    $self->value($newvalue);
};

has value => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $value = $self->init_value && $self->init_value->[0];
        my $v = $self->_to_dt($value, source => 'db');
        $self->has_value(1) if defined $value || $self->init_no_value;
        $v ||= DateTime->now if $self->column->default_today && !$self->record_id;
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
    $orig->($self, value => $self->value, @_);
};

sub _to_dt
{   my ($self, $value, %options) = @_;
    my $source = $options{source};
    $value = $value->{value} if ref $value eq 'HASH';
    if (!$value)
    {
        return;
    }
    if (ref $value eq 'DateTime')
    {
        return $value;
    }
    elsif ($source eq 'db')
    {
        if ($value =~ / /) # Assume datetime
        {
            return $self->schema->storage->datetime_parser->parse_datetime($value);
        } else {
            return $self->schema->storage->datetime_parser->parse_date($value);
        }
    }
    else { # Assume 'user'
        if (!$self->column->validate($value) && $options{bulk}) # Only allow duration during bulk update
        {
            # See if it's a duration and return that instead if so
            if (my $duration = DateTime::Format::DateManip->parse_duration($value))
            {
                return $self->value ? $self->value->clone->add_duration($duration) : undef;
            }
            else {
                # Will bork below
            }
        }
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

