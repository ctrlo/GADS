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

my $long = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum';

my $data = [
    {
        string1    => '',
        date1      => '',
        daterange1 => ['', ''],
    },{
        string1    => '',
        date1      => '',
        daterange1 => ['', ''],
    },{
        string1    => '',
        date1      => '2014-10-10',
        daterange1 => ['2014-03-21', '2015-03-01'],
    },{
        string1    => 'Foo',
        date1      => '2014-10-10',
        daterange1 => ['2010-01-04', '2011-06-03'],
    },{
        string1    => 'FooBar',
        date1      => '2015-10-10',
        daterange1 => ['2009-01-04', '2017-06-03'],
    },{
        string1    => "${long}1",
    },{
        string1    => "${long}2",
    },
];

my $sheet = t::lib::DataSheet->new(data => $data);

my $schema = $sheet->schema;
my $layout = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

# Manually force one string to be empty and one to be undef.
# Both should be returned during a search on is_empty
$schema->resultset('String')->find(1)->update({ value => undef });
$schema->resultset('String')->find(2)->update({ value => '' });

my @filters = (
    {
        name  => 'string is Foo',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'Foo',
            operator => 'equal',
        }],
        count => 1,
    },
    {
        name  => 'check case-insensitive search',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'foo',
            operator => 'begins_with',
        }],
        count => 2,
    },
    {
        name  => 'string is long1',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => "${long}1",
            operator => 'equal',
        }],
        count => 1,
    },
    {
        name  => 'string is long',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => $long,
            operator => 'begins_with',
        }],
        count => 2,
    },
    {
        name  => 'date is equal',
        rules => [{
            id       => $columns->{date1}->id,
            type     => 'date',
            value    => '2014-10-10',
            operator => 'equal',
        }],
        count => 2,
    },
    {
        name  => 'string begins with Foo',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'Foo',
            operator => 'begins_with',
        }],
        count => 2,
    },
    {
        name  => 'string is empty',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            operator => 'is_empty',
        }],
        count => 3,
    },
    {
        name  => 'string is not equal to Foo',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'Foo',
            operator => 'not_equal',
        }],
        count => 6,
    },
    {
        name  => 'daterange contains',
        rules => [{
            id       => $columns->{daterange1}->id,
            type     => 'daterange',
            value    => '2014-10-10',
            operator => 'contains',
        }],
        count => 2,
    },
    {
        name  => 'nested search',
        rules => [
            {
                id       => $columns->{string1}->id,
                type     => 'string',
                value    => 'Foo',
                operator => 'begins_with',
            },
            {
                rules => [
                    {
                        id       => $columns->{date1}->id,
                        type     => 'date',
                        value    => '2015-10-10',
                        operator => 'equal',
                    },
                    {
                        id       => $columns->{date1}->id,
                        type     => 'date',
                        value    => '2014-12-01',
                        operator => 'greater',
                    },
                ],
            },
        ],
        condition => 'AND',
        count     => 1,
    },
);

foreach my $filter (@filters)
{
    my $rules = encode_json({
        rules     => $filter->{rules},
        condition => $filter->{condition},
    });

    my $view = GADS::View->new(
        filter      => $rules,
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => undef,
    );

    my $records = GADS::Records->new(
        user    => undef,
        view    => $view,
        layout  => $layout,
        schema  => $schema,
    );

    is( $records->count, $filter->{count}, "$filter->{name} for record count $filter->{count}");
}

done_testing();
