=pod
GADS - Globally Accessible Data Store
Copyright (C) 2017 Ctrl O Ltd

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

package GADS::Datum::Autocur;

use HTML::Entities qw/encode_entities/;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Datum::Curcommon';

sub _transform_value
{   my ($self, $value) = @_;
    my ($record, $id);

    if (!$value || (ref $value eq 'HASH' && !keys %$value))
    {
        # Do nothing
    }
    elsif (!ref $value && defined $value) # Just ID
    {
        $id = $value;
    }
    elsif ($value->{value} && ref $value->{value} eq 'GADS::Record')
    {
        $record = $value->{value};
        $id = $record->current_id;
    }
    elsif (my $r = $value->{record})
    {
        $record = GADS::Record->new(
            schema               => $self->column->schema,
            layout               => $self->column->layout_parent,
            user                 => undef,
            record               => $r->{current}->{record_single},
            linked_id            => $r->{current}->{linked_id},
            parent_id            => $r->{current}->{parent_id},
            columns_retrieved_do => $self->column->curval_fields_retrieve,
        );
        $id = $r->{current_id};
    }
    else {
        panic "Unexpected value: $value";
    }
    ($record, $id);
}

1;
