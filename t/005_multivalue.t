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
    },
    {
        string1 => 'Bar',
        enum1   => 2,
    },
    {
        string1 => 'FooBar',
        enum1   => 3,
    },
];

my $sheet   = t::lib::DataSheet->new(
    data             => $data,
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
my $enum = $columns->{enum1};
my $calc = $columns->{calc1};
$enum->multivalue(1);
$enum->write;
$sheet->create_records;

my $record = GADS::Record->new(
    user   => undef,
    layout => $layout,
    schema => $schema,
);

my @tests = (
    {
        name      => 'Write 2 values',
        write     => [1, 2],
        as_string => 'foo1, foo2',
        search    => 'foo2',
        count     => 2,
        calcval   => 'foo1foo2',
    }
);

foreach my $test (@tests)
{
    $record->find_current_id(1);
    $record->fields->{$enum->id}->set_value($test->{write});
    $record->write;
    $record->clear;
    $record->find_current_id(1);
    is( $record->fields->{$enum->id}->as_string, $test->{as_string}, "Enum updated correctly for test $test->{name}" );
    is( $record->fields->{$calc->id}->as_string, $test->{calcval}, "Calc value correct for test $test->{name}" );

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
}

done_testing();
