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

my $data = [
    {
        string1    => '',
        date1      => '2014-10-10',
        daterange1 => ['2014-03-21', '2015-03-01'],
        enum1      => 1,
        tree1      => 4,
    },{
        string1    => 'Foo',
        date1      => '2014-10-10',
        daterange1 => ['2010-01-04', '2011-06-03'],
        enum1      => 1,
        tree1      => 4,
    },{
        string1    => 'FooBar',
        date1      => '2015-10-10',
        daterange1 => ['2009-01-04', '2017-06-03'],
        enum1      => 1,
        tree1      => 4,
    },{
        string1    => 'FooBar',
        date1      => '2015-10-10',
        daterange1 => ['2009-01-04', '2017-06-03'],
        enum1      => 1,
        tree1      => 4,
    },{
        string1    => 'FooBar',
        date1      => '2015-10-10',
        daterange1 => ['2009-01-04', '2017-06-03'],
        enum1      => 1,
        tree1      => 4,
    },{
        string1    => 'Disappear',
    },{
        string1    => 'FooFooBar',
        date1      => '2010-10-10',
    }
];

my $sheet = t::lib::DataSheet->new(data => $data);

my $schema = $sheet->schema;
my $layout = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

$schema->resultset('User')->populate([
    {
        id       => 1,
        username => 'user1@example.com',
        email    => 'user1@example.com',
    },
]);
$schema->resultset('UserGroup')->create({
    user_id  => 1,
    group_id => $sheet->group->id,
});

my @filters = (
    {
        name       => 'Update of record in no filter view',
        rules      => undef,
        columns    => [], # No columns, only appearance of new record will matter
        current_id => 1,
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
        current_id => 1,
        update => [
            {
                column => 'string1',
                value  => 'Nothing to see here',
            },
        ],
        alerts => 2, # new record and updated record
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
        current_id => 2,
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
        current_id => 3,
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
        current_id => 4,
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
        current_id => 5,
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
        current_id => 6,
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
        current_id => 7,
        update => [
            {
                column => 'string1',
                value  => 'Gone',
            },
        ],
        alerts => 1, # Disappears
    },
);

my $user = { id => 1, value => ', ' };
my $user2 = { id => 2, value => ', ' };

# First all all the filters and alerts#
foreach my $filter (@filters)
{
    my $rules = $filter->{rules} ? {
        rules     => $filter->{rules},
        condition => $filter->{condition},
    } : {};

    my $view = GADS::View->new(
        name        => $filter->{name},
        filter      => encode_json($rules),
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => $user,
        columns     => $filter->{columns},
    );
    $view->write;

    my $alert = GADS::Alert->new(
        user      => $user,
        layout    => $layout,
        schema    => $schema,
        frequency => 24,
        view_id   => $view->id,
    );
    $alert->write;
    $filter->{alert_id} = $alert->id;
}

$ENV{GADS_NO_FORK} = 1;

# Now update all the values, checking alerts as we go
foreach my $filter (@filters)
{
    my $alert_start = $schema->resultset('AlertSend')->search({
        current_id => $filter->{current_id},
        alert_id   => $filter->{alert_id},
    })->count;

    # First add record
    my $record = GADS::Record->new(
        user     => $user,
        layout   => $layout,
        schema   => $schema,
    );
    $record->initialise;
    foreach my $datum (@{$filter->{update}})
    {
        my $col_id = $columns->{$datum->{column}}->id;
        $record->fields->{$col_id}->set_value($datum->{value});
    }
    $record->write;
    my $alert_finish = $schema->resultset('AlertSend')->search({
        current_id => $record->current_id,
        alert_id   => $filter->{alert_id},
    })->count;

    # Now update existing record
    $record->clear;
    $record->find_current_id($filter->{current_id});
    foreach my $datum (@{$filter->{update}})
    {
        my $col_id = $columns->{$datum->{column}}->id;
        $record->fields->{$col_id}->set_value($datum->{value});
    }
    $record->write;
    $alert_finish += $schema->resultset('AlertSend')->search({
        current_id => $filter->{current_id},
        alert_id   => $filter->{alert_id},
    })->count;
    # Number of new alerts is the change of values, plus the new record, plus the view without a filter
    is( $alert_finish, $alert_start + $filter->{alerts}, "Correct number of alerts queued to be sent for filter: $filter->{name}" );
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

$sheet = t::lib::DataSheet->new(data => $data);
$schema = $sheet->schema;
$layout = $sheet->layout;
$columns = $sheet->columns;
$sheet->create_records;

# First create a view with no filter
$schema->resultset('User')->create({
    id       => 1,
    username => 'user1@example.com',
    email    => 'user1@example.com',
});
$schema->resultset('UserGroup')->create({
    user_id  => 1,
    group_id => $sheet->group->id,
});

my $view = GADS::View->new(
    name        => 'view1',
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $user,
    columns     => [$columns->{date1}->id],
);
$view->write;

my $alert = GADS::Alert->new(
    user      => $user,
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
my $rules = {
    rules     => [{
        id       => $columns->{string1}->id,
        type     => 'string',
        value    => 'Foo',
        operator => 'equal',
    }],
};

$view->filter(encode_json($rules));
$view->write;
is( $schema->resultset('AlertCache')->count, 5, "Correct number of alerts after view updated" );

# Do some tests on CURUSER alerts
$data = [
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
        person1 => 2,
    },
    {
        string1 => 'Foo',
        person1 => undef,
    },
    {
        string1 => 'Bar',
        person1 => undef,
    },
];

$sheet = t::lib::DataSheet->new(data => $data);
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
    user        => $user,
    global      => 1,
    columns     => [$columns->{string1}->id, $columns->{person1}->id],
);
$view->write;

