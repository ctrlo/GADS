#!/usr/bin/perl
use strict;
use warnings;

use feature 'say';

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2::Plugin::DBIC;

use GADS::Purge::Purger;

say "Usage: ./delete-file.pl <layout_id> <current_id> [<current_id> ...]" unless @ARGV > 1;
exit(1) unless @ARGV > 1;

my $layout_id = shift(@ARGV);

my $total = 0;

foreach my $current_id (@ARGV) {
    my $current = schema->resultset('Current')->find($current_id);
    my $record_id = $current->record_id;
    my $purger= GADS::Purge::Purger->new(
        schema => schema,
        record_id => $record_id,
        layout_id => $layout_id,
    );
    $total += $purger->purge;
}

say "Purged $total records";
exit(0);