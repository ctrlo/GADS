#!/usr/bin/perl
use strict;
use warnings;

use feature 'say';

use FindBin;
use lib "$FindBin::Bin/../lib";

use Encode 'encode';

use Dancer2;
use Dancer2::Plugin::DBIC;

sub purge_file {
    my $file = shift;

    schema->txn_do(
        sub {
            my $value = $file->value;
            $value->update(
                {
                    name     => 'purged',
                    mimetype => 'text/plain',
                    content  => encode( 'utf-8', 'purged' ),
                }
            );
        }
    );
}

sub purge {
    my $value = shift;
    if ( ref $value eq 'GADS::Schema::Result::File' ) {
        purge_file $value;
    }
    else {
        say "Unknown type: " . ref $value;
        exit(2);
    }
    say "Deleted " . $value->id . "\n";
}

say "Usage: ./delete-file.pl <current_id> <layout_id> [<layout id>...]" unless @ARGV > 1;
exit(1) unless @ARGV > 1;

my $current_id = shift(@ARGV);

my $total = 0;

my $current = schema->resultset('Current')->find($current_id);
my @records = $current->records->all;
my @values;

foreach my $layout (@ARGV) {
    push @values, $_->files->search( { layout_id => $layout } )->all foreach @records;
}

purge $_ foreach @values;

exit(0);
