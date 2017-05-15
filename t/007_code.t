use Test::More; # tests => 1;
use strict;
use warnings;

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime
use JSON qw(encode_json);
use Log::Report;
use GADS::Column::Calc;
use GADS::Filter;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use t::lib::DataSheet;

set_fixed_time('10/22/2014 01:00:00', '%m/%d/%Y %H:%M:%S'); # Fix all tests for _version_datetime calc

my $data = [
    {
        daterange1 => ['2000-10-10', '2001-10-10'],
        curval1    => 1,
    },
    {
        daterange1 => ['2012-11-11', '2013-11-11'],
        curval1    => 2,
    },
];

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema       = $curval_sheet->schema;
my $sheet        = t::lib::DataSheet->new(
    data             => $data,
    schema           => $schema,
    user_count       => 2,
    curval           => 2,
    curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
);
my $layout       = $sheet->layout;
my $columns      = $sheet->columns;
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
    code   => "foobar evaluate (L1curval)",
);
try { $calc2_col->write };
ok( $@, "Failed to write calc field with invalid function" );

# Then with invalid short name
$calc2_col = GADS::Column::Calc->new(
    schema => $schema,
    user   => undef,
    layout => $layout,
    name   => 'calc2',
    code   => "function evaluate (L1curval) \n return L1curval1.value\nend",
);
try { $calc2_col->write };
ok( $@, "Failed to write calc field with invalid short names" );

# Create a calc field that has something invalid in the nested code
my $calc3_col = GADS::Column::Calc->new(
    schema => $schema,
    user   => undef,
    layout => $layout,
    name   => 'calc3',
    code   => "function evaluate (L1curval1) \n adsfadsf return L1curval1.field_values.L2daterange1.from.year \nend",
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
        function evaluate (L1daterange1)
            foobar
        end
    ",
);
try { $rag3->write } hide => 'ALL';
($warning) = $@->exceptions;
like($warning, qr/syntax error/, "Warning received for syntax error in rag");
$rag3->delete;

my @tests = (
    {
        name   => 'return value of curval field not in normal view',
        type   => 'Calc',
        code   => "function evaluate (L1curval1,_id) \n return L1curval1.field_values.L2daterange1.from.year .. 'X' .. _id \nend",
        before => '2012X__ID', # __ID replaced by current ID
        after  => '2008X__ID',
    },
    {
        name => 'rag from daterange',
        type => 'Rag',
        code   => "
            function evaluate (L1daterange1)
                if L1daterange1 == nil then return end
                if L1daterange1.from.year < 2012 then return 'red' end
                if L1daterange1.from.year == 2012 then return 'amber' end
                if L1daterange1.from.year > 2012 then return 'green' end
            end
        ",
        before => 'b_red',
        after  => 'd_green',
    },
    {
        name           => 'decimal calc',
        type           => 'Calc',
        code           => "function evaluate (L1daterange1) \n return L1daterange1.from.year / 10 \nend",
        return_type    => 'numeric',
        decimal_places => 1,
        before         => '200.0',
        after          => '201.4',
    },
    {
        name        => 'calc fields that returns 0 (int)',
        type        => 'Calc',
        code        => "function evaluate (L1curval1) \n return 0 \nend",
        return_type => 'integer',
        before      => '0',
        after       => '0',
    },
    {
        name        => 'calc fields that returns 0 (string)',
        type        => 'Calc',
        code        => "function evaluate (L1curval1) \n return 0 \nend",
        return_type => 'string',
        before      => '0',
        after       => '0',
    },
    {
        name   => 'field with version editor',
        type   => 'Calc',
        code   => qq(function evaluate (_version_user) \n return _version_user.surname \nend),
        before => 'User1',
        after  => 'User2',
    },
    {
        name   => 'field with version date',
        type   => 'Calc',
        code   => qq(function evaluate (_version_datetime) \n return _version_datetime.day \nend),
        before => '22',
        after  => '15'
    },
);

foreach my $test (@tests)
{
    # Create a calc field that has something invalid in the nested code
    my $code_col = "GADS::Column::$test->{type}"->new(
        schema         => $schema,
        user           => undef,
        layout         => $layout,
        name           => 'code col',
        return_type    => $test->{return_type} || 'string',
        decimal_places => $test->{decimal_places},
        code           => $test->{code},
    );
    $code_col->write;

    my @results;
    
    # Code values should have been written to database by now
    $ENV{GADS_PANIC_ON_ENTERING_CODE} = 1;
    my $record = GADS::Records->new(
        user    => $sheet->user,
        layout  => $layout,
        schema  => $schema,
    )->single;
    push @results, $record;
    # Set env variables to allow record write (after retrieving results)
    $ENV{GADS_PANIC_ON_ENTERING_CODE} = 0;
    $ENV{GADS_NO_FORK} = 1;

    push @results, GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    )->find_current_id($record->current_id);

    # Plus new record
    my $record_new = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record_new->initialise;
    $record_new->fields->{$columns->{daterange1}->id}->set_value(['2000-10-10', '2001-10-10']);
    $record_new->fields->{$columns->{curval1}->id}->set_value(1);
    $record_new->write;
    my $cid = $record_new->current_id;
    $record_new->clear;
    $record_new->find_current_id($cid);
    push @results, $record_new;

    foreach my $record (@results)
    {
        my $before = $test->{before};
        my $cid = $record->current_id;
        $before =~ s/__ID/$cid/;
        is( $record->fields->{$code_col->id}->as_string, $before, "Correct code value for test $test->{name}" );

        # Check we can update the record
        set_fixed_time('11/15/2014 01:00:00', '%m/%d/%Y %H:%M:%S');
        $record->fields->{$columns->{daterange1}->id}->set_value(['2014-10-10', '2015-10-10']);
        $record->fields->{$columns->{curval1}->id}->set_value(2);
        $record->user({ id => 2 });
        $record->write;
        my $after = $test->{after};
        $after =~ s/__ID/$cid/;
        is( $record->fields->{$code_col->id}->as_string, $after, "Correct code value for test $test->{name}" );

        # Reset values for next test
        set_fixed_time('10/22/2014 01:00:00', '%m/%d/%Y %H:%M:%S');
        $record->fields->{$columns->{daterange1}->id}->set_value($data->[0]->{daterange1});
        $record->fields->{$columns->{curval1}->id}->set_value($data->[0]->{curval1});
        $record->user({ id => 1 });
        $record->write;
    }
    $code_col->delete;
}

restore_time();

done_testing();
