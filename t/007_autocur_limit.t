use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# A test to ensure that the automatic update of related autocur records when
# the parent record is updated still happens correctly if the submitting does
# not have access to these records

my $curval_sheet = Test::GADS::DataSheet->new(
    instance_id => 2,
    data => [
        {
            string1 => 'Foo',
            enum1   => 'foo1',
        },
        {
            string1 => 'Bar',
            enum1   => 'foo2',
        },
    ],
);
$curval_sheet->create_records;
my $schema = $curval_sheet->schema;

my $data = [
    {
        string1 => 'allowed',
        tree1   => 'tree1',
        curval1 => 1,
    },
    {
        string1 => 'banned',
        tree1   => 'tree2',
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
$sheet->create_records;
my $columns = $sheet->columns;
my $layout  = $sheet->layout;

# Add autocur to curval table
my $autocur1 = $curval_sheet->add_autocur(
    refers_to_instance_id => 1,
    related_field_id      => $sheet->columns->{curval1}->id,
    curval_field_ids      => [$sheet->columns->{string1}->id],
);

# Calc for autocur. Return all tree values from referred table
my $calc = $curval_sheet->columns->{calc1};
$calc->code('
    function evaluate (L2autocur1)
        ret = ""
        for _,val in ipairs(L2autocur1) do
            ret = ret .. val.field_values.L1tree1[1].value
        end
        return ret
    end');
$calc->return_type('string');
$calc->write;
# Clear sheet for new return type to take effect
$curval_sheet->layout->clear;
$calc = $curval_sheet->layout->column($calc->id);
$calc->update_cached;

# Add a limited view only allowing the user access to some records in the main
# table
my $rules = GADS::Filter->new(
    as_hash => {
        rules     => [{
            id       => $sheet->columns->{string1}->id,
            type     => 'string',
            value    => 'allowed',
            operator => 'equal',
        }],
    },
);

my $view_limit = GADS::View->new(
    name        => 'Limit to view',
    filter      => $rules,
    instance_id => $sheet->layout->instance_id,
    layout      => $sheet->layout,
    schema      => $schema,
    user        => $sheet->user,
    is_admin    => 1,
);
$view_limit->write;

my $normal_user = $sheet->user_normal1;
$normal_user->set_view_limits([$view_limit->id]);

# Check initial calc values
my $record = GADS::Record->new(
    user   => $curval_sheet->user,
    schema => $schema,
    layout => $layout,
);
$record->find_current_id(1);
is($record->fields->{$calc->id}->as_string, 'tree1', "Initial calc correct for first subrecord");
$record->clear;
$record->find_current_id(2);
is($record->fields->{$calc->id}->as_string, 'tree2', "Initial calc correct for second subrecord");

# Switch to normal user and make edit
$sheet->layout->user($normal_user);
$sheet->layout->clear;
$record = GADS::Record->new(
    user   => $normal_user,
    schema => $schema,
    layout => $layout,
);
$record->find_current_id(3);
$record->fields->{$columns->{curval1}->id}->set_value([1,2]);
$record->write(no_alerts => 1);

# Switch back and check values
$sheet->layout->user($sheet->user);
$sheet->layout->clear;
$record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $layout,
);
$record->find_current_id(1);
is($record->fields->{$curval_sheet->columns->{calc1}->id}->as_string, 'tree1', "Initial calc correct for first subrecord");
$record->clear;
$record->find_current_id(2);
is($record->fields->{$calc->id}->as_string, 'tree1tree2', "Initial calc correct for second subrecord");

done_testing();
