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

package GADS::Datum::Rag;

use Log::Report;
use Moo;
use namespace::clean;

extends 'GADS::Datum::Code';

sub convert_value
{   my ($self, $in) = @_;

    my $value = $in->{return};
    my $return;

    if ($in->{error}) # Will have already been reported
    {
        $return = 'e_purple';
    }
    elsif (!$value)
    {
        $return = 'a_grey';
    }
    elsif ($value eq 'red')
    {
        $return = 'b_red';
    }
    elsif ($value eq 'amber')
    {
        $return = 'c_amber';
    }
    elsif ($value eq 'green')
    {
        $return = 'd_green';
    }
    else {
        # Not expected
        $return = 'e_purple';
    }
}

sub write_value
{   my $self = shift;
    $self->write_cache('ragval', @_);
}

# XXX Why is this needed? Error when creating new record otherwise
sub as_integer
{   my $self = shift;
    !$self->value
        ? 0
        : $self->value eq 'a_grey'
        ? 1
        : $self->value eq 'b_red'
        ? 2
        : $self->value eq 'c_amber'
        ? 3
        : $self->value eq 'd_green'
        ? 4
        : $self->value eq 'e_purple'
        ? -1
        : -2;
}

sub as_string
{   my $self = shift;
    $self->value // "";
}

sub equal
{   my ($self, $a, $b) = @_;
    $a eq $b;
}

1;

