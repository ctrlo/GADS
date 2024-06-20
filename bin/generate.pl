#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2;
use Dancer2::Plugin::DBIC;
use DateTime::Event::Random;
use GADS::DB;
use GADS::Layout;
use Getopt::Long;
use Text::CSV;

my ($instance_id, $site_id);

GetOptions(
    'instance-id=s' => \$instance_id,
    'site-id=s'     => \$site_id,
) or exit;

$instance_id or die "Need instance ID with --instance-id";
$site_id     or die "Need site ID with --site-id";

GADS::DB->setup(schema);

GADS::Config->instance(config => config,);

schema->site_id($site_id);

my $csv = Text::CSV->new({ binary => 1 })    # should set binary attribute.
    or die "Cannot use CSV: " . Text::CSV->error_diag();

my $layout = GADS::Layout->new(
    user        => undef,
    schema      => schema,
    config      => config,
    instance_id => $instance_id,
);

my @row;
my @columns;
foreach my $col ($layout->all)
{
    next if $col->type eq "file" || !$col->userinput;
    push @row,     $col->name;
    push @columns, $col;
}

my @rows = (\@row);

my $start = DateTime->new(
    year  => 2013,
    month => 10,
    day   => 16,
);

my $end = DateTime->new(
    year  => 2020,
    month => 8,
    day   => 23,
);

my $config = GADS::Config->instance(
    config       => config,
    app_location => app->location,
);

my $dateformat = $config->dateformat;

for (1 .. 1000)
{
    my @row;
    foreach my $column (@columns)
    {
        next if $column->type eq "file" || !$column->userinput;
        if ($column->can('random'))
        {
            push @row, ($column->random || "");
        }
        elsif ($column->type eq "intgr")
        {
            push @row, int(rand(100000));
        }
        elsif ($column->type eq "date")
        {
            push @row,
                DateTime::Event::Random->datetime(
                    after  => $start,
                    before => $end
            )->format_cldr($dateformat);
        }
        elsif ($column->type eq "daterange")
        {
            my $date1 = DateTime::Event::Random->datetime(
                after  => $start,
                before => $end
            );
            my $date2 = DateTime::Event::Random->datetime(
                after  => $start,
                before => $end
            );
            ($date2, $date1) = ($date1, $date2)
                if DateTime->compare($date1, $date2) > 0;
            push @row,
                (     $date1->format_cldr($dateformat) . " - "
                    . $date2->format_cldr($dateformat));
        }
        else
        {
            push @row, "String text";
        }
    }
    push @rows, \@row;
}

$csv->eol("\n");
open my $fh, ">:encoding(utf8)", "new.csv" or die "new.csv: $!";
$csv->print($fh, $_) for @rows;
close $fh or die "new.csv: $!";

