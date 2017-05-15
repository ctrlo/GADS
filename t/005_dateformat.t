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

my $tests = {
    'yyyy-MM-dd' => {
        data => [
            {
                date1      => '2010-10-10',
                daterange1 => ['2000-10-10', '2001-10-10'],
            },
            {
                date1      => '2011-10-10',
                daterange1 => ['2009-08-10', '2012-10-10'],
            },
            {
                date1      => '2001-10-10',
                daterange1 => ['2008-08-10', '2011-10-10'],
            },
        ],
        search => {
            valid   => '2010-10-10',
            invalid => '10-10-2010',
            calc    => '2008-08-10',
        },
        retrieved => {
            date      => '2010-10-10',
            daterange => '2009-08-10 to 2012-10-10',
        },
    },
    'dd-MM-yyyy' => {
        data => [
            {
                date1      => '10-10-2010',
                daterange1 => ['10-10-2000', '10-10-2001'],
            },
            {
                date1      => '10-10-2011',
                daterange1 => ['10-08-2009', '10-10-2012'],
            },
            {
                date1      => '10-10-2001',
                daterange1 => ['10-08-2008', '10-10-2011'],
            },
        ],
        search => {
            valid   => '10-10-2010',
            invalid => '2010-10-10',
            calc    => '10-08-2008',
        },
        retrieved => {
            date      => '10-10-2010',
            daterange => '10-08-2009 to 10-10-2012',
        },
    },
};

foreach my $format (qw/yyyy-MM-dd dd-MM-yyyy/)
{
    my $config  = {
        gads => {
            dateformat => $format,
        },
    };
    GADS::Config->instance->config($config);
    my $test = $tests->{$format};
    my $sheet   = t::lib::DataSheet->new(
        data             => $test->{data},
        calc_code        => "function evaluate (L1daterange1) \n return L1daterange1.from.epoch \n end",
        calc_return_type => 'date',
    );
    my $schema  = $sheet->schema;
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;
    $sheet->create_records;

    # First test: check format of date column with search
    my $rules = encode_json({
        rules => [
            {
                id       => $columns->{date1}->id,
                type     => 'date',
                value    => $test->{search}->{valid},
                operator => 'equal',
            }
        ],
    });

    my $view_columns = [$columns->{date1}->id, $columns->{daterange1}->id];

    my $view = GADS::View->new(
        name        => 'Test view',
        filter      => $rules,
        columns     => $view_columns,
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

    is( $records->count, 1, "Correct number of records for date search");

    # Check that format retrieved is correct
    my $record = $records->single;
    my $date_id = $columns->{date1}->id;
    is( $record->fields->{$date_id}->as_string, $test->{retrieved}->{date}, "Date format correct for retrieved record");

    # check format of daterange column with search
    $rules = encode_json({
        rules => [
            {
                id       => $columns->{daterange1}->id,
                type     => 'date',
                value    => $test->{search}->{valid},
                operator => 'contains',
            }
        ],
    });
    $view->filter($rules);
    $view->write;
    $records->clear;
    is( $records->count, 2, "Correct number of records for daterange search");

    # Check that format retrieved is correct
    $record = $records->single;
    my $daterange_id = $columns->{daterange1}->id;
    is( $record->fields->{$daterange_id}->as_string, $test->{retrieved}->{daterange}, "Date range format correct for retrieved record");

    # Try searching for the calc value
    $rules = encode_json({
        rules => [
            {
                id       => $columns->{calc1}->id,
                type     => 'date',
                value    => $test->{search}->{calc},
                operator => 'equal',
            }
        ],
    });
    $view->filter($rules);
    $view->write;
    $records->clear;
    is( $records->count, 1, "Correct number of records for calc date search, format $format");

    # Try a quick search for date field
    $records->clear;
    my $results = $records->search_all_fields($test->{search}->{valid});
    is( @$results, 1, "Correct number of results for quick search, format $format" );

    # Try a quick search for calc field
    $records->clear;
    $results = $records->search_all_fields($test->{search}->{calc});
    is( @$results, 1, "Correct number of results for quick search for calc, format $format" );

    # Try creating a filter with invalid date format
    $rules = encode_json({
        rules => [
            {
                id       => $columns->{date1}->id,
                type     => 'date',
                value    => $test->{search}->{invalid},
                operator => 'equal',
            }
        ],
    });
    $view->filter($rules);
    try { $view->write };
    ok( $@, "Attempt to create filter with invalid date failed" );

    # Try creating a filter with empty string (invalid)
    $rules = encode_json({
        rules => [
            {
                id       => $columns->{date1}->id,
                type     => 'date',
                value    => '',
                operator => 'equal',
            }
        ],
    });
    $view->filter($rules);
    try { $view->write };
    ok( $@, "Attempt to create filter with empty string failed" );
}

done_testing();
