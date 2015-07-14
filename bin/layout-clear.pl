#!/usr/bin/perl

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

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use GADS::DB;
use GADS::Layout;

GADS::DB->setup(schema);

my $layout = GADS::Layout->new(user => undef, schema => schema);

my @columns;
my @all = reverse $layout->all(order_dependencies => 1);
foreach my $column (@all)
{
    say STDOUT "Deleting ".$column->name;
    $column->delete;
}

say STDERR "Deleting views...";
rset('User')->update({ lastview => undef });
rset('ViewLayout')->delete;
rset('Sort')->delete;
rset('AlertSend')->delete;
rset('Alert')->delete;
rset('AlertCache')->delete;
rset('View')->delete;

