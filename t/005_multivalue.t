use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use t::lib::DataSheet;

$ENV{GADS_NO_FORK} = 1;

my $data = [
    {
        string1 => 'Foo',
        enum1   => 7,
        enum2   => 10,
        tree1   => 13,
        curval1 => 1,
        curval2 => 2,
    },
    {
        string1 => 'Bar',
        enum1   => 8,
        enum2   => 11,
        tree1   => 14,
        curval1 => 1,
        curval2 => 2,
    },
    {
        string1 => 'FooBar',
        enum1   => 9,
        enum2   => 12,
        tree1   => 15,
        curval1 => 1,
        curval2 => 2,
    },
];

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;

my $sheet   = t::lib::DataSheet->new(
    data             => $data,
    schema           => $schema,
    curval           => 2,
    column_count     => {
        enum   => 2,
        curval => 2,
    },
    calc_code        => "
        function evaluate (enum1, curval1)
            values = {}
            for k, v in pairs(enum1.values) do table.insert(values, v) end
            table.sort(values)
            local text = ''
            for i,v in ipairs(values) do
                text = text .. v
            end
            for i,v in ipairs(curval1) do
                text = text .. v.field_values.string1
            end
            return text
        end
    ",
    calc_return_type => 'string',
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
my $enum1   = $columns->{enum1};
my $enum2   = $columns->{enum2};
my $curval1 = $columns->{curval1};
my $curval2 = $columns->{curval2};
my $tree    = $columns->{tree1};
my $calc    = $columns->{calc1};
$enum1->multivalue(1);
$enum1->write;
$enum2->multivalue(1);
$enum2->write;
$curval1->multivalue(1);
$curval1->write;
$curval2->multivalue(1);
$curval2->write;
$sheet->create_records;

my $record = GADS::Record->new(
    user   => undef,
    layout => $layout,
    schema => $schema,
);

my @tests = (
    {
        name      => 'Write 2 values',
        write     => {
            enum1   => [7, 8],
            curval1 => [1, 2],
        },
        as_string => {
            enum1   => 'foo1, foo2',
            enum2   => 'foo1',
            curval1 => 'Foo, 50, , , 2014-10-10, 2012-02-10 to 2013-06-15, , , c_amber, 2012; Bar, 99, , , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
            curval2 => 'Bar, 99, , , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
            tree1   => 'tree1',
            calc1   => 'foo1foo2FooBar', # 2x enum values then 2x string values from curval
        },
        search    => 'foo2',
        count     => 2,
    }
);

foreach my $test (@tests)
{
    $record->find_current_id(3);
    foreach my $type (keys %{$test->{write}})
    {
        my $col = $columns->{$type};
        $record->fields->{$col->id}->set_value($test->{write}->{$type});
    }
    $record->write;
    $record->clear;
    $record->find_current_id(3);
    foreach my $type (keys %{$test->{as_string}})
    {
        my $col = $columns->{$type};
        is( $record->fields->{$col->id}->as_string, $test->{as_string}->{$type}, "$type updated correctly for test $test->{name}" );
    }

    my $rules = encode_json({
        rules => [
            {
                id       => $columns->{enum1}->id,
                type     => 'string',
                value    => $test->{search},
                operator => 'equal',
            }
        ],
    });

    my $view = GADS::View->new(
        name        => 'Test view',
        filter      => $rules,
        instance_id => 1,
        columns     => [ map { $_->id } $layout->all ],
        layout      => $layout,
        schema      => $schema,
        user        => undef,
    );
    $view->write;

    my $records = GADS::Records->new(
        user    => undef,
        view    => $view,
        layout  => $layout,
        schema  => $schema,
    );

    is( $records->count, $test->{count}, "Correct number of records for search $test->{name}");

    $record = $records->single;

    foreach my $type (keys %{$test->{as_string}})
    {
        my $col = $columns->{$type};
        is( $record->fields->{$col->id}->as_string, $test->{as_string}->{$type}, "$type updated correctly for test $test->{name}" );
    }
}

done_testing();
