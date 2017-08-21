use Test::More; # tests => 1;
use strict;
use warnings;

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime
use JSON qw(encode_json);
use Log::Report;
use GADS::Filter;
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
        curval1    => 1,
    },{
        string1    => '',
        integer1   => 5,
        date1      => '',
        daterange1 => ['', ''],
        enum1      => 7,
        tree1      => 12,
        curval1    => 2,
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
        enum1      => 7, # Changed to 8 after creation to have multiple versions
        tree1      => 10,
    },{
        string1    => 'FooBar',
        date1      => '2015-10-10',
        daterange1 => ['2009-01-04', '2017-06-03'],
        enum1      => 8,
        tree1      => 11,
        curval2    => 1,
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
my $curval_columns = $curval_sheet->columns;
my $sheet   = t::lib::DataSheet->new(
    data             => $data,
    schema           => $schema,
    curval           => 2,
    multivalue       => 1,
    instance_id      => 1,
    calc_code        => "function evaluate (L1daterange1) \n if L1daterange1 == nil then return end \n return L1daterange1.from.epoch \n end",
    calc_return_type => 'date',
    column_count     => {
        enum   => 1,
        curval => 2,
    },
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
# Position curval first, as its internal _value fields are more
# likely to cause problems and therefore representative test failures
my @position = (
    $columns->{curval1}->id,
    $columns->{string1}->id,
    $columns->{integer1}->id,
    $columns->{date1}->id,
    $columns->{daterange1}->id,
    $columns->{enum1}->id,
    $columns->{tree1}->id,
);
$layout->position(@position);
$sheet->create_records;

my $record = GADS::Record->new(
    user   => $sheet->user,
    layout => $layout,
    schema => $schema,
);
$record->find_current_id(6);
$record->fields->{$columns->{enum1}->id}->set_value(8);
$record->write(no_alerts => 1);

# Add another curval field to a new table
my $curval_sheet2 = t::lib::DataSheet->new(schema => $schema, instance_id => 3, curval_offset => 12);
$curval_sheet2->create_records;
my $curval3 = GADS::Column::Curval->new(
    name               => 'curval3',
    type               => 'curval',
    user               => $sheet->user,
    layout             => $curval_sheet->layout,
    schema             => $schema,
    refers_to_instance => $curval_sheet2->instance_id,
    curval_field_ids   => [$curval_sheet2->columns->{string1}->id],
);
$curval3->write;
$curval_sheet->layout->clear;
$layout->clear;
my $records = GADS::Records->new(
    user    => undef,
    layout  => $curval_sheet->layout,
    schema  => $schema,
);
my $r = $records->single;
my ($curval3_value) = $schema->resultset('Current')->search({ 'instance_id' => $curval_sheet2->instance_id })->get_column('id')->all;
$r->fields->{$curval3->id}->set_value($curval3_value);
$r->write(no_alerts => 1);


# Manually force one string to be empty and one to be undef.
# Both should be returned during a search on is_empty
$schema->resultset('String')->find(3)->update({ value => undef });
$schema->resultset('String')->find(4)->update({ value => '' });

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
        name  => 'date is empty - value as array ref',
        rules => [{
            id       => $columns->{date1}->id,
            type     => 'date',
            operator => 'is_empty',
            value    => [],
        }],
        count => 4,
    },
    {
        name  => 'date is blank string', # Treat as empty
        rules => [{
            id       => $columns->{date1}->id,
            type     => 'date',
            value    => '',
            operator => 'equal',
        }],
        count     => 4,
        no_errors => 1, # Would normally bork
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
        name  => 'string does not begin with Foo',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'Foo',
            operator => 'not_begins_with',
        }],
        count => 5,
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
        name  => 'string is not equal to nothing', # should convert to not empty
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => '',
            operator => 'not_equal',
        }],
        count => 4,
    },
    {
        name  => 'string is not equal to nothing (array ref)', # should convert to not empty
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => [],
            operator => 'not_equal',
        }],
        count => 4,
    },
    {
        name  => 'greater than undefined value', # matches against empty instead
        rules => [{
            id       => $columns->{integer1}->id,
            type     => 'integer',
            operator => 'greater',
        }],
        count => 1,
    },
    {
        name  => 'daterange less than',
        rules => [{
            id       => $columns->{daterange1}->id,
            type     => 'daterange',
            value    => '2013-12-31',
            operator => 'less',
        }],
        count => 1,
    },
    {
        name  => 'daterange less or equal',
        rules => [{
            id       => $columns->{daterange1}->id,
            type     => 'daterange',
            value    => '2013-12-31',
            operator => 'less_or_equal',
        }],
        count => 2,
    },
    {
        name  => 'daterange greater than',
        rules => [{
            id       => $columns->{daterange1}->id,
            type     => 'daterange',
            value    => '2013-12-31',
            operator => 'greater',
        }],
        count => 1,
    },
    {
        name  => 'daterange greater or equal',
        rules => [{
            id       => $columns->{daterange1}->id,
            type     => 'daterange',
            value    => '2014-10-10',
            operator => 'greater_or_equal',
        }],
        count => 2,
    },
    {
        name  => 'daterange equal',
        rules => [{
            id       => $columns->{daterange1}->id,
            type     => 'daterange',
            value    => '2014-03-21 to 2015-03-01',
            operator => 'equal',
        }],
        count => 1,
    },
    {
        name  => 'daterange not equal',
        rules => [{
            id       => $columns->{daterange1}->id,
            type     => 'daterange',
            value    => '2014-03-21 to 2015-03-01',
            operator => 'not_equal',
        }],
        count => 6,
    },
    {
        name  => 'daterange empty',
        rules => [{
            id       => $columns->{daterange1}->id,
            type     => 'daterange',
            operator => 'is_empty',
        }],
        count => 4,
    },
    {
        name  => 'daterange not empty',
        rules => [{
            id       => $columns->{daterange1}->id,
            type     => 'daterange',
            operator => 'is_not_empty',
        }],
        count => 3,
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
        name  => 'Search negative multivalue enum',
        rules => [{
            id       => $columns->{enum1}->id,
            type     => 'string',
            value    => 'foo1',
            operator => 'not_equal',
        }],
        count => 4,
    },
    {
        name  => 'Search using enum with curval in view',
        columns => [$columns->{curval1}->id],
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
    {
        name  => 'Search for ID',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => -11, # Special id for ID column
                type     => 'integer',
                value    => '4',
                operator => 'equal',
            }
        ],
        count => 1,
    },
    {
        name  => 'Search for multiple IDs',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => -11, # Special id for ID column
                type     => 'integer',
                value    => ['4', '5'],
                operator => 'equal',
            }
        ],
        count => 2,
    },
    {
        name  => 'Search for empty IDs',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => -11, # Special id for ID column
                type     => 'integer',
                value    => [],
                operator => 'equal',
            }
        ],
        count => 0,
    },
    {
        name  => 'Search for version date 1',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => -12, # Special id for version datetime column
                type     => 'date',
                value    => '2014-10-10',
                operator => 'greater',
            },
            {
                id       => -12, # Special id for version datetime column
                type     => 'date',
                value    => '2014-10-11',
                operator => 'less',
            }
        ],
        condition => 'AND',
        count     => 7,
    },
    {
        name  => 'Search for version date 2',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => -12, # Special id for version datetime column
                type     => 'date',
                value    => '2014-10-15',
                operator => 'greater',
            },
        ],
        count => 0,
    },
    {
        name  => 'Search for version editor',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => -13, # Special id for version editor ID
                type     => 'integer',
                value    => '1',
                operator => 'equal',
            },
        ],
        count => 7,
    },
    {
        name  => 'Search for invalid date',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $columns->{date1}->id,
                type     => 'date',
                value    => '20188-01',
                operator => 'equal',
            },
        ],
        count     => 0,
        no_errors => 1,
    },
    {
        name  => 'Search for invalid daterange',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $columns->{daterange1}->id,
                type     => 'date',
                value    => '20188-01 XX',
                operator => 'equal',
            },
        ],
        count     => 0,
        no_errors => 1,
    },
    {
        name  => 'Search by curval ID',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $columns->{curval1}->id,
                type     => 'string',
                value    => '2',
                operator => 'equal',
            },
        ],
        count     => 1,
        no_errors => 1,
    },
    {
        name  => 'Search curval ID and enum, only curval in view',
        columns => [$columns->{curval1}->id], # Ensure it's added as first join
        rules => [
            {
                id       => $columns->{curval1}->id,
                type     => 'string',
                value    => '1',
                operator => 'equal',
            },
            {
                id       => $columns->{enum1}->id,
                type     => 'string',
                value    => 'foo1',
                operator => 'equal',
            },
        ],
        condition => 'AND',
        count     => 1,
        no_errors => 1,
    },
    {
        name  => 'Search by curval field',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $columns->{curval1}->id .'_'. $curval_columns->{string1}->id,
                type     => 'string',
                value    => 'Bar',
                operator => 'equal',
            },
        ],
        count     => 1,
        no_errors => 1,
    },
    {
        name  => 'Search by curval enum field',
        columns => [$columns->{enum1}->id],
        rules => [
            {
                id       => $columns->{curval1}->id .'_'. $curval_columns->{enum1}->id,
                type     => 'string',
                value    => 'foo2',
                operator => 'equal',
            },
        ],
        count     => 1,
        no_errors => 1,
    },
    {
        name  => 'Search by curval within curval',
        columns => [$columns->{curval1}->id],
        rules => [
            {
                id       => $columns->{curval1}->id .'_'. $curval3->id,
                type     => 'string',
                value    => $curval3_value,
                operator => 'equal',
            },
        ],
        count     => 1,
        no_errors => 1,
    },
    {
        name  => 'Search by curval enum field across 2 curvals',
        columns => [$columns->{enum1}->id],
        rules => [
            {
                id       => $columns->{curval1}->id .'_'. $curval_columns->{enum1}->id,
                type     => 'string',
                value    => 'foo2',
                operator => 'equal',
            },
            {
                id       => $columns->{curval2}->id .'_'. $curval_columns->{enum1}->id,
                type     => 'string',
                value    => 'foo1',
                operator => 'equal',
            },
        ],
        condition => 'OR',
        count     => 2,
        no_errors => 1,
    },
);

