
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

use Data::Dumper qw/Dumper/;
use Log::Report 'linkspace';
use Math::Round qw/round/;
use Moo;
use Scalar::Util qw(looks_like_number);
use namespace::clean;

extends 'GADS::Datum::Code';

with 'GADS::DateTime';
with 'GADS::Role::Presentation::Datum::String';

sub as_strings
{   my $self = shift;
    my (@return, $df, $dc);

    my $format = $df // $self->column->dateformat;

    foreach my $value (@{ $self->value })
    {
        push @return, !defined $value
            ? ''
            : ref $value eq 'DateTime'
            ? $self->date_as_string($value, $format)
            : $self->column->return_type eq 'daterange'
            ? $self->daterange_as_string($value, $format)
            : $self->column->return_type eq 'numeric' ? (
                ($dc //= $self->column->decimal_places // 0)
                ? sprintf("%.${dc}f", $value)
                : ($value + 0)    # Remove trailing zeros
            )
            : $value;
    }

    @return;
}

sub as_string
{   my $self = shift;
    join ', ', $self->as_strings;
}

sub _parse_date
{   $_[1] or return;
    $_[0]->schema->storage->datetime_parser->parse_date($_[1]);
}

sub _convert_date
{   my ($self, $val) = @_;
    my @return;
    if (defined $val && looks_like_number($val))
    {
        my $ret;
        try { $ret = DateTime->from_epoch(epoch => $val) };
        if (my $exception = $@->wasFatal)
        {
            warning "$@";
        }
        else
        {
            return $ret;
        }
    }
}

sub values { $_[0]->value }

sub convert_value
{   my ($self, $in) = @_;

    my $column = $self->column;

    my @values = $column->multivalue
        && ref $in->{return} eq 'ARRAY' ? @{ $in->{return} } : $in->{return};

    {
        local $Data::Dumper::Indent = 0;
        trace __x "Values into convert_value is: {value}",
            value => Dumper(\@values);
    }

    if ($in->{error})    # Will have already been reported
    {
        # Report useful error in case used as return type "error"
        my $m = __x "Unable to evaluate field \"{name}\": {error}",
            name  => $self->column->name,
            error => $in->{error};
        @values = ($m->toString);
    }

    my @return;

    foreach my $val (@values)
    {
        if ($column->return_type eq "date")    # Currently no time element
        {
            $val = $self->_convert_date($val);

            # Database only stores date part, so ensure local value reflects
            # that
            $val->truncate(to => 'day') if $val;
            push @return, $val || undef;
        }
        elsif ($column->return_type eq
            "daterange")    # Currently always has time element
        {
            if (!$val)
            {
                # Do nothing
            }
            elsif (ref $val eq 'HASH' && $val->{from} && $val->{to})
            {
                push @return,
                    $self->parse_daterange({
                        from => $self->_convert_date($val->{from}),
                        to   => $self->_convert_date($val->{to}),
                    });
            }
            else
            {
                warning __ "Unexpected daterange return type";
            }
        }
        elsif ($column->return_type eq 'numeric'
            || $column->return_type eq 'integer')
        {
            if (defined $val && looks_like_number($val))
            {
                my $ret = $val;
                $ret = round $ret
                    if defined $ret && $column->return_type eq 'integer';
                push @return, $ret;
            }
        }
        elsif ($column->return_type eq 'globe')
        {
            if ($self->column->check_country($val))
            {
                push @return, $val;
            }
            else
            {
                mistake __x
"Failed to produce globe location: unknown country {country}",
                    country => $val;
            }
        }
        else
        {
            push @return, $val if defined $val;
        }
    }

    no warnings "uninitialized";
    trace __x "Returning value from convert_value: {value}",
        value => Dumper(\@return);

    @return;
}

# Needed for overloading definitions, which should probably be removed at some
# point as they offer little benefit
sub as_integer { panic "Not implemented" }

sub write_value
{   my $self = shift;
    $self->write_cache('calcval');
}

# Compare 2 calc values. Could be from database or calculation. May be used
# with scalar values or arrays
sub equal
{   my ($self, $a, $b) = @_;
    my @a = ref $a eq 'ARRAY' ? @$a : ($a);
    my @b = ref $b eq 'ARRAY' ? @$b : ($b);
    if ($self->column->return_type eq 'daterange')
    {
        my $format = $self->column->dateformat;

        # Values can be a text representation ("xx to yy") or a DateTime::Span
        # Convert to a consistent textual value for comparison purposes
        @a = map {
            ref $_ eq 'DateTime::Span'
                ? $self->daterange_as_string($_, $format)
                : $_
        } @a;
        @b = map {
            ref $_ eq 'DateTime::Span'
                ? $self->daterange_as_string($_, $format)
                : $_
        } @b;
    }
    @a = sort @a if defined $a[0];
    @b = sort @b if defined $b[0];
    return 0 if @a != @b;

    # Iterate over each pair, return 0 if different
    foreach my $a2 (@a)
    {
        my $b2 = shift @b;

        (defined $a2 xor defined $b2)
            and return 0;
        !defined $a2 && !defined $b2 and next;    # Same
        my $rt = $self->column->return_type;
        if ($rt eq 'numeric' || $rt eq 'integer')
        {
            $a2 += 0;
            $b2 += 0;                             # Remove trailing zeros
            return 0 if $a2 != $b2;
        }
        elsif ($rt eq 'date')
        {
            # Type might have changed and old value be string
            ref $a2 eq 'DateTime' && ref $b2 eq 'DateTime' or return 0;
            return 0 if $a2 != $b2;
        }
        elsif ($rt eq 'daterange')
        {
            # Type might have changed and old value be string
            ref $a2 eq 'HASH'
                && $a2->{from} eq 'DateTime'
                && ref $b2 eq 'HASH'
                && $b2->{from} eq 'DateTime'
                or return 0;
            return 0 if $a2->{from} != $b2->{from} && $a2->{to} != $b2->{to};
        }
        else
        {
            return 0 if $a2 ne $b2;
        }
    }

    # Assume same
    return 1;
}

sub for_table
{   my $self   = shift;
    my $return = $self->for_table_template;
    $return->{values} = [ $self->as_strings ];
    $return;
}

sub _build_for_code
{   my $self = shift;
    my $rt   = $self->column->return_type;
    my @return;
    foreach my $val (@{ $self->value })
    {
        if ($rt eq 'date')
        {
            push @return, $self->date_for_code($val);
        }
        elsif ($rt eq 'daterange')
        {
            push @return,
                {
                    from  => $self->date_for_code($_->start),
                    to    => $self->date_for_code($_->end),
                    value => $self->_as_string($_),
                };
        }
        elsif ($rt eq 'numeric')
        {
            # Ensure true numeric value passed to Lua, otherwise "attempt to
            # compare number with string" errors are encountered
            push @return, $self->as_string + 0;
        }
        elsif ($rt eq 'integer')
        {
            push @return, defined $val ? int $val : undef;
        }
        else
        {
            push @return, defined $val ? "$val" : undef;
        }
    }

    $self->column->multivalue ? \@return : $return[0];
}

sub _build_blank { !length shift->as_string }

1;
