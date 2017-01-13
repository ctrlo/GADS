use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Column::Calc;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use t::lib::DataSheet;

my $data = [
    {
        string1    => 'foo',
        integer1   => '100',
        enum1      => 7,
        tree1      => 10,
        date1      => '2010-10-10',
        daterange1 => ['2000-10-10', '2001-10-10'],
        curval1    => 1,
        file1      => undef, # Add random file
    },
    {
        string1    => 'bar',
        integer1   => '200',
        enum1      => 8,
        tree1      => 11,
        date1      => '2011-10-10',
        daterange1 => ['2000-11-11', '2001-11-11'],
        curval1    => 2,
        file1      => undef,
    },
];

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = t::lib::DataSheet->new(
    data             => $data,
    schema           => $schema,
    curval           => 2,
    curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

# Various tests for field types
#
# Curval tests
my $curval = $columns->{curval1};

is( scalar @{$curval->values}, 2, "Correct number of values for curval field" );

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

# Now check that we're not building all curval values when we're just
# retrieving individual records
$ENV{PANIC_ON_CURVAL_BUILD_VALUES} = 1;

my $records = GADS::Records->new(
    user    => undef,
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
    code   => "function evaluate (curval1,id) \n return curval1.field_values.daterange1.from.year .. 'X' .. id \nend",
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
            if daterange1.from == nil then return end
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

$layout->clear;

$records = GADS::Records->new(
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);

# Code values should have been written to database by now
$ENV{GADS_PANIC_ON_ENTERING_CODE} = 1;

my $calc_col = $columns->{calc1};
my $rag_col  = $columns->{rag1};

my @calcs   = qw/2000 2012/;
my @calcs2  = qw/2012 2008/; # From default datasheet values for daterange1 (referenced from curval)
my @rags    = qw/b_red c_amber/;
my @results = @{$records->results};
# Set env variables to allow record write (after retrieving results)
$ENV{GADS_PANIC_ON_ENTERING_CODE} = 0;
$ENV{GADS_NO_FORK} = 1;
foreach my $record (@results)
{
    my $calc  = shift @calcs;
    my $calc2 = (shift @calcs2) . 'X' . $record->current_id;
    my $rag   = shift @rags;
    is( $record->fields->{$calc_col->id}->as_string, $calc, "Correct calc value for record" );
    is( $record->fields->{$calc2_col->id}->as_string, $calc2, "Correct calc2 value for record" );
    is( $record->fields->{$rag_col->id}->as_string, $rag, "Correct rag value for record" );
    # Check we can update the record
    $record->fields->{$columns->{daterange1}->id}->set_value(['2014-10-10', '2015-10-10']);
    $record->fields->{$columns->{curval1}->id}->set_value(2);
    $record->write;
    is( $record->fields->{$calc_col->id}->as_string, '2014', "Correct calc value for record after write" );
    $calc2 = '2008' . 'X' . $record->current_id;
    is( $record->fields->{$calc2_col->id}->as_string, $calc2, "Correct calc2 value for record after write" );
    is( $record->fields->{$rag_col->id}->as_string, 'd_green', "Correct rag value for record after write" );
}

done_testing();