foreach my $filter (@filters)
{
    my $rules = GADS::Filter->new(
        as_hash => {
            rules     => $filter->{rules},
            condition => $filter->{condition},
        },
    );

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
    $view->write(no_errors => $filter->{no_errors});

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
$records = GADS::Records->new(
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);

my $rules = GADS::Filter->new(
    as_hash => {
        rules     => [{
            id       => $columns->{date1}->id,
            type     => 'date',
            value    => '2014-10-10',
            operator => 'equal',
        }],
    },
);

my $view_limit = GADS::View->new(
    name        => 'Limit to view',
    filter      => $rules,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => undef,
);
$view_limit->write;

# XXX Need to get rid of user as a hash. For the time being, we need
# to variables.
my $user   = $sheet->user;
my $user_r = $schema->resultset('User')->find($user->{id});
$user_r->set_view_limits($view_limit->id);

$rules = GADS::Filter->new(
    as_hash => {
        rules     => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'Foo',
            operator => 'begins_with',
        }],
    },
);

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
    user    => $user,
    view    => $view,
    layout  => $layout,
    schema  => $schema,
);

is ($records->count, 1, 'Correct number of results when limiting to a view');

# Check can only directly access correct records
$record = GADS::Record->new(
    user   => $user,
    layout => $layout,
    schema => $schema,
);
is( $record->find_current_id(5)->current_id, 5, "Retrieved viewable current ID 5 in limited view" );
$record->clear;
try { $record->find_current_id(4) };
ok( $@, "Failed to retrieve non-viewable current ID 4 in limited view" );

