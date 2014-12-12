#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Event::Random;

my @title = (
    "Driver Safety",
    "Fire Safety Training",
    "DSE and Office Ergonomics",
    "Risk Management",
    "First Aid at Work",
    "Infection Control",
    "Stress at Work",
    "Food Hygiene Professional",
    "Slips Trips Falls",
    "Manual Handling and Risk Assessment",
    "Infection Control"
);

my @country = qw(
    China
    India
    Japan
    Mongolia
    Nepal
    Oman
    Pakistan
    Thailand
    Yemen
    Austria
    Bulgaria
    Finland
    France
    Germany
    Greece
    Ireland
    Italy
    Netherlands
    Sweden
    Switzerland
    UK
);

my @department = qw(
    Finance
    Marketing
    Engineering
);

my $start = DateTime->new(
      year       => 2013,
      month      => 10,
      day        => 16,
);

my $end = DateTime->new(
      year       => 2015,
      month      => 8,
      day        => 23,
);

print "Title,Description,Country,Estimated cost,Actual cost,Number of people,Date range,Date range,Department\n";

for (1..1000)
{
    my $title       = $title[int(rand(@title))];
    my $description = "$title training course";
    my $country     = $country[int(rand(@country))];
    my $est_cost    = int(rand(100000));
    my $actual_cost = int(rand(100000));
    my $people      = int(rand(11));

    my $from       = DateTime::Event::Random->datetime( after => $start, before => $end );
    my $duration   = int(rand(61));
    my $to         = $from->clone->add( days => $duration );
    my $department = $department[int(rand(@department))];

    print "$title,$description,$country,$est_cost,$actual_cost,$people,".$from->ymd.",".$to->ymd.",$department\n";
}

