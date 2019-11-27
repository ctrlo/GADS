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

use lib 't/lib';
use Test::GADS::DataSheet;

set_fixed_time('10/10/2014 01:00:00', '%m/%d/%Y %H:%M:%S');

# A bunch of records that will be used for the alert tests - mainly different
# records for different tests. XXX There needs to be a better way of managing
# these - each are referred to by their IDs in the tests, which makes adding
# tests difficult
my $data = [
    {
        string1    => '',
        date1      => '2014-10-10',
        daterange1 => ['2014-03-21', '2015-03-01'],
        enum1      => 'foo1',
        tree1      => 'tree1',
        curval1    => 1,
    },
    {
        string1    => '',
        date1      => '2014-10-10',
        daterange1 => ['2014-03-21', '2015-03-01'],
        enum1      => 'foo1',
        tree1      => 'tree1',
        curval1    => 1,
    },
    {
        string1    => '',
        date1      => '2014-10-10',
        daterange1 => ['2014-03-21', '2015-03-01'],
        enum1      => 'foo1',
        tree1      => 'tree1',
        curval1    => 1,
    },
    {
        string1    => '',
        date1      => '2014-10-10',
        daterange1 => ['2014-03-21', '2015-03-01'],
        enum1      => 'foo1',
        tree1      => 'tree1',
        curval1    => 1,
    },
    {
        string1    => 'Foo',
        date1      => '2014-10-10',
        daterange1 => ['2010-01-04', '2011-06-03'],
        enum1      => 'foo1',
        tree1      => 'tree1',
        curval1    => 1,
    },
    {
        string1    => 'FooBar',
        date1      => '2015-10-10',
        daterange1 => ['2009-01-04', '2017-06-03'],
        enum1      => 'foo1',
        tree1      => 'tree1',
        curval1    => 2,
    },
    {
        string1    => 'FooBar',
        date1      => '2015-10-10',
        daterange1 => ['2009-01-04', '2017-06-03'],
        enum1      => 'foo1',
        tree1      => 'tree1',
        curval1    => 2,
    },
    {
        string1    => 'FooBar',
        date1      => '2015-10-10',
        daterange1 => ['2009-01-04', '2017-06-03'],
        enum1      => 'foo1',
        tree1      => 'tree1',
    },
    {
        string1    => 'Disappear',
    },
    {
        string1    => 'FooFooBar',
        date1      => '2010-10-10',
    },
    {
        daterange1 => ['2009-01-04', '2017-06-03'],
    },
    {
        daterange1 => ['2009-01-04', '2017-06-03'],
    },
    {
        daterange1 => ['2009-01-04', '2017-06-03'],
    },
    {
        daterange1 => ['2009-01-04', '2017-06-03'],
    },
    {
        daterange1 => ['2009-01-04', '2017-06-03'],
    },
    {
        daterange1 => ['2009-01-04', '2017-06-03'],
    },
    {
        curval1    => 1,
        daterange1 => ['2014-01-04', '2017-06-03'],
    },
    {
        curval1    => 1,
        daterange1 => ['2014-01-04', '2017-06-03'],
    },
];

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, calc_return_type => 'string');
$curval_sheet->create_records;
my $curval_columns = $curval_sheet->columns;
my $schema = $curval_sheet->schema;

my $sheet = Test::GADS::DataSheet->new(
    data                     => $data,
    schema                   => $schema,
    curval                   => 2,
    user_permission_override => 0,
);

