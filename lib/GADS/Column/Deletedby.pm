=pod
GADS - Globally Accessible Data Store
Copyright (C) 2019 Ctrl O Ltd

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

package GADS::Column::Deletedby;

use Log::Report 'linkspace';
use Moo;

extends 'GADS::Column::Person';

has '+value_field' => (
    default => 'deletedby',
);

sub _build_table
{   my $self = shift;
    'Current';
}

sub _build_sprefix
{   my $self = shift;
    'current';
}

has '+internal' => (
    default => 1,
);

has '+userinput' => (
    default => 0,
);

has '+hidden' => (
    default => 1,
);

sub tjoin
{   my $self = shift;
    'createdby';
}

1;
