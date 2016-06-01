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
        old           => 'foo', # The initial value
        old_as_string => 'foo', # The initial value
        new           => 'bar', # The value it's changed to
        new_as_string => 'bar', # The string representation of the new value
    },
    integer1 => {
        old           => 100,
        old_as_string => '100',
        new           => 200,
        new_as_string => '200',
    },
    enum1 => {
        old           => 7,
        old_as_string => 'foo1',
        new           => 8,
        new_as_string => 'foo2',
    },
    tree1 => {
        old           => 10,
        old_as_string => 'tree1',
        new           => 11,
        new_as_string => 'tree2',
    },
    date1 => {
        old           => '2010-10-10',
        old_as_string => '2010-10-10',
        new           => '2011-10-10',
        new_as_string => '2011-10-10',
    },
    daterange1 => {
        old           => ['2000-10-10', '2001-10-10'],
        old_as_string => '2000-10-10 to 2001-10-10',
        new           => ['2000-11-11', '2001-11-11'],
        new_as_string => '2000-11-11 to 2001-11-11',
    },
    curval1 => {
        old           => 1,
        old_as_string => 'Foo, 50, , , 2014-10-10, 2012-02-10 to 2013-06-15, , , c_amber, ',
        new           => 2,
        new_as_string => 'Bar, 99, , , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, ',
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
            curval1    => '',
        },
    ],
    changed => [
        {
            string1    => 'foo',
            integer1   => '100',
            enum1      => 7,
            tree1      => 10,
            date1      => '2010-10-10',
            daterange1 => ['2000-10-10', '2001-10-10'],
            curval1    => 1,
        },
    ],
    nochange => [
        {
            string1    => 'bar',
            integer1   => '200',
            enum1      => 8,
            tree1      => 11,
            date1      => '2011-10-10',
            daterange1 => ['2000-11-11', '2001-11-11'],
            curval1    => 2,
        },
    ],
};

for my $test ('blank', 'nochange', 'changed')
{
    my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
    $curval_sheet->create_records;
    my $schema  = $curval_sheet->schema;
    my $sheet   = t::lib::DataSheet->new(data => $data->{$test}, schema => $schema, curval => 2);
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;
    $sheet->create_records;

    my $records = GADS::Records->new(
        user    => undef,
        layout  => $layout,
        schema  => $schema,
    );
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
        if ($test eq 'changed' || $test eq 'nochange')
        {
            ok( $datum->oldvalue, "$type oldvalue exists" );
            my $old = $test eq 'changed' ? $values->{$type}->{old_as_string} : $values->{$type}->{new_as_string};
            is( $datum->oldvalue && $datum->oldvalue->as_string, $old, "$type oldvalue exists and matches for test $test" );
        }
        elsif ($test eq 'blank')
        {
            ok( $datum->oldvalue && $datum->oldvalue->blank, "$type was blank" );
        }
        my $new_as_string = $values->{$type}->{new_as_string};
        is( $datum->as_string, $new_as_string, "$type is $new_as_string" );
    }
}


done_testing();
