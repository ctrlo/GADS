use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use t::lib::DataSheet;

# Create a recursive calc situation, and check that we don't get caught in a
# loop (in which case this test will never finish)

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;

my $sheet   = t::lib::DataSheet->new(
    schema           => $schema,
    data             => [],
    curval           => 2,
    curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
    calc_return_type => 'string',
    calc_code        => qq{function evaluate (L1curval1)
        -- Check that we can recurse into values as far as the
        -- own record's string value but not its curval
        if L1curval1.field_values.L2autocur1[1].field_values.L1string1 == "foo"
            and L1curval1.field_values.L2autocur1[1].field_values.L1curval1 == nil
        then
            return "Test passed"
        else
            return "Unexpected values: "
                .. L1curval1.field_values.L2autocur1[1].field_values.L1string1
                .. L1curval1.field_values.L2autocur1[1].field_values.L1curval1
        end
    end},
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

# Add autocur and calc of autocur to curval sheet, to check that gets
# updated on main sheet write
my $autocur = $curval_sheet->add_autocur(
    refers_to_instance_id => 1,
    related_field_id      => $columns->{curval1}->id,
    curval_field_ids      => [$columns->{string1}->id],
);

my $calc_recurse = GADS::Column::Calc->new(
    schema      => $schema,
    user        => $sheet->user,
    layout      => $curval_sheet->layout,
    name        => 'calc_recurse',
    name_short  => 'calc_recurse',
    return_type => 'integer',
    code        => "function evaluate (L2autocur1) \n return 450 \nend",
);
$calc_recurse->write;
$curval_sheet->layout->clear;

my $record = GADS::Record->new(
    user   => $sheet->user_normal1,
    layout => $layout,
    schema => $schema,
);
$record->initialise;

$record->fields->{$columns->{curval1}->id}->set_value(1);
$record->fields->{$columns->{string1}->id}->set_value('foo');
$record->write(no_alerts => 1);
my $current_id = $record->current_id;

$record->clear;
$record->find_current_id($current_id);

is($record->fields->{$columns->{calc1}->id}, "Test passed", "Calc evaluated correctly");
is($record->fields->{$columns->{curval1}->id}, "Foo", "Curval correct in record");

my $curval_sheet2 = t::lib::DataSheet->new(
    schema => $schema,
    instance_id => 3,
    data => [{
        string1 => 'FooBar1',
    }],
);
$curval_sheet2->create_records;
my $records = GADS::Records->new(
    user => $sheet->user,
    layout => $curval_sheet2->layout,
    schema => $schema,
);

my $curval = GADS::Column::Curval->new(
    schema => $schema,
    user   => $sheet->user,
    layout => $curval_sheet->layout,
);
$curval->refers_to_instance_id(3);
$curval->curval_field_ids([$curval_sheet2->columns->{string1}->id]);
$curval->type('curval');
$curval->name('Subcurval');
$curval->name_short('L2curval1');
$curval->set_permissions({$sheet->group->id => $sheet->default_permissions});
$curval->write;

$record->clear;
$record->find_current_id(1);
$record->fields->{$curval->id}->set_value(4);
$record->fields->{$curval_sheet->columns->{integer1}->id}->set_value(333);
$record->write(no_alerts => 1);

$record->find_current_id(1);

$sheet->layout->clear;

my $calc_curval = GADS::Column::Calc->new(
    schema      => $schema,
    user        => $sheet->user,
    layout      => $sheet->layout,
    name        => 'calc_curval',
    name_short  => 'calc_curval',
    return_type => 'string',
    code        => qq{function evaluate (L1curval1)
        return L1curval1.field_values.L2curval1.field_values.L3string1
    end},
);
$calc_curval->write;
$calc_curval->set_permissions({$sheet->group->id => $sheet->default_permissions});
$layout->clear;


$record->clear;
$record->find_current_id($current_id);

is($record->fields->{$calc_curval->id}->as_string, "FooBar1", "Values within values of curval code is correct");
done_testing();