my $layout = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $autocur1 = $curval_sheet->add_autocur(
    curval_field_ids      => [$columns->{daterange1}->id],
    refers_to_instance_id => 1,
    related_field_id      => $columns->{curval1}->id,
);
$layout->clear; # Ensure main layout takes account of its new child autocurs
my $curval_calc = $curval_sheet->columns->{calc1};
$curval_calc->code("
    function evaluate (L2autocur1)
        return_value = ''
        for _, v in pairs(L2autocur1) do
            if v.field_values.L1daterange1.from.year == 2014 then
                return_value = return_value .. v.field_values.L1daterange1.from.year
            end
        end
        return return_value
    end
");
$curval_calc->write;

my $created_calc = GADS::Column::Calc->new(
    name        => "Created calc",
    schema      => $schema,
    user        => $sheet->user,
    layout      => $layout,
    return_type => 'date',
    code => "
        function evaluate (_created)
            return _created.epoch
        end
    ",
);
$created_calc->write;
$created_calc->set_permissions({$sheet->group->id, $sheet->default_permissions});
$layout->clear;

my @filters = (
    {
        name       => 'Calc with record created date',
        rules      => undef,
        columns    => [$created_calc->id],
        current_id => 3,
        update     => [
            {
                column => 'string1',
                value  => 'foobar',
            },
        ],
        alerts => 1,
    },
    {
        name  => 'View filtering on record created date',
        rules => [
            {
                id       => $layout->column_by_name_short('_created')->id,
                type     => 'string',
                value    => '2014-10-20',
                operator => 'greater',
            },
        ],
        columns => [$columns->{string1}->id],
        current_id => 4,
        update => [
            {
                column => 'string1',
                value  => 'FooFoo',
            },
        ],
        alerts => 1, # New record only
    },
    {
        name  => 'View filtering on record updated date',
        rules => [
            {
                id       => $layout->column_by_name_short('_version_datetime')->id,
                type     => 'string',
                value    => '2014-10-20',
                operator => 'greater',
            },
        ],
        columns => [$columns->{date1}->id], # No change to data shown
        current_id => 5,
        update => [
            {
                column => 'string1',
                value  => 'FooFoo2',
            },
        ],
        alerts => 2, # New record and updated record
    },
    {
        name  => 'View filtering on record updated person',
        rules => [
            {
                id       => $layout->column_by_name_short('_version_user')->id,
                type     => 'string',
                value    => 'User5, User5',
                operator => 'equal',
            },
        ],
        columns => [$columns->{date1}->id], # No change to data shown
        current_id => 6,
        update => [
            {
                column => 'string1',
                value  => 'FooFoo3',
            },
        ],
        alerts => 2, # New record and updated record
    },
    {
        name  => 'View filtering on record updated person - unchanged',
        rules => [
            {
                id       => $layout->column_by_name_short('_version_user')->id,
                type     => 'string',
                value    => 'User5, User5',
                operator => 'equal',
            },
        ],
        columns => [$columns->{date1}->id], # No change to data shown
        # Use same record as previous test - user making the update will not
        # have changed and therefore this should not alert except for the new
        # record
        current_id => 6,
        update => [
            {
                column => 'string1',
                value  => 'FooFoo4',
            },
        ],
        alerts => 1, # New record only
    },
    {
        name       => 'Update of record in no filter view',
        rules      => undef,
        columns    => [], # No columns, only appearance of new record will matter
        current_id => 3,
        update     => [
            {
                column => 'string1',
                value  => 'xyz',
            },
        ],
        alerts => 1,
    },
    {
        name  => 'Record appears in view',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'Nothing to see here',
            operator => 'equal',
        }],
        columns => [$columns->{string1}->id],
        current_id => 3,
        update => [
            {
                column => 'string1',
                value  => 'Nothing to see here',
            },
        ],
        alerts => 2, # new record and updated record
    },
    {
        name  => 'Global view',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'Nothing to see here2',
            operator => 'equal',
        }],
        columns => [$columns->{string1}->id],
        current_id => 3,
        update => [
            {
                column => 'string1',
                value  => 'Nothing to see here2',
            },
        ],
        alerts => 2, # new record and updated record
        global_view => 1,
    },
    {
        name  => 'Group view',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'Nothing to see here3',
            operator => 'equal',
        }],
        columns => [$columns->{string1}->id],
        current_id => 3,
        update => [
            {
                column => 'string1',
                value  => 'Nothing to see here3',
            },
        ],
        alerts => 2, # new record and updated record
        group_view => 1,
    },
    {
        name  => 'Update to row in view',
        rules => [
            {
                id       => $columns->{string1}->id,
                type     => 'string',
                value    => 'Foo',
                operator => 'equal',
            },
            {
                id       => $columns->{date1}->id,
                type     => 'date',
                value    => '2000-01-04',
                operator => 'greater',
            },
        ],
        columns => [$columns->{date1}->id],
        current_id => 7,
        update => [
            {
                column => 'date1',
                value  => '2014-10-15',
            },
            {
                column => 'string1',
                value  => 'Foo',
            },
        ],
        alerts => 2, # New record and updated record
    },
    {
        name  => 'Update to row not in view',
        rules => [
            {
                id       => $columns->{string1}->id,
                type     => 'string',
                value    => 'FooBar',
                operator => 'equal',
            },
        ],
        columns => [$columns->{string1}->id],
        current_id => 8,
        update => [
            {
                column => 'date1',
                value  => '2014-10-15',
            },
        ],
        alerts => 0, # Neither update nor new appear/change in view
    },
    {
        name  => 'Update to row, one column in view and one not',
        rules => [
            {
                id       => $columns->{string1}->id,
                type     => 'string',
                value    => 'FooBar',
                operator => 'begins_with',
            },
        ],
        columns => [$columns->{string1}->id],
        current_id => 9,
        update => [
            {
                column => 'string1',
                value  => 'FooBar2',
            },
            {
                column => 'date1',
                value  => '2017-10-15',
            },
        ],
        alerts => 2, # One alert for only single column in view, one for new record
    },
    {
        name  => 'Update to row, changes to 2 columns both in view',
        rules => [
            {
                id       => $columns->{string1}->id,
                type     => 'string',
                value    => 'FooBar',
                operator => 'begins_with',
            },
        ],
        columns => [$columns->{string1}->id, $columns->{date1}->id],
        current_id => 10,
        update => [
            {
                column => 'string1',
                value  => 'FooBar2',
            },
            {
                column => 'date1',
                value  => '2017-10-15',
            },
        ],
        alerts => 3, # One alert for only single column in view, one for new record
    },
    {
        name  => 'Disappears from view',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'Disappear',
            operator => 'equal',
        }],
        columns => [$columns->{string1}->id],
        current_id => 11,
        update => [
            {
                column => 'string1',
                value  => 'Gone',
            },
        ],
        alerts => 1, # Disappears
    },
    {
        name  => 'Change of filter of column not in view',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'FooFooBar',
            operator => 'equal',
        }],
        columns => [$columns->{date1}->id],
        current_id => 12,
        update => [
            {
                column => 'string1',
                value  => 'Gone',
            },
        ],
        alerts => 1, # Disappears
    },
    {
        name  => 'Change of calc field in view',
        rules => undef,
        columns => [$columns->{calc1}->id],
        current_id => 13,
        update => [
            {
                column => 'daterange1',
                value  => ['2010-10-10', '2011-10-10'],
            },
        ],
        alerts => 2, # New record plus Calc field updated
    },
    {
        name  => 'Change of calc field forces record into view',
        rules => [{
            id       => $columns->{calc1}->id,
            type     => 'string',
            value    => '2014',
            operator => 'equal',
        }],
        columns => [$columns->{calc1}->id],
        current_id => 14,
        update => [
            {
                column => 'daterange1',
                value  => ['2014-10-10', '2015-10-10'],
            },
        ],
        alerts => 2, # New record plus calc field coming into view
    },
    {
        name  => 'Change of calc field makes no change to record not in view',
        rules => [{
            id       => $columns->{calc1}->id,
            type     => 'string',
            value    => '2015',
            operator => 'equal',
        }],
        columns => [$columns->{calc1}->id],
        current_id => 15,
        update => [
            {
                column => 'daterange1',
                value  => ['2014-10-10', '2015-10-10'],
            },
        ],
        alerts => 0, # Neither new record nor changed record will be in view
    },
    {
        name  => 'Change of rag field in view',
        rules => undef,
        columns => [$columns->{rag1}->id],
        current_id => 16,
        update => [
            {
                column => 'daterange1',
                value  => ['2012-10-10', '2013-10-10'],
            },
        ],
        alerts => 2, # New record plus Calc field updated
    },
    {
        name  => 'Change of rag field forces record into view',
        rules => [{
            id       => $columns->{rag1}->id,
            type     => 'string',
            value    => 'c_amber',
            operator => 'equal',
        }],
        columns => [$columns->{rag1}->id],
        current_id => 17,
        update => [
            {
                column => 'daterange1',
                value  => ['2012-10-10', '2015-10-10'],
            },
        ],
        alerts => 2, # New record plus calc field coming into view
    },
    {
        name  => 'Change of rag field makes no difference to record not in view',
        rules => [{
            id       => $columns->{rag1}->id,
            type     => 'string',
            value    => 'c_amber',
            operator => 'equal',
        }],
        columns => [$columns->{rag1}->id],
        current_id => 18,
        update => [
            {
                column => 'daterange1',
                value  => ['2013-10-10', '2015-10-10'],
            },
        ],
        alerts => 0, # Neither new record nor existing record in view
    },
    {
        name  => 'Change of autocur/calc in other table as a result of curval change',
        rules => [{
            id       => $curval_columns->{calc1}->id,
            type     => 'string',
            value    => '2014',
            operator => 'contains',
        }],
        alert_layout     => $curval_sheet->layout,
        columns          => [$curval_columns->{calc1}->id],
        current_id       => 19,
        alert_current_id => 2,
        update => [
            {
                column => 'curval1',
                value  => 2,
            },
            {
                column => 'daterange1',
                value  => ['2014-01-04', '2017-06-03'],
            },
        ],
        # One when new instance1 record means that 2014 appears in the autocur,
        # then a second alert when the existing instance1 record is edited and
        # causes it also to appear in the autocur
        alerts => 2,
    },
    {
        name  => 'Change of autocur in other table as a result of curval change',
        alert_layout     => $curval_sheet->layout,
        columns          => [$autocur1->id],
        current_id       => 20,
        alert_current_id => 2,
        update => [
            {
                column => 'curval1',
                value  => 2,
            },
            {
                column => 'daterange1',
                value  => ['2014-01-04', '2017-06-03'],
            },
        ],
        # There are actually 2 changes that take place that will cause alerts,
        # but both are exactly the same so only one will be written to the
        # alert cache.  The addition of a new record with "2" as the curval
        # value will cause a change of current ID 2, and then the change of an
        # existing record to value "2" will cause another similar change.
        alerts => 1,
    },
    {
        name  => 'Change of curval sub-field in filter',
        rules => [{
            id       => $columns->{curval1}->id . '_' . $curval_columns->{string1}->id,
            type     => 'string',
            value    => 'Bar',
            operator => 'equal',
        }],
        columns          => [$columns->{string1}->id],
        current_id       => 1,
        alert_current_id => [3,4,5,6,7,19,20],
        update_layout    => $curval_sheet->layout,
        update => [
            {
                column => 'string1',
                value  => 'Bar',
            },
        ],
        # 7 new records appear in the view, which are the 7 records referencing
        # curval record ID 1, none of which were contained in the view, and
        # then all appear when the curval record is updated to include it in
        # that view
        alerts => 7,
    },
);

