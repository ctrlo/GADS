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

package GADS::Datum::Curval;

use Moo;

extends 'GADS::Datum::Curcommon';

sub _transform_value
{   my ($self, $value) = @_;
    # XXX - messy to account for different initial values. Can be tidied once
    # we are no longer pre-fetching multiple records
    $value = $value->{value} if exists $value->{value}
        && (!defined $value->{value} || ref $value->{value} eq 'HASH' || ref $value->{value} eq 'GADS::Record');
    my ($record, $id);

    if (ref $value eq 'GADS::Record')
    {
        $record = $value;
        $id = $value->current_id;
    }
    elsif (ref $value)
    {
        $id = exists $value->{record_single} ? $value->{record_single}->{current_id} : $value->{value}; # XXX see above comment
        $record = GADS::Record->new(
            schema               => $self->column->schema,
            layout               => $self->column->layout_parent,
            user                 => undef,
            record               => exists $value->{record_single} ? $value->{record_single} : $value, # XXX see above comment
            current_id           => $id,
            linked_id            => $value->{linked_id},
            parent_id            => $value->{parent_id},
            columns_retrieved_do => $self->column->curval_fields_retrieve,
        );
    }
    else {
        $id = $value if !ref $value && defined $value; # Just ID
    }
    ($record, $id);
}

1;
