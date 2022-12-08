use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Tests for "limit rows" feature to limit the number of rows displayed in a
# record for a curval field

foreach my $multivalue (0..1)
{
    my $data = [
        {
            string1  => 'String1',
            enum1    => 'foo1',
            integer1 => 10,
        },
        {
            string1  => 'String2',
            enum1    => 'foo1',
            integer1 => 10,
        },
        {
            string1  => 'String3',
            enum1    => 'foo1',
            integer1 => 10,
        },
        {
            string1  => 'String4',
            enum1    => 'foo1',
            integer1 => 10,
        },
        {
            string1  => 'String5',
            enum1    => 'foo2',
            integer1 => 10,
        },
        {
            string1  => 'String6',
            enum1    => 'foo2',
            integer1 => 10,
        },
        {
            string1  => 'String7',
            enum1    => 'foo2',
            integer1 => 10,
        },
        {
            string1  => 'String8',
            enum1    => 'foo2',
            integer1 => 10,
        },
    ];
    my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, data => $data);
    $curval_sheet->create_records;
    my $curval_columns = $curval_sheet->columns;
    my $curval_layout  = $curval_sheet->layout;
    $curval_layout->sort_layout_id($curval_layout->column_id->id);
    $curval_layout->sort_type('desc');
    $curval_layout->write;
    my $schema = $curval_sheet->schema;

    my $sheet = Test::GADS::DataSheet->new(
        multivalue       => $multivalue,
        schema           => $schema,
        instance_id      => 1,
        data             => [
            {
                string1 => 'My project',
                curval1 => $multivalue ? [1,2,3,4,5,6,7] : [1],
            },
            {
                string1 => 'My project 2',
                curval1 => $multivalue ? [2,3,4,5,6] : [1],
            },
        ],
        curval           => 2,
        curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
        calc_code => qq(function evaluate (L1curval1)
            return_value = 0
            if L1curval1[1] then
                for _, v in pairs(L1curval1) do
                    return_value = return_value + v.field_values.L2integer1
                end
                return return_value
            end
            return L1curval1.field_values.L2integer1
        end),
    );
    $sheet->create_records;
    my $curval = $sheet->columns->{curval1};
    my $calc   = $sheet->columns->{calc1};
    my $string = $sheet->columns->{string1};

    # Set limit of 4 rows
    $curval->limit_rows(4);
    $curval->write;
    $sheet->layout->clear;

    # See if initial value only shows 4 rows
    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $sheet->layout,
        schema => $schema,
    );
    $record->find_current_id(9);
    my $cvalue1 = $multivalue ? "String7; String6; String5; String4" : 'String1';
    my $cvalue2 = $multivalue ? "String6; String5; String4; String3" : 'String1';
    is($record->fields->{$curval->id}->as_string, $cvalue1, "Correct curval value");
    is($record->fields->{$calc->id}->as_string, $multivalue ? 70 : 10, "Correct curval value");

    # Check loading of whole table
    my $records = GADS::Records->new(
        user   => $sheet->user,
        layout => $sheet->layout,
        schema => $schema,
    );
    $record = $records->single;
    is($record->fields->{$curval->id}->as_string, $cvalue1, "Correct curval value 1st record");
    is($record->fields->{$calc->id}->as_string, $multivalue ? 70 : 10, "Correct calc value 1st record");
    my $record2 = $records->single;
    is($record2->fields->{$curval->id}->as_string, $cvalue2, "Correct curval value 2nd record");
    is($record2->fields->{$calc->id}->as_string, $multivalue ? 50 : 10, "Correct calc value 2nd record");

    # Make an edit to the curval field
    $record->fields->{$curval->id}->set_value([8]);
    $record->write(no_alerts => 1);

    # Remove permission to write to curval field, which should not affect the
    # subsequent write
    $curval->set_permissions({$sheet->group->id => []});
    $curval->write;
    $sheet->layout->clear;

    # Reload and check value
    $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $sheet->layout,
        schema => $schema,
    );
    $record->find_current_id(9);
    $cvalue1 = $multivalue ? "String8; String7; String6; String5" : 'String8';
    is($record->fields->{$curval->id}->as_string, $cvalue1, "Correct curval value");
    # Make a no-op edit to the curval, which should have no effect, especially
    # as the user does not have permission
    my $ids = $record->fields->{$curval->id}->ids;
    $record->fields->{$curval->id}->set_value($ids);
    is($record->fields->{$calc->id}->as_string, $multivalue ? 80 : 10, "Correct calc value");

    # Make an edit to the record not including the curval field
    $record->fields->{$string->id}->set_value("Foobar");
    $record->write(no_alerts => 1);

    # Reload and check
    $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $sheet->layout,
        schema => $schema,
    );
    $record->find_current_id(9);
    is($record->fields->{$curval->id}->as_string, $cvalue1, "Correct curval value after non-curval write");
    is($record->fields->{$calc->id}->as_string, $multivalue ? 80 : 10, "Correct calc value");
}

done_testing();
