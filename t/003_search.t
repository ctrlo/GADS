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
use GADS::RecordsGraph;
use GADS::Schema;

use lib 't/lib';
use Test::GADS::DataSheet;

set_fixed_time('10/10/2014 01:00:00', '%m/%d/%Y %H:%M:%S'); # Fix all tests for this date so that CURDATE is consistent

my $long = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum';

my $data = [
    {
        string1    => '',
        integer1   => -4,
        date1      => '',
        daterange1 => ['', ''],
        enum1      => 'foo1',
        tree1      => 'tree1',
        curval1    => 1,
    },{
        string1    => '',
        integer1   => 5,
        date1      => '',
        daterange1 => ['', ''],
        enum1      => 'foo1',
        tree1      => 'tree3',
        curval1    => 2,
    },{
        string1    => '',
        integer1   => 6,
        date1      => '2014-10-10',
        daterange1 => ['2014-03-21', '2015-03-01'],
        enum1      => 'foo1',
        tree1      => 'tree2',
        curval1    => 2,
    },{
        string1    => 'Foo',
        integer1   => 7,
        date1      => '2014-10-10',
        daterange1 => ['2013-10-10', '2013-12-03'],
        enum1      => 'foo1', # Changed to foo2 after creation to have multiple versions
        tree1      => 'tree1',
    },{
        string1    => 'FooBar',
        date1      => '2015-10-10',
        daterange1 => ['2009-01-04', '2017-06-03'],
        enum1      => 'foo2',
        tree1      => 'tree2',
        curval2    => 1,
    },{
        string1    => "${long}1",
        integer1   => 2,
    },{
        string1    => "${long}2",
        integer1   => 3,
    },
];

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = Test::GADS::DataSheet->new(
    data                     => $data,
    schema                   => $schema,
    curval                   => 2,
    multivalue               => 1,
    instance_id              => 1,
    group                    => $curval_sheet->group,
    calc_code                => "
        function evaluate (L1daterange1)
            if type(L1daterange1) == \"table\" and L1daterange1[1] then
                dr1 = L1daterange1[1]
            elseif type(L1daterange1) == \"table\" and next(L1daterange1) == nil then
                dr1 = nil
            else
                dr1 = L1daterange1
            end
            if dr1 == nil then return end
            return dr1.from.epoch
        end",
    calc_return_type         => 'date',
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

my $calc_int = GADS::Column::Calc->new(
    schema          => $schema,
    user            => undef,
    layout          => $layout,
    name            => 'calc_int',
    return_type     => 'integer',
    code            => "function evaluate (L1integer1) return L1integer1 end",
    set_permissions => {
        $sheet->group->id => $sheet->default_permissions,
    },
);
$calc_int->write;
$layout->clear;

$sheet->create_records;
$curval_sheet->add_autocur(refers_to_instance_id => 1, related_field_id => $columns->{curval1}->id);
$curval_sheet->add_autocur(refers_to_instance_id => 1, related_field_id => $columns->{curval2}->id);
my $curval_columns = $curval_sheet->columns;
my $user = $sheet->user_normal1;

my $record = GADS::Record->new(
    user   => $user,
    layout => $layout,
    schema => $schema,
);
$record->find_current_id(6);
$record->fields->{$columns->{enum1}->id}->set_value(8);
$data->[3]->{enum1} = 'foo2';
$record->write(no_alerts => 1);

# Add another curval field to a new table
my $curval_sheet2 = Test::GADS::DataSheet->new(
    schema                   => $schema,
    group                    => $curval_sheet->group,
    instance_id              => 3,
    curval_offset            => 12,
    curval_field_ids         => [$sheet->columns->{integer1}->id],
);
$curval_sheet2->create_records;
my $curval3 = GADS::Column::Curval->new(
    name                  => 'curval3',
    type                  => 'curval',
    user                  => $user,
    layout                => $curval_sheet->layout,
    schema                => $schema,
    refers_to_instance_id => $curval_sheet2->instance_id,
    curval_field_ids      => [$curval_sheet2->columns->{string1}->id],
    set_permissions       => {
        $sheet->group->id => $sheet->default_permissions,
    },
);
$curval3->write;
$curval_sheet->layout->clear;
$layout->clear;
my $records = GADS::Records->new(
    user    => $user,
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
        aggregate => 7,
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
        aggregate => 7,
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
        aggregate => 2,
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
        aggregate => 5,
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
        aggregate => 13,
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
        aggregate => 13,
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
        aggregate => '',
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
        aggregate => 7,
    },
    {
        name  => 'negative filter for calc',
        rules => [{
            id       => $calc_int->id,
            type     => 'string',
            value    => -1,
            operator => 'less',
        }],
        count => 1,
        aggregate => -4,
    },
    {
        name  => 'date is empty',
        rules => [{
            id       => $columns->{date1}->id,
            type     => 'date',
            operator => 'is_empty',
        }],
        count => 4,
        aggregate => 6,
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
        aggregate => 6,
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
        aggregate => 6,
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
        aggregate => 7,
    },
    {
        name  => 'string contains ooba',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'ooba',
            operator => 'contains',
        }],
        count => 1,
        aggregate => '',
    },
    {
        name  => 'string does not contain ooba',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'ooba',
            operator => 'not_contains',
        }],
        count => 6,
        aggregate => 19,
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
        aggregate => 12,
    },
    {
        name  => 'string is empty',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            operator => 'is_empty',
        }],
        count => 3,
        aggregate => 7,
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
        aggregate => 12,
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
        aggregate => 12,
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
        aggregate => 12,
    },
    {
        name  => 'use of user team in substitution',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => '[CURUSER.TEAM]',
            operator => 'equal',
        }],
        count => 1,
        aggregate => 7,
    },
    {
        name  => 'greater than undefined value', # matches against empty instead
        rules => [{
            id       => $columns->{integer1}->id,
            type     => 'integer',
            operator => 'greater',
        }],
        count => 1,
        aggregate => '',
    },
    {
        name  => 'negative integer filter',
        rules => [{
            id       => $columns->{integer1}->id,
            type     => 'integer',
            operator => 'less',
            value    => -1,
        }],
        count => 1,
        aggregate => -4,
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
        aggregate => 7,
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
        aggregate => 7,
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
        aggregate => 6,
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
        aggregate => 6,
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
        aggregate => 6,
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
        aggregate => 13,
    },
    {
        name  => 'daterange empty',
        rules => [{
            id       => $columns->{daterange1}->id,
            type     => 'daterange',
            operator => 'is_empty',
        }],
        count => 4,
        aggregate => 6,
    },
    {
        name  => 'daterange not empty',
        rules => [{
            id       => $columns->{daterange1}->id,
            type     => 'daterange',
            operator => 'is_not_empty',
        }],
        count => 3,
        aggregate => 13,
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
        aggregate => 6,
    },
    {
        name  => 'daterange does not contain',
        rules => [{
            id       => $columns->{daterange1}->id,
            type     => 'daterange',
            value    => '2014-10-10',
            operator => 'not_contains',
        }],
        count => 5,
        aggregate => 13,
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
        aggregate => '',
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
        aggregate => 7,
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
        aggregate => 12,
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
        values => {
            $columns->{curval1}->id => "Foo, 50, foo1, , 2014-10-10, 2012-02-10 to 2013-06-15, , , c_amber, 2012",
        },
        aggregate => 7,
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
        aggregate => 3,
    },
    {
        name  => 'Search for ID',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $layout->column_id->id,
                type     => 'integer',
                value    => '4',
                operator => 'equal',
            }
        ],
        count => 1,
        aggregate => 5,
    },
    {
        name  => 'Search for multiple IDs',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $layout->column_id->id,
                type     => 'integer',
                value    => ['4', '5'],
                operator => 'equal',
            }
        ],
        count => 2,
        aggregate => 11,
    },
    {
        name  => 'Search for empty IDs',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $layout->column_id->id,
                type     => 'integer',
                value    => [],
                operator => 'equal',
            }
        ],
        count => 0,
        aggregate => '',
    },
    {
        name  => 'Search for version date 1',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $layout->column_by_name_short('_version_datetime')->id,
                type     => 'date',
                value    => '2014-10-10',
                operator => 'greater',
            },
            {
                id       => $layout->column_by_name_short('_version_datetime')->id,
                type     => 'date',
                value    => '2014-10-11',
                operator => 'less',
            }
        ],
        condition => 'AND',
        count     => 7,
        aggregate => 19,
    },
    {
        name  => 'Search for version date 2',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $layout->column_by_name_short('_version_datetime')->id,
                type     => 'date',
                value    => '2014-10-15',
                operator => 'greater',
            },
        ],
        count => 0,
        aggregate => '',
    },
    {
        name  => 'Search for created date',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $layout->column_by_name_short('_created')->id,
                type     => 'date',
                value    => '2014-10-15',
                operator => 'less',
            },
        ],
        count => 7,
        aggregate => 19,
    },
    {
        name  => 'Search for version editor',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $layout->column_by_name_short('_version_user')->id,
                type     => 'string',
                value    => $user->value,
                operator => 'equal',
            },
        ],
        count => 1, # Other records written by superadmin user on start
        aggregate => 7,
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
        aggregate => '',
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
        aggregate => '',
    },
    {
        name  => 'Search for blank calc date as empty string (array ref)',
        rules => [{
            id       => $columns->{calc1}->id,
            type     => 'date',
            value    => [''],
            operator => 'equal',
        }],
        count => 4,
        aggregate => 6,
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
        count     => 2,
        aggregate => 11,
    },
    {
        name  => 'Search by curval ID not equal',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $columns->{curval1}->id,
                type     => 'string',
                value    => '2',
                operator => 'not_equal',
            },
        ],
        count     => 5,
        aggregate => 8,
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
        aggregate => -4,
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
        count     => 2,
        aggregate => 11,
    },
    {
        name  => 'Search by curval field not equal',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $columns->{curval1}->id .'_'. $curval_columns->{string1}->id,
                type     => 'string',
                value    => 'Bar',
                operator => 'not_equal',
            },
        ],
        count     => 5,
        aggregate => 8,
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
        count     => 2,
        aggregate => 11,
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
        aggregate => -4,
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
        count     => 3,
        aggregate => 11,
    },
    {
        name  => 'Search by autocur ID',
        columns => [$curval_columns->{autocur1}->id],
        rules => [
            {
                id       => $curval_columns->{autocur1}->id,
                type     => 'string',
                value    => '3',
                operator => 'equal',
            },
        ],
        count     => 1,
        layout    => $curval_sheet->layout,
        aggregate => 50,
    },
    {
        name  => 'Search by autocur ID not equal',
        columns => [$curval_columns->{autocur1}->id],
        rules => [
            {
                id       => $curval_columns->{autocur1}->id,
                type     => 'string',
                value    => '3',
                operator => 'not_equal',
            },
        ],
        count       => 1,
        # Autocur treated as a multivalue with a single row with 2 different
        # values that are counted separately on a graph
        count_graph => 2,
        layout      => $curval_sheet->layout,
        aggregate   => 99,
    },
    {
        name  => 'Search by autocur enum field',
        columns => [$curval_columns->{string1}->id],
        rules => [
            {
                id       => $curval_columns->{autocur1}->id .'_'. $columns->{enum1}->id,
                type     => 'string',
                value    => 'foo1',
                operator => 'equal',
            },
        ],
        count     => 2,
        layout    => $curval_sheet->layout,
        aggregate => 149,
    },
    {
        name  => 'Search for invalid autocur',
        columns => [$curval_columns->{autocur1}->id],
        rules => [
            {
                id       => $curval_columns->{autocur1}->id,
                type     => 'string',
                value    => 'Foobar',
                operator => 'equal',
            },
        ],
        count     => 0,
        no_errors => 1,
        layout    => $curval_sheet->layout,
        aggregate => '',
    },
    {
        name  => 'Search by record ID',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $layout->column_by_name('ID')->id,
                type     => 'string',
                value    => '3',
                operator => 'equal',
            },
        ],
        count     => 1,
        aggregate => -4,
    },
    {
        name  => 'Search by invalid record ID',
        columns => [$columns->{string1}->id],
        rules => [
            {
                id       => $layout->column_by_name('ID')->id,
                type     => 'string',
                value    => '3DD',
                operator => 'equal',
            },
        ],
        count     => 0,
        no_errors => 1,
        aggregate => '',
    },
);

