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

use overload '""' => \&as_string;
use overload '+' => \&as_integer;

extends 'GADS::Datum::Code';

has set_value => (
    is       => 'rw',
);

has value => (
    is       => 'rw',
    lazy     => 1,
    builder => sub {
        my $self = shift;
        $self->_transform_value($self->set_value);
    },
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
    $value // "";
}

sub as_integer
{   my $self = shift;
    my $value = $self->value;
    $value = $value->epoch if ref $value eq 'DateTime';
    int ($value // 0);
}

sub _transform_value
{   my ($self, $original) = @_;

    my $column           = $self->column;
    my $code             = $column->calc;
    my $layout           = $self->layout;

    my $value;

    if (exists $original->{value} && !$self->force_update)
    {
        $value = $original->{value};
    }
    elsif (!$code)
    {
        return;
    }
    else {
        foreach my $col_id (@{$column->depends_on})
        {
            my $col    = $layout->column($col_id);
            my $name   = $col->name;
            my $dvalue = $self->dependent_values->{$col_id};

            if ($dvalue && $col->type eq "date")
            {
                $dvalue = $dvalue->value->epoch;
            }
            elsif ($col->type eq "daterange")
            {
                # Return value will eventually be undef if code returns blank string
                $dvalue = {
                    from => $dvalue && $dvalue->from_dt ? $dvalue->from_dt->epoch : "",
                    to   => $dvalue && $dvalue->to_dt   ? $dvalue->to_dt->epoch   : "",
                };
                $code =~ s/\[$name\.from\]/$dvalue->{from}/gi;
                $code =~ s/\[$name\.to\]/$dvalue->{to}/gi;
            }
            else {
                # XXX Is there a q char delimiter that is safe regardless
                # of input? Backtick is unlikely to be used...
                if ($col->numeric)
                {
                    $dvalue = $dvalue || 0;
                }
                else {
                    $dvalue = $dvalue ? "q`$dvalue`" : qq("");
                }
                $code =~ s/\[$name\]/$dvalue/gi;
            }
        }
        # Insert current date if required
        my $now = time;
        $code =~ s/CURDATE/$now/g;

        # Insert ID if required
        my $current_id = $self->current_id;
        $code =~ s/\[id\]/$current_id/g;

        # If there are still square brackets then something is wrong
        if ($code =~ /[\[\]]+/)
        {
            $value = 'Invalid field names in calc formula';
            assert "Invalid field names in calc formula. Remaining code: $code";
        }
        else {
            try { $value = $self->safe_eval("$code") };
            if ($@)
            {
                $value = $@->wasFatal->message;
                assert "Failed to eval calc. Code was: $code";
            }
        }

        $self->_write_calc($value);
    }
    if ($value && $column->return_type eq "date")
    {
        try { $value = DateTime->from_epoch(epoch => $value) };
        if (my $exception = $@->wasFatal)
        {
            $value = undef;
            assert "$@";
        }
    }
    $value;
}

sub _write_calc
{   my $self = shift;
    $self->write_cache('calcval', @_);
}

1;

