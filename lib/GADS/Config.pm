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

package GADS::Config;

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use Ouch;
schema->storage->debug(1);

use GADS::Schema;

sub conf
{   my ($self, $update) = @_;

    if($update)
    {
        my $new->{homepage_text} = $update->{homepage_text};
        $new->{sort_layout_id} = $update->{sort_layout_id} || undef;
        $new->{sort_type} = $update->{sort_type} if $update->{sort_type};
        my $c = rset('Instance')->single;
        $c->update($new);
    }
    
    rset('Instance')->single
        or ouch 'nosite', "No site configured";
}

1;

