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

use Data::Dumper;
use Log::Report;
use Math::Round qw/round/;
use Moo;
use Scalar::Util qw(looks_like_number);
use namespace::clean;

extends 'GADS::Datum::Code';

has set_value => (
    is       => 'rw',
    trigger  => sub {
        my $self = shift;
        $self->_set_has_value(1);
    },
);

has value => (
    is       => 'rw',
    lazy     => 1,
    clearer  => 1,
    builder  => sub {
        my $self = shift;
        $self->_transform_value($self->init_value);
    },
);

has has_value => (
    is => 'rwp',
);

has layout => (
    is       => 'rw',
    required => 1,
);

has params => (
    is => 'lazy',
);

sub _build_params
{   my $self = shift;
    $self->_sub_param_values($self->column->params);
}

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
sub _transform_value
{   my ($self, $original) = @_;

    my $column = $self->column;
    my $code   = $column->calc;
    my $layout = $self->layout;

    my $value;

    if (ref $original && !$self->force_update)
    {
        my $v  = $original->{$column->value_field};
        $value = $column->return_type eq 'date'
               ? $self->_parse_date($v)
               : $v;
    }
    elsif (!$code)
    {
        return;
    }
    else {
        # Used during tests to check that $original is being set correctly
        panic "Entering calculation code"
            if $ENV{GADS_PANIC_ON_ENTERING_CODE};

        my @params = @{$self->params};
        try { $value = $column->eval(@params) };
        if ($@)
        {
            $value = '<evaluation error>';
            warning __x"Failed to eval calc: {error} (code: {code}, params: {params})",
                error => $@->wasFatal->message->toString, code => $code, params => Dumper(@params);
        }
        # Convert as required
        if ($column->return_type eq "date")
        {
            $value = undef
                if !$value && !looks_like_number($value); # Convert empty strings to undef
            if (defined $value)
            {
                try { $value = DateTime->from_epoch(epoch => $value) };
                if (my $exception = $@->wasFatal)
                {
                    $value = undef;
                    warning "$@";
                }
            }
        }
        elsif ($column->return_type eq 'numeric' || $column->return_type eq 'integer')
        {
            $value = undef
                if !$value && !looks_like_number($value); # Convert empty strings to undef
            $value = round $value if defined $value && $column->return_type eq 'integer';
        }

        $self->_write_calc($value);
    }
    $value;
}

sub _write_calc
{   my $self = shift;
    $self->write_cache('calcval', @_);
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
        !DateTime->compare($a, $b);
    }
    else {
        $a eq $b;
    }
}

1;

