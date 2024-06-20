
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

package GADS::Type::Permissions;

use GADS::Type::Permission;

sub all
{   map { GADS::Type::Permission->new(short => $_) } qw(
        read write_new write_existing approve_new approve_existing
        write_new_no_approval write_existing_no_approval
    );
}

sub permission
{   my $short = shift;
    GADS::Type::Permission->new(short => $short);
}

sub permission_mapping
{   +{ map { $_->short => $_->medium } all() };
}

sub permission_inputs
{   +{ map { $_->short => $_->long } all() };
}

1;
