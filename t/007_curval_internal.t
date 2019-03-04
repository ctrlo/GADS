use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use t::lib::DataSheet;

# Tests to check that internal columns can be used in curval fields

my $data1 = [
    {
        string1 => 'foo1',
    },
];

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2, data => $data1);
$curval_sheet->create_records;
my $curval_string_id = $curval_sheet->columns->{string1}->id;
my $schema  = $curval_sheet->schema;

my $data2 = [
    {
        string1 => 'foo',
        curval1 => 1,
    },
];

my $sheet   = t::lib::DataSheet->new(
    data               => $data2,
    schema             => $schema,
    curval             => 1,
    curval_offset      => 6,
    curval_field_ids   => [
        $curval_sheet->columns->{string1}->id,
        $curval_sheet->layout->column_by_name_short('_serial')->id,
        $curval_sheet->layout->column_id->id,
    ],
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
my $curval  = $columns->{curval1};
$sheet->create_records;

my $record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $layout,
);
$record->find_current_id(2);

is($record->fields->{$curval->id}->as_string, "1, 1, foo1", "Curval with ID correct");


done_testing();
