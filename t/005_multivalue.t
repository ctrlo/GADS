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
        enum1   => 1,
        enum2   => 4,
        tree1   => 7,
    },
    {
        string1 => 'Bar',
        enum1   => 2,
        enum2   => 5,
        tree1   => 8,
    },
    {
        string1 => 'FooBar',
        enum1   => 3,
        enum2   => 6,
        tree1   => 9,
    },
];

my $sheet   = t::lib::DataSheet->new(
    data             => $data,
    column_count     => {
        enum => 2,
    },
    calc_code        => "
        function evaluate (enum1)
            values = {}
            for k, v in pairs(enum1.values) do table.insert(values, v) end
            table.sort(values)
            local text = ''
            for i,v in ipairs(values) do
                text = text .. v
            end
            return text
        end
    ",
    calc_return_type => 'string',
);
my $schema  = $sheet->schema;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
my $enum1 = $columns->{enum1};
my $enum2 = $columns->{enum2};
my $tree  = $columns->{tree1};
my $calc  = $columns->{calc1};
$enum1->multivalue(1);
$enum1->write;
$enum2->multivalue(1);
$enum2->write;
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
            enum1 => [1, 2],
        },
        as_string => {
            enum1 => 'foo1, foo2',
            enum2 => 'foo1',
            tree1 => 'tree1',
            calc1 => 'foo1foo2',
        },
        search    => 'foo2',
        count     => 2,
    }
);

foreach my $test (@tests)
{
    $record->find_current_id(1);
    foreach my $type (keys %{$test->{write}})
    {
        my $col = $columns->{$type};
        $record->fields->{$col->id}->set_value($test->{write}->{$type});
    }
    $record->write;
    $record->clear;
    $record->find_current_id(1);
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
