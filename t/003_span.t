use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Filter;
use GADS::Records;

use lib 't/lib';
use Test::GADS::DataSheet;

# A test to span different fields across different pages (when retrieving by
# page).  This creates a number of fields that will span across multiple pages
# when all are retrieved. A sort and a filter is used (with different fields
# than those retrieved) to test that the right fields are fetched across the
# pages. A curval is used, positioned as such that it will drop into a
# different page once sort is included

my $data = [
    {
        string1    => 'Foo',
        integer1   => 10,
        date1      => '2010-10-10',
        enum1      => 'foo1',
        tree1      => 'tree1',
        curval1    => 1,
    },{
        string1    => 'Bar',
        integer1   => 20,
        date1      => '2012-10-10',
        enum1      => 'foo2',
        tree1      => 'tree3',
        curval1    => 2,
    }
];

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = Test::GADS::DataSheet->new(
    data         => $data,
    schema       => $schema,
    curval       => 2,
    instance_id  => 1,
    column_count => {
        string => 5,
    },
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my @position = (
        $columns->{enum1}->id,
        $columns->{string1}->id,
        $columns->{string2}->id,
        $columns->{string3}->id,
        $columns->{string4}->id,
        $columns->{string5}->id,
        $columns->{integer1}->id,
        $columns->{date1}->id,
        $columns->{daterange1}->id,
        $columns->{tree1}->id,
        $columns->{curval1}->id,
);
$layout->position(@position);
$layout->clear;

my $rules = GADS::Filter->new(
    as_hash => {
        rules => [
            {
                id       => $columns->{enum1}->id,
                type     => 'string',
                value    => 'foo1',
                operator => 'equal',
            },
        ],
    },
);
my $view = GADS::View->new(
    name        => 'Test view',
    filter      => $rules,
    columns     => [
        $columns->{string1}->id,
        $columns->{string2}->id,
        $columns->{string3}->id,
        $columns->{string4}->id,
        $columns->{string5}->id,
        $columns->{integer1}->id,
        $columns->{date1}->id,
        $columns->{daterange1}->id,
        $columns->{tree1}->id,
        $columns->{curval1}->id,
    ],
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $sheet->user,
);
# Add a sort to introduce a "hidden" field in the first page that would
# otherwise not be included
$view->set_sorts({fields => [$columns->{enum1}->id], types => ['asc']});
$view->write;

my $records = GADS::Records->new(
    user    => $sheet->user,
    view    => $view,
    layout  => $layout,
    schema  => $schema,
);

is( $records->count, 1, "Correct count of records");
is( @{$records->results}, 1, "Correct number of records returned");

done_testing();
