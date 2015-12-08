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

use Log::Report;
use Moo;
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
        $self->_transform_value($self->set_value);
    },
);

has has_value => (
    is => 'rwp',
);

has dependent_values => (
    is       => 'rw',
    required => 1,
);

has layout => (
    is       => 'rw',
    required => 1,
);

sub as_string
{   my $self = shift;
    my $value = $self->value;
    $value = $value->ymd if ref $value eq 'DateTime';
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
    $value ||= "";
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

    my $column           = $self->column;
    my $code             = $column->calc;
    my $layout           = $self->layout;

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
        foreach my $col_id (@{$column->depends_on})
        {
            my $col    = $layout->column($col_id);
            $code = $self->sub_values($col, $code);
        }
        # Insert current date if required
        $code = $self->sub_date($code, 'CURDATE', DateTime->now->truncate(to => 'day'));

        # Insert ID if required
        my $current_id = $self->current_id;
        $code =~ s/\[id\]/$current_id/g
            if $code;

        # If there are still square brackets then something is wrong
        if ($code && $code =~ /[\[\]]+/)
        {
            $value = $column->return_type eq 'date'
                   ? undef
                   : 'Invalid field names in calc formula';
            assert "Invalid field names in calc formula. Remaining code: $code";
        }
        elsif (defined $code) {
            try { $value = $self->safe_eval("$code") };
            if ($@)
            {
                $value = $@->wasFatal->message->toString;
                assert "Failed to eval calc. Code was: $code";
            }
            # Convert to date if required
            if ($column->return_type eq "date")
            {
                try { $value = DateTime->from_epoch(epoch => $value) };
                if (my $exception = $@->wasFatal)
                {
                    $value = undef;
                    assert "$@";
                }
            }
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