$alert = GADS::Alert->new(
    user      => $user,
    layout    => $layout,
    schema    => $schema,
    frequency => 24,
    view_id   => $view->id,
);
$alert->write;

is( $schema->resultset('AlertCache')->count, 10, "Correct number of alerts inserted" );

# Add a person filter, check alert cache
$rules = {
    rules     => [{
        id       => $columns->{person1}->id,
        type     => 'string',
        value    => '[CURUSER]',
        operator => 'equal',
    }],
};

$view->filter(encode_json($rules));
$view->write;
is( $schema->resultset('AlertCache')->search({ user_id => 1 })->count, 4, "Correct number of alerts for initial CURUSER filter addition (user1)" );
is( $schema->resultset('AlertCache')->search({ user_id => 2 })->count, 0, "Correct number of alerts for initial CURUSER filter addition (user2)" );

$alert = GADS::Alert->new(
    user      => $user2,
    layout    => $layout,
    schema    => $schema,
    frequency => 24,
    view_id   => $view->id,
);
$alert->write;

is( $schema->resultset('AlertCache')->search({ user_id => 1 })->count, 4, "Still correct number of alerts for CURUSER filter addition (user1)" );
is( $schema->resultset('AlertCache')->search({ user_id => 2 })->count, 2, "Correct number of alerts for new CURUSER filter addition (user2)" );
is( $schema->resultset('AlertCache')->search({ user_id => undef })->count, 0, "No null user_id values inserted for CURUSER filter addition" );

# Change global view slightly, check alerts
$rules = {
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
};
$view->filter(encode_json($rules));
$view->write;

is( $schema->resultset('AlertCache')->search({ user_id => 1 })->count, 2, "Correct number of CURUSER alerts after filter change (user1)" );
is( $schema->resultset('AlertCache')->search({ user_id => 2 })->count, 2, "Correct number of CURUSER alerts after filter change (user2)" );
is( $schema->resultset('AlertCache')->search({ user_id => undef })->count, 0, "No null user_id values after filter change" );

# Update a record so as to cause a search_views with CURUSER
my $record = GADS::Record->new(
    user     => $user,
    layout   => $layout,
    schema   => $schema,
);
$record->find_current_id(1);
$record->fields->{$columns->{string1}->id}->set_value('FooBar');
$record->write;

# And remove curuser filter
$rules = {
    rules     => [
        {
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'Foo',
            operator => 'equal',
        }
    ],
};
$view->filter(encode_json($rules));
$view->write;

is( $schema->resultset('AlertCache')->search({ user_id => { '!=' => undef } })->count, 0, "Correct number of user_id alerts after removal of curuser filter" );
is( $schema->resultset('AlertCache')->search({ user_id => undef })->count, 4, "Correct number of normal alerts after removal of curuser filter" );

# Test some bulk alerts, which normally happen on code field updates
diag "About to test alerts for bulk updates. This could take some time...";

# Some bulk data, almost all matching the filter, but not quite,
# to test big queries (otherwise current_ids is not searched)
$data = [ { string1 => 'Bar' } ];
push @$data, { string1 => 'Foo' }
    for (1..1000);

$sheet = t::lib::DataSheet->new(data => $data);
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

$schema->resultset('User')->create({
    id       => 1,
    username => 'user1@example.com',
    email    => 'user1@example.com',
});
$schema->resultset('UserGroup')->create({
    user_id  => 1,
    group_id => $sheet->group->id,
});

$rules = {
    rules     => [{
        id       => $columns->{string1}->id,
        type     => 'string',
        value    => 'Foo',
        operator => 'equal',
    }],
};

$view = GADS::View->new(
    name        => 'view1',
    filter      => encode_json($rules),
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $user,
    columns     => [$columns->{string1}->id],
);
$view->write;

$alert = GADS::Alert->new(
    user      => $user,
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
    user        => $user,
    base_url    => undef, # $self->base_url,
    current_ids => [@ids],
    columns     => [$columns->{string1}->id],
);
$alert_send->process;

# We should now have 999 new alerts to send (1001 records, minus one popped from
# current_ids, minus first one not in view)
is( $alerts_rs->count, $alert_count + 999, "Correct number of bulk alerts inserted" );

done_testing();
