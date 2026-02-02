use Test::More;    # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;
use GADS::Filter;
use GADS::View;

use lib 't/lib';
use Test::GADS::DataSheet;

use Data::Dump qw(pp);

my $long_string = "Y3EucBXt2aTYnHNb2hXJTrgAg0QqRieA1kxNo1ud2TbcyxrXMXqu"
                . "/m83YtthBWYXiEdocydX69XqB/6IK+6NqGDZJgofxgjVxGJmP1HONBT651Yj/"
                . "47mRf4+coC3gqvzh6vQ1nCeZyWeVKVuoiiG5INOuwanGJESPDgJrvichI00Czskjah5Ju6/"
                . "tHOez+6p3hciNXUYuq76g6KFkTn4tbWegJd2Hh/bNVYqTX5yDW0MIQQQSoe2i+NLA5xi";

my $data = [
    {
        string1 => [$long_string],
    },
    {
        string1 => ['The quick brown fox jumps over the lazy dog.'],
    }
];

my $sheet = Test::GADS::DataSheet->new(
    data       => $data,
    multivalue => 0,
    calc_code  => "
            function evaluate (L1string1)
                return L1string1
            end
        ",
    calc_return_type => 'string',
);
$sheet->create_records;

my $schema  = $sheet->schema;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
my $user    = $sheet->user_normal1;

my $string1 = $columns->{string1};
my $calc1   = $columns->{calc1};

my $record = GADS::Record->new(
    layout      => $layout,
    schema      => $schema,
    instance_id => 1,
    user        => $user,
);

$record->find_current_id(1);

my $filter = GADS::Filter->new(
    as_hash => {
        rules => [
            {
                id       => $calc1->id,
                type     => 'string',
                value    => $long_string,
                operator => 'equal',
            }
        ],
    },
);

my $view = GADS::View->new(
    name        => 'View table',
    filter      => $filter,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    is_shared   => 1,
);

$view->write( no_errors => 1 );

my $records = GADS::Records->new(
    user   => $user,
    layout => $layout,
    schema => $schema,
    view   => $view
);

is $records->count, 1, "One record found with long string in calc field";

$filter->as_hash->{rules}[0]{value} = "brown";
$filter->as_hash->{rules}[0]{operator} = "contains";

my $view2 = GADS::View->new(
    name        => 'View table 2',
    filter      => $filter,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    is_shared   => 1,
);

$view2->write( no_errors => 1 );

$records->clear;

$records->view($view2);

is $records->count, 1, "One record found with the word `brown` in the string field";

$records->clear;

$records->view(undef);

is $records->count, 2, "No filter, two records found";

$records->clear;

$filter->as_hash->{rules}[0]{value} = "non-existing string";
$filter->as_hash->{rules}[0]{operator} = "equal";

my $view3 = GADS::View->new(
    name        => 'View table 3',
    filter      => $filter,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    is_shared   => 1,
);

$records->view($view);

is $records->count, 0, "No records found with non-existing string";

done_testing;
