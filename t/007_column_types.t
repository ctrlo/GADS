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

use lib 't/lib';
use Test::GADS::DataSheet;

my $config = {
    gads => {
        uploads => './uploads'
    }
};

GADS::Config->instance->config($config);

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
    {
        string1    => 'FooBar',
        integer1   => 150,
        date1      => '2000-01-02',
        daterange1 => ['2001-05-12', '2002-03-22'],
        enum1      => 3,
    },
];

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, data => $data2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = Test::GADS::DataSheet->new(
    data             => $data,
    schema           => $schema,
    multivalue       => 1,
    curval           => 2,
    curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
    calc_code        => "function evaluate (L1string1)
        if type(L1string1) == \"table\" then
            L1string1 = L1string1[1]
        end
        return L1string1
    end",
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
    user   => $sheet->user,
    layout => $layout,
    schema => $schema,
);
$record->find_current_id(1);
try { $record->delete_current; $record->purge_current };
like($@, qr/The following records refer to this record as a value/, "Failed to purge record in a curval");
# Restore deleted record
$record->restore;

my $user = $sheet->user_normal1;
my $curval = $columns->{curval1};

is( scalar @{$curval->filtered_values}, 4, "Correct number of values for curval field (filtered)" );
is( scalar @{$curval->all_values}, 4, "Correct number of values for curval field (all)" );

# Create a second curval sheet, and check that we can link to first sheet
# (which links to second)
my $curval_sheet2 = Test::GADS::DataSheet->new(schema => $schema, curval => 1, instance_id => 3, curval_offset => 12);
$curval_sheet2->create_records;
is( scalar @{$curval_sheet2->columns->{curval1}->filtered_values}, 2, "Correct number of values for curval field" );

# Add a curval field without any columns. Check that it doesn't cause fatal
# errors when building values.
# This won't normally be allowed, but we want to test anyway just in case - set
# an env variable to allow it.
$ENV{GADS_ALLOW_BLANK_CURVAL} = 1;
my $curval_blank = GADS::Column::Curval->new(
    schema                => $schema,
    user                  => $user,
    layout                => $layout,
    name                  => 'curval blank',
    type                  => 'curval',
    refers_to_instance_id => $curval_sheet->layout->instance_id,
    curval_field_ids      => [],
);
$curval_blank->set_permissions({$sheet->group->id => $sheet->default_permissions});
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
    user                  => $user,
    layout                => $layout,
    name                  => 'curval blank',
    type                  => 'curval',
    refers_to_instance_id => $curval_sheet->layout->instance_id,
    curval_field_ids      => [],
);
$curval_blank_filter->set_permissions({$sheet->group->id => $sheet->default_permissions});
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
    user                  => $user,
    layout                => $layout,
    name                  => 'curval fields',
    type                  => 'curval',
    refers_to_instance_id => $curval_sheet->layout->instance_id,
    curval_field_ids      => [$curval_sheet->columns->{string1}->id],
);
$curval_add_remove->set_permissions({$sheet->group->id => $sheet->default_permissions});
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
    user               => $user,
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
        layout => $layout,
    ),
    refers_to_instance_id => $curval_sheet->layout->instance_id,
    curval_field_ids      => [ $curval_sheet->columns->{integer1}->id ], # Purposefully different to previous tests
);
$curval_filter->set_permissions({$sheet->group->id => $sheet->default_permissions});
$curval_filter->write;
# Clear the layout to force the column to be build, and also to build
# dependencies properly in the next test
$layout->clear;
is( scalar @{$curval_filter->filtered_values}, 1, "Correct number of values for curval field with filter (filtered)" );
is( scalar @{$curval_filter->all_values}, 4, "Correct number of values for curval field with filter (all)" );

# Create a record with a curval value, change the filter, and check that the
# value is still set for the legacy record even though it no longer includes that value.
# This test also checks that different multivalue curvals (with different
# selected fields) behave as expected (multivalue curvals are fetched
# separately).
my $curval_id = $curval_filter->filtered_values->[0]->{id};
my $curval_value = $curval_filter->filtered_values->[0]->{value};
$record = GADS::Records->new(
    user    => $user,
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
        layout => $layout,
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
    user    => $user,
    layout  => $layout,
    schema  => $schema,
)->single;
is( $record->fields->{$curval_filter->id}->ids->[0], $curval_id, "Curval value ID still correct after filter change (multiple)");
is( $record->fields->{$curval_filter->id}->as_string, $curval_value, "Curval value still correct after filter change (multiple)");
my $fields = { L2enum1 => 1 };
is( $record->fields->{$curval_filter->id}->for_code(fields => $fields)->[0]->{field_values}->{L2enum1}, 'foo1', "Curval value for code still correct after filter change (multiple)");

