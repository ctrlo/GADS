use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime

use JSON qw(encode_json);
use Log::Report;
use GADS::Record;

use lib 't/lib';
use Test::GADS::DataSheet;

my $sheet   = Test::GADS::DataSheet->new;
my $schema  = $sheet->schema;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $date = $columns->{date1};

# Test default date

my $record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $layout,
);

$record->initialise;

is($record->fields->{$date->id}->as_string, "", "Date blank by default");

# Make date field default to today
set_fixed_time('10/10/2014 01:00:00', '%m/%d/%Y %H:%M:%S');

$date->default_today(1);
$date->write;
$layout->clear;
$record->clear;
$record->initialise(instance_id => 1);

is($record->fields->{$date->id}->as_string, "2014-10-10", "Date default to today");

# Write blank value and check it hasn't default to today
$record->fields->{$date->id}->set_value('');
$record->write(no_alerts => 1);
my $cid = $record->current_id;
$record->clear;
$record->find_current_id($cid);
is($record->fields->{$date->id}->as_string, "", "Date blank after write");

done_testing();