foreach my $multivalue (0..1)
{
    $sheet->set_multivalue($multivalue);

    # Set aggregate fields. Only needs to be done once, and after that the user
    # does not have permission to write the field settings
    my $integer1 = $layout->column_by_name('integer1');
    if (!$multivalue)
    {
        $integer1->aggregate('sum');
        $integer1->write;
        $layout->clear;
    }

    my $integer1_curval = $curval_sheet->layout->column_by_name('integer1');
    if (!$multivalue)
    {
        $integer1_curval->aggregate('sum');
        $integer1_curval->write;
        $curval_sheet->layout->clear;
    }

    # Run 2 loops, one without the standard layout from the initial build, and a
    # second with the layouts all built from scratch using GADS::Instances
    foreach my $layout_from_instances (0..1)
    {
        my $instances;
        if ($layout_from_instances)
        {
            $instances = GADS::Instances->new(schema => $schema, user => $user);
            $layout = $instances->layout($layout->instance_id);
        }

        foreach my $filter (@filters)
        {
            my $layout_filter = $filter->{layout};
            $layout_filter &&= $instances->layout($layout_filter->instance_id)
                if $layout_from_instances;
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
                layout      => $layout_filter || $layout,
                schema      => $schema,
                user        => $user,
            );
            # If the filter is expected to bork, then check that it actually does first
            if ($filter->{no_errors})
            {
                try { $view->write };
                ok($@, "Failed to write view with invalid value, test: $filter->{name}");
                is($@->wasFatal->reason, 'ERROR', "Generated user error when writing view with invalid value");
            }
            $view->write(no_errors => $filter->{no_errors});

            my $records = GADS::Records->new(
                user    => $user,
                view    => $view,
                layout  => $layout_filter || $layout,
                schema  => $schema,
            );

            is( $records->count, $filter->{count}, "$filter->{name} for record count $filter->{count}");
            is( @{$records->results}, $filter->{count}, "$filter->{name} actual records matches count $filter->{count}");
            if (my $test_values = $filter->{values})
            {
                foreach my $field (keys %$test_values)
                {
                    is($records->results->[0]->fields->{$field}->as_string, $test_values->{$field}, "Test value of $filter->{name} correct");
                }
            }

            $view->set_sorts({fields => $view_columns, types => ['asc']});
            $view->write(no_errors => $filter->{no_errors});
            $records = GADS::Records->new(
                user    => $user,
                view    => $view,
                layout  => $layout_filter || $layout,
                schema  => $schema,
            );

            is( $records->count, $filter->{count}, "$filter->{name} for record count $filter->{count}");
            is( @{$records->results}, $filter->{count}, "$filter->{name} actual records matches count $filter->{count}");

            # Basic aggregate tests
            {
                my @column_ids = @{$view->columns};
                my $int_id = $records->layout->instance_id == $curval_sheet->layout->instance_id
                    ? $integer1_curval->id : $integer1->id;
                push @column_ids, $int_id if ! grep $_ == $int_id, @column_ids;
                $view->columns(\@column_ids);
                $view->write(no_errors => $filter->{no_errors});
                $records->clear;
                my $aggregate = $records->aggregate_results;
                is($aggregate->fields->{$int_id}->as_string, $filter->{aggregate}, "Aggregate integer value correct");
            }

            # Basic graph test. Total of points on graph should match the number of results
            my $graph = GADS::Graph->new(
                layout       => $layout_filter || $layout,
                schema       => $schema,
                current_user => $sheet->user,
            );
            $graph->title('Test');
            $graph->type('bar');
            my $axis = $filter->{columns}->[0] || $columns->{string1}->id;
            $graph->x_axis($axis);
            $graph->y_axis($axis);
            $graph->y_axis_stack('count');
            $graph->write;

            my $records_group = GADS::RecordsGraph->new(
                user              => $user,
                layout            => $layout_filter || $layout,
                schema => $schema,
            );
            my $graph_data = GADS::Graph::Data->new(
                id      => $graph->id,
                view    => $view,
                records => $records_group,
                schema  => $schema,
            );

            my $graph_total = 0;
            $graph_total += $_ foreach @{$graph_data->points->[0]}; # Count total number of records
            my $count = $filter->{count_graph} || $filter->{count};
            is($graph_total, $count, "Item total on graph matches table for $filter->{name}");
        }
    }
}

