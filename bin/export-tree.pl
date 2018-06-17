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
use Tree::DAG_Node;
use Encode;

schema->storage->debug(1);

my ($layout_id) = @ARGV;

$layout_id or die "Usage: $0 layout-id";

my $l = rset('Layout')->find($layout_id)
    or die "Layout ID $layout_id not found in database";

say STDERR "Using field ".$l->name;

my $original;

my $tree; my @order;

foreach my $enum (
    rset('Enumval')->search({
        'me.layout_id' => $layout_id,
        'me.deleted'   => 0,
    },{
        prefetch => 'parent',
        order_by => 'me.value',
    })->all
){
    my $parent = $enum->parent && $enum->parent->id;
    my $node = Tree::DAG_Node->new();
    $node->name($enum->value);
    $tree->{$enum->id} = {
        node   => $node,
        parent => $parent,
    };
    # Keep order in a list
    push @order, $enum->id;
}

my $root = Tree::DAG_Node->new();
$root->name("Root");

foreach my $n (@order)
{
    my $node = $tree->{$n};
    if (my $parent = $node->{parent})
    {
        $tree->{$parent}->{node}->add_daughter($node->{node});
    }
    else {
        $root->add_daughter($node->{node});
    }
}

foreach ($root->dump_names({indent => ',', tick => ''}))
{
    s/\\x26/&/g;
    s/\\x19/'/g;
    s/\\'/'/g;
    s/"/'/g;
    s/^(\h*)'/$1/g;
    s/'$//g;
    s/,'/,/g;
    print;
}

