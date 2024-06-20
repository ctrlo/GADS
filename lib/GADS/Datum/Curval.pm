
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
    $value = $value->{value}
        if ref $value eq 'HASH'
        && exists $value->{value}
        && (!defined $value->{value}
        || ref $value->{value} eq 'HASH'
        || ref $value->{value} eq 'GADS::Record');
    my ($record, $id);

    if (ref $value eq 'GADS::Record')
    {
        $record = $value;
        $id     = $value->current_id;
    }
    elsif (ref $value)
    {
        my $record_id;
        if (exists $value->{record_single})
        {
            $id        = $value->{record_single}->{current_id};
            $value     = $value->{record_single};
            $record_id = $value->{id};
        }
        else
        {
            $id        = $value->{value};
            $record_id = $value->{record_id};
        }
        my %params = (
            schema               => $self->column->schema,
            layout               => $self->column->layout_parent,
            user                 => undef,
            record               => $value,
            current_id           => $id,
            record_id            => $record_id,
            columns_retrieved_do => $self->column->curval_fields_retrieve,
            columns_retrieved_no => $self->column->curval_fields_retrieve,
        );

        # Do not set these values, as if the values do not exist then they will
        # not be lazily built
        $params{linked_id} = $value->{linked_id} if exists $value->{linked_id};
        $params{parent_id} = $value->{parent_id} if exists $value->{parent_id};
        $params{is_draft}  = $value->{draftuser_id}
            if exists $value->{draftuser_id};
        $record = GADS::Record->new(%params);
    }
    else
    {
        $id = $value if !ref $value && defined $value;    # Just ID
    }
    ($record, $id);
}

1;