# First write all the filters and alerts
foreach my $filter (@filters)
{
    my $rules = $filter->{rules} ? {
        rules     => $filter->{rules},
        condition => $filter->{condition},
    } : {};

    my $alert_layout = $filter->{alert_layout} || $layout;
    my $view = GADS::View->new(
        name        => $filter->{name},
        filter      => encode_json($rules),
        instance_id => $alert_layout->instance_id,
        layout      => $alert_layout,
        schema      => $schema,
        columns     => $filter->{columns},
    );
    $view->global(1) if $filter->{global_view} || $filter->{group_view};
    $view->group_id($sheet->group->id) if $filter->{group_view};
    $view->write;

    my $alert = GADS::Alert->new(
        user      => $sheet->user_normal1, # Different user to that doing the update
        layout    => $filter->{alert_layout} || $layout,
        schema    => $schema,
        frequency => 24,
        view_id   => $view->id,
    );
    $alert->write;
    $filter->{alert_id} = $alert->id;
}

$ENV{GADS_NO_FORK} = 1;

set_fixed_time('11/10/2014 01:00:00', '%m/%d/%Y %H:%M:%S');

# Now update all the values, checking alerts as we go
foreach my $filter (@filters)
{
    # Clear out any existing alerts, for a fair count and also in case the same
    # alert is written again
    $schema->resultset('AlertSend')->search({
        current_id => $filter->{alert_current_id} || $filter->{current_id},
        alert_id   => $filter->{alert_id},
    })->delete;

    # First add record
    my $update_layout = $filter->{update_layout} || $layout;
    my $record = GADS::Record->new(
        user     => $sheet->user_normal2,
        layout   => $update_layout,
        schema   => $schema,
    );
    $record->initialise;
    foreach my $datum (@{$filter->{update}})
    {
        my $col_id = $update_layout->column_by_name($datum->{column})->id;
        $record->fields->{$col_id}->set_value($datum->{value});
    }
    $record->write;

    my $alert_finish; # Count for written alerts
    # Count number of alerts for the just-written record, but not for
    # autocur tests (new record will affect other record)
    $alert_finish += $schema->resultset('AlertSend')->search({
        current_id => $record->current_id,
        alert_id   => $filter->{alert_id},
    })->count unless $filter->{alert_current_id};

    # Now update existing record
    $record->clear;
    $record->find_current_id($filter->{current_id});
    foreach my $datum (@{$filter->{update}})
    {
        my $col_id = $update_layout->column_by_name($datum->{column})->id;
        $record->fields->{$col_id}->set_value($datum->{value});
    }
    $record->write;

    # Add the number of alerts created as a result of record update to previous
    # alert count
    $alert_finish += $schema->resultset('AlertSend')->search({
        current_id => $filter->{alert_current_id} || $filter->{current_id},
        alert_id   => $filter->{alert_id},
    })->count;

    # Number of new alerts is the change of values, plus the new record, plus the view without a filter
    is( $alert_finish, $filter->{alerts}, "Correct number of alerts queued to be sent for filter: $filter->{name}" );
}

