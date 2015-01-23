#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use DateTime::Event::Random;
use GADS::DB;
use GADS::Layout;
use Text::CSV;

GADS::DB->setup(schema);

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
    or die "Cannot use CSV: ".Text::CSV->error_diag ();

my $layout = GADS::Layout->new(user => undef, schema => schema);

my @row; my @columns;
foreach my $col ($layout->all)
{
    next if $col->type eq "file" || !$col->userinput;
    if ($col->type eq "daterange")
    {
        push @row, ($col->name, $col->name);
    }
    else {
        push @row, $col->name;
    }
    push @columns, $col;
}

my @rows = (\@row);

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

for (1..1000)
{
    my @row;
    foreach my $column (@columns)
    {
        next if $column->type eq "file" || !$column->userinput;
        if ($column->type eq "enum" || $column->type eq "tree")
        {
            push @row, $column->random;
        }
        elsif ($column->type eq "intgr")
        {
            push @row, int(rand(100000));
        }
        elsif ($column->type eq "date")
        {
            push @row, DateTime::Event::Random->datetime( after => $start, before => $end )->ymd;
        }
        elsif ($column->type eq "daterange")
        {
            my $date1 = DateTime::Event::Random->datetime( after => $start, before => $end );
            my $date2 = DateTime::Event::Random->datetime( after => $start, before => $end );
            ($date2, $date1) = ($date1, $date2) if DateTime->compare($date1, $date2) > 0;
            push @row, ($date1->ymd, $date2->ymd);
        }
        else {
            push @row, "String text";
        }
    }
    push @rows, \@row;
}

$csv->eol ("\n");
open my $fh, ">:encoding(utf8)", "new.csv" or die "new.csv: $!";
$csv->print ($fh, $_) for @rows;
close $fh or die "new.csv: $!";

