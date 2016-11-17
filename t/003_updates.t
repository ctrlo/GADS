use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use t::lib::DataSheet;

# A number of tests to try updates to records, primarily concerned with making
# sure the relevant SQL joins pull out the correct number of records. If we get
# the joins and/or conditions wrong, then multiple versions of the same record
# can be pulleed out together. These tests include checking the master sheet
# when updating another sheet it references.

my $data1 = [
    {
        string1    => '',
        integer1   => 10,
        date1      => '',
        daterange1 => ['2011-10-10', '2011-10-12'],
        enum1      => 7,
        tree1      => 10,
        curval1    => 1,
    },
];

my @update1 = (
    {
        string1    => 'Foo',
        integer1   => 20,
        date1      => '2010-10-10',
        daterange1 => ['', ''],
        enum1      => 8,
        tree1      => 12,
        curval1    => 1,
    },
    {
        string1    => 'Bar',
        integer1   => 30,
        date1      => '2014-10-10',
        daterange1 => ['2014-03-21', '2015-03-01'],
        enum1      => 7,
        tree1      => 11,
        curval1    => 1,
    },
);

my $data2 = [
    {
        string1    => 'FooBar1',
    },
];

my @update2 = (
    {
        string1    => 'FooBar2',
    },
    {
        string1    => 'FooBar3',
    },
);

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2, data => $data2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = t::lib::DataSheet->new(data => $data1, schema => $schema, curval => 2);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $records = GADS::Records->new(
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);

is ($records->count, 1, 'Correct count of results initially');
is (@{$records->results}, 1, 'Correct number of results initially');

my $record = $records->single;

# First updates to the main sheet

foreach my $update (@update1)
{
    foreach my $column (keys %$update)
    {
        my $field = $columns->{$column}->id;
        my $datum = $record->fields->{$field};
        $datum->set_value($update->{$column});
    }
    $record->write(no_alerts => 1);
    is ($records->count, 1, 'Count of records still correct after value update');
    is (@{$records->results}, 1, 'Number of actual records still correct after value update');
}

# Then updates to the curval sheet. We need to check the number
# of records in both sheets though.
my $records_curval = GADS::Records->new(
    user    => undef,
    layout  => $curval_sheet->layout,
    schema  => $schema,
);
my $record_curval = $records_curval->single;

foreach my $update (@update2)
{
    foreach my $column (keys %$update)
    {
        my $field = $curval_sheet->columns->{$column}->id;
        my $datum = $record_curval->fields->{$field};
        $datum->set_value($update->{$column});
    }
    $record_curval->write(no_alerts => 1);
    $records->clear; $records_curval->clear;
    is ($records->count, 1, 'Count of sheet 1 records still correct after value update');
    is (@{$records->results}, 1, 'Number of actual sheet 1 records still correct after value update');
    is ($records_curval->count, 1, 'Count of curval sheet records still correct after value update');
    is (@{$records_curval->results}, 1, 'Number of actual curval sheet records still correct after value update');
}

done_testing();
