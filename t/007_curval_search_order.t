use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use GADS::Records;
use GADS::View;
use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Test to check that ordering by curval works correctly even when filtering on
# a curval field that is not displayed. This test was written to try and check
# for a bug where the filtered curval field was incorrectly added as a join at
# the prefetch, which resulted in records appearing multiple times.  However,
# it's not been possible to replicate it on the test system.  Postgresql was
# retrieving the records in a random order (only sorted on the curval displayed
# fields, not the extra field) which made the retrieval unpredictable. In any
# case, it is a worthwhile test so it remains here.

my $data1 = [
    {
        enum1   => [2,3],
        string1 => 'apple4',
    },
    {
        enum1   => [1,3],
        string1 => 'apple2',
    },
    {
        enum1   => [3],
        string1 => 'apple1',
    },
    {
        enum1   => [3,1],
        string1 => 'apple3',
    },
];

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, data => $data1, multivalue => 1);
$curval_sheet->create_records;
my @position = (
    $curval_sheet->columns->{enum1}->id,
    $curval_sheet->columns->{string1}->id,
);
$curval_sheet->layout->position(@position);
my $schema  = $curval_sheet->schema;

my $data2 = [
    {
        string1 => 'pear1',
        curval1 => 2,
    },
    {
        string1 => 'pear2',
        curval1 => 3,
    },
    {
        string1 => 'pear3',
        curval1 => 2,
    },
    {
        string1 => 'pear4',
        curval1 => 1,
    },
];

my $sheet = Test::GADS::DataSheet->new(
    data             => $data2,
    schema           => $schema,
    curval           => 2,
    curval_field_ids => [ $curval_sheet->columns->{string1}->id],#, $curval_sheet->columns->{enum1}->id ],
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;
@position = (
    $columns->{curval1}->id,
    $columns->{string1}->id,
);
$layout->position(@position);
$layout->clear;

my $rules = GADS::Filter->new(
    as_hash => {
        rules     => [
            {
                id       => $columns->{curval1}->id.'_'.$curval_sheet->columns->{enum1}->id,
                type     => 'string',
                value    => 'foo1',
                operator => 'equal',
            },
            {
                id       => $columns->{curval1}->id.'_'.$curval_sheet->columns->{enum1}->id,
                type     => 'string',
                value    => 'foo2',
                operator => 'equal',
            },
        ],
        condition => 'OR',
    },
);

my $view = GADS::View->new(
    name        => 'Curval search',
    filter      => $rules,
    columns     => [$columns->{curval1}->id, $columns->{string1}->id],
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $sheet->user,
);
$view->set_sorts({fields => [$columns->{curval1}->id], types => ['asc']});
$view->write;

my $records = GADS::Records->new(
    view   => $view,
    user   => $sheet->user,
    schema => $schema,
    layout => $layout,
);

is(@{$records->results}, 3, "Correct number of records with curval filter");
is($records->count, 3, "Correct record count with curval filter");
my $curid = $columns->{curval1}->id;
is($records->single->fields->{$curid}->as_string, "apple2", "Correct record curval value");
is($records->single->fields->{$curid}->as_string, "apple2", "Correct record curval value");
is($records->single->fields->{$curid}->as_string, "apple4", "Correct record curval value");

done_testing();
