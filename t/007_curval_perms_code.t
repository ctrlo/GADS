use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Tests to check that code values of curvals include all fields regardless of
# user permissions. Various combinations of the field(s) with the limited
# permissions being in and out of the curval fields.

foreach my $test (qw/normal limited_in limited_out limited_both/)
{
    my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
    $curval_sheet->create_records;
    my $schema        = $curval_sheet->schema;
    my $curval_string = $curval_sheet->columns->{string1};
    my $curval_enum   = $curval_sheet->columns->{enum1};

    my $data = [
        {
            string1 => 'foo',
            curval1 => 1,
        },
    ];

    # For code values of curval fields we only need the fields with the short
    # names. However, the code as-is retrieves all fields with the all_fields
    # flag. So to test the correct testing of the correct fields being retrieved,
    # we need a test that includes all fields and then a test that includes all
    # fields minus the field that cannot be read (to see whether the missing
    # non-readable field is noticed)
    my $curval_field_ids = $test eq 'limited_out' || $test eq 'limited_both'
        ? [
            $curval_sheet->columns->{integer1}->id,
            $curval_sheet->columns->{enum1}->id,
            $curval_sheet->columns->{tree1}->id,
            $curval_sheet->columns->{date1}->id,
            $curval_sheet->columns->{daterange1}->id,
            $curval_sheet->columns->{file1}->id,
            $curval_sheet->columns->{person1}->id,
            $curval_sheet->columns->{rag1}->id,
            $curval_sheet->columns->{calc1}->id,
        ] : [
            $curval_sheet->columns->{string1}->id,
            $curval_sheet->columns->{integer1}->id,
            $curval_sheet->columns->{enum1}->id,
            $curval_sheet->columns->{tree1}->id,
            $curval_sheet->columns->{date1}->id,
            $curval_sheet->columns->{daterange1}->id,
            $curval_sheet->columns->{file1}->id,
            $curval_sheet->columns->{person1}->id,
            $curval_sheet->columns->{rag1}->id,
            $curval_sheet->columns->{calc1}->id,
        ];
    my $sheet   = Test::GADS::DataSheet->new(
        data                     => $data,
        schema                   => $schema,
        curval                   => 2,
        curval_field_ids         => $curval_field_ids,
        calc_return_type         => 'string',
        calc_code => "function evaluate (L1curval1)
            return L1curval1.field_values.L2string1 .. L1curval1.field_values.L2integer1 .. L1curval1.field_values.L2enum1
        end",
    );
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;
    $sheet->create_records;
    my $calc = $columns->{calc1};
    my $curval = $columns->{curval1};

    if ($test =~ /limited/)
    {
        $curval_string->set_permissions({$sheet->group->id => []});
        $curval_string->write;
    }
    if ($test eq 'limited_both')
    {
        $curval_enum->set_permissions({$sheet->group->id => []});
        $curval_enum->write;
    }
    $layout->clear;
    $layout->user($sheet->user_normal1);

    my $record = GADS::Record->new(
        user   => $sheet->user_normal1,
        schema => $schema,
        layout => $layout,
    );
    $record->find_current_id(3);
    $record->fields->{$curval->id}->set_value(2);
    $record->write(no_alerts => 1);
    $record->clear;
    $record->find_current_id(3);

    is($record->fields->{$calc->id}->as_string, "Bar99foo2", "Calc value correct");
    # Check the curval value is still limited as expected
    my $expected = $test eq 'normal'
        ? 'Bar, 99, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008'
        : $test eq 'limited_both'
        ? '99, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008'
        : '99, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008';
    is($record->fields->{$curval->id}->as_string, $expected, "Curval string value correct");
}

done_testing();
