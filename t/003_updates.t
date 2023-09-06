use Test::More; # tests => 1;
use strict;
use warnings;

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime
use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use lib 't/lib';
use Test::GADS::DataSheet;

set_fixed_time('10/10/2014 01:00:00', '%m/%d/%Y %H:%M:%S'); # Write initial values as this date

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
        curval1    => 2,
        curval2    => 1,
    },
    {
        integer1 => 45,
        curval1  => 1,
    },
];

my @update1 = (
    {
        updates => [
            {
                string1    => 'Foo',
                integer1   => 20,
                date1      => '2010-10-10',
                daterange1 => ['', ''],
                enum1      => 8,
                tree1      => 12,
                curval1    => 1,
                curval2    => 1,
            },
        ],
        autocur_value => 'Foo, 20, foo2, tree3, 2010-10-10, , , , a_grey, ; , 45, , , , , , , a_grey, ',
        autocur_value2 => '',
    },
    {
        updates => [
            {
                curval1 => undef,
                curval2 => undef,
            },
            {
                curval1 => undef,
            },
        ],
        autocur_value => '',
        autocur_value2 => '',
    },
    {
        updates => [
            {
                string1    => 'Bar',
                integer1   => 30,
                date1      => '2014-10-10',
                daterange1 => ['2014-03-21', '2015-03-01'],
                enum1      => 7,
                tree1      => 11,
                curval1    => 1,
                curval2    => 1,
            },
            {
                curval1 => [1, 2],
            },
        ],
        autocur_value => 'Bar, 30, foo1, tree2, 2014-10-10, 2014-03-21 to 2015-03-01, , , d_green, 2014; , 45, , , , , , , a_grey, ',
        autocur_value2 => ', 45, , , , , , , a_grey, ',
    },
);

my $data2 = [
    {
        string1    => 'FooBar1',
    },
    {
        string1    => 'FooBar2',
    },
];

