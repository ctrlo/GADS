#!/usr/bin/perl
use strict;
use warnings;

use feature 'say';

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2::Plugin::DBIC;

say "Usage: ./delete-file.pl <current_id> <layout_id> [<layout id>...]" unless @ARGV > 1;
exit(1) unless @ARGV > 1;

my $current_id = shift(@ARGV);

my $total = 0;

my $current = schema->resultset('Current')->find($current_id);
my @records = $current->records->all;
my @values;

foreach my $layout (@ARGV) {
    push @values, $_->calcvals->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->dateranges->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->dates->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->enums->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->files->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->intgrs->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->people->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->ragvals->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->strings->search({ layout_id => $layout })->all foreach @records;
}

foreach my $value (@values) {
    $value->purge;
    $total++;
}

say "Purged $total records";
exit(0);
