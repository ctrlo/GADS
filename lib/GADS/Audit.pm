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

package GADS::Audit;

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use Ouch;
schema->storage->debug(1);

use GADS::Schema;

sub user_action
{   my ($self, $user_id, $description) = @_;

    rset('Audit')->create({
        user_id     => $user_id,
        description => $description,
        type        => 'user_action',
        datetime    => \"NOW()",
    });
}

sub login_change
{   my ($self, $user_id, $description) = @_;

    rset('Audit')->create({
        user_id     => $user_id,
        description => $description,
        type        => 'login_change',
        datetime    => \"NOW()",
    });
}

sub login_success
{   my ($self, $user_id, $username) = @_;

    rset('Audit')->create({
        user_id     => $user_id,
        description => "Successful login by username $username",
        type        => 'login_success',
        datetime    => \"NOW()",
    });
}

sub logout
{   my ($self, $user_id, $username) = @_;

    rset('Audit')->create({
        user_id     => $user_id,
        description => "Logout by username $username",
        type        => 'logout',
        datetime    => \"NOW()",
    });
}

sub login_failure
{   my ($self, $username) = @_;

    rset('Audit')->create({
        description => "Login failure using username $username",
        type        => 'login_failure',
        datetime    => \"NOW()",
    });
}

1;


