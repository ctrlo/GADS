use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Column::Calc;
use GADS::Filter;
use GADS::Layout;
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
    calc_code        => "function evaluate (string1) \n return string1 \nend",
    calc_return_type => 'string',
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

# Various tests for field types
#
# Curval tests
my $curval = $columns->{curval1};

is( scalar @{$curval->values}, 3, "Correct number of values for curval field" );

# Create a second curval sheet, and check that we can link to first sheet
# (which links to second)
my $curval_sheet2 = t::lib::DataSheet->new(schema => $schema, curval => 1, instance_id => 3);
$curval_sheet2->create_records;
is( scalar @{$curval_sheet2->columns->{curval1}->values}, 2, "Correct number of values for curval field" );

# Create another curval fields that would cause a recursive loop. Check that it
# fails
my $curval_fail = GADS::Column::Curval->new(
    schema => $schema,
    user   => undef,
    layout => $curval_sheet->layout,
);
$curval_fail->refers_to_instance($layout->instance_id);
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
    schema             => $schema,
    user               => undef,
    layout             => $layout,
    name               => 'curval blank',
    type               => 'curval',
    refers_to_instance => $curval_sheet->layout->instance_id,
    curval_field_ids   => [],
);
$curval_blank->write;
# Clear the layout to force the column to be build, and also to build
# dependencies properly in the next test
$layout->clear;
# Now force the values to be built. This should not bork
try { $layout->column($curval_blank->id)->values };
ok( !$@, "Building values for curval with no fields does not bork" );

# Check that an undefined filter does not cause an exception.  Normally a blank
# filter would be written as an empty JSON string, but that may not be there
# for columns from old versions
my $curval_blank_filter = GADS::Column::Curval->new(
    schema             => $schema,
    user               => undef,
    layout             => $layout,
    name               => 'curval blank',
    type               => 'curval',
    refers_to_instance => $curval_sheet->layout->instance_id,
    curval_field_ids   => [],
);
$curval_blank_filter->write;
# Clear the layout to force the column to be build
$layout->clear;
# Manually blank the filters
$schema->resultset('Layout')->update({ filter => undef });
# Now force the values to be built. This should not bork
try { $layout->column($curval_blank_filter->id)->values };
ok( !$@, "Undefined filter does not cause exception during layout build" );

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
    refers_to_instance => $curval_sheet->layout->instance_id,
    curval_field_ids   => [],
);
$curval_filter->write;
# Clear the layout to force the column to be build, and also to build
# dependencies properly in the next test
$layout->clear;
is( scalar @{$curval_filter->values}, 1, "Correct number of values for curval field with filter" );

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
        ? '$calc1'
        : $match
        ? "\$$field"
        : $test eq 'nomatch'
        ? '$tree1'
        : '$string123';

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
        refers_to_instance => $curval_sheet->layout->instance_id,
        curval_field_ids   => [ $curval_sheet->columns->{string1}->id ],
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
    is( scalar @{$curval_filter->values}, $count, "Correct number of values for curval field with $field filter, test $test" );

    # Check that we can create a new record with the filtered curval field in
    $layout->clear;
    my $record_new = GADS::Record->new(
        user     => $sheet->user,
        layout   => $layout,
        schema   => $schema,
    );
    $record_new->initialise;
    is( scalar @{$layout->column($curval_filter->id)->values}, 0, "Correct number of values for curval field with filter" );
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
$layout->clear;
foreach ($layout->all)
{
    $_->type('string');
    $_->write;
}
$layout->clear;
foreach my $col (reverse $layout->all(order_dependencies => 1))
{
    my $name = $col->name;
    try { $col->delete };
    is( $@, '', "Deletion of field $name of type string did not throw exception" );
}

# Calc column tests
$data = [
    {
        daterange1 => ['2000-10-10', '2001-10-10'],
        curval1    => 1,
    },
    {
        daterange1 => ['2012-11-11', '2013-11-11'],
        curval1    => 2,
    },
];

$curval_sheet = t::lib::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
$schema       = $curval_sheet->schema;
$sheet        = t::lib::DataSheet->new(
    data             => $data,
    schema           => $schema,
    curval           => 2,
    curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
);
$layout       = $sheet->layout;
$columns      = $sheet->columns;
$sheet->create_records;

# Attempt to create additional calc field separately.
# This has been known to cause errors with $layout not
# being updated properly

# First try with invalid function
my $calc2_col = GADS::Column::Calc->new(
    schema => $schema,
    user   => undef,
    layout => $layout,
    name   => 'calc2',
    code   => "foobar evaluate (curval)",
);
try { $calc2_col->write };
ok( $@, "Failed to write calc field with invalid function" );

# Then with invalid short name
$calc2_col = GADS::Column::Calc->new(
    schema => $schema,
    user   => undef,
    layout => $layout,
    name   => 'calc2',
    code   => "function evaluate (curval) \n return curval1.value\nend",
);
try { $calc2_col->write };
ok( $@, "Failed to write calc field with invalid short names" );

