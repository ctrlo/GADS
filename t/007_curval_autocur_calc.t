use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Test to ensure that calc fields in an autocur that depends on a curval are
# updated correctly when the autocur record is updated

# Data for curval sheet
my $data = [
    {
        string1 => 'bar1',
    },
    {
        string1 => 'bar2',
    },
];
my $curval_sheet = Test::GADS::DataSheet->new(
    instance_id => 2,
);
$curval_sheet->create_records;
my $curval_layout = $curval_sheet->layout;
my $schema = $curval_sheet->schema;

# Data for main sheet
$data = [
    {
        string1 => 'foo1',
        date1   => '2010-10-10',
        curval1 => [1,2],
    },
];

# Main sheet
my $sheet   = Test::GADS::DataSheet->new(
    multivalue       => 1,
    data             => $data,
    schema           => $schema,
    curval           => 2,
    curval_field_ids => [$curval_sheet->columns->{string1}->id],
);
my $layout  = $sheet->layout;

# Autocur
my $autocur1 = $curval_sheet->add_autocur(
    refers_to_instance_id => 1,
    related_field_id      => $sheet->columns->{curval1}->id,
    curval_field_ids      => [$sheet->columns->{string1}->id],
);

my $columns = $sheet->columns;
my $string1 = $columns->{string1};
my $date1   = $columns->{date1};

# Calc for autocur. Return all string values from referred table
my $calc_curval = $curval_sheet->columns->{calc1};
$calc_curval->code('
    function evaluate (L2autocur1)
        ret = ""
        for _,val in ipairs(L2autocur1) do
            ret = ret .. val.field_values.L1string1[1]
        end
        return ret
    end');
$calc_curval->return_type('string');
$calc_curval->write;

# Second calc to show whether record has been re-evaluated when it shouldn't be
my $calc_curval2 = GADS::Column::Calc->new(
    schema      => $schema,
    user        => $sheet->user,
    layout      => $curval_sheet->layout,
    name        => 'calc2',
    name_short  => 'L2calc2',
    return_type => 'string',
    code        => qq(function evaluate (L2autocur1)
        return os.time()
    end),
);
$calc_curval2->set_permissions({$sheet->group->id => $sheet->default_permissions});
$calc_curval2->write;

$layout->clear;

$sheet->create_records;
my $curval = $columns->{curval1};

my $record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $curval_layout,
);

# Test that initial calc values are correct, each sub-record being referred
# from one other record
$record->find_current_id(1);
is($record->fields->{$calc_curval->id}->as_string, 'foo1', "Calc value from first autocur correct");

# Write value in main record that should be updated in curval records
$record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $layout,
);
$record->find_current_id(3);
$record->fields->{$string1->id}->set_value('foo2');
$record->write(no_alerts => 1);

# Load curval record and check
# First one
$record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $curval_layout,
);
$record->find_current_id(1);
is($record->fields->{$calc_curval->id}->as_string, 'foo2', "Calc value from first autocur correct");

# Second one
$record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $curval_layout,
);
$record->find_current_id(2);
is($record->fields->{$calc_curval->id}->as_string, 'foo2', "Calc value from first autocur correct");

# Now make a change to a field in the main record which should *not* result in
# the curval records being re-evaluated. To detect this, use the time value
# that is returned from the second calc
my $time = $record->fields->{$calc_curval2->id}->as_string;
sleep 3;

$record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $layout,
);
$record->find_current_id(3);
$record->fields->{$date1->id}->set_value('2022-04-03');
$record->write(no_alerts => 1);

$record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $curval_layout,
);
$record->find_current_id(1);
is($record->fields->{$calc_curval2->id}->as_string, $time, "Calc has not been re-evaluated");

done_testing();
