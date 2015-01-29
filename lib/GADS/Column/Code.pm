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

package GADS::Column::Code;

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

has write_cache => (
    is      => 'rw',
    default => 1,
);

sub update_cached
{   my ($self, $table) = @_;

    return unless $self->write_cache;

    $self->schema->resultset($table)->search({
        layout_id => $self->id,
    })->delete;

    # Need to refresh layout for updated calculation. Also
    # need it for the dependent fields
    my $layout = GADS::Layout->new(
        user   => $self->user,
        schema => $self->schema,
    );

    my $records = GADS::Records->new(
        user         => $self->user,
        layout       => $layout,
        schema       => $self->schema,
        force_update => 1,
    );
    my $depends = $self->depends_on;
    $records->search(
        columns => [@{$depends},$self->id],
    );
    # Force an update on each row
    foreach (@{$records->results})
    { $_->fields->{$self->id}->value }
};

1;

