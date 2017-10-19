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
        tree1      => 'tree1',
    },
    {
        daterange1 => ['2012-11-11', '2013-11-11'],
        curval1    => 2,
        tree1      => 'tree1',
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
    calc_code        => "function evaluate (L1daterange1) \n return L1daterange1.from.epoch \n end",
    calc_return_type => 'date',
);
my $layout       = $sheet->layout;
my $columns      = $sheet->columns;
$sheet->create_records;

my $autocur1 = $curval_sheet->add_autocur(
    curval_field_ids      => [$columns->{daterange1}->id],
    refers_to_instance_id => 1,
    related_field_id      => $columns->{curval1}->id,
);
$layout->clear; # Ensure main layout takes account of its new child autocurs

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

# Then with short name from other table (invalid)
$calc2_col = GADS::Column::Calc->new(
    schema => $schema,
    user   => undef,
    layout => $layout,
    name   => 'calc2',
    code   => "function evaluate (L2string1) \n return L2string1\nend",
);
try { $calc2_col->write };
like( $@, qr/It is only possible to use fields from the same table/, "Failed to write calc field with short name from other table" );

# Create a calc field that has something invalid in the nested code
my $calc_inv_string = GADS::Column::Calc->new(
    schema => $schema,
    user   => undef,
    layout => $layout,
    name   => 'calc3',
    code   => "function evaluate (L1curval1) \n adsfadsf return L1curval1.field_values.L2daterange1.from.year \nend",
);
try { $calc_inv_string->write } hide => 'ALL';
my ($warning) = $@->exceptions;
like($warning, qr/syntax error/, "Warning received for syntax error in calc");

# Invalid Lua code with return value not string
my $calc_inv_int = GADS::Column::Calc->new(
    schema      => $schema,
    user        => undef,
    layout      => $layout,
    name        => 'calc3',
    return_type => 'integer',
    code        => "function evaluate (L1curval1) \n adsfadsf return L1curval1.field_values.L2daterange1.from.year \nend",
);
try { $calc_inv_int->write } hide => 'ALL';
($warning) = $@->exceptions;
like($warning, qr/syntax error/, "Warning received for syntax error in calc");

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

# Check that numeric return type from calc can be used in another calc
my $calc_integer = GADS::Column::Calc->new(
    schema      => $schema,
    user        => undef,
    layout      => $layout,
    name        => 'calc_integer',
    name_short  => 'calc_integer',
    return_type => 'integer',
    code        => "function evaluate (L1string1) \n return 450 \nend",
);
$calc_integer->write;
my $calc_numeric = GADS::Column::Calc->new(
    schema      => $schema,
    user        => undef,
    layout      => $layout,
    name        => 'calc_numeric',
    name_short  => 'calc_numeric',
    return_type => 'numeric',
    code        => "function evaluate (L1string1) \n return 10.56 \nend",
);
$calc_numeric->write;
$layout->clear;

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
        name   => 'use date from another calc field',
        type   => 'Calc',
        code   => qq(function evaluate (L1calc1) \n return L1calc1.year \nend),
        before => '2000',
        after  => '2014'
    },
    {
        name   => 'use value from another calc field (integer)', # Lua will bork if calc_integer not proper number
        type   => 'Calc',
        code   => qq(function evaluate (calc_integer) \n if calc_integer > 200 then return "greater" else return "less" end \nend),
        before => 'greater',
        after  => 'greater'
    },
    {
        name   => 'use value from another calc field (numeric)',
        type   => 'Calc',
        code   => qq(function evaluate (calc_numeric) \n if calc_numeric > 100 then return "greater" else return "less" end \nend),
        before => 'less',
        after  => 'less'
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
        name        => 'calc fields that returns 0 (date)',
        type        => 'Calc',
        code        => "function evaluate (L1curval1) \n return 0 \nend",
        return_type => 'date',
        before      => '1970-01-01',
        after       => '1970-01-01',
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
    {
        name   => 'tree node',
        type   => 'Calc',
        code   => qq(function evaluate (L1tree1) \n return L1tree1.value \nend),
        before => 'tree1',
        after  => 'tree3'
    },
    {
        name   => 'autocur',
        type   => 'Calc',
        layout => $curval_sheet->layout,
        record_check => 1,
        code   => qq(function evaluate (L2autocur1)
            return_value = ''
            for _, v in pairs(L2autocur1) do
                return_value = return_value .. v.field_values.L1daterange1.from.year
            end
            return return_value
        end),
        before => '20002000', # Original first record plus new record
        after  => '2000', # Only one referring record after test
    },
    {
        name          => 'autocur code update only',
        type          => 'Calc',
        layout        => $curval_sheet->layout,
        record_check  => 1,
        curval_update => 0,
        code          => qq(function evaluate (L2autocur1)
            return_value = ''
            for _, v in pairs(L2autocur1) do
                return_value = return_value .. v.field_values.L1daterange1.from.year
            end
            return return_value
        end),
        before => '20002000', # Original first record plus new record
        after  => '20002014', # One record has daterange updated only
    },
);

