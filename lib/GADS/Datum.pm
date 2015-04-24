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

package GADS::Datum;

use HTML::Entities;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

has record_id => (
    is => 'rw',
);

has current_id => (
    is => 'rw',
);

has column => (
    is => 'rw',
);

has changed => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has blank => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has init_no_value => (
    is  => 'rw',
    isa => Bool,
);

has oldvalue => (
    is  => 'rw',
);

sub html
{   my $self = shift;
    encode_entities $self->as_string;
}

sub clone
{   my ($self, @extra) = @_;
    # This will be called from a child class, in which case @extra can specify
    # additional attributes specific to that class
    ref($self)->new(
        column     => $self->column,
        record_id  => $self->record_id,
        current_id => $self->current_id,
        column     => $self->column,
        blank      => $self->blank,
        @extra
    );
}

1;

