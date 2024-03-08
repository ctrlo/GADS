use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use lib 't/lib';
use Test::GADS::DataSheet;

# Populate data with valid countries and not-valid countries. This will change
# the number of rows in the database when the return-type changes, as the
# non-valid countries will not be written
my $data = [
    {
        string1 => ['Albania','Bar2','Bar3'],
    },
    {
        string1 => ['Bar4'],
    },
];

my $sheet   = Test::GADS::DataSheet->new(
    data             => $data,
    multivalue       => 1,
    calc_code        => "
        function evaluate (L1string1)
            return L1string1
        end
    ",
    calc_return_type => 'string',
);
$sheet->create_records;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
my $schema  = $sheet->schema;

my $string1 = $columns->{string1};
my $calc1 = $columns->{calc1};

# Check initial cached values
my $urs = $schema->resultset('CalcUnique');
is($urs->count, 4, "Correct number of values in cache");
my $expected = [qw/Albania Bar2 Bar3 Bar4/];
is_deeply([map $_->value_text, $urs->all], $expected, "Correct initial values for cached table");

# Make a change to single record
my $record = GADS::Record->new(
    user    => $sheet->user,
    layout  => $layout,
    schema  => $schema,
);
$record->find_current_id(2);
$record->fields->{$string1->id}->set_value("Bar5");
$record->write(no_alerts => 1);

is($urs->count, 4, "Correct number of values in cache after record write");
$expected = [qw/Albania Bar2 Bar3 Bar5/];
is_deeply([map $_->value_text, $urs->all], $expected, "Correct values for cached table and record write");

# Make a change to be same as existing value
$record->clear;
$record->find_current_id(2);
$record->fields->{$string1->id}->set_value("Bar3");
$record->write(no_alerts => 1);

is($urs->count, 3, "Correct number of values in cache after record write with existing");
$expected = [qw/Albania Bar2 Bar3/];
is_deeply([map $_->value_text, $urs->all], $expected, "Correct values for cached table with existing");

# Add it back in
$record->clear;
$record->find_current_id(2);
$record->fields->{$string1->id}->set_value("Bar6");
$record->write(no_alerts => 1);

is($urs->count, 4, "Correct number of values in cache after record write with new");
$expected = [qw/Albania Bar2 Bar3 Bar6/];
is_deeply([map $_->value_text, $urs->all], $expected, "Correct values for cached table with new");

# Change return type to Globe - same storage field in database
$calc1->code("function evaluate (L1string1) \n return L1string1 \nend");
$calc1->return_type('globe');
$calc1->write;

is($urs->count, 1, "Correct number of values in cache after change to globe");
$expected = [qw/Albania/];
is_deeply([map $_->value_text, $urs->all], $expected, "Correct values after change to globe");

# Change return type to different database field
$calc1->code("function evaluate (_id) \n return {10,20,30} \nend");
$calc1->return_type('integer');
$calc1->write;

is($urs->count, 3, "Correct number of values in cache after change to int");
$expected = [qw/10 20 30/];
is_deeply([map $_->value_int, $urs->all], $expected, "Correct values for cached table after change to int");

done_testing();
