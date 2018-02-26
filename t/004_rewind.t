use Test::More; # tests => 1;
use strict;
use warnings;

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime
use DateTime;
use JSON qw(encode_json);
use Log::Report;
use GADS::Graph;
use GADS::Graph::Data;
use GADS::Record;
use GADS::Records;
use GADS::RecordsGroup;

use t::lib::DataSheet;

$ENV{GADS_NO_FORK} = 1;

my $data = [
    {
        string1  => 'Foo1',
        integer1 => 10,
    },
];

foreach my $multivalue (0..1)
{
    # We will use 3 dates for the data: all 10th October, but years 2014, 2015, 2016
    set_fixed_time('10/10/2014 01:00:00', '%m/%d/%Y %H:%M:%S');

    my $sheet = t::lib::DataSheet->new(data => $data, multivalue => $multivalue);
    $sheet->create_records;

    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $string1  = $sheet->columns->{string1};
    my $integer1 = $sheet->columns->{integer1};

    my $records = GADS::Records->new(
        user    => undef,
        layout  => $layout,
        schema  => $schema,
    );

    is($records->count, 1, "Correct number of records on initial creation");

    my $record = $records->single;

    # Make 2 further writes for subsequent 2 years
    set_fixed_time('10/10/2015 01:00:00', '%m/%d/%Y %H:%M:%S');
    $record->fields->{$string1->id}->set_value('Foo2');
    $record->fields->{$integer1->id}->set_value('20');
    $record->write;
    set_fixed_time('10/10/2016 01:00:00', '%m/%d/%Y %H:%M:%S');
    $record->fields->{$string1->id}->set_value('Foo3');
    $record->fields->{$integer1->id}->set_value('30');
    $record->write;

    # And a new record for the third year
    $record->remove_id;
    $record->fields->{$string1->id}->set_value('Foo10');
    $record->fields->{$integer1->id}->set_value('100');
    $record->write;

    $records->clear;
    is($records->count, 2, "Correct number of records for today after second write");

    # Go back to initial values (2014)
    my $previous = DateTime->new(
        year       => 2015,
        month      => 01,
        day        => 01,
        hour       => 12,
    );
    # Use rewind feature and check records are as they were on previous date
    $records = GADS::Records->new(
        user    => undef,
        layout  => $layout,
        schema  => $schema,
        rewind  => $previous,
    );
    is($records->count, 1, "Correct number of records for previous date (2014) $multivalue");

    $record = $records->single;

    is($record->fields->{$string1->id}->as_string, 'Foo1', "Correct old value for first record (2014)");

    # Go back to second set (2015)
    $previous->add(years => 1);
    $records = GADS::Records->new(
        user    => undef,
        layout  => $layout,
        schema  => $schema,
        rewind  => $previous,
    );
    is($records->count, 1, "Correct number of records for previous date (2015)");
    $record = $records->single;
    is($record->fields->{$string1->id}->as_string, 'Foo2', "Correct old value for first record (2015)");

    # And back to today
    $records = GADS::Records->new(
        user    => undef,
        layout  => $layout,
        schema  => $schema,
    );
    is($records->count, 2, "Correct number of records for current date");
    $record = $records->single;
    is($record->fields->{$string1->id}->as_string, 'Foo3', "Correct value for first record current date");

    # Retrieve single record
    $record = GADS::Record->new(
        user   => undef,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id(1);
    is($record->fields->{$string1->id}->as_string, 'Foo3', "Correct value for first record current date, single retrieve");
    $record = GADS::Record->new(
        user   => undef,
        layout => $layout,
        schema => $schema,
        rewind => $previous,
    );
    # First check record versions within current window
    $record->find_record_id(1);
    is($record->fields->{$string1->id}->as_string, 'Foo1', "Correct old value for first version");
    $record->clear;
    $record->find_record_id(2);
    is($record->fields->{$string1->id}->as_string, 'Foo2', "Correct old value for second version");
    $record->clear;
    # Check cannot retrieve latest version with rewind set as-is
    try { $record->find_record_id(3) };
    like($@, qr/Requested record not found/, "Cannot retrieve version after current rewind setting");
    $record->clear;
    # Check current version
    $record->find_current_id(1);
    is($record->fields->{$string1->id}->as_string, 'Foo2', "Correct old value for first record (2015), single retrieve");
    # Try an edit - should bork
    $record->fields->{$string1->id}->set_value('Bar');
    try { $record->write };
    ok($@, "Unable to write to record from historic retrieval");

    # Do a graph check from a rewind date
    my $graph = GADS::Graph->new(
        title        => 'Rewind graph',
        layout       => $layout,
        schema       => $schema,
        type         => 'bar',
        x_axis       => $string1->id,
        y_axis       => $integer1->id,
        y_axis_stack => 'sum',
    );
    $graph->write;
    $records = GADS::RecordsGroup->new(
        user    => undef,
        layout  => $layout,
        schema  => $schema,
    );
    my $graph_data = GADS::Graph::Data->new(
        id      => $graph->id,
        records => $records,
        schema  => $schema,
    );
    is_deeply($graph_data->xlabels, ['Foo10','Foo3'], "Graph labels for current date correct");
    is_deeply($graph_data->points, [[100,30]], "Graph data for current date correct");
    $records = GADS::RecordsGroup->new(
        user    => undef,
        layout  => $layout,
        schema  => $schema,
        rewind  => $previous,
    );
    $graph_data = GADS::Graph::Data->new(
        id      => $graph->id,
        records => $records,
        schema  => $schema,
    );
    is_deeply($graph_data->xlabels, ['Foo2'], "Graph data for previous date is correct");
    is_deeply($graph_data->points, [[20]], "Graph labels for previous date is correct");
}

restore_time();

done_testing();
