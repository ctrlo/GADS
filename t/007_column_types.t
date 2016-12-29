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
my $sheet   = t::lib::DataSheet->new(data => $data, schema => $schema, curval => 2);
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
    },
    {
        daterange1 => ['2012-11-11', '2013-11-11'],
    },
];

$sheet   = t::lib::DataSheet->new(data => $data);
$schema  = $sheet->schema;
$layout  = $sheet->layout;
$columns = $sheet->columns;
$sheet->create_records;

$records = GADS::Records->new(
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);

# Code values should have been written to database by now
$ENV{GADS_PANIC_ON_ENTERING_CODE} = 1;

my $calc_col = $columns->{calc1};
my $rag_col  = $columns->{rag1};

my @calcs = qw/2000 2012/;
my @rags  = qw/b_red c_amber/;
foreach my $record (@{$records->results})
{
    my $calc  = shift @calcs;
    my $rag   = shift @rags;
    is( $record->fields->{$calc_col->id}->as_string, $calc, "Correct calc value for record" );
    is( $record->fields->{$rag_col->id}->as_string, $rag, "Correct rag value for record" );
}

$ENV{GADS_PANIC_ON_ENTERING_CODE} = 0;

done_testing();