# Now create properly, with return value of field not in normal
$calc2_col = GADS::Column::Calc->new(
    schema => $schema,
    user   => undef,
    layout => $layout,
    name   => 'calc2',
    code   => "function evaluate (curval1,_id) \n return curval1.field_values.daterange1.from.year .. 'X' .. _id \nend",
);
$calc2_col->write;

# Same for RAG
my $rag2 = GADS::Column::Rag->new(
    schema => $schema,
    user   => undef,
    layout => $layout,
    name   => 'rag2',
    code   => "
        function evaluate (daterange1)
            if daterange1 == nil then return end
            if daterange1.from.year < 2012 then return 'red' end
            if daterange1.from.year == 2012 then return 'amber' end
            if daterange1.from.year > 2012 then return 'green' end
        end
    ",
);
$rag2->write;

# Create a calc field that has something invalid in the nested code
my $calc3_col = GADS::Column::Calc->new(
    schema => $schema,
    user   => undef,
    layout => $layout,
    name   => 'calc3',
    code   => "function evaluate (curval1) \n adsfadsf return curval1.field_values.daterange1.from.year \nend",
);
try { $calc3_col->write } hide => 'ALL';
my ($warning) = $@->exceptions;
like($warning, qr/syntax error/, "Warning received for syntax error in calc");
$calc3_col->delete;

# Same for RAG
my $rag3 = GADS::Column::Rag->new(
    schema => $schema,
    user   => undef,
    layout => $layout,
    name   => 'rag2',
    code   => "
        function evaluate (daterange1)
            foobar
        end
    ",
);
try { $rag3->write } hide => 'ALL';
($warning) = $@->exceptions;
like($warning, qr/syntax error/, "Warning received for syntax error in rag");
$rag3->delete;

# Create calc fields that returns 0
my $calc_zero_int = GADS::Column::Calc->new(
    schema      => $schema,
    user        => undef,
    layout      => $layout,
    name        => 'calc4',
    code        => "function evaluate (curval1) \n return 0 \nend",
    return_type => 'integer',
);
$calc_zero_int->write;
my $calc_zero_str = GADS::Column::Calc->new(
    schema      => $schema,
    user        => undef,
    layout      => $layout,
    name        => 'calc4',
    code        => "function evaluate (curval1) \n return 0 \nend",
    return_type => 'string',
);
$calc_zero_str->write;

# Calc field with version editor
my $calc_version = GADS::Column::Calc->new(
    schema      => $schema,
    user        => undef,
    layout      => $layout,
    name        => 'calc5',
    code        => "function evaluate (_version_user) \n return _version_user.surname \nend",
    return_type => 'string',
);
$calc_version->write;

$layout->clear;

$records = GADS::Records->new(
    user    => $sheet->user,
    layout  => $layout,
    schema  => $schema,
);

# Code values should have been written to database by now
$ENV{GADS_PANIC_ON_ENTERING_CODE} = 1;

my $calc_col = $columns->{calc1};
my $rag_col  = $columns->{rag1};

my @calcs   = qw/2000 2012 2000/;
my @calcs2  = qw/2012 2008 2012/; # From default datasheet values for daterange1 (referenced from curval)
my @rags    = qw/b_red c_amber b_red/;
my @results = @{$records->results};
# Set env variables to allow record write (after retrieving results)
$ENV{GADS_PANIC_ON_ENTERING_CODE} = 0;
$ENV{GADS_NO_FORK} = 1;
push @results, GADS::Record->new(
    user   => $sheet->user,
    layout => $layout,
    schema => $schema,
)->find_current_id(3);
foreach my $record (@results)
{
    my $calc  = shift @calcs;
    my $calc2 = (shift @calcs2) . 'X' . $record->current_id;
    my $rag   = shift @rags;
    is( $record->fields->{$calc_col->id}->as_string, $calc, "Correct calc value for record" );
    is( $record->fields->{$calc2_col->id}->as_string, $calc2, "Correct calc2 value for record" );
    is( $record->fields->{$calc_zero_int->id}->as_string, '0', "Correct calc value for zero int" );
    is( $record->fields->{$calc_zero_str->id}->as_string, '0', "Correct calc value for zero string" );
    is( $record->fields->{$calc_version->id}->as_string, 'User1', "Correct calc value for record version user" );
    is( $record->fields->{$rag_col->id}->as_string, $rag, "Correct rag value for record" );
    # Check we can update the record
    $record->fields->{$columns->{daterange1}->id}->set_value(['2014-10-10', '2015-10-10']);
    $record->fields->{$columns->{curval1}->id}->set_value(2);
    $record->write;
    is( $record->fields->{$calc_col->id}->as_string, '2014', "Correct calc value for record after write" );
    $calc2 = '2008' . 'X' . $record->current_id;
    is( $record->fields->{$calc2_col->id}->as_string, $calc2, "Correct calc2 value for record after write" );
    is( $record->fields->{$rag_col->id}->as_string, 'd_green', "Correct rag value for record after write" );
    is( $record->fields->{$calc_version->id}->as_string, 'User1', "Correct calc value for record version user after write" );
}

done_testing();
