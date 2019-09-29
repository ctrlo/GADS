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

package GADS::DateTime;

use DateTime::Format::CLDR;
use GADS::Config;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

sub parse_datetime
{   my $value = shift;
    return undef if !$value;
    return $value if ref $value eq 'DateTime';
    my $dateformat = GADS::Config->instance->dateformat;
    # If there's a space in the input value, assume it includes a time as well
    $dateformat .= ' HH:mm:ss' if $value =~ / /;
    my $cldr = DateTime::Format::CLDR->new(
        pattern => $dateformat,
    );
    $value && $cldr->parse_datetime($value);
}

1;