# Test updates of views
$data = [
    {
        string1 => 'Foo',
        date1   => '2014-10-10',
    },
    {
        string1 => 'Foo',
        date1   => '2014-10-10',
    },
    {
        string1 => 'Foo',
        date1   => '2014-10-10',
    },
    {
        string1 => 'Foo',
        date1   => '2014-10-10',
    },
    {
        string1 => 'Foo',
        date1   => '2014-10-10',
    },
    {
        string1 => 'Bar',
        date1   => '2014-10-10',
    },
    {
        string1 => 'Bar',
        date1   => '2014-10-10',
    },
];

$sheet = Test::GADS::DataSheet->new(data => $data);
$schema = $sheet->schema;
$layout = $sheet->layout;
$columns = $sheet->columns;
$sheet->create_records;

# First create a view with no filter
my $view = GADS::View->new(
    name        => 'view1',
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $sheet->user,
    columns     => [$columns->{date1}->id],
);
$view->write;

my $alert = GADS::Alert->new(
    user      => $sheet->user,
    layout    => $layout,
    schema    => $schema,
    frequency => 24,
    view_id   => $view->id,
);
$alert->write;

is( $schema->resultset('AlertCache')->count, 7, "Correct number of alerts inserted" );

# Add a column, check alert cache
$view->columns([$columns->{string1}->id, $columns->{date1}->id]);
$view->write;
is( $schema->resultset('AlertCache')->count, 14, "Correct number of alerts for column addition" );

