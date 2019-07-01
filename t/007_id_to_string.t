use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use JSON qw(encode_json);
use Log::Report;

use t::lib::DataSheet;

my $data = [
    {
        string1    => 'Foo',
        integer1   => '100',
        enum1      => 7,
        tree1      => 10,
        date1      => '2010-10-10',
        daterange1 => ['2000-10-10', '2001-10-10'],
        curval1    => 1,
    },
    {
        string1    => 'Bar',
        integer1   => '200',
        enum1      => 8,
        tree1      => 11,
        date1      => '2011-10-10',
        daterange1 => ['2000-11-11', '2001-11-11'],
        curval1    => 2,
    },
];

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = t::lib::DataSheet->new(
    data             => $data,
    schema           => $schema,
    curval           => 2,
    curval_field_ids => [$curval_sheet->columns->{string1}->id, $curval_sheet->columns->{enum1}->id],
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my @tests = (
    {
        name   => 'enum1',
        id     => 7,
        string => 'foo1',
    },
    {
        name   => 'tree1',
        id     => 11,
        string => 'tree2',
    },
    {
        name   => 'person1',
        id     => 1,
        string => 'User1, User1',
    },
    {
        name   => 'curval1',
        id     => 2,
        string => 'Bar, foo2',
    },
    {
        name   => 'rag1',
        id     => 'b_red',
        string => 'Red',
    },
);

foreach my $test (@tests)
{
    my $col = $columns->{$test->{name}};
    ok($col->fixedvals, "Column $test->{name} has fixed values");
    is($col->id_as_string($test->{id}), $test->{string}, "ID to string correct for $test->{name}");
    is($col->id_as_string(undef), '', "ID to string correct for $test->{name} for undefined ID");
}

done_testing();
