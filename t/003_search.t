use Test::More; # tests => 1;
use strict;
use warnings;

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime
use JSON qw(encode_json);
use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use t::lib::DataSheet;

set_fixed_time('10/10/2014 01:00:00', '%m/%d/%Y %H:%M:%S'); # Fix all tests for this date so that CURDATE is consistent

my $long = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum';

my $data = [
    {
        string1    => '',
        integer1   => 4,
        date1      => '',
        daterange1 => ['', ''],
        enum1      => 7,
        tree1      => 10,
        curval1    => 2,
    },{
        string1    => '',
        integer1   => 5,
        date1      => '',
        daterange1 => ['', ''],
        enum1      => 7,
        tree1      => 12,
    },{
        string1    => '',
        integer1   => 6,
        date1      => '2014-10-10',
        daterange1 => ['2014-03-21', '2015-03-01'],
        enum1      => 7,
        tree1      => 11,
    },{
        string1    => 'Foo',
        integer1   => 7,
        date1      => '2014-10-10',
        daterange1 => ['2013-10-10', '2013-12-03'],
        enum1      => 8,
        tree1      => 10,
    },{
        string1    => 'FooBar',
        integer1   => 1,
        date1      => '2015-10-10',
        daterange1 => ['2009-01-04', '2017-06-03'],
        enum1      => 8,
        tree1      => 11,
    },{
        string1    => "${long}1",
        integer1   => 2,
    },{
        string1    => "${long}2",
        integer1   => 3,
    },
];



my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = t::lib::DataSheet->new(
    data             => $data,
    schema           => $schema,
    curval           => 2,
    calc_code        => "function evaluate (daterange1) \n if daterange1.from == nil then return end \n return daterange1.from.epoch \n end",
    calc_return_type => 'date',
);
my $layout  = $sheet->layout;
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
        name  => 'date using CURDATE',
        rules => [{
            id       => $columns->{date1}->id,
            type     => 'date',
            value    => 'CURDATE',
            operator => 'equal',
        }],
        count => 2,
    },
    {
        name  => 'date using CURDATE plus 1 year',
        rules => [{
            id       => $columns->{date1}->id,
            type     => 'date',
            value    => 'CURDATE + '.(86400 * 365), # Might be leap seconds etc, but close enough
            operator => 'equal',
        }],
        count => 1,
    },
    {
        name  => 'date in calc',
        rules => [{
            id       => $columns->{calc1}->id,
            type     => 'date',
            value    => 'CURDATE - '.(86400 * 365), # Might be leap seconds etc, but close enough
            operator => 'equal',
        }],
        count => 1,
    },
    {
        name  => 'date is empty',
        rules => [{
            id       => $columns->{date1}->id,
            type     => 'date',
            operator => 'is_empty',
        }],
        count => 4,
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
    {
        name  => 'Search using enum with different tree in view',
        rules => [{
            id       => $columns->{enum1}->id,
            type     => 'string',
            value    => 'foo1',
            operator => 'equal',
        }],
        count => 3,
    },
    {
        name  => 'Search 2 using enum with different tree in view',
        columns => [$columns->{tree1}->id, $columns->{enum1}->id],
        rules => [
            {
                id       => $columns->{tree1}->id,
                type     => 'string',
                value    => 'tree1',
                operator => 'equal',
            }
        ],
        count => 2,
    },
);
foreach my $filter (@filters)
{
    my $rules = encode_json({
        rules     => $filter->{rules},
        condition => $filter->{condition},
    });

    my $view_columns = $filter->{columns} || [$columns->{string1}->id, $columns->{tree1}->id];
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

    is( $records->count, $filter->{count}, "$filter->{name} for record count $filter->{count}");
    is( @{$records->results}, $filter->{count}, "$filter->{name} actual records matches count $filter->{count}");

    $view->set_sorts($view_columns, 'asc');
    $records = GADS::Records->new(
        user    => undef,
        view    => $view,
        layout  => $layout,
        schema  => $schema,
    );

    is( $records->count, $filter->{count}, "$filter->{name} for record count $filter->{count}");
    is( @{$records->results}, $filter->{count}, "$filter->{name} actual records matches count $filter->{count}");

}

# Search with a limited view defined
my $records = GADS::Records->new(
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);

