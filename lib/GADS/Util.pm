
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

use warnings;
use strict;

package GADS::Util;

# Noddy email address validator. Not much point trying to be too clever here.
# We don't use Email::Valid, as that will check for RFC822 address as opposed
# to pure email address on its own.
sub email_valid
{   my ($class, $email) = @_;
    $email =~ m/^[=+\'a-z0-9._-]+@[a-z0-9.-]+\.[a-z]{2,10}$/i;
}

1;

