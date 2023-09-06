use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Test 2 autocur fields back to the same sheet, both referred to with separate
# calc fields.

my $curval_sheet = Test::GADS::DataSheet->new(
    instance_id => 2,
);
$curval_sheet->create_records;
my $schema = $curval_sheet->schema;

# Curval sheet
my $data = [
    {
        string1 => 'foo1',
        date1   => '2010-10-10',
        curval1 => 1,
    },
    {
        string1 => 'foo2',
        date1   => '2009-10-10',
        curval1 => 2,
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

# First autocur
my $autocur1 = $curval_sheet->add_autocur(
    refers_to_instance_id => 1,
    related_field_id      => $sheet->columns->{curval1}->id,
    curval_field_ids      => [$sheet->columns->{string1}->id],
);

# Second autocur
my $autocur2 = $curval_sheet->add_autocur(
    refers_to_instance_id => 1,
    related_field_id      => $sheet->columns->{curval1}->id,
    curval_field_ids      => [$sheet->columns->{date1}->id],
);

my $columns = $sheet->columns;

# Calc for first autocur. Return all string values from referred table
my $calc = $curval_sheet->columns->{calc1};
$calc->code('
    function evaluate (L2autocur1)
        ret = ""
        for _,val in ipairs(L2autocur1) do
            ret = ret .. val.field_values.L1string1[1]
        end
        return ret
    end');
$calc->return_type('string');
$calc->write;

# Calc for second autocur, same as first
my $calc2 = GADS::Column::Calc->new(
    schema      => $schema,
    user        => $sheet->user,
    layout      => $curval_sheet->layout,
    name        => 'calc2',
    name_short  => 'L2calc2',
    return_type => 'string',
    code        => qq(function evaluate (L2autocur2)
        ret = ""
        for _,val in ipairs(L2autocur2) do
            ret = ret .. val.field_values.L1string1[1]
        end
        return ret
    end),
);
$calc2->set_permissions({$sheet->group->id => $sheet->default_permissions});
$calc2->write;
$layout->clear;

$sheet->create_records;
my $curval = $columns->{curval1};

my $record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $layout,
);

# Test that initial calc values are correct, each sub-record being referred
# from one other record
$record->find_current_id(2);
is($record->fields->{$calc->id}->as_string, "foo2", "Calc value from first autocur correct");
is($record->fields->{$calc2->id}->as_string, "foo2", "Calc value from second autocur correct");

# Now add a second curval value to one of the main records
$record->clear;
$record->find_current_id(3);
my $curval_datum = $record->fields->{$curval->id};
$record->fields->{$curval->id}->set_value([1,2]);

$record->write(no_alerts => 1);

$record->clear;

# Same test as above, this time the sub-record should be referred from 2
# records on the main table
$record->find_current_id(2);

# Without any caching, values would be the default ordering which is the selected field in the
# curval. That's string1 for autocur1 and date1 for autocur2. But with caching,
# the same ordering is returned for each autocur.
is($record->fields->{$calc->id}->as_string, "foo1foo2", "Calc value from first autocur correct");
is($record->fields->{$calc2->id}->as_string, "foo2foo1", "Calc value from second autocur correct");

done_testing();