# Remove a column, check alert cache
$view->columns([$columns->{string1}->id]);
$view->write;
is( $schema->resultset('AlertCache')->count, 7, "Correct number of alerts for column removal" );

# Add a filter to the view, alert cache should be updated
$view->filter->as_hash({
    rules     => [{
        id       => $columns->{string1}->id,
        type     => 'string',
        value    => 'Foo',
        operator => 'equal',
    }],
});

$view->write;
is( $schema->resultset('AlertCache')->count, 5, "Correct number of alerts after view updated" );

# Instantiate view from scratch, check that change in filter changes alerts
# First as hash
$view = GADS::View->new(
    id          => $view->id,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $sheet->user,
);
$view->filter->as_hash({
    rules     => [{
        id       => $columns->{string1}->id,
        type     => 'string',
        value    => 'Bar',
        operator => 'equal',
    }],
});
$view->write;
is( $schema->resultset('AlertCache')->count, 2, "Correct number of alerts after view updated (from hash)" );
# Then as JSON
$view = GADS::View->new(
    id          => $view->id,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $sheet->user,
);
$view->filter->as_json(encode_json({
    rules     => [{
        id       => $columns->{string1}->id,
        type     => 'string',
        value    => 'Foo',
        operator => 'equal',
    }],
}));
$view->write;
is( $schema->resultset('AlertCache')->count, 5, "Correct number of alerts after view updated (from json)" );

