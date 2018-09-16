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

sub as_string
{   my $self = shift;
    my @values = @{$self->value};
    my @return;
    foreach my $value (@values)
    {
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
        push @return, "$value";
    }
    return join ', ', @return;
}

sub _parse_date
{   $_[1] or return;
    $_[0]->schema->storage->datetime_parser->parse_date($_[1]);
}

sub convert_value
{   my ($self, $in) = @_;

    my $column = $self->column;

    my @values = $column->multivalue && ref $in->{return} eq 'ARRAY'
        ? @{$in->{return}} : $in->{return};
    my $old_indent = $Data::Dumper::Indent;
    $Data::Dumper::Indent = 0;
    trace __x"Values into convert_value is: {value}", value => Dumper(\@values);
    $Data::Dumper::Indent = $old_indent;

    my $return;

    if ($in->{error}) # Will have already been reported
    {
        @values = ('<evaluation error>');
    }

    my @return;

    foreach my $val (@values)
    {
        if ($column->return_type eq "date")
        {
            if (defined $val && looks_like_number($val))
            {
                my $ret;
                try { $ret = DateTime->from_epoch(epoch => $val) };
                if (my $exception = $@->wasFatal)
                {
                    warning "$@";
                }
                else {
                    push @return, $ret;
                }
            }
            # Database only stores date part, so ensure local value reflects
            # that
            $return->truncate(to => 'day') if $return;
        }
        elsif ($column->return_type eq 'numeric' || $column->return_type eq 'integer')
        {
            if (defined $val && looks_like_number($val))
            {
                my $ret = $val;
                $ret = round $ret if defined $ret && $column->return_type eq 'integer';
                push @return, $ret;
            }
        }
        elsif ($column->return_type eq 'globe')
        {
            if ($self->column->check_country($val))
            {
                push @return, $val;
            }
            else {
                mistake __x"Failed to produce globe location: unknown country {country}", country => $val;
            }
        }
        else {
            push @return, $val;
        }
    }

    no warnings "uninitialized";
    trace __x"Returning value from convert_value: {value}", value => Dumper(\@return);

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
    @a = sort @a if defined $a[0];
    @b = sort @b if defined $b[0];
    return 0 if @a != @b;
    # Iterate over each pair, return 0 if different
    foreach my $a2 (@a)
    {
        my $b2 = shift @b;

        (defined $a2 xor defined $b2)
            and return 0;
        !defined $a2 && !defined $b2 and next; # Same
        my $rt = $self->column->return_type;
        if ($rt eq 'numeric' || $rt eq 'integer')
        {
            $a2 += 0; $b2 += 0; # Remove trailing zeros
            return 0 if $a2 != $b2;
        }
        elsif ($rt eq 'date')
        {
            # Type might have changed and old value be string
            ref $a2 eq 'DateTime' && ref $b2 eq 'DateTime' or return 0;
            return 0 if $a2 != $b2;
        }
        else {
            return 0 if $a2 ne $b2;
        }
    }
    # Assume same
    return 1;
}

sub for_code
{   my $self = shift;
    my $rt = $self->column->return_type;
    my @return;
    foreach my $val (@{$self->value})
    {
        if ($rt eq 'date')
        {
            push @return, $self->_date_for_code($val);
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
        else {
            push @return, defined $val ? "$val" : undef;
        }
    }

    $self->column->multivalue ? \@return : $return[0];
}

sub _build_blank { !shift->as_string }

1;
