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
use MooX::Types::MooseLike::Base qw(Maybe Str);

use overload '""'  => 'long', fallback => 1;

has short => (
    is  => 'rw',
    isa => Maybe[Str],
);

sub long {
    my $self = shift;
    $self->short or return "";
      $self->short eq 'read'                       ? 'Values can be read'
    : $self->short eq 'write_new'                  ? 'Values can be written to new records'
    : $self->short eq 'write_existing'             ? 'Modifications can be made to existing records'
    : $self->short eq 'approve_new'                ? 'Values for new records can be approved'
    : $self->short eq 'approve_existing'           ? 'Modifications to existing records can be approved'
    : $self->short eq 'write_new_no_approval'      ? 'Values for new records do not require approval'
    : $self->short eq 'write_existing_no_approval' ? 'Modifications to existing records do not require approval'
    : '';
}

sub medium {
    my $self = shift;
    $self->short or return "";
      $self->short eq 'read'                       ? 'Read'
    : $self->short eq 'write_new'                  ? 'Write new'
    : $self->short eq 'write_existing'             ? 'Edit'
    : $self->short eq 'approve_new'                ? 'Approve new'
    : $self->short eq 'approve_existing'           ? 'Approve existing'
    : $self->short eq 'write_new_no_approval'      ? 'Write without approval'
    : $self->short eq 'write_existing_no_approval' ? 'Edit without approval'
    : '';
}

1;