# Add a second view limit
$rules = GADS::Filter->new(
    as_hash => {
        rules     => [{
            id       => $columns->{date1}->id,
            type     => 'date',
            value    => '2015-10-10',
            operator => 'equal',
        }],
    },
);

my $view_limit2 = GADS::View->new(
    name        => 'Limit to view2',
    filter      => $rules,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => undef,
);
$view_limit2->write;

$user_r->set_view_limits($view_limit->id, $view_limit2->id);

$records = GADS::Records->new(
    view_limits => [ $view_limit, $view_limit2 ],
    user    => $user,
    view    => $view,
    layout  => $layout,
    schema  => $schema,
);

is ($records->count, 2, 'Correct number of results when limiting to 2 views');

# Quick searches
# First with limited view still defined
is (@{$records->search_all_fields('Foobar')}, 0, 'Correct number of quick search results when limiting to a view');

# Same again but limited by enumval
$view_limit->filter(GADS::Filter->new(
    as_hash => {
        rules     => [{
            id       => $columns->{enum1}->id,
            type     => 'string',
            value    => 'foo2',
            operator => 'equal',
        }],
    },
));
$view_limit->write;
$records = GADS::Records->new(
    view_limits => [ $view_limit ],
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);
is ($records->count, 2, 'Correct number of results when limiting to a view with enumval');
is (@{$records->search_all_fields('2014-10-10')}, 1, 'Correct number of quick search results when limiting to a view with enumval');

