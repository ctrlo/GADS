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

package GADS::Datum::Calc;

use Log::Report 'linkspace';
use Math::Round qw/round/;
use Moo;
use Scalar::Util qw(looks_like_number);
use namespace::clean;

extends 'GADS::Datum::Code';

sub as_string
{   my $self = shift;
    my $value = $self->value;
    $value = $value->format_cldr($self->column->dateformat) if ref $value eq 'DateTime';
    if ($self->column->return_type eq 'numeric')
    {
        if (my $dc = $self->column->decimal_places)
        {
            $value = sprintf("%.${dc}f", $value)
        }
        elsif (!defined $value)
        {
            $value = '';
        }
        else {
            $value += 0; # Remove trailing zeros
        }
    }
    $value //= "";
    "$value";
}

sub as_integer
{   my $self = shift;
    my $value = $self->value;
    $value = $value->epoch if ref $value eq 'DateTime';
    no warnings 'numeric';
    int ($value || 0);
}

sub _parse_date
{   $_[1] or return;
    $_[0]->schema->storage->datetime_parser->parse_date($_[1]);
}

sub convert_value
{   my ($self, $in) = @_;

    my $column = $self->column;

    my $value = $in->{return};
    trace "Value into convert_value is: $value";

    my $return;

    if ($in->{error}) # Will have already been reported
    {
        $return = '<evaluation error>';
    }
    elsif ($column->return_type eq "date")
    {
        if ($value && looks_like_number($value))
        {
            try { $return = DateTime->from_epoch(epoch => $value) };
            if (my $exception = $@->wasFatal)
            {
                warning "$@";
            }
        }
    }
    elsif ($column->return_type eq 'numeric' || $column->return_type eq 'integer')
    {
        if (defined $value && looks_like_number($value))
        {
            $return = $value;
            $return = round $return if defined $return && $column->return_type eq 'integer';
        }
    }
    else {
        $return = $value;
    }

    no warnings "uninitialized";
    trace "Returning value from convert_value: $return";

    $return;
}

sub write_value
{   my $self = shift;
    $self->write_cache('calcval');
}

# Compare 2 calc values. Could be from database or calculation
sub equal
{   my ($self, $a, $b) = @_;
    (defined $a xor defined $b)
        and return;
    my $rt = $self->column->return_type;
    if ($rt eq 'numeric' || $rt eq 'integer')
    {
        $a += 0; $b += 0; # Remove trailing zeros
        $a == $b;
    }
    elsif ($rt eq 'date')
    {
        # Type might have changed and old value be string
        ref $a eq 'DateTime' && ref $b eq 'DateTime' or return;
        !DateTime->compare($a, $b);
    }
    else {
        $a eq $b;
    }
}

sub for_code
{   my $self = shift;
    if ($self->column->return_type eq 'date')
    {
        $self->_date_for_code($self->value);
    }
    else {
        $self->as_string;
    }
}

1;

