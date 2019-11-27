use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use JSON qw(encode_json);
use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

my $data = [
    {
        string1    => 'Foo',
        integer1   => '100',
        enum1      => 7,
        tree1      => 10,
        date1      => '2010-10-10',
        daterange1 => ['2000-10-10', '2001-10-10'],
        curval1    => 1,
        person1    => 1,
        file1      => {
            name     => 'file1.txt',
            mimetype => 'text/plain',
            content  => 'Text file1',
        },
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

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = Test::GADS::DataSheet->new(
    data             => $data,
    schema           => $schema,
    curval           => 2,
    curval_field_ids => [$curval_sheet->columns->{string1}->id, $curval_sheet->columns->{enum1}->id],
    calc_code        => qq(function evaluate (L1string1) \n return L1string1 .. "XX" \nend),
    calc_return_type => 'string',
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my @tests = (
    {
        name   => 'Enum',
        col    => 'enum1',
        search => [8], # foo2
        count  => 1,
    },
    {
        name   => 'Enum multiple',
        col    => 'enum1',
        search => [7,8], # foo2
        count  => 2,
    },
    {
        name   => 'Tree',
        col    => 'tree1',
        search => [11],
        count  => 1,
    },
    {
        name   => 'Tree multiple',
        col    => 'tree1',
        search => [10,11],
        count  => 2,
    },
    {
        name   => 'String match',
        col    => 'string1',
        search => ['Bar'],
        count  => 1,
    },
    {
        name   => 'String like',
        col    => 'string1',
        search => ['Ba'],
        count  => 1,
    },
    {
        name   => 'String multiple',
        col    => 'string1',
        search => ['Foo', 'Bar'],
        count  => 2,
    },
    {
        name   => 'String no match',
        col    => 'string1',
        search => ['foobar'],
        count  => 0,
    },
    {
        name   => 'Integer',
        col    => 'integer1',
        search => ['200'],
        count  => 1,
    },
    {
        name   => 'Curval',
        col    => 'curval1',
        search => ['1'],
        count  => 1,
    },
    {
        name   => 'Date',
        col    => 'date1',
        search => ['2011-10-10'],
        count  => 1,
    },
    {
        name   => 'Date range',
        col    => 'daterange1',
        search => ['2000-11-11 to 2001-11-11'],
        count  => 1,
    },
    {
        name   => 'File',
        col    => 'file1',
        search => ['file1.txt'],
        count  => 1,
    },
    {
        name   => 'File - begins with',
        col    => 'file1',
        search => ['file'],
        count  => 1,
    },
    {
        name   => 'Calc - begins with',
        col    => 'calc1',
        search => ['Foox'],
        count  => 1,
    },
    {
        name   => 'Rag',
        col    => 'rag1',
        search => ['b_red'],
        count  => 2,
    },
    {
        name   => 'Person',
        col    => 'person1',
        search => ['1'],
        count  => 1,
    },
);

foreach my $test (@tests)
{
    my $filters = [
            +{
                id    => $columns->{$test->{col}}->id,
                value => $test->{search},
            }
    ];
    my $records = GADS::Records->new(
        additional_filters => $filters,
        user               => $sheet->user,
        layout             => $layout,
        schema             => $schema,
    );
    is($records->count, $test->{count}, "Count correct for additional filters $test->{name}");
}

done_testing();
