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

package GADS::Type::Permission;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use overload '""'  => 'long', fallback => 1;

has short => (
    is  => 'rw',
    isa => Maybe[Str],
);

sub long {
    my $self = shift;
    $self->short or return "";
      $self->short eq 'read'              ? 'Read values'
    : $self->short eq 'write_new'         ? 'Enter values for new records'
    : $self->short eq 'write_existing'    ? 'Edit values of existing records'
    : $self->short eq 'approve'           ? 'Approve values'
    : $self->short eq 'write_no_approval' ? 'Enter values without requiring approval'
    : '';
}

1;

