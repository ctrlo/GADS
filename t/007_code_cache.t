use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use lib 't/lib';
use Test::GADS::DataSheet;

# Populate data with valid countries and not-valid countries. This will change
# the number of rows in the database when the return-type changes, as the
# non-valid countries will not be written
my $data = [
    {
        string1 => ['Albania','Bar2','Bar3'],
    },
    {
        string1 => ['Bar4'],
    },
];

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, data => []);
$curval_sheet->create_records;
my $curval_string = $curval_sheet->columns->{string1};
my $schema  = $curval_sheet->schema;

my $sheet   = Test::GADS::DataSheet->new(
    data             => $data,
    schema           => $schema,
    multivalue       => 1,
    curval           => 2,
    curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
    calc_code        => "
        function evaluate (L1string1)
            return L1string1
        end
    ",
    calc_return_type => 'string',
);
$sheet->create_records;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;

my $string1 = $columns->{string1};
my $calc1   = $columns->{calc1};
my $curval1 = $columns->{curval1};

my $autocur = $curval_sheet->add_autocur(
    refers_to_instance_id => 1,
    related_field_id      => $curval1->id,
    curval_field_ids      => [$string1->id],
);

# Add calc field to curval table with calc that refers back to main table
my $curval_calc = GADS::Column::Calc->new(
    schema      => $schema,
    user        => $sheet->user,
    layout      => $curval_sheet->layout,
    name        => 'Calc to main table',
    name_short  => 'L2calc2',
    return_type => 'string',
    code        => "function evaluate (L2autocur1)
        return L2autocur1[1].field_values.L1string1[1]
    end",
);
$curval_calc->set_permissions({$sheet->group->id => $sheet->default_permissions});
$curval_calc->write;

# Set up calc field to be editable, so that it changes when the main record is
# written to
$curval1->show_add(1);
$curval1->value_selector('noshow');
$curval1->write(no_alerts => 1);

$layout->clear;

# Check initial cached values
my $urs = $schema->resultset('CalcUnique')->search({ layout_id => $calc1->id });
is($urs->count, 4, "Correct number of values in cache");
my $expected = [qw/Albania Bar2 Bar3 Bar4/];
is_deeply([map $_->value_text, $urs->all], $expected, "Correct initial values for cached table");

# Make a change to single record
my $record = GADS::Record->new(
    user    => $sheet->user,
    layout  => $layout,
    schema  => $schema,
);
$record->find_current_id(2);
$record->fields->{$string1->id}->set_value("Bar5");
$record->write(no_alerts => 1);

is($urs->count, 4, "Correct number of values in cache after record write");
$expected = [qw/Albania Bar2 Bar3 Bar5/];
is_deeply([map $_->value_text, $urs->all], $expected, "Correct values for cached table and record write");

# Make a change to be same as existing value
$record->clear;
$record->find_current_id(2);
$record->fields->{$string1->id}->set_value("Bar3");
$record->write(no_alerts => 1);

is($urs->count, 3, "Correct number of values in cache after record write with existing");
$expected = [qw/Albania Bar2 Bar3/];
is_deeply([map $_->value_text, $urs->all], $expected, "Correct values for cached table with existing");

# Add it back in
$record->clear;
$record->find_current_id(2);
$record->fields->{$string1->id}->set_value("Bar6");
$record->write(no_alerts => 1);

is($urs->count, 4, "Correct number of values in cache after record write with new");
$expected = [qw/Albania Bar2 Bar3 Bar6/];
is_deeply([map $_->value_text, $urs->all], $expected, "Correct values for cached table with new");

# Change return type to Globe - same storage field in database
$calc1->code("function evaluate (L1string1) \n return L1string1 \nend");
$calc1->return_type('globe');
$calc1->write;

is($urs->count, 1, "Correct number of values in cache after change to globe");
$expected = [qw/Albania/];
is_deeply([map $_->value_text, $urs->all], $expected, "Correct values after change to globe");

# Change return type to different database field
$calc1->code("function evaluate (_id) \n return {10,20,30} \nend");
$calc1->return_type('integer');
$calc1->write;

is($urs->count, 3, "Correct number of values in cache after change to int");
$expected = [qw/10 20 30/];
is_deeply([map $_->value_int, $urs->all], $expected, "Correct values for cached table after change to int");

# Test changes to editable curval. These tests make sure that if a curval is
# edited from a main record that its cached unique values are stored correctly.
# The tests edit the curval from the main record, and reuse (and disuse) values
# that are common across different records in the main table
{
    $record->clear;
    $record->find_current_id(2);
    my $curval_datum = $record->fields->{$curval1->id};
    $curval_datum->set_value([$curval_string->field."=foo55"]);
    $record->write(no_alerts => 1);

    $urs = $schema->resultset('CalcUnique')->search({ layout_id => $curval_calc->id });
    $expected = [qw/Bar6/];
    is_deeply([map $_->value_text, $urs->all], $expected, "Correct values for cached table after change to int");

    $record->clear;
    $record->find_current_id(2);
    $record->fields->{$string1->id}->set_value('Bar7');
    $record->write(no_alerts => 1);

    $urs = $schema->resultset('CalcUnique')->search({ layout_id => $curval_calc->id });
    $expected = [qw/Bar7/];
    is_deeply([map $_->value_text, $urs->all], $expected, "Correct values for cached table after change to int");

    $record->clear;
    $record->find_current_id(1);
    $curval_datum = $record->fields->{$curval1->id};
    $curval_datum->set_value([$curval_string->field."=foo56"]);
    $record->fields->{$string1->id}->set_value('Bar7');
    $record->write(no_alerts => 1);

    $urs = $schema->resultset('CalcUnique')->search({ layout_id => $curval_calc->id });
    $expected = [qw/Bar7/];
    is_deeply([map $_->value_text, $urs->all], $expected, "Correct values for cached table after change to int");

    $record->clear;
    $record->find_current_id(1);
    $record->fields->{$string1->id}->set_value('Bar8');
    $record->write(no_alerts => 1);

    $urs = $schema->resultset('CalcUnique')->search({ layout_id => $curval_calc->id });
    $expected = [qw/Bar7 Bar8/];
    is_deeply([map $_->value_text, $urs->all], $expected, "Correct values for cached table after change to int");
}

done_testing();