# Do some tests on CURUSER alerts. One for filter on person field, other on string
foreach my $curuser_type (qw/person string/)
{
    # Hard-coded user IDs. Ideally we would take these from the users that have
    # been created, but they need to be defined now to pass to the datasheet
    # creation
    $data = $curuser_type eq 'person'
        ? [
            {
                string1 => 'Foo',
                person1 => 1,
            },
            {
                string1 => 'Bar',
                person1 => 1,
            },
            {
                string1 => 'Foo',
                person1 => 4,
            },
            {
                string1 => 'Foo',
                person1 => undef,
            },
            {
                string1 => 'Bar',
                person1 => undef,
            },
        ]
        : [
            {
                integer1 => '100',
                string1  => 'User1, User1',
            },
            {
                integer1 => '200',
                string1  => 'User1, User1',
            },
            {
                integer1 => '100',
                string1  => 'User4, User4',
            },
            {
                integer1 => '100',
                string1  => undef,
            },
            {
                integer1 => '200',
                string1  => undef,
            },
        ];

    $sheet = Test::GADS::DataSheet->new(data => $data, user_count => 2);
    $schema = $sheet->schema;
    $layout = $sheet->layout;
    $columns = $sheet->columns;
    $sheet->create_records;

    # First create a view with no filter

    my $col_ids = $curuser_type eq 'person'
        ? [$columns->{string1}->id, $columns->{person1}->id]
        : [$columns->{integer1}->id, $columns->{string1}->id];
    $view = GADS::View->new(
        name        => 'view1',
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        global      => 1,
        columns     => $col_ids,
    );
    $view->write;

    $alert = GADS::Alert->new(
        user      => $sheet->user,
        layout    => $layout,
        schema    => $schema,
        frequency => 24,
        view_id   => $view->id,
    );
    $alert->write;

    is( $schema->resultset('AlertCache')->count, 10, "Correct number of alerts inserted" );

    # Add a person filter, check alert cache
    my $filter_id = $curuser_type eq 'person'
        ? $columns->{person1}->id
        : $columns->{string1}->id;
    $view->filter->as_hash({
        rules     => [{
            id       => $filter_id,
            type     => 'string',
            value    => '[CURUSER]',
            operator => 'equal',
        }],
    });

    $view->write;
    is( $schema->resultset('AlertCache')->search({ user_id => 1 })->count, 4, "Correct number of alerts for initial CURUSER filter addition (user1)" );
    is( $schema->resultset('AlertCache')->search({ user_id => 2 })->count, 0, "Correct number of alerts for initial CURUSER filter addition (user2)" );

    $alert = GADS::Alert->new(
        user      => $sheet->user_normal1,
        layout    => $layout,
        schema    => $schema,
        frequency => 24,
        view_id   => $view->id,
    );
    $alert->write;

    is( $schema->resultset('AlertCache')->search({ user_id => 1 })->count, 4, "Still correct number of alerts for CURUSER filter addition (user1)" );
    is( $schema->resultset('AlertCache')->search({ user_id => $sheet->user_normal1->id })->count, 2, "Correct number of alerts for new CURUSER filter addition (user2)" );
    is( $schema->resultset('AlertCache')->search({ user_id => undef })->count, 0, "No null user_id values inserted for CURUSER filter addition" );

    # Change global view slightly, check alerts
    if ($curuser_type eq 'person')
    {
        $view->filter->as_hash({
            rules     => [
                {
                    id       => $columns->{person1}->id,
                    type     => 'string',
                    value    => '[CURUSER]',
                    operator => 'equal',
                }, {
                    id       => $columns->{string1}->id,
                    type     => 'string',
                    value    => 'Foo',
                    operator => 'equal',
                }
            ],
        });
    }
    else {
        $view->filter->as_hash({
            rules     => [
                {
                    id       => $columns->{string1}->id,
                    type     => 'string',
                    value    => '[CURUSER]',
                    operator => 'equal',
                }, {
                    id       => $columns->{integer1}->id,
                    type     => 'string',
                    value    => 100,
                    operator => 'equal',
                }
            ],
        });
    }
    $view->write;

    is( $schema->resultset('AlertCache')->search({ user_id => 1 })->count, 2, "Correct number of CURUSER alerts after filter change (user1)" );
    is( $schema->resultset('AlertCache')->search({ user_id => $sheet->user_normal1->id })->count, 2, "Correct number of CURUSER alerts after filter change (user2)" );
    is( $schema->resultset('AlertCache')->search({ user_id => undef })->count, 0, "No null user_id values after filter change" );

    # Update a record so as to cause a search_views with CURUSER
    my $record = GADS::Record->new(
        user     => $sheet->user,
        layout   => $layout,
        schema   => $schema,
    );
    $record->find_current_id(1);
    if ($curuser_type eq 'person')
    {
        $record->fields->{$columns->{string1}->id}->set_value('FooBar');
    }
    else {
        $record->fields->{$columns->{integer1}->id}->set_value(150);
    }
    $record->write;

    # And remove curuser filter
    if ($curuser_type eq 'person')
    {
        $view->filter->as_hash({
            rules     => [
                {
                    id       => $columns->{string1}->id,
                    type     => 'string',
                    value    => 'Foo',
                    operator => 'equal',
                }
            ],
        });
    }
    else {
        $view->filter->as_hash({
            rules     => [
                {
                    id       => $columns->{integer1}->id,
                    type     => 'string',
                    value    => '100',
                    operator => 'equal',
                }
            ],
        });
    }
    $view->write;

    is( $schema->resultset('AlertCache')->search({ user_id => { '!=' => undef } })->count, 0, "Correct number of user_id alerts after removal of curuser filter" );
    is( $schema->resultset('AlertCache')->search({ user_id => undef })->count, 4, "Correct number of normal alerts after removal of curuser filter" );
}

