use Test::More; # tests => 1;
use strict;
use warnings;

# Tests for timezones of record created dates. The general presumption should
# be that all times are stored in the database as UTC. When they are presented
# to the user, they should be shown in local time (currently only London).

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime

use GADS::Records;
use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

my $sheet   = Test::GADS::DataSheet->new(
    data      => [],
    calc_code => "function evaluate (_version_datetime)
        return _version_datetime.hour
    end",
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
my $schema  = $sheet->schema;
my $string1 = $columns->{string1};
my $calc1   = $columns->{calc1};
my $version = $layout->column_by_name_short('_version_datetime');
my $created = $layout->column_by_name_short('_created');
$sheet->create_records;

# Create new record in standard time
set_fixed_time('01/01/2014 12:00:00', '%m/%d/%Y %H:%M:%S');

my $record = GADS::Record->new(
    layout => $layout,
    user   => $sheet->user,
    schema => $schema,
);
$record->initialise;
$record->fields->{$string1->id}->set_value('Foobar');
$record->write(no_alerts => 1);
$record->clear;

$record->find_current_id(1);

is($record->get_field_value($version)->values->[0]->hour, 12, "Correct version hour for standard time");
is($record->get_field_value($created)->values->[0]->hour, 12, "Correct created hour for standard time");
is($record->get_field_value($calc1)->as_string, 12, "Correct hour for standard time - calc");

# Update the record as if daylight saving time
set_fixed_time('06/01/2014 14:00:00', '%m/%d/%Y %H:%M:%S');

$record->fields->{$string1->id}->set_value('Foobar2');
$record->write(no_alerts => 1);
is($record->get_field_value($created)->as_string, '2014-01-01 12:00:00', "Record created time correct");
is($record->get_field_value($version)->as_string, '2014-06-01 15:00:00', "Record updated time correct");
$record->clear;

$record->find_current_id(1);

is($record->get_field_value($version)->values->[0]->hour, 14, "Correct hour for daylight saving time");
is($record->get_field_value($version)->as_string, '2014-06-01 15:00:00', "Correct hour for daylight saving time as display string");
is($record->get_field_value($created)->values->[0]->hour, 12, "Correct created hour for saving time");
is($record->get_field_value($created)->as_string, '2014-01-01 12:00:00', "Correct created hour for saving time");
is($record->get_field_value($calc1)->as_string, 15, "Correct hour for daylight saving time - calc");

# Create new record in daylight saving time
set_fixed_time('06/01/2014 16:00:00', '%m/%d/%Y %H:%M:%S');

$record->clear;
$record->initialise;
$record->fields->{$string1->id}->set_value('Foobar3');
$record->write(no_alerts => 1);
is($record->get_field_value($created)->values->[0]->hour, 16, "Correct hour in datum for daylight saving time");
is($record->get_field_value($created)->as_string, '2014-06-01 17:00:00', "Record created time display string correct");
is($record->get_field_value($version)->values->[0]->hour, 16, "Correct hour in version datum for daylight saving time");
is($record->get_field_value($version)->as_string, '2014-06-01 17:00:00', "Record updated time correct");
$record->clear;
$record->find_current_id(2);

# Check that the time has been stored in the database as UTC. This is ideally
# to check for a bug that resulted in it being inserted in DST, but
# unfortunately that bug is only exhibited in Pg not SQLite. Tests need to use
# Pg...
is($schema->resultset('Record')->find($record->record_id)->created, '2014-06-01T16:00:00', "Date insert into database as UTC");

is($record->get_field_value($version)->values->[0]->hour, 16, "Correct hour for daylight saving time");
is($record->get_field_value($created)->as_string, '2014-06-01 17:00:00', "Record created time display string correct");
is($record->get_field_value($created)->values->[0]->hour, 16, "Correct created hour for saving time");
is($record->get_field_value($version)->as_string, '2014-06-01 17:00:00', "Record updated time correct");
is($record->get_field_value($calc1)->as_string, 17, "Correct hour for daylight saving time - calc");

# Check that sorting by created field works
{
    # First ensure that we have more records than the standard page size of 100
    set_fixed_time('07/01/2014 16:00:00', '%m/%d/%Y %H:%M:%S');
    my $record = GADS::Record->new(
        layout => $layout,
        user   => $sheet->user,
        schema => $schema,
    );
    for (1..200)
    {
        $record->initialise(instance_id => 1);
        $record->fields->{$string1->id}->set_value('foobar4');
        $record->write(no_alerts => 1);
        $record->clear;
    }
    # Then add a later one one, which should appear at one end of the sort
    set_fixed_time('08/01/2014 16:00:00', '%m/%d/%Y %H:%M:%S');
    $record->initialise(instance_id => 1);
    $record->fields->{$string1->id}->set_value('foobar4');
    $record->write(no_alerts => 1);
    $record->clear;

    # Finally update the first record, so that it has the latest version time
    # but the earliest created time
    set_fixed_time('10/01/2014 14:00:00', '%m/%d/%Y %H:%M:%S');
    $record->find_current_id(1);
    $record->fields->{$string1->id}->set_value('Foobar5');
    $record->write(no_alerts => 1);

    my $view = GADS::View->new(
        name        => 'Test view',
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view->set_sorts({fields => [$created->id], types => ['asc']});
    $view->write;

    my $records = GADS::Records->new(
        user    => $sheet->user,
        view    => $view,
        layout  => $layout,
        schema  => $schema,
    );

    is($records->single->current_id, 1, "First record correct (ascending)");
    $view->set_sorts({fields => [$created->id], types => ['desc']});
    $view->write;
    $records->clear;
    is($records->single->current_id, 203, "First record correct (descending)");
}

# Test searching by created time
{
    my $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $created->id,
                type     => 'string',
                value    => '2014-01-01 12:00:00',
                operator => 'equal',
            }],
        },
    );
    my $view = GADS::View->new(
        name        => 'Test view',
        filter      => $rules,
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view->write;

    my $records = GADS::Records->new(
        user    => $sheet->user,
        view    => $view,
        layout  => $layout,
        schema  => $schema,
    );

    is($records->count, 1, "Correct number of records for search by created user");
    is($records->single->current_id, 1, "Record correct, search by created user");
}
done_testing();
