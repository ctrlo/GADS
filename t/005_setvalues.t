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

my $values = {
    string1 => {
        old       => 'foo', # The initial value
        new       => 'bar', # The value it's changed to
        as_string => 'bar', # The string representation of the new value
    },
    integer1 => {
        old       => 100,
        new       => 200,
        as_string => '200',
    },
    enum1 => {
        old       => 1,
        new       => 2,
        as_string => 'foo2',
    },
    tree1 => {
        old       => 4,
        new       => 5,
        as_string => 'tree2',
    },
    date1 => {
        old       => '2010-10-10',
        new       => '2011-10-10',
        as_string => '2011-10-10',
    },
    daterange1 => {
        old       => ['2000-10-10', '2001-10-10'],
        new       => ['2000-11-11', '2001-11-11'],
        as_string => '2000-11-11 to 2001-11-11',
    },
};

my $data = {
    blank => [
        {
            string1    => '',
            integer1   => '',
            enum1      => '',
            tree1      => '',
            date1      => '',
            daterange1 => ['', ''],
        },
    ],
    changed => [
        {
            string1    => 'foo',
            integer1   => '100',
            enum1      => 1,
            tree1      => 4,
            date1      => '2010-10-10',
            daterange1 => ['2000-10-10', '2001-10-10'],
        },
    ],
    nochange => [
        {
            string1    => 'bar',
            integer1   => '200',
            enum1      => 2,
            tree1      => 5,
            date1      => '2011-10-10',
            daterange1 => ['2000-11-11', '2001-11-11'],
        },
    ],
};

for my $test ('blank', 'nochange', 'changed')
{
    my $sheet = t::lib::DataSheet->new(data => $data->{$test});

    my $schema = $sheet->schema;
    my $layout = $sheet->layout;
    my $columns = $sheet->columns;
    $sheet->create_records;

    my $records = GADS::Records->new(
        user    => undef,
        layout  => $layout,
        schema  => $schema,
    );
    $records->search;
    my $results = $records->results;

    is( scalar @$results, 1, "One record in test dataset");

    my ($record) = @$results;

    foreach my $type (keys %$values)
    {
        my $datum = $record->fields->{$columns->{$type}->id};
        if ($test eq 'blank')
        {
            ok( $datum->blank, "$type is blank" );
        }
        else {
            ok( !$datum->blank, "$type is not blank" );
        }
        $datum->set_value($values->{$type}->{new});
        if ($test eq 'blank' || $test eq 'changed')
        {
            ok( $datum->changed, "$type has changed" );
        }
        else {
            ok( !$datum->changed, "$type has not changed" );
        }
        my $as_string = $values->{$type}->{as_string};
        is( $datum->as_string, $as_string, "$type is $as_string" );
    }
}


done_testing();