# Check alerts after update of calc column code
$sheet = Test::GADS::DataSheet->new;
$schema = $sheet->schema;
$layout = $sheet->layout;
$columns = $sheet->columns;
$sheet->create_records;

# First create a view with no filter
$view = GADS::View->new(
    name        => 'view1',
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $sheet->user,
    global      => 1,
    columns     => [$columns->{calc1}->id],
);
$view->write;

$alert = GADS::Alert->new(
    user      => $sheet->user,
    layout    => $layout,
    schema    => $schema,
    frequency => 24,
    view_id   => $view->id,
);
$alert->write;

is( $schema->resultset('AlertCache')->count, 2, "Correct number of alerts inserted for initial calc test write" );
is( $schema->resultset('AlertSend')->count, 0, "Start calc column change test with no alerts to send" );

# Update calc column to same result (extra space to ensure update), should be no more alerts
my $calc_col = $columns->{calc1};
$calc_col->code("function evaluate (L1daterange1) \n if L1daterange1 == null then return end \n return L1daterange1.from.year\nend ");
$calc_col->write;
is( $schema->resultset('AlertSend')->count, 0, "Correct number of alerts after calc update with no change" );

# Update calc column for different result (one record will change, other has same end year)
$calc_col->code("function evaluate (L1daterange1) \n if L1daterange1 == null then return end \n return L1daterange1.to.year\nend");
$calc_col->write;
is( $schema->resultset('AlertSend')->count, 1, "Correct number of alerts to send after calc update with change" );

# Add filter, check alert after calc update
$schema->resultset('AlertSend')->delete;
$view->filter->as_hash({
    rules     => [
        {
            id       => $columns->{calc1}->id,
            type     => 'string',
            value    => '2011',
            operator => 'greater',
        },
    ],
});
$view->write;
is( $schema->resultset('AlertCache')->count, 1, "Correct number of alert caches after filter applied" );
$calc_col->code("function evaluate (L1daterange1) \n if L1daterange1 == null then return end \n return L1daterange1.from.year\nend");
$calc_col->write;
is( $schema->resultset('AlertSend')->count, 1, "Correct number of alerts to send after calc updated with filter in place" );

