use Test::More; # tests => 1;
use strict;
use warnings;

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime
use DateTime;
use JSON qw(encode_json);
use Log::Report;
use GADS::Filter;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::RecordsGraph;
use GADS::Schema;

use lib 't/lib';
use Test::GADS::DataSheet;

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
my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my %data1 = map +( $_->{field}.'1' => $_->{begin_set} ), @values;
my %data2 = map +( $_->{field}.'2' => $_->{begin_set} ), @values;
my $sheet   = Test::GADS::DataSheet->new(
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
                previous_values => 'positive',
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

my @tests = (
    {
        field          => 'integer1',
        value_before   => 340,
        value_after    => 450,
        filter_value   => 420,
        operator       => 'less',
        count_normal   => 0,
        count_previous => 1,
    },
    {
        field          => 'integer1',
        value_before   => 700,
        value_after    => 450,
        filter_value   => 600,
        operator       => 'greater',
        count_normal   => 0,
        count_previous => 1,
    },
    {
        field          => 'integer1',
        value_before   => 340,
        value_after    => 450,
        filter_value   => 340,
        operator       => 'less_or_equal',
        count_normal   => 0,
        count_previous => 1,
    },
    {
        field          => 'integer1',
        value_before   => 340,
        value_after    => 450,
        filter_value   => 340,
        operator       => 'not_equal',
        count_normal   => 1,
        count_previous => 0,
    },
    {
        field          => 'integer1',
        value_before   => undef,
        value_after    => 100,
        operator       => 'is_empty',
        count_normal   => 0,
        count_previous => 1,
    },
    {
        field          => 'integer1',
        value_before   => 100,
        value_after    => undef,
        operator       => 'is_not_empty',
        count_normal   => 0,
        count_previous => 1,
    },
    {
        field          => 'string1',
        value_before   => 'apples',
        value_after    => 'oranges',
        filter_value   => 'apples',
        operator       => 'not_equal',
        count_normal   => 1,
        count_previous => 0,
    },
    {
        field          => 'string1',
        value_before   => 'apples',
        value_after    => 'oranges',
        filter_value   => 'pple',
        operator       => 'contains',
        count_normal   => 0,
        count_previous => 1,
    },
    {
        field          => 'string1',
        value_before   => 'apples',
        value_after    => 'oranges',
        filter_value   => 'pple',
        operator       => 'not_contains',
        count_normal   => 1,
        count_previous => 0,
    },
    {
        field          => 'string1',
        value_before   => 'apples',
        value_after    => 'oranges',
        filter_value   => 'appl',
        operator       => 'not_begins_with',
        count_normal   => 1,
        count_previous => 0,
    },
    {
        field          => 'string1',
        value_before   => undef,
        value_after    => 'Foobar',
        operator       => 'is_empty',
        count_normal   => 0,
        count_previous => 1,
        empty_defined  => 1,
    },
    {
        field          => 'string1',
        value_before   => 'Foobar',
        value_after    => undef,
        operator       => 'is_not_empty',
        count_normal   => 0,
        count_previous => 1,
        empty_defined  => 1,
    },
    {
        field          => 'string1',
        value_before   => undef,
        value_after    => 'Foobar',
        operator       => 'is_empty',
        count_normal   => 0,
        count_previous => 1,
        empty_defined  => 0,
    },
    {
        field          => 'string1',
        value_before   => 'Foobar',
        value_after    => undef,
        operator       => 'is_not_empty',
        count_normal   => 0,
        count_previous => 1,
        empty_defined  => 0,
    },
    {
        field          => 'enum1',
        value_before   => [1,2],
        value_after    => 3,
        filter_value   => 'foo2',
        operator       => 'not_equal',
        count_normal   => 1,
        count_previous => 0,
    },
    # 2 tests to check limiting previous value searches within a specified
    # timeframe.
    # First a standard check of all previous records, searching for an enum
    # value that ever has been enum1.
    {
        field          => 'enum1',
        value_before   => 1,
        value_after    => 3,
        filter_value   => 'foo1',
        operator       => 'equal',
        count_normal   => 0,
        count_previous => 1,
        last_edited    => 0,
    },
    # Then the same filter, this time limiting to any record edits after
    # 1/3/2014. As enum1 was only foo1 at the first edit on 1/1/2014 this
    # should not match anything.
    {
        field          => 'enum1',
        value_before   => 1,
        value_after    => 3,
        filter_value   => 'foo1',
        operator       => 'equal',
        count_normal   => 0,
        count_previous => 0,
        last_edited    => 1,
    },
    {
        # Check other multivalue
        field          => 'enum1',
        value_before   => [1,2],
        value_after    => 3,
        filter_value   => 'foo1',
        operator       => 'not_equal',
        count_normal   => 1,
        count_previous => 0,
    },
);

foreach my $test (@tests)
{
    my $data = [
        {
            $test->{field} => $test->{value_before},
        },
    ];

    # Initial record values
    set_fixed_time('01/01/2014 01:00:00', '%d/%m/%Y %H:%M:%S');
    my $sheet   = Test::GADS::DataSheet->new(
        data       => $data,
        multivalue => 1,
        column_count => {
            string    => 2,
        },
    );
    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $columns  = $sheet->columns;
    my $col      = $columns->{$test->{field}},

    # Change to the "after" value
    set_fixed_time('01/06/2014 01:00:00', '%d/%m/%Y %H:%M:%S');
    my $record = GADS::Record->new(
        schema => $schema,
        layout => $layout,
        user   => $sheet->user,
    );
    $record->find_current_id(1);
    $record->fields->{$col->id}->set_value($test->{value_after});
    $record->write(no_alerts => 1);

    # Now make an unrelated change in the record, so that a new version is
    # written but that the value being tested remains the same
    set_fixed_time('01/01/2015 01:00:00', '%d/%m/%Y %H:%M:%S');
    $record = GADS::Record->new(
        schema => $schema,
        layout => $layout,
        user   => $sheet->user,
    );
    $record->find_current_id(1);
    $record->fields->{$columns->{string2}->id}->set_value('Blah');
    $record->write(no_alerts => 1);

    # Enable tests for both empty string and NULL values
    if (exists $test->{empty_defined})
    {
        my $val = $test->{empty_defined} ? '' : undef;
        $schema->resultset('String')->search({
            value => [undef, ''],
        })->update({
            value       => $val,
            value_index => $val,
        });
    }

    my $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $columns->{$test->{field}}->id,
                type     => 'string',
                value    => $test->{filter_value},
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

    is ($records->count, $test->{count_normal}, "Correct number of results - operator $test->{operator}");

    $rules = $test->{last_edited}
        ? GADS::Filter->new(
            as_hash => {
                rules     => [
                    {
                        id       => $columns->{$test->{field}}->id,
                        type     => 'string',
                        value    => $test->{filter_value},
                        operator => $test->{operator},
                    },
                    {
                        id        => $layout->column_by_name_short('_version_datetime')->id,
                        type      => 'date',
                        value     => '2014-03-01',
                        operator  => 'greater',
                    },
                ],
                previous_values => 'positive',
            },
        )
        : GADS::Filter->new(
            as_hash => {
                rules     => [{
                    id              => $columns->{$test->{field}}->id,
                    type            => 'string',
                    value           => $test->{filter_value},
                    operator        => $test->{operator},
                    previous_values => 'positive',
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

    is ($records->count, $test->{count_previous}, "Correct number of results inc previous - operator $test->{operator}");
}

# Test previous values for groups. Make some edits over a period of time, and
# attempt to retrieve previous values only between certain edit dates
{
    set_fixed_time('01/01/2014 01:00:00', '%m/%d/%Y %H:%M:%S');

    my $sheet   = Test::GADS::DataSheet->new(
        data       => [{
            integer1 => 10,
        }],
        multivalue => 1,
    );
    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $columns  = $sheet->columns;
    my $int      = $columns->{integer1},

    set_fixed_time('09/01/2014 01:00:00', '%m/%d/%Y %H:%M:%S');
    my $record = GADS::Record->new(
        schema => $schema,
        layout => $layout,
        user   => $sheet->user,
    );
    $record->find_current_id(1);
    $record->fields->{$columns->{string1}->id}->set_value('foobar');
    $record->write(no_alerts => 1);

    set_fixed_time('01/02/2015 01:00:00', '%m/%d/%Y %H:%M:%S');
    $record = GADS::Record->new(
        schema => $schema,
        layout => $layout,
        user   => $sheet->user,
    );
    $record->find_current_id(1);
    $record->fields->{$int->id}->set_value(20);
    $record->write(no_alerts => 1);

    set_fixed_time('01/01/2016 01:00:00', '%m/%d/%Y %H:%M:%S');
    $record->clear;
    $record->find_current_id(1);
    $record->fields->{$int->id}->set_value(30);
    $record->write(no_alerts => 1);

    foreach my $test ('normal', 'inrange', 'outrange')
    {
        foreach my $negative (0..1)
        {
            my $hash = {
                rules     => [
                    {
                        id              => $int->id,
                        type            => 'string',
                        value           => 20,
                        operator        => $negative ? 'not_equal' : 'equal',
                    },
                    {
                        id              => $layout->column_by_name_short('_version_datetime')->id,
                        type            => 'string',
                        value           => $test eq 'inrange' ? '2014-10-01' : '2014-06-01',
                        operator        => 'greater',
                    },
                    {
                        id              => $layout->column_by_name_short('_version_datetime')->id,
                        type            => 'string',
                        value           => $test eq 'inrange' ? '2015-06-01' : '2014-10-01',
                        operator        => 'less',
                    }
                ],
                operator => 'AND',
            };
            $hash->{previous_values} = 'positive' unless $test eq 'normal';
            my $rules = GADS::Filter->new(
                as_hash => $hash,
            );

            my $view_previous = GADS::View->new(
                name        => 'Test view previous group',
                filter      => $rules,
                instance_id => $sheet->instance_id,
                layout      => $sheet->layout,
                schema      => $schema,
                user        => $sheet->user,
            );
            $view_previous->write;

            my $records = GADS::Records->new(
                user    => $sheet->user,
                view    => $view_previous,
                layout  => $sheet->layout,
                schema  => $schema,
            );

            my $expected = $test eq 'inrange' ? 1 : 0;
            $expected = $expected ? 0 : 1
                if $negative && $test ne 'normal';
            is ($records->count, $expected, "Correct number of results for group include previous ($test), negative: $negative");
        }
    }

    # Now a test to see if a value has changed in a certain period
    foreach my $inrange (0..1)
    {
        my $rules = GADS::Filter->new(
            as_hash => {
                rules     => [
                    {
                        rules => [
                            {
                                id              => $int->id,
                                type            => 'string',
                                value           => 10,
                                operator        => 'equal',
                            },
                            {
                                id              => $layout->column_by_name_short('_version_datetime')->id,
                                type            => 'string',
                                value           => $inrange ? '2013-06-01' : '2014-10-01',
                                operator        => 'greater',
                            },
                            {
                                id              => $layout->column_by_name_short('_version_datetime')->id,
                                type            => 'string',
                                value           => '2015-06-01',
                                operator        => 'less',
                            }
                        ],
                        previous_values => 'positive',
                    },
                    {
                        rules => [
                            {
                                id              => $int->id,
                                type            => 'string',
                                value           => 10,
                                operator        => 'not_equal',
                            },
                            {
                                id              => $layout->column_by_name_short('_version_datetime')->id,
                                type            => 'string',
                                value           => $inrange ? '2013-06-01' : '2014-10-01',
                                operator        => 'greater',
                            },
                            {
                                id              => $layout->column_by_name_short('_version_datetime')->id,
                                type            => 'string',
                                value           => '2015-06-01',
                                operator        => 'less',
                            }
                        ],
                        previous_values => 'positive',
                    },
                ],
                operator        => 'AND',
            },
        );

        my $view_previous = GADS::View->new(
            name        => 'Test view previous group',
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

        my $expected = $inrange ? 1 : 0;
        is ($records->count, $expected, "Correct number of results for group include previous with value change");
    }

    # Negative group previous values match
    foreach my $match (qw/positive negative/) # Check both to ensure difference
    {
        my $rules = GADS::Filter->new(
            as_hash => {
                rules     => [
                    {
                        rules => [
                            {
                                id              => $int->id,
                                type            => 'string',
                                value           => 20,
                                operator        => 'equal',
                            },
                            {
                                id              => $layout->column_by_name_short('_version_datetime')->id,
                                type            => 'string',
                                value           => '2015-06-01',
                                operator        => 'less',
                            },
                        ],
                        previous_values => $match,
                    },
                ],
            },
        );

        my $view_previous = GADS::View->new(
            name        => 'Test view previous group',
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

        my $expected = $match eq 'negative' ? 0 : 1;
        is ($records->count, $expected, "Correct number of results for negative previous value group");
    }

    # Now a test to see if a value has changed in a certain period
    foreach my $inrange (0..1)
    {
        my $rules = GADS::Filter->new(
            as_hash => {
                rules     => [
                    {
                        rules => [
                            {
                                id              => $int->id,
                                type            => 'string',
                                value           => 20,
                                operator        => 'equal',
                            },
                            {
                                id              => $layout->column_by_name_short('_version_datetime')->id,
                                type            => 'string',
                                value           => '2014-12-31',
                                operator        => 'less',
                            }
                        ],
                        previous_values => 'negative',
                    },
                    {
                        rules => [
                            {
                                id              => $int->id,
                                type            => 'string',
                                value           => 20,
                                operator        => 'equal',
                            },
                            {
                                id              => $layout->column_by_name_short('_version_datetime')->id,
                                type            => 'string',
                                value           => '2015-01-01',
                                operator        => 'greater',
                            },
                            {
                                id              => $layout->column_by_name_short('_version_datetime')->id,
                                type            => 'string',
                                value           => '2015-12-31',
                                operator        => 'less',
                            }
                        ],
                        previous_values => 'positive',
                    },
                ],
                operator        => 'AND',
            },
        );

        my $view_previous = GADS::View->new(
            name        => 'Test view previous group',
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

        my $expected = $inrange ? 1 : 1;
        is ($records->count, $expected, "Correct number of results for searching for change in period");
    }

}

done_testing();
