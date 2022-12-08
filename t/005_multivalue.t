use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use lib 't/lib';
use Test::GADS::DataSheet;

$ENV{GADS_NO_FORK} = 1;

my $data = [
    {
        string1 => 'Foo',
        enum1   => 7,
        enum2   => 10,
        tree1   => 13,
        tree2   => 16,
        curval1 => 1,
        curval2 => 2,
    },
    {
        string1 => 'Bar',
        enum1   => 8,
        enum2   => 11,
        tree1   => 14,
        tree2   => 17,
        curval1 => 1,
        curval2 => 2,
    },
    {
        string1 => 'FooBar',
        enum1   => 9,
        enum2   => 12,
        tree1   => 15,
        tree2   => 18,
        curval1 => 1,
        curval2 => 2,
    },
];

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, multivalue => 1);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;

my $sheet   = Test::GADS::DataSheet->new(
    data             => $data,
    schema           => $schema,
    curval           => 2,
    column_count     => {
        enum   => 2,
        curval => 3, # 2 multi and 1 single (with multi fields)
        tree   => 2,
    },
    calc_code        => "
        function evaluate (L1enum1, L1curval1, L1tree1)
            values = {}
            for k, v in pairs(L1enum1.values) do table.insert(values, v.value) end
            table.sort(values)
            local text = ''
            for i,v in ipairs(values) do
                text = text .. v
            end
            for i,v in ipairs(L1curval1) do
                text = text .. v.field_values.L2string1[1]
            end
            for i,v in ipairs(L1tree1) do
                text = text .. v.value
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
my $curval3 = $columns->{curval3};
my $tree1   = $columns->{tree1};
my $tree2   = $columns->{tree2};
my $calc    = $columns->{calc1};
$enum1->multivalue(1);
$enum1->write;
$enum2->multivalue(1);
$enum2->write;
$curval1->multivalue(1);
$curval1->write;
$curval2->multivalue(1);
$curval2->write;
$tree1->multivalue(1);
$tree1->write;
$tree2->multivalue(1);
$tree2->write;
$sheet->create_records;
my $user = $sheet->user;

my $record = GADS::Record->new(
    user   => $user,
    layout => $layout,
    schema => $schema,
);

my @tests = (
    {
        name      => 'Write 2 values',
        write     => {
            enum1   => [7, 8],
            curval1 => [1, 2],
            curval3 => [1],
            tree1   => [13, 14],
        },
        as_string => {
            enum1   => 'foo1, foo2',
            enum2   => 'foo1',
            curval1 => 'Foo, 50, foo1, , 2014-10-10, 2012-02-10 to 2013-06-15, , , c_amber, 2012; Bar, 99, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
            curval2 => 'Bar, 99, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
            curval3 => 'Foo, 50, foo1, , 2014-10-10, 2012-02-10 to 2013-06-15, , , c_amber, 2012',
            tree1   => 'tree1, tree2',
            tree2   => 'tree1',
            calc1   => 'foo1foo2BarFootree1tree2', # 2x enum values then 2x string values from curval then 2x tree
        },
        search    => [
            {
                column => 'enum1',
                value  => 'foo2',
            },
        ],
        count     => 2,
    },
    {
        name      => 'Search 2 values',
        write     => {
            enum1  => [7, 8],
            enum2  => [10, 11],
            tree1  => 13,
            tree2  => 16,
        },
        as_string => {
            enum1   => 'foo1, foo2',
            enum2   => 'foo1, foo2',
            curval1 => 'Foo, 50, foo1, , 2014-10-10, 2012-02-10 to 2013-06-15, , , c_amber, 2012; Bar, 99, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
            curval2 => 'Bar, 99, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
            tree1   => 'tree1',
            tree2   => 'tree1',
            calc1   => 'foo1foo2BarFootree1', # 2x enum values then 2x string values from curval, just 1 tree
        },
        search    => [
            {
                column => 'enum1',
                value  => 'foo1',
            },
            {
                column => 'enum2',
                value  => 'foo1',
            },
        ],
        count     => 1,
    },
    {
        name      => 'Search 2 tree values',
        write     => {
            tree1  => [13, 14],
            tree2  => [16, 17],
        },
        as_string => {
            enum1   => 'foo1, foo2',
            enum2   => 'foo1, foo2',
            curval1 => 'Foo, 50, foo1, , 2014-10-10, 2012-02-10 to 2013-06-15, , , c_amber, 2012; Bar, 99, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
            curval2 => 'Bar, 99, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
            tree1   => 'tree1, tree2',
            tree2   => 'tree1, tree2',
            calc1   => 'foo1foo2BarFootree1tree2', # 2x enum values then 2x string values from curval then 2x tree
        },
        search    => [
            {
                column => 'tree1',
                value  => 'tree1',
            },
            {
                column => 'tree2',
                value  => 'tree1',
            },
        ],
        count     => 1,
    },
    {
        name      => 'Search negative 1',
        write     => {
            enum1  => [7, 8],
            enum2  => [11, 12],
        },
        search    => [
            {
                column   => 'enum1',
                value    => 'foo1',
                operator => 'not_equal',
            },
        ],
        count     => 2,
    },
    {
        name      => 'Search negative 2',
        write     => {
            enum1  => [7, 8],
            enum2  => [10, 11],
        },
        search    => [
            {
                column   => 'enum1',
                value    => 'foo2',
                operator => 'not_equal',
            },
        ],
        count     => 1,
    },
    {
        name      => 'Search negative 3',
        write     => {
            enum1  => [7, 8],
            enum2  => [11, 12],
        },
        search    => [
            {
                column   => 'enum1',
                value    => ['foo1', 'foo2'],
                operator => 'not_equal',
            },
        ],
        count     => 1,
    },
    {
        name      => 'Search negative 1 tree',
        write     => {
            tree1  => [13, 14],
            tree2  => [17, 18],
        },
        search    => [
            {
                column   => 'tree1',
                value    => 'tree1',
                operator => 'not_equal',
            },
        ],
        count     => 2,
    },
    {
        name      => 'Search negative 2 tree',
        write     => {
            tree1  => [13, 14],
            tree2  => [16, 17],
        },
        search    => [
            {
                column   => 'tree1',
                value    => 'tree2',
                operator => 'not_equal',
            },
        ],
        count     => 1,
    },
    {
        name      => 'Search negative 3 tree',
        write     => {
            tree1  => [13, 14],
            tree2  => [17, 18],
        },
        search    => [
            {
                column   => 'tree1',
                value    => ['tree1', 'tree2'],
                operator => 'not_equal',
            },
        ],
        count     => 1,
    },
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
    if ($test->{as_string})
    {
        foreach my $type (keys %{$test->{as_string}})
        {
            my $col = $columns->{$type};
            is( $record->fields->{$col->id}->as_string, $test->{as_string}->{$type}, "$type updated correctly for test $test->{name}" );
        }
    }

    my @rules = map {
        +{
            id       => $columns->{$_->{column}}->id,
            type     => 'string',
            value    => $_->{value},
            operator => $_->{operator} || 'equal',
        }
    } @{$test->{search}};
    my $rules = encode_json({
        rules     => \@rules,
        condition => 'OR',
    });

    my $view = GADS::View->new(
        name        => 'Test view',
        filter      => $rules,
        instance_id => 1,
        columns     => [ map { $_->id } $layout->all ],
        layout      => $layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view->write;

    my $records = GADS::Records->new(
        user    => $user,
        view    => $view,
        layout  => $layout,
        schema  => $schema,
    );

    is( $records->count, $test->{count}, "Correct number of records for search $test->{name}");

    $record = $records->single;

    if ($test->{as_string})
    {
        foreach my $type (keys %{$test->{as_string}})
        {
            my $col = $columns->{$type};
            is( $record->fields->{$col->id}->as_string, $test->{as_string}->{$type}, "$type updated correctly for test $test->{name}" );
        }
    }
}

# Now test that even if a field is set back to single-value, that any existing
# multi-values are still displayed
$enum1->multivalue(0);
$enum1->write;
$enum2->multivalue(0);
$enum2->write;
$curval1->multivalue(0);
$curval1->write;
$curval2->multivalue(0);
$curval2->write;
$tree1->multivalue(0);
$tree1->write;
$tree2->multivalue(0);
$tree2->write;

$layout->clear;
$record->clear;

# First test with record retrieved via GADS::Record
$record->find_current_id(3);

my %expected = (
    enum1   => 'foo1, foo2',
    enum2   => 'foo2, foo3',
    curval1 => 'Foo, 50, foo1, , 2014-10-10, 2012-02-10 to 2013-06-15, , , c_amber, 2012; Bar, 99, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
    curval2 => 'Bar, 99, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
    tree1   => 'tree1, tree2',
    tree2   => 'tree2, tree3',
);

foreach my $type (keys %expected)
{
    my $col = $columns->{$type};
    is( $record->fields->{$col->id}->as_string, $expected{$type}, "$type correct for single field with multiple values (single retrieval)" );
}

# And now via GADS:Records
my $records = GADS::Records->new(
    user    => $user,
    layout  => $layout,
    schema  => $schema,
);
$record = $records->single;
foreach my $type (keys %expected)
{
    my $col = $columns->{$type};
    is( $record->fields->{$col->id}->as_string, $expected{$type}, "$type correct for single field with multiple values (multiple retrieval)" );
}

done_testing();