my @update2 = (
    {
        updates => {
            string1    => 'FooBar2',
        },
        curval1_string => 'FooBar2, , , , , , , , a_grey, ',
        curval2_string => 'FooBar2, , , , , , , , a_grey, ',
    },
    {
        updates => {
            string1    => 'FooBar3',
        },
        curval1_string => 'FooBar3, , , , , , , , a_grey, ',
        curval2_string => 'FooBar3, , , , , , , , a_grey, ',
    },
);

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, data => $data2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = Test::GADS::DataSheet->new(
    data         => $data1,
    schema       => $schema,
    curval       => 2,
    multivalue   => 1,
    column_count => {
        enum   => 1,
        curval => 2, # Test for correct number of record_later searches
    },
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;
my $user = $sheet->user;
# Add autocur field
my $autocur1 = $curval_sheet->add_autocur(refers_to_instance_id => 1, related_field_id => $columns->{curval1}->id);

# Check initial content of single record
my $record_single = GADS::Record->new(
    user   => $user,
    layout => $layout,
    schema => $schema,
);
is( $record_single->find_current_id(3)->current_id, 3, "Retrieved record from main table" );
my $curval1_id = $columns->{curval1}->id;
my $curval2_id = $columns->{curval2}->id;
is( $record_single->fields->{$curval1_id}->as_string, 'FooBar2, , , , , , , , a_grey, ', "Correct initial curval1 value from main table");
is( $record_single->fields->{$curval2_id}->as_string, 'FooBar1, , , , , , , , a_grey, ', "Correct initial curval2 value from main table");
# $record->clear;

my $records = GADS::Records->new(
    user    => $user,
    layout  => $layout,
    schema  => $schema,
);

is ($records->count, 2, 'Correct count of results initially');
is (@{$records->results}, 2, 'Correct number of results initially');

# Set up curval record
my $record_curval = GADS::Record->new(
    user    => $user,
    layout  => $curval_sheet->layout,
    schema  => $schema,
);
$record_curval->find_current_id(1);

# Check autocur value of curval sheet
is( $record_curval->fields->{$autocur1->id}->as_string, ', 45, , , , , , , a_grey, ', "Autocur value correct initially");

# First updates to the main sheet
foreach my $test (@update1)
{
    $records->clear;
    foreach my $update (@{$test->{updates}})
    {
        my $record = $records->single;
        foreach my $column (keys %$update)
        {
            my $field = $columns->{$column}->id;
            my $datum = $record->fields->{$field};
            $datum->set_value($update->{$column});
        }
        $record->write(no_alerts => 1);
        is ($records->count, 2, 'Count of records still correct after value update');
        is (@{$records->results}, 2, 'Number of actual records still correct after value update');
    }
    # Check autocur value of curval sheet after updates
    $record_curval->clear;
    $record_curval->find_current_id(1);
    is( $record_curval->fields->{$autocur1->id}->as_string, $test->{autocur_value}, "Autocur value correct after first updates");
    # And same but accessed via GADS::Records
    # This tests that fetch_multivalues correctly retrieves multiple values for
    # multiple records (both curval records are referred to by the first main
    # sheet record)
    my $records2 = GADS::Records->new(
        schema => $schema,
        layout => $curval_sheet->layout,
        user   => $user,
    );
    # First curval record (ID 1)
    my $record_curval_single = $records2->single;
    is( $record_curval_single->fields->{$autocur1->id}->as_string, $test->{autocur_value}, "Autocur value correct after first - record 1");
    # Second curval record (ID 2)
    $record_curval_single = $records2->single;
    is( $record_curval_single->fields->{$autocur1->id}->as_string, $test->{autocur_value2}, "Autocur value correct after first - record 2");
}

# Then updates to the curval sheet. We need to check the number
# of records in both sheets though.

foreach my $update (@update2)
{
    my $updates = $update->{updates};
    foreach my $column (keys %$updates)
    {
        my $field = $curval_sheet->columns->{$column}->id;
        my $datum = $record_curval->fields->{$field};
        $datum->set_value($updates->{$column});
    }
    $record_curval->write(no_alerts => 1);
    $records->clear;
    is ($records->count, 2, 'Count of sheet 1 records still correct after value update');
    is (@{$records->results}, 2, 'Number of actual sheet 1 records still correct after value update');

    my $records_curval = GADS::Records->new(
        user    => $user,
        layout  => $curval_sheet->layout,
        schema  => $schema,
    );
    is ($records_curval->count, 2, 'Count of curval sheet records still correct after value update');
    is (@{$records_curval->results}, 2, 'Number of actual curval sheet records still correct after value update');

    $record_single->clear;
    is( $record_single->find_current_id(3)->current_id, 3, "Retrieved record from main table after curval update" );
    is( $record_single->fields->{$curval1_id}->as_string, $update->{curval1_string}, "Correct curval1 value from main table after update");
    is( $record_single->fields->{$curval2_id}->as_string, $update->{curval2_string}, "Correct curval2 value from main table after update");
}

# Test forget_history functionality
{
    $schema->resultset('Instance')->find($layout->instance_id)->update({
        forget_history => 1,
    });
    $layout->clear;
    my $versions_before = $schema->resultset('Record')->count;
    my $record = GADS::Record->new(
        user   => $user,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id(3);
    like($record->created, qr/2014/, "Record version is old date");
    $record->fields->{$columns->{string1}->id}->set_value("Foobar");
    # Write with a new date that we can check
    set_fixed_time('10/10/2015 01:00:00', '%m/%d/%Y %H:%M:%S');
    $record->write(no_alerts => 1);
    my $versions_after = $schema->resultset('Record')->count;
    is($versions_after, $versions_before, "No new versions written");
    $record->clear;
    $record->find_current_id(3);
    like($record->created, qr/2015/, "Record version is new date");

    # Make sure version history still written for other sheet
    my $record_curval = GADS::Record->new(
        user   => $user,
        layout => $curval_sheet->layout,
        schema => $schema,
    );
    $record_curval->find_current_id(1);
    $record_curval->fields->{$curval_sheet->columns->{string1}->id}->set_value("Foobar2");
    $record_curval->write(no_alerts => 1);
    $versions_after = $schema->resultset('Record')->count;
    is($versions_after, $versions_before + 1, "One new version written");

    # Revert to normal functionality
    $schema->resultset('Instance')->find($layout->instance_id)->update({
        forget_history => 0,
    });
    $layout->clear;
    $versions_before = $schema->resultset('Record')->count;
    $record->clear;
    $record->find_current_id(3);
    $record->fields->{$columns->{string1}->id}->set_value("Foobar3");
    $record->write(no_alerts => 1);
    $versions_after = $schema->resultset('Record')->count;
    is($versions_after, $versions_before + 1, "One new version written");
}

# Test changes of curval edits
{
    my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
    $curval_sheet->create_records;
    my $curval_columns = $curval_sheet->columns;
    my $schema  = $curval_sheet->schema;
    my $sheet   = Test::GADS::DataSheet->new(
        data => [{
            curval1 => [1, 2],
        }],
        schema           => $schema,
        curval           => 2,
        curval_field_ids => [ $curval_sheet->columns->{string1}->id ]
    );
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;
    $sheet->create_records;
    my $curval = $columns->{curval1};
    my $string = $columns->{string1};
    $curval->show_add(1);
    $curval->value_selector('noshow');
    $curval->write(no_alerts => 1);

    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id(3);
    my $curval_datum = $record->fields->{$curval->id};
    is($curval_datum->as_string, "Foo; Bar", "Initial value of curval correct");

    $curval_datum->set_value([1, 2]);
    ok(!$curval_datum->changed, "Curval not changed with same ID");
    my $stringf = $curval_columns->{string1}->field;
    $curval_datum->set_value([$stringf.'=Foo&current_id=1', $stringf.'=Bar&current_id=2']);
    ok(!$curval_datum->changed, "Curval not changed with same content");
    $curval_datum->set_value([$stringf.'=Foobar&current_id=1', $stringf.'=Bar&current_id=2']);
    ok($curval_datum->changed, "Curval changed with HTML update");
}

done_testing();
