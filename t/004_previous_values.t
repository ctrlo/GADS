use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Filter;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::RecordsGraph;
use GADS::Schema;

use t::lib::DataSheet;

# Test search of historical values. To make sure that values from other fields
# of the same type are not being included, create 2 fields for each column
# type, setting the initial value as the same to begin with, then only updating
# the first
my @values = (
    {
        field        => 'string',
        begin_set    => 'Foobar1',
        begin_string => 'Foobar1',
        end_set      => 'Foobar2',
        end_string   => 'Foobar2',
        second_field => 'string2',
    },
    # Enum and trees can be set using the text value during initial write only.
    # After that the ID is needed, which is specified by end_set_id (only the
    # first field value is written)
    {
        field        => 'enum',
        begin_set    => 'foo1',
        begin_string => 'foo1',
        end_set      => 'foo2',
        end_set_id   => 8,
        end_string   => 'foo2',
    },
    {
        field        => 'tree',
        begin_set    => 'tree1',
        begin_string => 'tree1',
        end_set      => 'tree2',
        end_set_id   => 14,
        end_string   => 'tree2',
    },
    {
        field        => 'integer',
        begin_set    => 45,
        begin_string => '45',
        end_set      => 55,
        end_string   => '55',
    },
    {
        field        => 'date',
        begin_set    => '2010-01-02',
        begin_string => '2010-01-02',
        end_set      => '2010-03-06',
        end_string   => '2010-03-06',
    },
    {
        field        => 'daterange',
        begin_set    => ['2012-04-02', '2012-05-10'],
        begin_string => '2012-04-02 to 2012-05-10',
        end_set      => ['2012-06-01', '2012-07-10'],
        end_string   => '2012-06-01 to 2012-07-10',
    },
);

# XXX Curval tests to be done
my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my %data1 = map +( $_->{field}.'1' => $_->{begin_set} ), @values;
my %data2 = map +( $_->{field}.'2' => $_->{begin_set} ), @values;
my $sheet   = t::lib::DataSheet->new(
    data         => [\%data1, \%data2],
    schema       => $schema,
    curval       => 2,
    instance_id  => 1,
    column_count => {
        string    => 2,
        enum      => 2,
        tree      => 2,
        integer   => 2,
        date      => 2,
        daterange => 2,
    },
);
$sheet->create_records;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;

my $records = GADS::Records->new(
    schema => $schema,
    layout => $sheet->layout,
    user   => $sheet->user,
);

my $record1 = $records->single;
my $record2 = $records->single;
my $cid1 = $record1->current_id;
my $cid2 = $record2->current_id;

# Check initial written values
foreach my $value (@values)
{
    my $field1 = $value->{field}.'1';
    my $field2 = $value->{field}.'2';
    my $col = $columns->{$field1};
    is($record1->fields->{$col->id}->as_string, $value->{begin_string}, "Initial record1 value correct for $field1");
    $col = $columns->{$field2};
    is($record2->fields->{$col->id}->as_string, $value->{begin_string}, "Initial record2 value correct for $field2");
}

# Write second values
foreach my $value (@values)
{
    my $col = $columns->{$value->{field}.'1'};
    my $set_value = $value->{end_set_id} || $value->{end_set};
    $record1->fields->{$col->id}->set_value($set_value);
}
$record1->write(no_alerts => 1);

# Check second written values
$record1->clear;
$record1->find_current_id($cid1);
foreach my $value (@values)
{
    my $col = $columns->{$value->{field}.'1'};
    is($record1->fields->{$col->id}->as_string, $value->{end_string}, "Written value correct for $value->{field}");
}

foreach my $value (@values)
{
    my $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $columns->{$value->{field}.'1'}->id,
                type     => 'string',
                value    => $value->{begin_string},
                operator => 'equal',
            }],
        },
    );

    my $view = GADS::View->new(
        name        => 'Test view',
        filter      => $rules,
        instance_id => $sheet->instance_id,
        layout      => $sheet->layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view->write;

    $records = GADS::Records->new(
        user    => $sheet->user,
        view    => $view,
        layout  => $sheet->layout,
        schema  => $schema,
    );

    is ($records->count, 0, "No results using normal search on old value - $value->{field}");

    $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id              => $columns->{$value->{field}.'1'}->id,
                type            => 'string',
                value           => $value->{begin_string},
                operator        => 'equal',
                previous_values => 1,
            }],
        },
    );

    my $view_previous = GADS::View->new(
        name        => 'Test view previous',
        filter      => $rules,
        instance_id => $sheet->instance_id,
        layout      => $sheet->layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view_previous->write;

    $records = GADS::Records->new(
        user    => $sheet->user,
        view    => $view_previous,
        layout  => $sheet->layout,
        schema  => $schema,
    );

    is ($records->count, 1, "Returned record when searching previous values - $value->{field}");

}

my @integers = (
    {
        value    => 50,
        operator => 'less',
    },
    {
        value    => 45,
        operator => 'less_or_equal',
    },
    {
        value          => 55,
        operator       => 'not_equal',
        # Includes second record with blank values
        count_normal   => 1,
        count_previous => 2,
    },
);

foreach my $test (@integers)
{
    my $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $columns->{integer1}->id,
                type     => 'string',
                value    => $test->{value},
                operator => $test->{operator},
            }],
        },
    );

    my $view = GADS::View->new(
        name        => 'Test view',
        filter      => $rules,
        instance_id => $sheet->instance_id,
        layout      => $sheet->layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view->write;

    $records = GADS::Records->new(
        user    => $sheet->user,
        view    => $view,
        layout  => $sheet->layout,
        schema  => $schema,
    );

    is ($records->count, $test->{count_normal} || 0, "No results using normal search on integer value - operator $test->{operator}");

    $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id              => $columns->{integer1}->id,
                type            => 'string',
                value           => $test->{value},
                operator        => $test->{operator},
                previous_values => 1,
            }],
        },
    );

    my $view_previous = GADS::View->new(
        name        => 'Test view previous',
        filter      => $rules,
        instance_id => $sheet->instance_id,
        layout      => $sheet->layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view_previous->write;

    $records = GADS::Records->new(
        user    => $sheet->user,
        view    => $view_previous,
        layout  => $sheet->layout,
        schema  => $schema,
    );

    is ($records->count, $test->{count_previous} || 1, "Returned record when searching previous integer values - operator $test->{operator}");
}

done_testing();
