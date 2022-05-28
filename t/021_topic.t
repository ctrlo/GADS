use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;


my $sheet   = Test::GADS::DataSheet->new;
my $schema  = $sheet->schema;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;

$sheet->create_records;

# Create 2 topics. One will be some initial summary fields. The other will
# contain an authorisation field. It will only be possible to edit the
# authorisation field once the summary is completed.
my $topic1 = $schema->resultset('Topic')->create({
    name        => 'Summary',
    instance_id => $layout->instance_id,
});

my $topic2 = $schema->resultset('Topic')->create({
    name        => 'Authorisation',
    instance_id => $layout->instance_id,
});

is($schema->resultset('Topic')->count, 2, "Correct number of topics created");

my $string1  = $columns->{string1};
my $integer1 = $columns->{integer1};
my $date1    = $columns->{date1};
foreach my $col ($string1, $integer1)
{
    $col->topic_id($topic1->id);
    $col->optional(0) unless $col->name eq 'date1'; # Test for optional field too
    $col->write;
}

my $enum1 = $columns->{enum1};
$enum1->topic_id($topic2->id);
$enum1->write;

# Check correct number of topics against fields
is($schema->resultset('Layout')->search({ topic_id => { '!=' => undef } })->count, 3, "Topics added to fields");

# Set up editing restriction
$topic1->prevent_edit_topic_id($topic2->id);
$topic1->update;

my $record = GADS::Record->new(
    user   => $sheet->user,
    layout => $layout,
    schema => $schema,
);
$record->initialise;

my $record_count = $schema->resultset('Current')->count;
# First try writing the record with the missing values
$record->fields->{$enum1->id}->set_value(2);
try { $record->write(no_alerts => 1) };
like($@, qr/until the following fields have been completed.*string1.*integer1/, "Unable to write with missing values");
is($schema->resultset('Current')->count, $record_count, "No new records created");

# Set one of the values, should be the same
$record->fields->{$string1->id}->set_value("Foobar");
try { $record->write(no_alerts => 1) };
like($@, qr/until the following fields have been completed.*integer1/, "Unable to write with missing values");

# Set the second one, should write now
$record->fields->{$integer1->id}->set_value(100);
try { $record->write(no_alerts => 1) };
ok(!$@, "Record written after values completed");
is($schema->resultset('Current')->count, $record_count + 1, "Current table has new record");
my $record_id = $record->current_id;
$record->clear;
$record->find_current_id($record_id);
my $fields = $record->fields;
is($fields->{$integer1->id}->as_string, 100, "Correct integer value after write");
is($fields->{$string1->id}->as_string, 'Foobar', "Correct string value after write");
is($fields->{$enum1->id}->as_string, 'foo2', "Correct enum value after write");

# Now blank a value, shouldn't be able to write again
$record->fields->{$integer1->id}->set_value('');
try { $record->write(no_alerts => 1) };
like($@, qr/until the following fields have been completed.*integer1/, "Unable to write with missing values");
# Remove enum value, should write
$record->fields->{$enum1->id}->set_value('');
try { $record->write(no_alerts => 1) };
ok(!$@, "Written record after setting dependent value to blank");

# Test deletion of table containing only topics
my $count = $schema->resultset('Instance')->count;
my $blank = GADS::Layout->new(
    name   => 'Temp',
    user   => $sheet->user,
    schema => $schema,
);
$blank->write;
is($schema->resultset('Instance')->count, $count + 1, "Table created");
my $topic = $schema->resultset('Topic')->create({
    name        => 'Temp',
    instance_id => $blank->instance_id,
});
$blank->delete;
is($schema->resultset('Instance')->count, $count, "Table deleted");

done_testing();