# Add view limit to user
my $autocur1 = $curval_sheet->add_autocur(refers_to_instance_id => 1, related_field_id => $columns->{curval1}->id);
{
    $layout->user($user); # Default sheet layout user is superadmin. Change to normal user
    $curval_sheet->layout->user($user); # Default sheet layout user is superadmin. Change to normal user
    $layout->clear;
    is( scalar @{$curval_filter->filtered_values}, 2, "Correct number of filted values for curval before view_limit" );

    # Add a view limit
    my $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $curval_sheet->columns->{enum1}->id,
                type     => 'string',
                value    => 'foo2',
                operator => 'equal',
            }],
        },
    );

    my $view_limit = GADS::View->new(
        name        => 'Limit to view',
        filter      => $rules,
        instance_id => 2,
        layout      => $curval_sheet->layout,
        schema      => $schema,
        user        => $user,
    );
    $view_limit->write;

    $user->set_view_limits([$view_limit->id]);

    $layout->clear;
    $curval_filter = $layout->column($curval_filter->id);
    is( scalar @{$curval_filter->filtered_values}, 1, "Correct number of filtered values after view_limit applied" );
    is( scalar @{$curval_filter->all_values}, 1, "Correct number of values after view_limit applied (all)" );

    # Check that an override ignores the view_limit
    $curval_filter->override_permissions(1);
    $curval_filter->write(force => 1);
    $layout->clear;
    $curval_filter = $layout->column($curval_filter->id);
    is( scalar @{$curval_filter->filtered_values}, 2, "Correct number of values for curval field with filter (filtered)" );

    # Add view limit to main table and check autocur values.
    # The curval refers to records that this user does not have access to, so
    # it should return a blank value
    $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $columns->{enum1}->id,
                type     => 'string',
                value    => 'foo3', # Nothing matches, should be no autocur values
                operator => 'equal',
            }],
        },
    );

    $view_limit = GADS::View->new(
        name        => 'Limit to view',
        filter      => $rules,
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => $user,
    );
    $view_limit->write;
    $user->set_view_limits([$view_limit->id]);
    my $record = GADS::Record->new(
        user   => $user,
        schema => $schema,
        layout => $curval_sheet->layout,
    );
    $record->find_current_id($curval_id);
    is($record->fields->{$autocur1->id}->as_string, '', "Autocur with limited record not shown");

    # With the view limit still in place, create a view which includes the
    # autocur field as well as having it as a sort
    my $view_sort = GADS::View->new(
        name        => 'Sorted view with autocur',
        columns     => [$autocur1->id],
        instance_id => 2,
        layout      => $curval_sheet->layout,
        schema      => $schema,
        user        => $user,
    );
    $view_sort->set_sorts({ fields => [$autocur1->id."_".$columns->{enum1}->id], types => ['asc']});
    $view_sort->write;
    my $records = GADS::Records->new(
        user   => $user,
        schema => $schema,
        layout => $curval_sheet->layout,
        view   => $view_sort,
    );
    is(@{$records->results}, 4, "Correct number of records");
    is($_->fields->{$autocur1->id}->as_string, '', "Correct autocur value") foreach @{$records->results};

    # Return to normal for remainder of tests
    $user->set_view_limits([]);
    $layout->clear;
    $curval_filter = $layout->column($curval_filter->id);
}

# Check that we can filter on a value in the record
my @position = (
    $columns->{integer1}->id,
    $columns->{date1}->id,
    $columns->{daterange1}->id,
    $columns->{enum1}->id,
    $columns->{tree1}->id,
    $columns->{curval1}->id,
    $curval_filter->id,
    $columns->{string1}->id,
);
$layout->position(@position);
# Add multi-value calc for filtering tests
my $calc2 = GADS::Column::Calc->new(
    schema         => $schema,
    user           => $sheet->user,
    layout         => $layout,
    name           => 'calc2',
    name_short     => 'L1calc2',
    return_type    => 'string',
    code           => qq(function evaluate (_id, L1date1, L1daterange1) \n return {"Foo", "Bar"} \nend),
    multivalue     => 1,
);
$calc2->set_permissions({$sheet->group->id => $sheet->default_permissions});
$calc2->write(force => 1);