# Test view limits defined to user accounts and tables
foreach my $multivalue (0..1)
{
    $sheet->set_multivalue($multivalue);

    $layout = $sheet->layout;
    $columns = $sheet->columns;

    # Test view limit applied to table but not user
    my $rules_table = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $columns->{date1}->id,
                type     => 'date',
                value    => '2015-10-10',
                operator => 'equal',
            }],
        },
    );

    my $view_limit_table = GADS::View->new(
        name        => 'Limit to view table',
        filter      => $rules_table,
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => $user,
        is_admin    => 1,
    );
    $view_limit_table->write;

    $layout->view_limit_id($view_limit_table->id);
    $layout->write;

    $records = GADS::Records->new(
        user    => $user,
        layout  => $layout,
        schema  => $schema,
    );

    is ($records->count, 1, 'Correct number of results when limiting to a view for a table');

    # Add a view limit to the user. This should replace the default table limit
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
        user        => $user,
        is_admin    => 1,
    );
    $view_limit->write;

    $user->set_view_limits([$view_limit->id]);

    $records->clear;
    is ($records->count, 2, 'Correct number of results when limiting to a view for the table and a user');

    # Remove the table limit
    $layout->view_limit_id(undef);
    $layout->write;

    # And search with a normal view plus the user's limit view
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
        user        => $user,
    );
    $view->write;

    $records = GADS::Records->new(
        user    => $user,
        view    => $view,
        layout  => $layout,
        schema  => $schema,
    );

    is ($records->count, 1, 'Correct number of results when limiting to a view');

    # Remove user's permissions to the field in the view limit and check it
    # still works as expected (user's permissions should be ignored on a view
    # they are using directly, but not indirectly such as a defined view limit)
    my $date1 = $columns->{date1};
    $date1->set_permissions({$sheet->group->id, []});
    $date1->write;
    $layout->clear;

    $records = GADS::Records->new(
        user    => $user,
        view    => $view,
        layout  => $layout,
        schema  => $schema,
    );
    is ($records->count, 1, 'Correct number of results when limiting to a view without permission to field');

    # Reset back to normal
    $date1->set_permissions({$sheet->group->id, $sheet->default_permissions});
    $date1->write;
    $layout->clear;

    # Check can only directly access correct records. Test with and without any
    # columns selected.
    for (0..1)
    {
        my $cols_select = $_ ? [] : undef;
        $record = GADS::Record->new(
            user    => $user,
            columns => $cols_select,
            layout  => $layout,
            schema  => $schema,
        );
        is( $record->find_current_id(5)->current_id, 5, "Retrieved viewable current ID 5 in limited view" );
        is( $record->find_record_id(5)->current_id, 5, "Retrieved viewable record ID 5 in limited view" );
        $record->clear;
        try { $record->find_current_id(4) };
        ok( $@, "Failed to retrieve non-viewable current ID 4 in limited view" );
        try { $record->find_record_id(4) };
        ok( $@, "Failed to retrieve non-viewable record ID 4 in limited view" );
        # Temporarily flag record as deleted and check it can't be shown
        $schema->resultset('Current')->find(5)->update({ deleted => DateTime->now });
        try { $record->find_current_id(5) };
        like($@, qr/Requested record not found/, "Failed to find deleted current ID 5" );
        try { $record->find_record_id(5) };
        like($@, qr/Requested record not found/, "Failed to find deleted record ID 5" );

        # Draft record whilst view limit in force
        my $draft = GADS::Record->new(
            user   => $user,
            layout => $layout,
            schema => $schema,
        );
        $draft->initialise;
        $draft->fields->{$columns->{string1}->id}->set_value("Draft");
        $draft->write(draft => 1);
        $draft->clear;
        $draft->load_remembered_values(instance_id => $layout->instance_id);
        is($draft->fields->{$columns->{string1}->id}->as_string, "Draft", "Draft sub-record retrieved");

        # Reset
        $schema->resultset('Current')->find(5)->update({ deleted => undef });
    }

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
        user        => $user,
    );
    $view_limit2->write;

    $user->set_view_limits([$view_limit->id, $view_limit2->id]);

    $records = GADS::Records->new(
        user    => $user,
        view    => $view,
        layout  => $layout,
        schema  => $schema,
    );

    is ($records->count, 2, 'Correct number of results when limiting to 2 views');

    # view limit with a view with negative match multivalue filter
    # (this has caused recusion in the past)
    {
        # First define limit view
        $rules = GADS::Filter->new(
            as_hash => {
                rules     => [{
                    id       => $columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo1',
                    operator => 'not_equal',
                }],
            },
        );

        my $view_limit3 = GADS::View->new(
            name        => 'limit to view',
            filter      => $rules,
            instance_id => 1,
            layout      => $layout,
            schema      => $schema,
            user        => $user,
        );
        $view_limit3->write;

        $user->set_view_limits([$view_limit3->id]);

        # Then add a normal view
        $rules = GADS::Filter->new(
            as_hash => {
                rules     => [{
                    id       => $columns->{date1}->id,
                    type     => 'string',
                    value    => '2014-10-10',
                    operator => 'equal',
                }],
            },
        );
        $view = GADS::View->new(
            name        => 'date1',
            filter      => $rules,
            instance_id => 1,
            layout      => $layout,
            schema      => $schema,
            user        => $user,
        );
        $view->write;

        $records = GADS::Records->new(
            user   => $user,
            view   => $view,
            layout => $layout,
            schema => $schema,
        );

        is ($records->count, 1, 'Correct result count when limiting to negative multivalue view');
        is (@{$records->results}, 1, 'Correct number of results when limiting to negative multivalue view');

    }

    # Quick searches
    # Limited view still defined, but selected view from last results ("date1") will not be used
    $records->clear;
    $records->search('Foobar');
    is (@{$records->results}, 1, 'Correct number of quick search results when limiting to a view');
    # And again with record that is not in limited view
    $records->clear;
    $records->search('-4');
    is (@{$records->results}, 0, 'Correct number of quick search results when limiting to a view');
    # And again with numerical search (also searches record IDs). Current ID in limited view
    $records->clear;
    $records->search(8);
    is (@{$records->results}, 1, 'Correct number of quick search results for number when limiting to a view (match)');
    # This time a current ID that is not in limited view
    $records->clear;
    $records->search(5);
    # Finds record ID 7 (there is a "5" in the daterange of the curval), but should not find record ID 5
    is (@{$records->results}, 1, 'Correct number of quick search results for number when limiting to a view (no match)');
    is ($records->single->current_id, 7, 'Does not find record ID in limited view');
    # Reset and do again with non-negative view
    $records->clear;
    $user->set_view_limits([$view_limit->id]);
    $records->search('Foobar');
    is (@{$records->results}, 0, 'Correct number of quick search results when limiting to a view');
    # Current ID in limited view
    $records->clear;
    $records->search(8);
    is (@{$records->results}, 0, 'Correct number of quick search results for number when limiting to a view (match)');
    # Current ID that is not in limited view
    $records->clear;
    $records->search(5);
    is (@{$records->results}, 1, 'Correct number of quick search results for number when limiting to a view (no match)');

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
        user    => $user,
        layout  => $layout,
        schema  => $schema,
    );
    is ($records->count, 2, 'Correct number of results when limiting to a view with enumval');
    {
        my $limit = $schema->resultset('ViewLimit')->create({
            user_id => $user->id,
            view_id => $view_limit->id,
        });
        my $record = GADS::Record->new(
            user   => $user,
            layout => $layout,
            schema => $schema,
        );
        is( $record->find_current_id(7)->current_id, 7, "Retrieved record within limited view" );
        $limit->delete;
    }
    $records->clear;
    $records->search('2014-10-10');
    is (@{$records->results}, 1, 'Correct number of quick search results when limiting to a view with enumval');
    # Check that record can be retrieved for edit
    my $record = GADS::Record->new(
        user   => $user,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id($records->single->current_id);

    # Same again but limited by curval
    $view_limit->filter(GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $columns->{curval1}->id,
                type     => 'string',
                value    => '1',
                operator => 'equal',
            }],
        },
    ));
    $view_limit->write;
    $records = GADS::Records->new(
        view_limits => [ $view_limit ],
        user    => $user,
        layout  => $layout,
        schema  => $schema,
    );
    is ($records->count, 1, 'Correct number of results when limiting to a view with curval');
    is (@{$records->results}, 1, 'Correct number of results when limiting to a view with curval');

    # Check that record can be retrieved for edit
    $record = GADS::Record->new(
        user   => $user,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id($records->single->current_id);

    {
        my $limit = $schema->resultset('ViewLimit')->create({
            user_id => $user->id,
            view_id => $view_limit->id,
        });
        my $record = GADS::Record->new(
            user   => $user,
            layout => $layout,
            schema => $schema,
        );
        is( $record->find_current_id(3)->current_id, 3, "Retrieved record within limited view" );
        $limit->delete;
    }
    $records->clear;
    $records->search('foo1');
    is (@{$records->results}, 1, 'Correct number of quick search results when limiting to a view with curval');

    # Same again but limited by curval subfield and enum
    $view_limit->filter(GADS::Filter->new(
        as_hash => {
            rules     => [
                {
                    id       => $columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo1',
                    operator => 'equal',
                },
                {
                    id       => $columns->{curval1}->id.'_'.$curval_sheet->columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo1',
                    operator => 'equal',
                },
            ],
            operator => 'AND',
        },
    ));
    $view_limit->write;
    $records = GADS::Records->new(
        user    => $user,
        layout  => $layout,
        schema  => $schema,
    );
    is ($records->count, 1, 'Correct number of results when limiting to a view with curval');
    is (@{$records->results}, 1, 'Correct number of results when limiting to a view with curval');

    $records = GADS::Records->new(
        user    => $user,
        layout  => $layout,
        schema  => $schema,
    );
    $records->search('foo1');
    is ($records->pages, 1, "Correct number of pages");
    is (@{$records->results}, 1, 'Correct number of quick search results when limiting to a view with curval');

    # Now normal
    $user->set_view_limits([]);
    $records = GADS::Records->new(
        user    => $user,
        layout  => $layout,
        schema  => $schema,
    );
    $records->clear;
    $records->search('2014-10-10');
    is (@{$records->results}, 4, 'Quick search for 2014-10-10');
    $records->clear;
    $records->search('Foo');
    is (@{$records->results}, 5, 'Quick search for foo');
    $records->clear;
    $records->search('99');
    is (@{$records->results}, 2, 'Quick search for 99');
    $records->clear;
    $records->search('1979-01-204');
    is (@{$records->results}, 0, 'Quick search for invalid date');

    # Specific record retrieval
    $record = GADS::Record->new(
        user   => $user,
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
    try { $record->find_current_id('XYXY') };
    like( $@, qr/Invalid record ID/, "Correct error when finding record ID that is invalid" );
    try { $record->find_current_id('123XYXY') };
    like( $@, qr/Invalid record ID/, "Correct error when finding record ID that is invalid (2)" );
}

{
    # Test view_limit_extra functionality
    my $sheet = Test::GADS::DataSheet->new(data =>
    [
        {
            string1    => 'FooBar',
            integer1   => 50,
        },
        {
            string1    => 'Bar',
            integer1   => 100,
        },
        {
            string1    => 'Foo',
            integer1   => 150,
        },
        {
            string1    => 'FooBar',
            integer1   => 200,
        },
    ]);
    $sheet->create_records;
    my $schema  = $sheet->schema;
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;

    my $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $columns->{string1}->id,
                type     => 'string',
                value    => 'FooBar',
                operator => 'equal',
            }],
        },
    );

    my $limit_extra1 = GADS::View->new(
        name        => 'Limit to view extra',
        filter      => $rules,
        instance_id => $layout->instance_id,
        layout      => $layout,
        schema      => $schema,
        user        => $sheet->user,
        is_admin    => 1,
    );
    $limit_extra1->write;

    $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $columns->{integer1}->id,
                type     => 'string',
                value    => '75',
                operator => 'greater',
            }],
        },
    );

    my $limit_extra2 = GADS::View->new(
        name        => 'Limit to view extra',
        filter      => $rules,
        instance_id => $layout->instance_id,
        layout      => $layout,
        schema      => $schema,
        user        => $sheet->user,
        is_admin    => 1,
    );
    $limit_extra2->write;

    $schema->resultset('Instance')->find($layout->instance_id)->update({
        default_view_limit_extra_id => $limit_extra1->id,
    });
    $layout->clear;

    my $records = GADS::Records->new(
        user    => $sheet->user,
        layout  => $layout,
        schema  => $schema,
    );
    my $string1 = $columns->{string1}->id;
    is($records->count, 2, 'Correct number of results when limiting to a view limit extra');
    is($records->single->fields->{$string1}->as_string, "FooBar", "Correct limited record");

    $records = GADS::Records->new(
        user                => $sheet->user,
        layout              => $layout,
        schema              => $schema,
        view_limit_extra_id => $limit_extra2->id,
    );
    is ($records->count, 3, 'Correct number of results when changing view limit extra');
    is($records->single->fields->{$string1}->as_string, "Bar", "Correct limited record when changed");

    my $user = $sheet->user;
    $user->set_view_limits([ $limit_extra1->id ]);
    $records = GADS::Records->new(
        user                => $user,
        layout              => $layout,
        schema              => $schema,
        view_limit_extra_id => $limit_extra2->id,
    );
    is ($records->count, 1, 'Correct number of results with both view limits and extra limits');
    is($records->single->fields->{$string1}->as_string, "FooBar", "Correct limited record for both types of limit");
    # Reset
    $user->set_view_limits([]);

    # Turn this into a curval that is referenced - limit view extra should be
    # ignored.
    my $main = Test::GADS::DataSheet->new(
        data        => [],
        schema      => $schema,
        curval      => 1,
        multivalue  => 1,
        instance_id => 2,
    );
    $main->create_records;
    my $main_string = $main->columns->{string1};
    # Test as admin user (with permission to set own view extra ID) and normal
    # user without the permission
    foreach my $test (qw/admin normal/)
    {
        my $user = $test eq 'normal' ? $sheet->user_normal1 : $sheet->user;
        $main->layout->user($user);
        $main->layout->clear;
        my $record = GADS::Record->new(
            user    => $user,
            layout  => $main->layout,
            schema  => $schema,
        );
        $record->initialise;
        my $curval = $main->layout->column_by_name_short('L2curval1');
        is(@{$curval->filtered_values}, 4, "Values for curval not filtered by limit extra");
        $record->fields->{$curval->id}->set_value([1,2,3]);
        $record->fields->{$main_string->id}->set_value($test);
        $record->write(no_alerts => 1 );
        my $cid = $record->current_id;
        $record->clear;
        $record->find_current_id($cid);
        is(@{$record->fields->{$curval->id}->ids}, 3, "Curval contains all values despite extra limit");
    }

    # Same but with autocur instead of curval.
    # First add a view limit to the just-created main table
    $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $main_string->id,
                type     => 'string',
                value    => 'normal',
                operator => 'equal',
            }],
        },
    );
    my $limit_extra_autocur = GADS::View->new(
        name        => 'Limit to view extra',
        filter      => $rules,
        instance_id => $main->layout->instance_id,
        layout      => $main->layout,
        schema      => $schema,
        user        => $sheet->user,
        is_admin    => 1,
    );
    $limit_extra_autocur->write(force => 1);
    $schema->resultset('Instance')->find($main->layout->instance_id)->update({
        default_view_limit_extra_id => $limit_extra_autocur->id,
    });
    $main->layout->clear;
    # Now add an autocur to the original table (used as the curval sub-table)
    # to see what is referring to it
    my $autocur = $sheet->add_autocur(
        refers_to_instance_id => 2,
        related_field_id      => $main->columns->{curval1}->id,
        curval_field_ids      => [$main->columns->{string1}->id],
    );
    foreach my $test (qw/admin normal/)
    {
        my $user = $test eq 'normal' ? $sheet->user_normal1 : $sheet->user;
        $layout->user($user);
        $layout->clear;
        my $record = GADS::Record->new(
            user    => $user,
            layout  => $layout,
            schema  => $schema,
        );
        $record->initialise;
        # Find one of the original records first created, which should now have
        # some records referring back to it from the previous tests
        $record->find_current_id(1);
        # There should be 2 records in curvals referring to this table, both
        # created in the previous test
        is(@{$record->fields->{$autocur->id}->ids}, 2, "Autocur contains all values despite extra limit");
    }
}

