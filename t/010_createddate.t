use Test::More; # tests => 1;
use strict;
use warnings;

# Tests for timezones of record created dates. The general presumption should
# be that all times are stored in the database as UTC. When they are presented
# to the user, they should be shown in local time (currently only London).

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime

use GADS::Records;
use Log::Report;

use t::lib::DataSheet;

my $sheet   = t::lib::DataSheet->new(
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

is($record->fields->{$version->id}->values->[0]->hour, 12, "Correct version hour for standard time");
is($record->fields->{$created->id}->values->[0]->hour, 12, "Correct created hour for standard time");
is($record->fields->{$calc1->id}->as_string, 12, "Correct hour for standard time - calc");

# Update the record as if daylight saving time
set_fixed_time('06/01/2014 14:00:00', '%m/%d/%Y %H:%M:%S');

$record->fields->{$string1->id}->set_value('Foobar2');
$record->write(no_alerts => 1);
$record->clear;

$record->find_current_id(1);

is($record->fields->{$version->id}->values->[0]->hour, 15, "Correct hour for daylight saving time");
is($record->fields->{$created->id}->values->[0]->hour, 12, "Correct created hour for saving time");
is($record->fields->{$calc1->id}->as_string, 15, "Correct hour for daylight saving time - calc");

# Create new record in daylight saving time
set_fixed_time('06/01/2014 16:00:00', '%m/%d/%Y %H:%M:%S');

$record->clear;
$record->initialise;
$record->fields->{$string1->id}->set_value('Foobar3');
$record->write(no_alerts => 1);
$record->clear;
$record->find_current_id(2);

is($record->fields->{$version->id}->values->[0]->hour, 17, "Correct hour for daylight saving time");
is($record->fields->{$created->id}->values->[0]->hour, 17, "Correct created hour for saving time");
is($record->fields->{$calc1->id}->as_string, 17, "Correct hour for daylight saving time - calc");

done_testing();