# Mock tests for testing alerts for changes as a result of current date.
# Mocking the time in Perl will not affect Lua, so instead we insert the
# year hard-coded in the Lua code. Years of 2010 and 2014 are used for the tests.
foreach my $viewtype (qw/normal group global/)
{
    $sheet = Test::GADS::DataSheet->new(
        calc_code => "function evaluate (L1daterange1) \nif L1daterange1.from.year < 2010 then return 1 else return 0 end\nend",
    );
    $sheet->create_records;
    $schema = $sheet->schema;
    my $layout = $sheet->layout;
    $columns = $sheet->columns;

    # First create a view with no filter
    $view = GADS::View->new(
        name        => 'view1',
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => $sheet->user,
        global      => $viewtype eq 'group' || $viewtype eq 'global' ? 1 : 0,
        group_id    => $viewtype eq 'group' && $sheet->group->id,
        columns     => [$columns->{calc1}->id],
        filter      => GADS::Filter->new->as_hash({
            rules     => [
                {
                    id       => $columns->{calc1}->id,
                    type     => 'string',
                    value    => '1',
                    operator => 'equal',
                },
            ],
        }),
    );
    $view->write;

    $alert = GADS::Alert->new(
        user      => $sheet->user,
        layout    => $layout,
        schema    => $schema,
        frequency => 24,
        view_id   => $view->id,
    );
    $alert->write;

    # Should be nothing in view initially - current year equal to 2014
    is( $schema->resultset('AlertCache')->count, 1, "Correct number of alerts inserted for initial calc test write" );
    is( $schema->resultset('AlertSend')->count, 0, "Start calc column change test with no alerts to send" );

    # Wind date forward 4 years, should now appear in view
    $schema->resultset('Calc')->update({
        code => "function evaluate (L1daterange1) \nif L1daterange1.from.year < 2014 then return 1 else return 0 end\nend",
    });
    # Create new layout without user ID, as it would be in overnight updates
    $layout = GADS::Layout->new(
        user                     => undef,
        schema                   => $schema,
        config                   => $sheet->config,
        instance_id              => $sheet->layout->instance_id,
        user_permission_override => 1, # $self->user_permission_override,
    );
    $layout->column_by_name('calc1')->update_cached;
    is( $schema->resultset('AlertCache')->count, 2, "Correct number of alerts inserted for initial calc test write" );
    is( $schema->resultset('AlertSend')->count, 1, "Correct number of alerts after calc update with no change" );
}

# Test some bulk alerts, which normally happen on code field updates
note "About to test alerts for bulk updates. This could take some time...";

# Some bulk data, almost all matching the filter, but not quite,
# to test big queries (otherwise current_ids is not searched)
$data = [ { string1 => 'Bar' } ];
push @$data, { string1 => 'Foo' }
    for (1..1000);

$sheet = Test::GADS::DataSheet->new(data => $data);
$schema = $sheet->schema;
$layout = $sheet->layout;
$columns = $sheet->columns;
$sheet->create_records;

# Check alert count now, same query we perform at end
my $alerts_rs = $schema->resultset('AlertSend')->search({
    alert_id  => 1,
    layout_id => $columns->{string1}->id,
});
my $alert_count = $alerts_rs->count;

my $rules = GADS::Filter->new(
    as_hash => {
        rules     => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'Foo',
            operator => 'equal',
        }],
    },
);

$view = GADS::View->new(
    name        => 'view1',
    filter      => $rules,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $sheet->user,
    columns     => [$columns->{string1}->id],
);
$view->write;

$alert = GADS::Alert->new(
    user      => $sheet->user,
    layout    => $layout,
    schema    => $schema,
    frequency => 24,
    view_id   => $view->id,
);
$alert->write;

my @ids = $schema->resultset('Current')->get_column('id')->all;
pop @ids; # Again, not all current_ids, otherwise current_ids will not be searched

my $alert_send = GADS::AlertSend->new(
    layout      => $layout,
    schema      => $schema,
    user        => $sheet->user,
    base_url    => undef, # $self->base_url,
    current_ids => [@ids],
    columns     => [$columns->{string1}->id],
);
$alert_send->process;

# We should now have 999 new alerts to send (1001 records, minus one popped from
# current_ids, minus first one not in view)
is( $alerts_rs->count, $alert_count + 999, "Correct number of bulk alerts inserted" );

# Create a record on another sheet which does not have alerts. Tests for a
# previous bug where views with alerts were being searched across all tables
# rather than just the current one.
$schema->resultset('AlertCache')->delete;
my $sheet2 = Test::GADS::DataSheet->new(schema => $schema, instance_id => 2, curval_offset => 6);
$sheet2->create_records;
my $record = GADS::Record->new(
    user     => $sheet2->user,
    layout   => $sheet2->layout,
    schema   => $schema,
);
$record->initialise;
$record->fields->{$sheet2->columns->{string1}->id}->set_value('FooBar');
$record->write;
$schema->resultset('AlertCache')->delete;
is( $schema->resultset('AlertCache')->count, 0, "No alerts created for sheet with no alerts" );

done_testing();
