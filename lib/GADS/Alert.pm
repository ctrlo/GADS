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

package GADS::Alert;

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
schema->storage->debug(1);
use Ouch;
use Scalar::Util qw(looks_like_number);

sub alert
{
    my ($self, $view_id, $frequency, $user) = @_;

    # Check that user has access to this view (borks on no access)
    my $view = GADS::View->view($view_id, $user);

    if (looks_like_number $frequency)
    {
        ouch 'badparam', "Frequency value of $frequency is invalid"
            unless $frequency == 0 || $frequency == 24;
    }
    else {
        ouch 'badparam', "Frequency value of $frequency is invalid"
            unless !$frequency;
    }
        
    my ($alert) = rset('Alert')->search({
        view_id => $view_id,
        user_id => $user->{id},
    });

    if ($alert)
    {
        if ($frequency)
        {
            $alert->update({ frequency => $frequency });
        }
        else {
            $alert->delete;
        }
    }
    else {
        rset('Alert')->create({
            view_id   => $view_id,
            user_id   => $user->{id},
            frequency => $frequency,
        });
    }
}

1;