# Add display field for filtering tests
my $date1 = $columns->{date1};
my @rules = ({
    id       => $columns->{string1}->id,
    operator => 'equal',
    value    => 'Foo',
});
my $as_hash = {
    condition => undef,
    rules     => \@rules,
};
$date1->display_fields(GADS::Filter->new(
    layout  => $layout,
    as_hash => $as_hash,
));
$date1->write(force => 1);

$layout->clear;
$curval_filter = $layout->column($curval_filter->id);
foreach my $test (qw/string1 enum1 calc1 integer1 multi negative nomatch invalid calcmulti displayfield/)
{
    my $field = $test =~ /(string1|enum1|calc1|integer1)/
        ? $test
        : $test eq 'calcmulti'
        ? 'string1'
        : $test =~ /(multi|negative)/
        ? 'enum1'
        : $test eq 'displayfield'
        ? 'date1'
        : 'string1';
    my $match = $test =~ /(string1|enum1|calc1|integer1|multi|negative)/ ? 1 : 0;
    my $value = $test eq 'calc1'
        ? '$L1calc1'
        : $test eq 'integer1'
        ? '$L1integer1'
        : $test eq 'calcmulti'
        ? '$L1calc2'
        : $match
        ? "\$L1$field"
        : $test eq 'nomatch'
        ? '$L1tree1'
        : $test eq 'displayfield'
        ? '$L1date1'
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
        : $test eq 'integer1'
        ? {
            rules => [{
                id       => $curval_sheet->columns->{'integer1'}->id,
                type     => 'string',
                value    => $value,
                operator => 'less',
            }],
        }
        : $test eq 'calcmulti'
        ? {
            rules => [{
                id       => $curval_sheet->columns->{'string1'}->id,
                type     => 'string',
                value    => $value,
                operator => 'equal',
            }],
        }
        : $test eq 'displayfield'
        ? {
            rules => [{
                id       => $curval_sheet->columns->{'date1'}->id,
                type     => 'string',
                value    => $value,
                operator => 'greater',
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

    $curval_filter->filter(GADS::Filter->new(
            as_hash => $rules,
            layout  => $layout,
        ),
    );
    $curval_filter->curval_field_ids([ $curval_sheet->columns->{string1}->id ]);
    $curval_filter->write(force => 1);
    $curval_filter->clear;

    my $input_required = $test eq 'displayfield'
        ? 2
        : $test eq 'calcmulti'
        ? 3 # date1, daterange1, plus string1 which date1 is a display condition of
        : $test eq 'invalid'
        ? 0
        : 1;
    is(@{$curval_filter->subvals_input_required}, $input_required, "Correct number of input fields required for $test");

    # Clear the layout to force the column to be build, and also to build
    # dependencies properly in the next test
    $layout->clear;
    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id(5);

    # Hack to make it look like the dependent datums for the curval filter have been written to
    my $written_field = $field eq 'calc1' ? 'string1' : $field;
    my $datum = $record->fields->{$columns->{$written_field}->id};
    $datum->oldvalue($datum->clone);
    $record->write(
        dry_run           => 1,
        missing_not_fatal => 1,
        submitted_fields  => $curval_filter->subvals_input_required,
    );
    my $count = $test =~ 'multi'
        ? 3
        : $test eq 'negative'
        ? 2
        : $test eq 'displayfield'
        ? 1
        : $match && $field eq 'enum1'
        ? 2
        : $match && $field eq 'integer1'
        ? 3
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
    my $cv = $layout->column($curval_filter->id);
    $count = $test eq 'multi'
        ? 1
        : $test eq 'negative'
        ? 3
        : $test eq 'calcmulti'
        ? 3
        : $match && $field eq 'enum1'
        ? 1
        : $match
        ? 0
        : 0;
    is( scalar @{$layout->column($curval_filter->id)->filtered_values}, $count, "Correct number of values for curval field with filter" );

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

# Test update of internal columns
foreach my $internal ($layout->all(only_internal => 1))
{
    try { $internal->write(force => 1) };
    like($@, qr/Internal fields cannot be edited/, "Failed to update internal field");
}

# Test deletion of columns in first datasheet. But first, remove curval field
# that refers to this one
$curval_sheet2->columns->{curval1}->delete;
# And autocur
$autocur1->delete;
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
$curval_sheet = Test::GADS::DataSheet->new(schema => $schema, instance_id => 2);
$sheet   = Test::GADS::DataSheet->new(data => $data, schema => $schema, curval => 2);
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