my $rules = encode_json({
    rules     => [{
        id       => $columns->{date1}->id,
        type     => 'date',
        value    => '2015-01-01',
        operator => 'greater',
    }],
});

my $limit_to_view = GADS::View->new(
    name        => 'Limit to view',
    filter      => $rules,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => undef,
);
$limit_to_view->write;

$rules = encode_json({
    rules     => [{
        id       => $columns->{string1}->id,
        type     => 'string',
        value    => 'Foo',
        operator => 'begins_with',
    }],
});

my $view = GADS::View->new(
    name        => 'Foo',
    filter      => $rules,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => undef,
);
$view->write;

$records = GADS::Records->new(
    user    => {
        limit_to_view => $limit_to_view->id,
    },
    view    => $view,
    layout  => $layout,
    schema  => $schema,
);

is ($records->count, 1, 'Correct number of results when limiting to a view');

# Quick searches
# First with limited view still defined
is (@{$records->search_all_fields('2014-10-10')}, 0, 'Correct number of quick search results when limiting to a view');
# Now normal
$records = GADS::Records->new(
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);
is (@{$records->search_all_fields('2014-10-10')}, 2, 'Quick search for 2014-10-10');
is (@{$records->search_all_fields('Foo')}, 1, 'Quick search for foo');
is (@{$records->search_all_fields('Foo*')}, 5, 'Quick search for foo*');
is (@{$records->search_all_fields('99')}, 1, 'Quick search for 99');
is (@{$records->search_all_fields('1979-01-204')}, 0, 'Quick search for invalid date');

# Specific record retrieval
my $record = GADS::Record->new(
    user   => undef,
    layout => $layout,
    schema => $schema,
);
is( $record->find_record_id(3)->record_id, 3, "Retrieved history record ID 3" );
$record->clear;
is( $record->find_current_id(3)->current_id, 3, "Retrieved current ID 3" );
# Find records from different layout
$record->clear;
is( $record->find_record_id(1)->record_id, 1, "Retrieved history record ID 1 from other datasheet" );
$record->clear;
is( $record->find_current_id(1)->current_id, 1, "Retrieved current ID 1 from other datasheet" );

# Check sorting functionality
# First check default_sort functionality
$records = GADS::Records->new(
    default_sort => {
        type => 'asc',
        id   => -1,
    },
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);
is( $records->results->[0]->current_id, 3, "Correct first record for default_sort (asc)");
is( $records->results->[-1]->current_id, 9, "Correct last record for default_sort (asc)");
$records = GADS::Records->new(
    default_sort => {
        type => 'desc',
        id   => -1,
    },
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);
is( $records->results->[0]->current_id, 9, "Correct first record for default_sort (desc)");
is( $records->results->[-1]->current_id, 3, "Correct last record for default_sort (desc)");
$records = GADS::Records->new(
    default_sort => {
        type => 'desc',
        id   => $columns->{integer1}->id,
    },
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);
is( $records->results->[0]->current_id, 6, "Correct first record for default_sort (column in view)");
is( $records->results->[-1]->current_id, 7, "Correct last record for default_sort (column in view)");

# Standard sort parameter for search()
$records = GADS::Records->new(
    sort => {
        type => 'desc',
        id   => $columns->{integer1}->id,
    },
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);
is( $records->results->[0]->current_id, 6, "Correct first record for standard sort");
is( $records->results->[-1]->current_id, 7, "Correct last record for standard sort");

# Standard sort parameter for search() with invalid column. This can happen if the
# user switches tables and there is still a sort parameter in the session. In this
# case, it should revert to the default search.
$records = GADS::Records->new(
    sort => {
        type => 'desc',
        id   => -1000,
    },
    default_sort => {
        type => 'desc',
        id   => $columns->{integer1}->id,
    },
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);
is( $records->results->[0]->current_id, 6, "Correct first record for standard sort");
is( $records->results->[-1]->current_id, 7, "Correct last record for standard sort");

