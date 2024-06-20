
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

package GADS::RecordsGraph;

use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base     qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;

extends 'GADS::Records';

has '+group_values_as_index' => (default => 0,);

has '+is_group' => (default => 1,);

1;

