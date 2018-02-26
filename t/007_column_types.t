use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use JSON qw(encode_json);
use Log::Report;
use GADS::Layout;
use GADS::Column::Calc;
use GADS::Filter;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use t::lib::DataSheet;

my $data = [
    {
        string1    => 'Foo',
        integer1   => '100',
        enum1      => [7, 8],
        tree1      => 10,
        date1      => '2010-10-10',
        daterange1 => ['2000-10-10', '2001-10-10'],
        curval1    => 1,
        file1      => undef, # Add random file
    },
    {
        string1    => 'Bar',
        integer1   => '200',
        enum1      => 8,
        tree1      => 11,
        date1      => '2011-10-10',
        daterange1 => ['2000-11-11', '2001-11-11'],
        curval1    => 2,
        file1      => undef,
    },
];

my $data2 = [
    {
        string1    => 'Foo',
        integer1   => 50,
        date1      => '2014-10-10',
        daterange1 => ['2012-02-10', '2013-06-15'],
        enum1      => 1,
    },
    {
        string1    => 'Bar',
        integer1   => 99,
        date1      => '2009-01-02',
        daterange1 => ['2008-05-04', '2008-07-14'],
        enum1      => 2,
    },
    {
        string1    => 'Bar',
        integer1   => 99,
        date1      => '2009-01-02',
        daterange1 => ['2008-05-04', '2008-07-14'],
        enum1      => '',
    },
];

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2, data => $data2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = t::lib::DataSheet->new(
    data             => $data,
    schema           => $schema,
    multivalue       => 1,
    curval           => 2,
    curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
    calc_code        => "function evaluate (L1string1) \n return L1string1 \nend",
    calc_return_type => 'string',
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

# Various tests for field types
#
# Code

my $calc = $columns->{calc1};
$calc->code('function evaluate (_id) return "test“test" end');
try { $calc->write };
ok($@, "Failed to write calc code with invalid character");

# Curval tests
#
# First check that we cannot delete a record that is referred to
my $record = GADS::Record->new(
    user   => undef,
    layout => $layout,
    schema => $schema,
);
$record->find_current_id(1);
try { $record->delete_current; $record->purge_current };
like($@, qr/The following records refer to this record as a value/, "Failed to purge record in a curval");
# Restore deleted record
$record->restore;

my $curval = $columns->{curval1};

is( scalar @{$curval->filtered_values}, 3, "Correct number of values for curval field (filtered)" );
is( scalar @{$curval->all_values}, 3, "Correct number of values for curval field (all)" );

# Create a second curval sheet, and check that we can link to first sheet
# (which links to second)
my $curval_sheet2 = t::lib::DataSheet->new(schema => $schema, curval => 1, instance_id => 3, curval_offset => 12);
$curval_sheet2->create_records;
is( scalar @{$curval_sheet2->columns->{curval1}->filtered_values}, 2, "Correct number of values for curval field" );

# Create another curval fields that would cause a recursive loop. Check that it
# fails
my $curval_fail = GADS::Column::Curval->new(
    schema => $schema,
    user   => undef,
    layout => $curval_sheet->layout,
);
$curval_fail->refers_to_instance_id($layout->instance_id);
$curval_fail->curval_field_ids([$columns->{string1}->id]);
$curval_fail->type('curval');
$curval_fail->name('curval fail');
try { $curval_fail->write };
ok( $@, "Attempt to create curval recursive reference fails" );

# Add a curval field without any columns. Check that it doesn't cause fatal
# errors when building values.
# This won't normally be allowed, but we want to test anyway just in case - set
# an env variable to allow it.
$ENV{GADS_ALLOW_BLANK_CURVAL} = 1;
my $curval_blank = GADS::Column::Curval->new(
    schema                => $schema,
    user                  => undef,
    layout                => $layout,
    name                  => 'curval blank',
    type                  => 'curval',
    refers_to_instance_id => $curval_sheet->layout->instance_id,
    curval_field_ids      => [],
);
$curval_blank->write;
# Clear the layout to force the column to be build, and also to build
# dependencies properly in the next test
$layout->clear;
# Now force the values to be built. This should not bork
try { $layout->column($curval_blank->id)->filtered_values };
ok( !$@, "Building values for curval with no fields does not bork" );

# Check that an undefined filter does not cause an exception.  Normally a blank
# filter would be written as an empty JSON string, but that may not be there
# for columns from old versions
my $curval_blank_filter = GADS::Column::Curval->new(
    schema                => $schema,
    user                  => undef,
    layout                => $layout,
    name                  => 'curval blank',
    type                  => 'curval',
    refers_to_instance_id => $curval_sheet->layout->instance_id,
    curval_field_ids      => [],
);
$curval_blank_filter->write;
# Clear the layout to force the column to be build
$layout->clear;
# Manually blank the filters
$schema->resultset('Layout')->update({ filter => undef });
# Now force the values to be built. This should not bork
try { $layout->column($curval_blank_filter->id)->filtered_values };
ok( !$@, "Undefined filter does not cause exception during layout build" );

# Check that we can add and remove curval field IDs
my $field_count = $schema->resultset('CurvalField')->count;
my $curval_add_remove = GADS::Column::Curval->new(
    schema                => $schema,
    user                  => undef,
    layout                => $layout,
    name                  => 'curval fields',
    type                  => 'curval',
    refers_to_instance_id => $curval_sheet->layout->instance_id,
    curval_field_ids      => [$curval_sheet->columns->{string1}->id],
);
$curval_add_remove->write;
# Should be one more
is($schema->resultset('CurvalField')->count, $field_count + 1, "Correct number of fields after new");
$layout->clear;
$curval_add_remove = $layout->column($curval_add_remove->id);
$curval_add_remove->curval_field_ids([$curval_sheet->columns->{string1}->id, $curval_sheet->columns->{integer1}->id]);
$curval_add_remove->write;
is($schema->resultset('CurvalField')->count, $field_count + 2, "Correct number of fields after addition");
$layout->clear;
$curval_add_remove = $layout->column($curval_add_remove->id);
$curval_add_remove->curval_field_ids([$curval_sheet->columns->{integer1}->id]);
$curval_add_remove->write;
is($schema->resultset('CurvalField')->count, $field_count + 1, "Correct number of fields after removal");
$curval_add_remove->delete;
$layout->clear;

# Filter on curval tests
my $curval_filter = GADS::Column::Curval->new(
    schema             => $schema,
    user               => undef,
    layout             => $layout,
    name               => 'curval filter',
    type               => 'curval',
    filter             => GADS::Filter->new(
        as_hash => {
            rules => [{
                id       => $curval_sheet->columns->{string1}->id,
                type     => 'string',
                value    => 'Foo',
                operator => 'equal',
            }],
        },
    ),
    refers_to_instance_id => $curval_sheet->layout->instance_id,
    curval_field_ids      => [ $curval_sheet->columns->{integer1}->id ], # Purposefully different to previous tests
);
$curval_filter->write;
# Clear the layout to force the column to be build, and also to build
# dependencies properly in the next test
$layout->clear;
is( scalar @{$curval_filter->filtered_values}, 1, "Correct number of values for curval field with filter (filtered)" );
is( scalar @{$curval_filter->all_values}, 3, "Correct number of values for curval field with filter (all)" );

# Create a record with a curval value, change the filter, and check that the
# value is still set for the legacy record even though it no longer includes that value.
# This test also checks that different multivalue curvals (with different
# selected fields) behave as expected (multivalue curvals are fetched
# separately).
my $curval_id = $curval_filter->filtered_values->[0]->{id};
my $curval_value = $curval_filter->filtered_values->[0]->{value};
$record = GADS::Records->new(
    user    => $sheet->user,
    layout  => $layout,
    schema  => $schema,
)->single;
$record->fields->{$curval_filter->id}->set_value($curval_id);
$record->write(no_alerts => 1);
$curval_filter->filter(
    GADS::Filter->new(
        as_hash => {
            rules => [{
                id       => $curval_sheet->columns->{string1}->id,
                type     => 'string',
                value    => 'Bar',
                operator => 'equal',
            }],
        },
    ),
);
$curval_filter->write;
$layout->clear;
isnt( $curval_filter->filtered_values->[0]->{id}, $curval_id, "Available curval values has changed after filter change" );
my $cur_id = $record->current_id;
$record->clear;
$record->find_current_id($cur_id);
is( $record->fields->{$curval_filter->id}->id, $curval_id, "Curval value ID still correct after filter change");
is( $record->fields->{$curval_filter->id}->as_string, $curval_value, "Curval value still correct after filter change");
# Same again for multivalue (values are retrieved later using a Records search)
$curval_filter->multivalue(1);
$curval_filter->write;
$layout->clear;
$record = GADS::Records->new(
    user    => $sheet->user,
    layout  => $layout,
    schema  => $schema,
)->single;
is( $record->fields->{$curval_filter->id}->ids->[0], $curval_id, "Curval value ID still correct after filter change (multiple)");
is( $record->fields->{$curval_filter->id}->as_string, $curval_value, "Curval value still correct after filter change (multiple)");
is( $record->fields->{$curval_filter->id}->for_code->[0]->{field_values}->{L2enum1}, 'foo1', "Curval value for code still correct after filter change (multiple)");

# Check that we can filter on a value in the record
foreach my $test (qw/string1 enum1 calc1 multi negative nomatch invalid/)
{
    my $field = $test =~ /(string1|enum1|calc1)/
        ? $test
        : $test =~ /(multi|negative)/
        ? 'enum1'
        : 'string1';
    my $match = $test =~ /(string1|enum1|calc1|multi|negative)/ ? 1 : 0;
    my $value = $test eq 'calc1'
        ? '$L1calc1'
        : $match
        ? "\$L1$field"
        : $test eq 'nomatch'
        ? '$L1tree1'
        : '$L1string123';

    my $rules = $test eq 'multi'
        ? {
            rules => [
                {
                    id       => $curval_sheet->columns->{$field}->id,
                    type     => 'string',
                    value    => $value,
                    operator => 'equal',
                },
                {
                    id       => $curval_sheet->columns->{$field}->id,
                    type     => 'string',
                    operator => 'is_empty',
                },
            ],
            condition => 'OR',
        }
        : $test eq 'negative'
        ? {
            rules => [{
                id       => $curval_sheet->columns->{$field}->id,
                type     => 'string',
                value    => $value,
                operator => 'not_equal',
            }],
        }
        : $test eq 'calc1'
        ? {
            rules => [{
                id       => $curval_sheet->columns->{'string1'}->id,
                type     => 'string',
                value    => $value,
                operator => 'equal',
            }],
        }
        : {
            rules => [{
                id       => $curval_sheet->columns->{$field}->id,
                type     => 'string',
                value    => $value,
                operator => 'equal',
            }],
        };

    $curval_filter = GADS::Column::Curval->new(
        schema             => $schema,
        user               => undef,
        layout             => $layout,
        name               => 'curval filter',
        type               => 'curval',
        filter             => GADS::Filter->new(
            as_hash => $rules,
        ),
        refers_to_instance_id => $curval_sheet->layout->instance_id,
        curval_field_ids      => [ $curval_sheet->columns->{string1}->id ],
    );
    $curval_filter->write;

    # Clear the layout to force the column to be build, and also to build
    # dependencies properly in the next test
    $layout->clear;
    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id(4);

    # Hack to make it look like the dependent datums for the curval filter have been written to
    my $written_field = $field eq 'calc1' ? 'string1' : $field;
    my $datum = $record->fields->{$columns->{$written_field}->id};
    $datum->oldvalue($datum->clone);
    my $count = $test eq 'multi'
        ? 3
        : $test eq 'negative'
        ? 1
        : $match && $field eq 'enum1'
        ? 2
        : $match
        ? 1
        : 0;
    is( scalar @{$curval_filter->filtered_values}, $count, "Correct number of values for curval field with $field filter, test $test" );

    # Check that we can create a new record with the filtered curval field in
    $layout->clear;
    my $record_new = GADS::Record->new(
        user     => $sheet->user,
        layout   => $layout,
        schema   => $schema,
    );
    $record_new->initialise;
    is( scalar @{$layout->column($curval_filter->id)->filtered_values}, 0, "Correct number of values for curval field with filter" );
    if ($test eq 'invalid')
    {
        # Will be ready already - no proper dependent values
        ok( $record_new->fields->{$curval_filter->id}->ready_to_write, "Curval field $field with invalid record filter already ready to write" );
        ok( $record_new->fields->{$curval_filter->id}->show_for_write, "Curval field $field with invalid record filter is shown for write" );
    }
    else {
        ok( !$record_new->fields->{$curval_filter->id}->ready_to_write, "Curval field $field with record filter not yet ready to write, test $test" );
        ok( !$record_new->fields->{$curval_filter->id}->show_for_write, "Curval field $field with record filter not yet shown for write, test $test" );
    }
    my $ready = $field eq 'calc1' ? 0 : 1;
    is( $record_new->fields->{$columns->{$field}->id}->ready_to_write, $ready, "Field $field is ready to write, test $test" );
    is( $record_new->fields->{$columns->{$field}->id}->show_for_write, $ready, "Field $field is shown for write, test $test" );
    ok( !$record_new->fields->{$columns->{$field}->id}->written_to, "Field $field is written to, test $test" );
    # Write the required value and then check that it is now ready
    # Use the values from previous retrieved record - we know these are valid
    foreach my $f (qw/enum1 string1 tree1/)
    {
        my $col_id = $columns->{$f}->id;
        $record_new->fields->{$col_id}->set_value($record->fields->{$col_id}->value);
    }
    ok( $record_new->fields->{$columns->{$field}->id}->written_to, "Field $field is written to, test $test" );
    $record_new->show_for_write_clear;
    ok( $record_new->fields->{$curval_filter->id}->ready_to_write, "Curval field $field with record filter is now ready to write, test $test" );
    ok( $record_new->fields->{$curval_filter->id}->show_for_write, "Curval field $field with record filter is now shown for write, test $test" );
    ok( $record_new->fields->{$columns->{$field}->id}->ready_to_write, "Field $field is still ready to write, test $test" );
    ok( !$record_new->fields->{$columns->{$field}->id}->show_for_write, "Field $field is not shown for write, test $test" );
    $curval_filter->delete;
}

# Now check that we're not building all curval values when we're just
# retrieving individual records
$ENV{PANIC_ON_CURVAL_BUILD_VALUES} = 1;

my $records = GADS::Records->new(
    user    => $sheet->user,
    layout  => $layout,
    schema  => $schema,
);

ok( $_->fields->{$curval->id}->text, "Curval field of record has a textual value" ) foreach @{$records->results};

$layout->clear; # Rebuild layout for dependencies

# Test addition and removal of tree values
{
    my $tree = $columns->{tree1};
    my $count_values = $schema->resultset('Enumval')->search({ layout_id => $tree->id, deleted => 0 })->count;
    is($count_values, 3, "Number of tree values correct at start");

    $tree->clear;
    $tree->update([
        {
            'children' => [],
            'data' => {},
            'text' => 'tree1',
            'id' => 'j1_1',
        },
        {
            'data' => {},
            'text' => 'tree2',
            'children' => [
                {
                    'data' => {},
                    'text' => 'tree3',
                    'children' => [],
                    'id' => 'j1_3'
                },
            ],
            'id' => 'j1_2',
        },
        {
            'children' => [],
            'data' => {},
            'text' => 'tree4',
            'id' => 'j1_4',
        },
    ]);
    $count_values = $schema->resultset('Enumval')->search({ layout_id => $tree->id, deleted => 0 })->count;
    is($count_values, 4, "Number of tree values increased by one after addition");

    $tree->clear;
    $tree->update([
        {
            'children' => [],
            'data' => {},
            'text' => 'tree4',
            'id' => 'j1_4',
        },
    ]);
    $count_values = $schema->resultset('Enumval')->search({ layout_id => $tree->id, deleted => 0 })->count;
    is($count_values, 1, "Number of tree values decreased after removal");
}

# Test deletion of columns in first datasheet. But first, remove curval field
# that refers to this one
$curval_sheet2->columns->{curval1}->delete;
foreach my $col (reverse $layout->all(order_dependencies => 1))
{
    my $col_id = $col->id;
    my $name   = $col->name;
    ok( $schema->resultset('Layout')->find($col_id), "Field $name currently exists in layout table");
    try { $col->delete };
    is( $@, '', "Deletion of field $name did not throw exception" );
    # Check that it's actually gone
    ok( !$schema->resultset('Layout')->find($col_id), "Field $name has been removed from layout table");
}

# Now do the same tests again, but this time change all the field
# types to string. This tests that any data not normally associated
# with that particular type is still deleted.
$curval_sheet = t::lib::DataSheet->new(schema => $schema, instance_id => 2);
$sheet   = t::lib::DataSheet->new(data => $data, schema => $schema, curval => 2);
$layout  = $sheet->layout;
$columns = $sheet->columns;
# We don't normally allow change of type, as the wrong actions will take
# place. Force it directly via the database.
$schema->resultset('Layout')->update({ type => 'string' });
$layout->clear;
foreach my $col (reverse $layout->all(order_dependencies => 1))
{
    my $name = $col->name;
    try { $col->delete };
    is( $@, '', "Deletion of field $name of type string did not throw exception" );
}

done_testing();
