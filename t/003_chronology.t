use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Test for chronology functionality, including permissions

my $data = [
    {
        string1  => 'Foo1',
        integer1 => 10,
    }
];

my $sheet = Test::GADS::DataSheet->new(data => $data, has_rag => 0);
$sheet->create_records;

my $schema  = $sheet->schema;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
my $user    = $sheet->user;
my $string1 = $columns->{string1};
my $integer1 = $columns->{integer1};

my $record = GADS::Record->new(
    user   => $user,
    layout => $layout,
    schema => $schema,
);
$record->find_current_id(1);

is($record->fields->{$string1->id}->as_string, 'Foo1', "Correct initial value of string");
is($record->fields->{$integer1->id}->as_string, '10', "Correct initial value of integer");

# First change
$record->fields->{$string1->id}->set_value('Foo2');
$record->fields->{$integer1->id}->set_value(20);
$record->write(no_alerts => 1);
$record->find_current_id(1);
is($record->fields->{$string1->id}->as_string, 'Foo2', "Change of string successful");
is($record->fields->{$integer1->id}->as_string, '20', "Change of integer successful");

# Second change
$record->fields->{$integer1->id}->set_value(30);
$record->write(no_alerts => 1);
$record->find_current_id(1);
is($record->fields->{$integer1->id}->as_string, '30', "Second change of integer successful");

$record->clear;

# Check changes as full user
{
    $record->find_chronology_id(1);

    my @changed = @{$record->chronology};
    is(@changed, 3, "Correct number of total versions");

    # Initial write
    my @changes = @{(shift @changed)->{changed}};
    is(@changes, 2, "Correct number of changes");
    my $changed_string = shift @changes;
    is($changed_string->{name_short}, 'L1string1', "Showing initial string as change");
    my $changed_integer = shift @changes;
    is($changed_integer->{name_short}, 'L1integer1', "Showing initial integer as change");

    # First change
    @changes = @{(shift @changed)->{changed}};
    is(@changes, 2, "Correct number of changes");
    $changed_string = shift @changes;
    is($changed_string->{name_short}, 'L1string1', "Showing change of string");
    $changed_integer = shift @changes;
    is($changed_integer->{name_short}, 'L1integer1', "Showing change of integer");

    # Second change
    @changes = @{(shift @changed)->{changed}};
    is(@changes, 1, "Correct number of changes");
    $changed_integer = shift @changes;
    is($changed_integer->{name_short}, 'L1integer1', "Showing change of integer in second edit");
}

# Check changes as user without permission on integer field
{
    $integer1->set_permissions({$sheet->group->id => []});
    $integer1->write;
    $layout->clear;
    $record->find_chronology_id(1);

    my @changed = @{$record->chronology};
    is(@changed, 2, "Correct number of total versions");

    # Initial write
    my @changes = @{(shift @changed)->{changed}};
    is(@changes, 1, "Correct number of changes");
    my $changed_string = shift @changes;
    is($changed_string->{name_short}, 'L1string1', "Showing initial string as change");

    # First change
    @changes = @{(shift @changed)->{changed}};
    is(@changes, 1, "Correct number of changes");
    $changed_string = shift @changes;
    is($changed_string->{name_short}, 'L1string1', "Showing change of string");

    # Second change not shown as integer not visible
}

#
done_testing();