foreach my $test (@tests)
{
    # Create a calc field that has something invalid in the nested code
    my $code_col = "GADS::Column::$test->{type}"->new(
        schema         => $schema,
        user           => undef,
        layout         => $test->{layout} || $layout,
        name           => 'code col',
        return_type    => $test->{return_type} || 'string',
        decimal_places => $test->{decimal_places},
        code           => $test->{code},
    );
    $code_col->write;
    $layout->clear;

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
    $record_new->fields->{$columns->{tree1}->id}->set_value(10);
    try { $record_new->write } hide => 'WARNING'; # Hide warnings from invalid calc fields
    my $cid = $record_new->current_id;
    $record_new->clear;
    $record_new->find_current_id($cid);
    push @results, $record_new;

    foreach my $record (@results)
    {
        my $before = $test->{before};
        my $cid = $record->current_id;
        $before =~ s/__ID/$cid/;
        my $record_check;
        if (my $rcid = $test->{record_check})
        {
            $record_check = GADS::Record->new(
                user   => $sheet->user,
                layout => $test->{layout},
                schema => $schema,
            );
            $record_check->find_current_id($rcid);
        }
        else {
            $record_check = $record;
        }
        is( $record_check->fields->{$code_col->id}->as_string, $before, "Correct code value for test $test->{name} (before)" );

        # Check we can update the record
        set_fixed_time('11/15/2014 01:00:00', '%m/%d/%Y %H:%M:%S');
        $record->fields->{$columns->{daterange1}->id}->set_value(['2014-10-10', '2015-10-10']);
        $record->fields->{$columns->{curval1}->id}->set_value(2)
            unless exists $test->{curval_update} && !$test->{curval_update};
        $record->fields->{$columns->{tree1}->id}->set_value(12);
        $record->user({ id => 2 });
        try { $record->write } hide => 'WARNING'; # Hide warnings from invalid calc fields
        $@->reportFatal; # In case any fatal errors
        my $after = $test->{after};
        $after =~ s/__ID/$cid/;
        if (my $rcid = $test->{record_check})
        {
            $record_check->clear;
            $record_check->find_current_id($rcid);
        }
        is( $record_check->fields->{$code_col->id}->as_string, $after, "Correct code value for test $test->{name} (after)" );
        is( $record->fields->{$calc_inv_string->id}->as_string, '<evaluation error>', "<evaluation error>or test $test->{name}" );
        is( $record->fields->{$calc_inv_int->id}->as_string, '', "<evaluation error>2or test $test->{name}" );

        unless ($test->{record_check}) # Test will not work from wrong datasheet
        {
            $schema->resultset('Enumval')->find(12)->update({ deleted => 1 });
            $layout->clear;
            my $current_id = $record->current_id;
            $record->clear;
            $record->find_current_id($current_id);
            $record->fields->{$columns->{string1}->id}->set_value('Foobar'); # Ensure change has happened
            try { $record->write } hide => 'WARNING';
            $@->reportFatal; # In case any fatal errors
            $record->clear;
            $record->find_current_id($current_id);
            is( $record->fields->{$code_col->id}->as_string, $after, "Correct code value for test $test->{name} after enum deletion" );
        }

        # Reset values for next test
        $schema->resultset('Enumval')->find(12)->update({ deleted => 0 });
        $layout->clear;
        set_fixed_time('10/22/2014 01:00:00', '%m/%d/%Y %H:%M:%S');
        $record->fields->{$columns->{daterange1}->id}->set_value($data->[0]->{daterange1});
        $record->fields->{$columns->{curval1}->id}->set_value($data->[0]->{curval1});
        $record->fields->{$columns->{string1}->id}->set_value('');
        $record->fields->{$columns->{tree1}->id}->set_value(10);
        $record->user({ id => 1 });
        try { $record->write } hide => 'WARNING'; # Hide warnings from invalid calc fields
        $@->reportFatal; # In case any fatal errors
    }
    # XXX Hack to allow record to be deleted
    $record_new->user->{permission}->{delete} = 1;
    $record_new->delete_current;
    $code_col->delete;
}

restore_time();

done_testing();