my @sorts = (
    {
        name         => 'Sort by single column in view ascending',
        show_columns => [$columns->{string1}->id, $columns->{enum1}->id],
        sort_by      => [$columns->{enum1}->id],
        sort_type    => ['asc'],
        first        => qr/^(8|9)$/,
        last         => qr/^(6|7)$/,
    },
    {
        name         => 'Sort by single column not in view ascending',
        show_columns => [$columns->{string1}->id, $columns->{tree1}->id],
        sort_by      => [$columns->{enum1}->id],
        sort_type    => ['asc'],
        first        => qr/^(8|9)$/,
        last         => qr/^(6|7)$/,
    },
    {
        name         => 'Sort by single column not in view descending',
        show_columns => [$columns->{string1}->id, $columns->{tree1}->id],
        sort_by      => [$columns->{enum1}->id],
        sort_type    => ['desc'],
        first        => qr/^(6|7)$/,
        last         => qr/^(8|9)$/,
    },
    {
        name         => 'Sort by two columns, one in view one not in view, asc then desc',
        show_columns => [$columns->{string1}->id, $columns->{tree1}->id],
        sort_by      => [$columns->{enum1}->id, $columns->{daterange1}->id],
        sort_type    => ['asc', 'desc'],
        first        => qr/^(8|9)$/,
        last         => qr/^(7)$/,
    },
    {
        name         => 'Sort with filter on enums',
        show_columns => [$columns->{enum1}->id,$columns->{curval1}->id,$columns->{tree1}->id],
        sort_by      => [$columns->{enum1}->id],
        sort_type    => ['asc'],
        first        => qr/^(3)$/,
        last         => qr/^(6)$/,
        max_id       => 6,
        min_id       => 3,
        count        => 2,
        filter       => {
            rules => [
                {
                    id       => $columns->{tree1}->id,
                    type     => 'string',
                    value    => 'tree1',
                    operator => 'equal',
                },
            ],
        },
    },
    # Sometimes _value table numbers can get mixed up, so try the opposite way round as well
    {
        name         => 'Sort with filter on enums - opposite filter/sort combo',
        show_columns => [$columns->{enum1}->id,$columns->{curval1}->id,$columns->{tree1}->id],
        sort_by      => [$columns->{tree1}->id],
        sort_type    => ['asc'],
        first        => qr/^(3)$/,
        last         => qr/^(4)$/,
        max_id       => 5,
        min_id       => 3,
        count        => 3,
        filter       => {
            rules => [
                {
                    id       => $columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo1',
                    operator => 'equal',
                },
            ],
        },
    },
    {
        name         => 'Sort by enum that is after another enum in the fetched column',
        show_columns => [$columns->{enum1}->id,$columns->{curval1}->id,$columns->{tree1}->id],
        sort_by      => [$columns->{tree1}->id],
        sort_type    => ['asc'],
        first        => qr/^(8|9)$/,
        last         => qr/^(4)$/,
    },
);

foreach my $sort (@sorts)
{
    # If doing a count with the sort, then do an extra pass, one to check that actual
    # number of rows retrieved, and one to check the count calculation function
    my $passes = $sort->{count} ? 3 : 2;
    foreach my $pass (1..$passes)
    {
        my $filter = encode_json($sort->{filter} || {});
        my $view = GADS::View->new(
            name        => 'Test view',
            columns     => $sort->{show_columns},
            filter      => $filter,
            instance_id => 1,
            layout      => $layout,
            schema      => $schema,
            user        => undef,
        );
        $view->write;
        $view->set_sorts($sort->{sort_by}, $sort->{sort_type});

        $records = GADS::Records->new(
            user    => undef,
            view    => $view,
            layout  => $layout,
            schema  => $schema,
        );
        $records->sort({ type => 'desc', id => -1 })
            if $pass == 1;

        # Test override of sort first
        if ($pass == 1)
        {
            my $first = $sort->{max_id} || 9;
            my $last  = $sort->{min_id} || 3;
            is( $records->results->[0]->current_id, $first, "Correct first record for sort override and test $sort->{name}");
            is( $records->results->[-1]->current_id, $last, "Correct last record for sort override and test $sort->{name}");
        }
        elsif ($pass == 2)
        {
            is( @{$records->results}, $sort->{count}, "Correct number of records in results for sort $sort->{name}" )
                if $sort->{count};

            like( $records->results->[0]->current_id, $sort->{first}, "Correct first record for sort $sort->{name}");
            like( $records->results->[-1]->current_id, $sort->{last}, "Correct last record for sort $sort->{name}");
        }
        else {
            is( $records->count, $sort->{count}, "Correct record count for sort $sort->{name}" )
        }
    }
}

restore_time();

done_testing();
