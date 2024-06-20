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

use Dancer2;
use Dancer2::Plugin::DBIC;
use GADS::Schema;
use Text::CSV;

my ($layout_id, $parent_top) = @ARGV;

$layout_id
    or die "Usage: $0 layout-id [parent-id] (use STDIN for the CSV data)";

my $l = rset('Layout')->find($layout_id)
    or die "Layout ID $layout_id not found in database";

say STDERR "Using field " . $l->name;

my $csv = Text::CSV->new({ binary => 1 })    # should set binary attribute?
    or die "Cannot use CSV: " . Text::CSV->error_diag();

my @parents;
while (<STDIN>)
{
    $csv->parse($_) or die "Failed to parse link $_";
    my @row = $csv->fields;

    my $count;
    foreach my $col (@row)
    {
        $count++;
        next unless $col;
        my $parent = $parents[ $count - 1 ] || $parent_top;
        $parent = rset('Enumval')->create({
            value     => $col,
            layout_id => $layout_id,
            parent    => $parent,
        })->id;
        $parents[$count] = $parent;
    }
}

