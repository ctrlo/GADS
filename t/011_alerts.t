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
        string1    => 'Disappear',
    },
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

my @filters = (
    {
        name       => 'Update of record in no filter view',
        rules      => undef,
        columns    => [],
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
        name  => 'Disappears from view',
        rules => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'Disappear',
            operator => 'equal',
        }],
        columns => [$columns->{string1}->id],
        current_id => 4,
        update => [
            {
                column => 'string1',
                value  => 'Gone',
            },
        ],
        alerts => 1, # Disappears
    },
);

my $user = { id => 1 };

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
    $alert_finish += $schema->resultset('AlertSend')->search({ current_id => $filter->{current_id} })->count;
    # Number of new alerts is the change of values, plus the new record, plus the view without a filter
    is( $alert_finish, $alert_start + $filter->{alerts}, "Correct number of alerts queued to be sent for filter: $filter->{name}" );
}

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

my $rules = {
    rules     => [{
        id       => $columns->{string1}->id,
        type     => 'string',
        value    => 'Foo',
        operator => 'equal',
    }],
};

my $view = GADS::View->new(
    name        => 'view1',
    filter      => encode_json($rules),
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $user,
    columns     => [$columns->{string1}->id],
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

# We should now have 1000 new alerts to send
is( $alerts_rs->count, $alert_count + 1000, "Correct number of bulk alerts inserted" );

done_testing();
