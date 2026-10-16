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
use GADS::RecordsGraph;

use lib 't/lib';
use Test::GADS::DataSheet;

$ENV{GADS_NO_FORK} = 1;

my $curval_data = [
    {
        string1 => 'Bar1',
    },
    {
        string1 => 'Bar2',
    },
    {
        string1 => 'Bar3',
    },
    {
        string1 => 'Bar4',
    },
];

my $data = [
    {
        # Be sure to test all fields, which will span across multiple database
        # fetches
        string1    => 'Foo1',
        integer1   => 10,
        enum1      => 7,
        tree1      => 10,
        curval1    => undef,
        date1      => '2024-10-10',
        daterange1 => ['2025-02-10', '2025-06-15'],
        person1    => 1,
    },
];

foreach my $multivalue (0..3)
{
    # multivalue 0 - neither
    # multivalue 1 - main only
    # multivalue 2 - curval only
    # multivalue 3 - both

    # We will use 3 dates for the data: all 10th October, but years 2014, 2015, 2016
    set_fixed_time('10/10/2014 01:00:00', '%m/%d/%Y %H:%M:%S');

    my $curval_sheet = Test::GADS::DataSheet->new(
        data        => $curval_data,
        multivalue  => $multivalue >= 2 ? 1 : 0,
        instance_id => 2,
    );
    $curval_sheet->create_records;
    my $schema = $curval_sheet->schema;

    my $sheet = Test::GADS::DataSheet->new(
        data             => $data,
        multivalue       => $multivalue == 1 || $multivalue == 3 ? 1 : 0,
        schema           => $schema,
        curval           => 2,
        curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
    );
    $sheet->create_records;

    my $layout     = $sheet->layout;
    my $string1    = $sheet->columns->{string1};
    my $integer1   = $sheet->columns->{integer1};
    my $enum1      = $sheet->columns->{enum1};
    my $tree1      = $sheet->columns->{tree1};
    my $curval1    = $sheet->columns->{curval1};
    my $date1      = $sheet->columns->{date1};
    my $daterange1 = $sheet->columns->{daterange1};
    my $person1    = $sheet->columns->{person1};

    # First check historical view on only one record (with blank curval value
    # to check for a subrecord that is completely missing and will therefore
    # not have a version date)
    my $previous = DateTime->new(
        year       => 2015,
        month      => 01,
        day        => 01,
        hour       => 12,
    );
    # Check with Records object and single Record
    my $records = GADS::Records->new(
        user    => $sheet->user,
        layout  => $layout,
        schema  => $schema,
        rewind  => $previous,
    );
    is($records->count, 1, "Correct number of records for previous date (2014)");
    my @records = ($records->single);
    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
        rewind => $previous,
    );
    $record->find_current_id(5);
    push @records, $record;

    # Check both, should be same
    foreach my $rec (@records)
    {
        is($rec->fields->{$string1->id}->as_string, 'Foo1', "Correct old value for first record (2014)");
        is($rec->fields->{$integer1->id}->as_string, '10', "Correct old value for first record (2014)");
        is($rec->fields->{$enum1->id}->as_string, 'foo1', "Correct old value for first record (2014)");
        is($rec->fields->{$tree1->id}->as_string, 'tree1', "Correct old value for first record (2014)");
        is($rec->fields->{$curval1->id}->as_string, '', "Correct old value for first record (2014)");
        is($rec->fields->{$date1->id}->as_string, '2024-10-10', "Correct old value for first record (2014)");
        is($rec->fields->{$daterange1->id}->as_string, '2025-02-10 to 2025-06-15', "Correct old value for first record (2014)");
        is($rec->fields->{$person1->id}->as_string, 'User1, User1', "Correct old value for first record (2014)");
    }

    # Now back to normal to make updates
    $records = GADS::Records->new(
        user    => $sheet->user,
        layout  => $layout,
        schema  => $schema,
    );

    is($records->count, 1, "Correct number of records on initial creation");
    $record = $records->single;

    # Make 2 further writes for subsequent 2 years
    set_fixed_time('10/10/2015 01:00:00', '%m/%d/%Y %H:%M:%S');
    $record->fields->{$string1->id}->set_value('Foo2');
    $record->fields->{$integer1->id}->set_value('20');
    $record->fields->{$enum1->id}->set_value('8');
    $record->fields->{$tree1->id}->set_value('11');
    $record->fields->{$curval1->id}->set_value('2');
    $record->fields->{$date1->id}->set_value('2024-11-10');
    $record->fields->{$daterange1->id}->set_value(['2025-03-10', '2025-07-15']);
    $record->fields->{$person1->id}->set_value('2');
    $record->write;
    set_fixed_time('10/10/2016 01:00:00', '%m/%d/%Y %H:%M:%S');
    $record->fields->{$string1->id}->set_value('Foo3');
    $record->fields->{$integer1->id}->set_value('30');
    $record->fields->{$enum1->id}->set_value('9');
    $record->fields->{$tree1->id}->set_value('12');
    $record->fields->{$curval1->id}->set_value('3');
    $record->fields->{$date1->id}->set_value('2024-12-10');
    $record->fields->{$daterange1->id}->set_value(['2025-04-10', '2025-08-15']);
    $record->fields->{$person1->id}->set_value('3');
    $record->write;

    # Make an update to the early curval record, this should not be seen in the
    # tests with the dates used
    my $curval_record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $curval_record->find_current_id(1);
    $curval_record->fields->{$curval_sheet->columns->{string1}->id}->set_value('Bar1a');
    $curval_record->write(no_alerts => 1);

    # And a new record for the third year
    $record->remove_id;
    $record->fields->{$string1->id}->set_value('Foo10');
    $record->fields->{$integer1->id}->set_value('100');
    $record->fields->{$enum1->id}->set_value('8');
    $record->fields->{$tree1->id}->set_value('10');
    $record->fields->{$curval1->id}->set_value('4');
    $record->fields->{$date1->id}->set_value('2024-12-15');
    $record->fields->{$daterange1->id}->set_value(['2025-05-10', '2025-09-15']);
    $record->fields->{$person1->id}->set_value('4');
    $record->write;

    $records->clear;
    is($records->count, 2, "Correct number of records for today after second write");

    # Go back to initial values (2014)
    $previous = DateTime->new(
        year       => 2015,
        month      => 01,
        day        => 01,
        hour       => 12,
    );
    # Use rewind feature and check records are as they were on previous date
    $records = GADS::Records->new(
        user    => $sheet->user,
        layout  => $layout,
        schema  => $schema,
        rewind  => $previous,
    );
    is($records->count, 1, "Correct number of records for previous date (2014)");

    $record = $records->single;

    is($record->fields->{$string1->id}->as_string, 'Foo1', "Correct old value for first record (2014)");
    is($record->fields->{$integer1->id}->as_string, '10', "Correct old value for integer (2014)");
    is($record->fields->{$enum1->id}->as_string, 'foo1', "Correct old value for enum (2014)");
    is($record->fields->{$tree1->id}->as_string, 'tree1', "Correct old value for tree (2014)");
    is($record->fields->{$curval1->id}->as_string, '', "Correct old value for curval (2014)");
    is($record->fields->{$date1->id}->as_string, '2024-10-10', "Correct old value for date (2014)");
    is($record->fields->{$daterange1->id}->as_string, '2025-02-10 to 2025-06-15', "Correct old value for daterange (2014)");
    is($record->fields->{$person1->id}->as_string, 'User1, User1', "Correct old value for person (2014)");

    # Go back to second set (2015)
    $previous->add(years => 1);
    $records = GADS::Records->new(
        user    => $sheet->user,
        layout  => $layout,
        schema  => $schema,
        rewind  => $previous,
    );
    is($records->count, 1, "Correct number of records for previous date (2015)");
    $record = $records->single;
    is($record->fields->{$string1->id}->as_string, 'Foo2', "Correct old value for first record (2015)");
    is($record->fields->{$integer1->id}->as_string, '20', "Correct old value for integer (2015)");
    is($record->fields->{$enum1->id}->as_string, 'foo2', "Correct old value for enum (2015)");
    is($record->fields->{$tree1->id}->as_string, 'tree2', "Correct old value for tree (2015)");
    is($record->fields->{$curval1->id}->as_string, 'Bar2', "Correct old value for curval (2015)");
    is($record->fields->{$date1->id}->as_string, '2024-11-10', "Correct old value for date (2015)");
    is($record->fields->{$daterange1->id}->as_string, '2025-03-10 to 2025-07-15', "Correct old value for daterange (2015)");
    is($record->fields->{$person1->id}->as_string, 'User2, User2', "Correct old value for person (2015)");

    # And back to today
    $records = GADS::Records->new(
        user    => $sheet->user,
        layout  => $layout,
        schema  => $schema,
    );
    is($records->count, 2, "Correct number of records for current date");
    $record = $records->single;
    is($record->fields->{$string1->id}->as_string, 'Foo3', "Correct value for first record current date");
    is($record->fields->{$integer1->id}->as_string, '30', "Correct value for integer current date");
    is($record->fields->{$enum1->id}->as_string, 'foo3', "Correct value for enum current date");
    is($record->fields->{$tree1->id}->as_string, 'tree3', "Correct value for tree current date");
    is($record->fields->{$curval1->id}->as_string, 'Bar3', "Correct value for curval current date");
    is($record->fields->{$date1->id}->as_string, '2024-12-10', "Correct value for date current date");
    is($record->fields->{$daterange1->id}->as_string, '2025-04-10 to 2025-08-15', "Correct value for daterange current date");
    is($record->fields->{$person1->id}->as_string, 'User3, User3', "Correct value for person current date");

    # Retrieve single record
    $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id(5);
    is($record->fields->{$string1->id}->as_string, 'Foo3', "Correct string value for first record current date, single retrieve");
    is($record->fields->{$integer1->id}->as_string, '30', "Correct integer value for first record current date, single retrieve");
    is($record->fields->{$enum1->id}->as_string, 'foo3', "Correct enum value for first record current date, single retrieve");
    is($record->fields->{$tree1->id}->as_string, 'tree3', "Correct tree value for first record current date, single retrieve");
    is($record->fields->{$curval1->id}->as_string, 'Bar3', "Correct curval value for first record current date, single retrieve");
    is($record->fields->{$date1->id}->as_string, '2024-12-10', "Correct date value for first record current date, single retrieve");
    is($record->fields->{$daterange1->id}->as_string, '2025-04-10 to 2025-08-15', "Correct daterange value for first record current date, single retrieve");
    is($record->fields->{$person1->id}->as_string, 'User3, User3', "Correct person value for first record current date, single retrieve");
    my $vs = join ' ', map { $_->created->ymd } $record->versions;
    is($vs, "2016-10-10 2015-10-10 2014-10-10", "All versions in live version");
    $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
        rewind => $previous,
    );
    # First check record versions within current window
    $record->find_record_id(5);
    is($record->fields->{$string1->id}->as_string, 'Foo1', "Correct old string value for first version");
    is($record->fields->{$integer1->id}->as_string, '10', "Correct old integer value for first version");
    is($record->fields->{$enum1->id}->as_string, 'foo1', "Correct old enum value for first version");
    is($record->fields->{$tree1->id}->as_string, 'tree1', "Correct old tree value for first version");
    is($record->fields->{$curval1->id}->as_string, '', "Correct old curval value for first version");
    is($record->fields->{$date1->id}->as_string, '2024-10-10', "Correct old date value for first version");
    is($record->fields->{$daterange1->id}->as_string, '2025-02-10 to 2025-06-15', "Correct old daterange value for first version");
    is($record->fields->{$person1->id}->as_string, 'User1, User1', "Correct old person value for first version");
    $vs = join ' ', map { $_->created->ymd } $record->versions;
    is($vs, "2015-10-10 2014-10-10", "Only first 2 versions in old version");
    $record->clear;
    $record->find_record_id(6);
    is($record->fields->{$string1->id}->as_string, 'Foo2', "Correct old string value for second version");
    is($record->fields->{$integer1->id}->as_string, '20', "Correct old integer value for second version");
    is($record->fields->{$enum1->id}->as_string, 'foo2', "Correct old enum value for second version");
    is($record->fields->{$tree1->id}->as_string, 'tree2', "Correct old tree value for second version");
    is($record->fields->{$curval1->id}->as_string, 'Bar2', "Correct old curval value for second version");
    is($record->fields->{$date1->id}->as_string, '2024-11-10', "Correct old date value for second version");
    is($record->fields->{$daterange1->id}->as_string, '2025-03-10 to 2025-07-15', "Correct old daterange value for second version");
    is($record->fields->{$person1->id}->as_string, 'User2, User2', "Correct old person value for second version");
    $record->clear;
    # Check cannot retrieve latest version with rewind set as-is
    try { $record->find_record_id(7) };
    like($@, qr/Requested record not found/, "Cannot retrieve version after current rewind setting");
    $record->clear;
    # Check current version
    $record->find_current_id(5);
    is($record->fields->{$string1->id}->as_string, 'Foo2', "Correct old string value for first record (2015), single retrieve");
    is($record->fields->{$integer1->id}->as_string, '20', "Correct old integer value for first record (2015), single retrieve");
    is($record->fields->{$enum1->id}->as_string, 'foo2', "Correct old enum value for first record (2015), single retrieve");
    is($record->fields->{$tree1->id}->as_string, 'tree2', "Correct old tree value for first record (2015), single retrieve");
    is($record->fields->{$curval1->id}->as_string, 'Bar2', "Correct old curval value for first record (2015), single retrieve");
    is($record->fields->{$date1->id}->as_string, '2024-11-10', "Correct old date value for first record (2015), single retrieve");
    is($record->fields->{$daterange1->id}->as_string, '2025-03-10 to 2025-07-15', "Correct old daterange value for first record (2015), single retrieve");
    is($record->fields->{$person1->id}->as_string, 'User2, User2', "Correct old person value for first record (2015), single retrieve");
    # Try an edit - should bork
    $record->fields->{$string1->id}->set_value('Bar');
    try { $record->write };
    ok($@, "Unable to write to record from historic retrieval");

    # Do a graph check from a rewind date
    my $graph = GADS::Graph->new(
        title        => 'Rewind graph',
        layout       => $layout,
        schema       => $schema,
        current_user => $sheet->user,
        type         => 'bar',
        x_axis       => $string1->id,
        y_axis       => $integer1->id,
        y_axis_stack => 'sum',
    );
    $graph->write;
    $records = GADS::RecordsGraph->new(
        user    => $sheet->user,
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
    $records = GADS::RecordsGraph->new(
        user    => $sheet->user,
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