# Now normal
$records = GADS::Records->new(
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);
is (@{$records->search_all_fields('2014-10-10')}, 4, 'Quick search for 2014-10-10');
is (@{$records->search_all_fields('Foo')}, 3, 'Quick search for foo');
is (@{$records->search_all_fields('Foo*')}, 5, 'Quick search for foo*');
is (@{$records->search_all_fields('99')}, 1, 'Quick search for 99');
is (@{$records->search_all_fields('1979-01-204')}, 0, 'Quick search for invalid date');

# Specific record retrieval
$record = GADS::Record->new(
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
# Records that don't exist
$record->clear;
try { $record->find_record_id(100) };
like( $@, qr/Record version ID 100 not found/, "Correct error when finding record version that does not exist" );
$record->clear;
try { $record->find_current_id(100) };
like( $@, qr/Record ID 100 not found/, "Correct error when finding record ID that does not exist" );

# Check sorting functionality
# First check default_sort functionality
$records = GADS::Records->new(
    default_sort => {
        type => 'asc',
        id   => -11,
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
        id   => -11,
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
        name         => 'Sort by ID descending',
        show_columns => [$columns->{string1}->id, $columns->{enum1}->id],
        sort_by      => [undef],
        sort_type    => ['desc'],
        first        => qr/^9$/,
        last         => qr/^3$/,
    },
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
    {
        name         => 'Sort by enum with filter on curval',
        show_columns => [$columns->{enum1}->id,$columns->{curval1}->id,$columns->{tree1}->id],
        sort_by      => [$columns->{enum1}->id],
        sort_type    => ['asc'],
        first        => qr/^(4)$/,
        last         => qr/^(7)$/,
        max_id       => 7,
        min_id       => 4,
        count        => 2,
        filter       => {
            rules => [
                {
                    id       => $columns->{curval1}->id .'_'. $curval_columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo2',
                    operator => 'equal',
                },
                {
                    id       => $columns->{curval2}->id .'_'. $curval_columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo1',
                    operator => 'equal',
                },
            ],
            condition => 'OR',
        },
    },
    {
        name         => 'Sort by curval with filter on curval',
        show_columns => [$columns->{enum1}->id,$columns->{curval1}->id,$columns->{curval2}->id],
        sort_by      => [$columns->{curval1}->id],
        sort_type    => ['asc'],
        first        => qr/^(4)$/,
        last         => qr/^(3)$/,
        max_id       => 4,
        min_id       => 3,
        count        => 2,
        filter       => {
            rules => [
                {
                    id       => $columns->{curval1}->id .'_'. $curval_columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo1',
                    operator => 'equal',
                },
                {
                    id       => $columns->{curval1}->id .'_'. $curval_columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo2',
                    operator => 'equal',
                },
            ],
            condition => 'OR',
        },
    },
    {
        name         => 'Sort by curval without curval in view',
        show_columns => [$columns->{string1}->id],
        sort_by      => [$columns->{curval1}->id],
        sort_type    => ['asc'],
        first        => qr/^(5|6|7|8|9)$/,
        last         => qr/^(3)$/,
        max_id       => 9,
        min_id       => 3,
        count        => 7,
    },
);

foreach my $sort (@sorts)
{
    # If doing a count with the sort, then do an extra pass, one to check that actual
    # number of rows retrieved, and one to check the count calculation function
    my $passes = $sort->{count} ? 4 : 3;
    foreach my $pass (1..$passes)
    {
        my $filter = GADS::Filter->new(
            as_hash => ($sort->{filter} || {}),
        );
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
        my $sort_type = @{$sort->{sort_type}} > 1
            ? $sort->{sort_type}
            : $sort->{sort_type}->[0] eq 'asc' && $pass == 2
            ? ['asc']
            : $sort->{sort_type}->[0] eq 'asc' && $pass == 3
            ? ['desc']
            : $sort->{sort_type}->[0] eq 'desc' && $pass == 2
            ? ['desc']
            : $sort->{sort_type}->[0] eq 'desc' && $pass == 3
            ? ['asc']
            : $sort->{sort_type};
        $view->set_sorts($sort->{sort_by}, $sort_type);

        $records = GADS::Records->new(
            page    => 1,
            user    => undef,
            view    => $view,
            layout  => $layout,
            schema  => $schema,
        );
        $records->sort({ type => 'desc', id => -11 })
            if $pass == 1;

        # Test override of sort first
        if ($pass == 1)
        {
            my $first = $sort->{max_id} || 9;
            my $last  = $sort->{min_id} || 3;
            # 1 record per page to test sorting across multiple pages
            $records->clear;
            $records->rows(1);
            is( $records->results->[0]->current_id, $first, "Correct first record for sort override and test $sort->{name}");
            $records->clear;
            $records->page($sort->{count} || 7);
            is( $records->results->[-1]->current_id, $last, "Correct last record for sort override and test $sort->{name}");
        }
        elsif ($pass == 2 || $pass == 3)
        {
            next if $pass == 3 && @{$sort->{sort_type}} > 1;
            # First check number of results for page of all records
            is( @{$records->results}, $sort->{count}, "Correct number of records in results for sort $sort->{name}" )
                if $sort->{count};

            # Then switch to 1 record per page to test sorting across multiple pages
            $records->clear;
            $records->rows(1);
            if ($pass == 2)
            {
                like( $records->results->[0]->current_id, $sort->{first}, "Correct first record for sort $sort->{name}");
                $records->clear;
                $records->page($sort->{count} || 7);
                like( $records->results->[0]->current_id, $sort->{last}, "Correct last record for sort $sort->{name}");
            }
            else {
                like( $records->results->[0]->current_id, $sort->{last}, "Correct first record for sort $sort->{name} in reverse");
                $records->clear;
                $records->page($sort->{count} || 7);
                like( $records->results->[0]->current_id, $sort->{first}, "Correct last record for sort $sort->{name} in reverse");
            }
        }
        else {
            is( $records->count, $sort->{count}, "Correct record count for sort $sort->{name}" )
        }
    }
}

restore_time();

done_testing();