# Check sorting functionality
# First check default_sort functionality
$records = GADS::Records->new(
    default_sort => {
        type => 'asc',
        id   => $layout->column_id->id,
    },
    user    => $user,
    layout  => $layout,
    schema  => $schema,
);
is( $records->results->[0]->current_id, 3, "Correct first record for default_sort (asc)");
is( $records->results->[-1]->current_id, 9, "Correct last record for default_sort (asc)");
$records = GADS::Records->new(
    default_sort => {
        type => 'desc',
        id   => $layout->column_id->id,
    },
    user    => $user,
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
    user    => $user,
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
    user    => $user,
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
    user    => $user,
    layout  => $layout,
    schema  => $schema,
);
is( $records->results->[0]->current_id, 6, "Correct first record for standard sort");
is( $records->results->[-1]->current_id, 7, "Correct last record for standard sort");

my @sorts = (
    {
        name         => 'Sort by ID descending',
        show_columns => [qw/string1 enum1/],
        sort_by      => [undef],
        sort_type    => ['desc'],
        first        => qr/^9$/,
        last         => qr/^3$/,
    },
    {
        name         => 'Sort by single column in view ascending',
        show_columns => [qw/string1 enum1/],
        sort_by      => [qw/enum1/],
        sort_type    => ['asc'],
        first        => qr/^(8|9)$/,
        last         => qr/^(6|7)$/,
    },
    {
        name         => 'Sort by single column not in view ascending',
        show_columns => [qw/string1 tree1/],
        sort_by      => [qw/enum1/],
        sort_type    => ['asc'],
        first        => qr/^(8|9)$/,
        last         => qr/^(6|7)$/,
    },
    {
        name         => 'Sort by single column not in view descending',
        show_columns => [qw/string1 tree1/],
        sort_by      => [qw/enum1/],
        sort_type    => ['desc'],
        first        => qr/^(6|7)$/,
        last         => qr/^(8|9)$/,
    },
    {
        name         => 'Sort by single column not in view ascending (opposite enum columns)',
        show_columns => [qw/string1 enum1/],
        sort_by      => [qw/tree1/],
        sort_type    => ['asc'],
        first        => qr/^(8|9)$/,
        last         => qr/^(4)$/,
    },
    {
        name         => 'Sort by two columns, one in view one not in view, asc then desc',
        show_columns => [qw/string1 tree1/],
        sort_by      => [qw/enum1 daterange1/],
        sort_type    => ['asc', 'desc'],
        first        => qr/^(8|9)$/,
        last         => qr/^(7)$/,
    },
    {
        name         => 'Sort with filter on enums',
        show_columns => [qw/enum1 curval1 tree1/],
        sort_by      => [qw/enum1/],
        sort_type    => ['asc'],
        first        => qr/^(3)$/,
        first_string => { curval1 => '' },
        last         => qr/^(6)$/,
        last_string  => { curval1 => 'Foo, 50, foo1, , 2014-10-10, 2012-02-10 to 2013-06-15, , , c_amber, 2012' },
        max_id       => 6,
        min_id       => 3,
        count        => 2,
        filter       => {
            rules => [
                {
                    name     => 'tree1',
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
        show_columns => [qw/enum1 curval1 tree1/],
        sort_by      => [qw/tree1/],
        sort_type    => ['asc'],
        first        => qr/^(3)$/,
        last         => qr/^(4)$/,
        max_id       => 5,
        min_id       => 3,
        count        => 3,
        filter       => {
            rules => [
                {
                    name     => 'enum1',
                    type     => 'string',
                    value    => 'foo1',
                    operator => 'equal',
                },
            ],
        },
    },
    {
        name         => 'Sort with filter on tree',
        show_columns => [qw/string1 enum1/],
        sort_by      => [qw/enum1/],
        sort_type    => ['asc'],
        first        => qr/^(3)$/,
        last         => qr/^(6)$/,
        max_id       => 6,
        min_id       => 3,
        count        => 2,
        filter       => {
            rules => [
                {
                    name     => 'tree1',
                    type     => 'string',
                    value    => 'tree1',
                    operator => 'equal',
                },
            ],
        },
    },
    {
        name         => 'Sort by enum that is after another enum in the fetched column',
        show_columns => [qw/enum1 curval1 tree1/],
        sort_by      => [qw/tree1/],
        sort_type    => ['asc'],
        first        => qr/^(8|9)$/,
        last         => qr/^(4)$/,
    },
    {
        name         => 'Sort by enum with filter on curval',
        show_columns => [qw/enum1 curval1 tree1/],
        sort_by      => [qw/enum1/],
        sort_type    => ['asc'],
        first        => qr/^(4|5)$/,
        last         => qr/^(7)$/,
        max_id       => 7,
        min_id       => 4,
        count        => 3,
        filter       => {
            rules => [
                {
                    name     => 'curval1_'.$curval_columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo2',
                    operator => 'equal',
                },
                {
                    name     => 'curval2_'.$curval_columns->{enum1}->id,
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
        show_columns => [qw/enum1 curval1 curval2/],
        sort_by      => [qw/curval1/],
        sort_type    => ['asc'],
        first        => qr/^(4|5)$/,
        last         => qr/^(3)$/,
        max_id       => 5,
        min_id       => 3,
        count        => 3,
        filter       => {
            rules => [
                {
                    name     => 'curval1_'.$curval_columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo1',
                    operator => 'equal',
                },
                {
                    name     => 'curval1_'.$curval_columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo2',
                    operator => 'equal',
                },
            ],
            condition => 'OR',
        },
    },
    {
        name           => 'Sort by field in curval',
        show_columns   => [qw/enum1 curval1 curval2/],
        sort_by        => [qw/string1/],
        sort_by_parent => [qw/curval1/],
        sort_type      => ['asc'],
        first          => qr/^(6|7|8|9)$/,
        last           => qr/^(3)$/,
        max_id         => 9,
        min_id         => 3,
        count          => 7,
    },
    {
        name         => 'Sort by curval without curval in view',
        show_columns => [qw/string1/],
        sort_by      => [qw/curval1/],
        sort_type    => ['asc'],
        first        => qr/^(6|7|8|9)$/,
        last         => qr/^(3)$/,
        max_id       => 9,
        min_id       => 3,
        count        => 7,
    },
    {
        name           => 'Sort by field in curval without curval in view',
        show_columns   => [qw/integer1/],
        sort_by        => [qw/string1/],
        sort_by_parent => [qw/curval1/],
        sort_type      => ['asc'],
        first          => qr/^(6|7|8|9)$/,
        last           => qr/^(3)$/,
        max_id         => 9,
        min_id         => 3,
        count          => 7,
    },
);

foreach my $multivalue (0..1)
{
    $sheet->clear_not_data(multivalue => $multivalue);
    my $layout     = $sheet->layout;
    my $columns    = $sheet->columns;
    my $cid_adjust = 9; # For some reason database restarts at same ID second time

    foreach my $sort (@sorts)
    {
        # If doing a count with the sort, then do an extra pass, one to check that actual
        # number of rows retrieved, and one to check the count calculation function
        my $passes = $sort->{count} ? 4 : 3;
        foreach my $pass (1..$passes)
        {
            my $filter = GADS::Filter->new(
                as_hash => ($sheet->convert_filter($sort->{filter}) || {}),
            );

            my @show_columns = map { $columns->{$_}->id } @{$sort->{show_columns}};
            my $view = GADS::View->new(
                name        => 'Test view',
                columns     => [@show_columns],
                filter      => $filter,
                instance_id => 1,
                layout      => $layout,
                schema      => $schema,
                user        => $user,
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

            my @sort_by;
            if ($sort->{sort_by_parent})
            {
                my @children = @{$sort->{sort_by}};
                foreach my $parent (@{$sort->{sort_by_parent}})
                {
                    my $cname = shift @children;
                    my $id    = $curval_columns->{$cname}->id;
                    my $parent_id = $columns->{$parent}->id;
                    push @sort_by, "${parent_id}_$id";
                }
            }
            else {
                @sort_by = map { $_ ? $columns->{$_}->id : $layout->column_id->id } @{$sort->{sort_by}};
            }
            $view->set_sorts({fields => [@sort_by], types => $sort_type});
            $view->write;

            $records = GADS::Records->new(
                page    => 1,
                user    => $user,
                view    => $view,
                layout  => $layout,
                schema  => $schema,
            );
            $records->sort({ type => 'desc', id => $layout->column_id->id })
                if $pass == 1;

            # Test override of sort first
            if ($pass == 1)
            {
                my $first = $sort->{max_id} || 9;
                my $last  = $sort->{min_id} || 3;
                # 1 record per page to test sorting across multiple pages
                $records->clear;
                $records->rows(1);
                is( $records->results->[0]->current_id - $cid_adjust, $first, "Correct first record for sort override and test $sort->{name}");
                if ($sort->{first_string})
                {
                    foreach my $colname (keys %{$sort->{first_string}})
                    {
                        my $colid = $columns->{$colname}->id;
                        is(
                            $records->results->[0]->fields->{$colid}->as_string,
                            $sort->{first_string}->{$colname},
                            "Correct first record value for $colname in test $sort->{name}"
                        );
                    }
                }
                $records->clear;
                $records->page($sort->{count} || 7);
                is( $records->results->[-1]->current_id - $cid_adjust, $last, "Correct last record for sort override and test $sort->{name}");
                if ($sort->{last_string})
                {
                    foreach my $colname (keys %{$sort->{last_string}})
                    {
                        my $colid = $columns->{$colname}->id;
                        is(
                            $records->results->[0]->fields->{$colid}->as_string,
                            $sort->{last_string}->{$colname},
                            "Correct last record value for $colname in test $sort->{name}"
                        );
                    }
                }
            }
            elsif ($pass == 2 || $pass == 3)
            {
                next if $pass == 3 && @{$sort->{sort_type}} > 1;
                # First check number of results for page of all records
                is( @{$records->results}, $sort->{count}, "Correct number of records in results for sort $sort->{name}" )
                    if $sort->{count};

                # First with full page of results
                $records->clear;
                if ($pass == 2)
                {
                    like( $records->results->[0]->current_id - $cid_adjust, $sort->{first}, "Correct first record for sort $sort->{name}");
                    like( $records->results->[-1]->current_id - $cid_adjust, $sort->{last}, "Correct last record for sort $sort->{name}");
                }
                else {
                    like( $records->results->[0]->current_id - $cid_adjust, $sort->{last}, "Correct first record for sort $sort->{name} in reverse");
                    like( $records->results->[-1]->current_id - $cid_adjust, $sort->{first}, "Correct last record for sort $sort->{name} in reverse");
                }

                # Then switch to 1 record per page to test sorting across multiple pages
                $records->clear;
                $records->rows(1);
                if ($pass == 2)
                {
                    like( $records->results->[0]->current_id - $cid_adjust, $sort->{first}, "Correct first record for sort $sort->{name}");
                    $records->clear;
                    $records->page($sort->{count} || 7);
                    like( $records->results->[0]->current_id - $cid_adjust, $sort->{last}, "Correct last record for sort $sort->{name}");
                }
                else {
                    like( $records->results->[0]->current_id - $cid_adjust, $sort->{last}, "Correct first record for sort $sort->{name} in reverse");
                    $records->clear;
                    $records->page($sort->{count} || 7);
                    like( $records->results->[0]->current_id - $cid_adjust, $sort->{first}, "Correct last record for sort $sort->{name} in reverse");
                }
            }
            else {
                is( $records->count, $sort->{count}, "Correct record count for sort $sort->{name}" )
            }

            if ($pass == 1)
            {
                # Basic graph test. Total of points on graph should match the number of results.
                # Even though graphs do not use sorting, so a test with a sort
                # as the user may still be using a view with a sort defined.
                my $graph = GADS::Graph->new(
                    layout       => $layout,
                    schema       => $schema,
                    current_user => $sheet->user,
                );
                $graph->title('Test');
                $graph->type('bar');
                my $axis = $columns->{string1}->id;
                $graph->x_axis($axis);
                $graph->y_axis($axis);
                $graph->y_axis_stack('count');
                $graph->write;

                my $records_group = GADS::RecordsGraph->new(
                    user   => $user,
                    layout => $layout,
                    schema => $schema,
                );
                my $graph_data = GADS::Graph::Data->new(
                    id      => $graph->id,
                    view    => $view,
                    records => $records_group,
                    schema  => $schema,
                );

                my $graph_total = 0;
                $graph_total += $_ foreach @{$graph_data->points->[0]}; # Count total number of records
                my $count = $sort->{filter} ? $sort->{count} : 7;
                is($graph_total, $count, "Item total on graph matches table for $sort->{name}");
            }
        }
    }
}

restore_time();

done_testing();
