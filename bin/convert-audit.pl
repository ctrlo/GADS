#!/bin/perl

use utf8;

use strict;
use warnings;

use Time::Piece;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2;
use Dancer2::Plugin::DBIC;

sub utc_to_local {
    my $utc_ts = shift;

    $utc_ts =~ s/^(\d{4}-\d{2}-\d{2}).(\d{2}:\d{2}:\d{2}).*$/$1 $2/ or die "Invalid date format: $utc_ts";
    my $utc_tp = Time::Piece->strptime( $utc_ts, '%Y-%m-%d %H:%M:%S' );
    my $local_tp = localtime( $utc_tp->epoch );
    return $local_tp->strftime( '%Y-%m-%d %H:%M:%S' );
}

my @records = schema->resultset('Audit')->all;

for my $record (@records) {
    my $utc_ts = $record->datetime;
    print "UTC time is $utc_ts\n";
    my $local_ts = utc_to_local( $utc_ts );
    print "Local time is $local_ts\n";
    $record->update( { datetime => $local_ts } );
}
