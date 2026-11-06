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
package GADS::Helper::Pager;

use strict;
use warnings;

use Exporter qw/import/;

our @EXPORT_OK = qw(get_page);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

=head1 FUNCTIONS
=head2 get_page
Return items for a page - we start from the end and return the last $count+1 items
This is for Chronology paging - but I felt it may be useful elsewhere too.
=cut
sub get_page {
    my ($page, $size, @items) = @_;

    my $start = -(($page * $size) + 1);
    my $end = -((($page - 1) * $size) + 1);
    my @result = @items[ $start..$end ];
    return grep { defined } @result;
}

1;
