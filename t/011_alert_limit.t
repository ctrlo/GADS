use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use lib 't/lib';
use Test::GADS::DataSheet;

$ENV{GADS_NO_FORK} = 1;

# Tests for alerts on a system with limited views for users

my $data = [
    {
        string1    => 'Foo',
        date1      => '2014-10-10',
    },
    {
        string1    => 'Bar',
        date1      => '2014-10-10',
    },
    {
        string1    => 'Apple',
        date1      => '2015-10-10',
    },
    {
        string1    => 'Pear',
        date1      => '2015-10-10',
    },
];

my $sheet = Test::GADS::DataSheet->new(
    data                     => $data,
    user_permission_override => 0,
);

my $layout  = $sheet->layout;
my $columns = $sheet->columns;
my $schema  = $sheet->schema;
$sheet->create_records;

# Create view for limit user's records
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

my $view_limit = GADS::View->new(
    name        => 'Limit to view',
    filter      => $rules,
    instance_id => $layout->instance_id,
    layout      => $layout,
    schema      => $schema,
    user        => $sheet->user,
    is_admin    => 1,
);
$view_limit->write;

my $user = $sheet->user_normal1;
$user->set_view_limits([$view_limit->id]);

# Check view limit is working
my $records = GADS::Records->new(
    user    => $user,
    layout  => $layout,
    schema  => $schema,
);

is ($records->count, 1, 'Correct number of results when limiting to a view');

$rules = {
    rules => [{
        id       => $columns->{date1}->id,
        type     => 'date',
        value    => '2014-10-10',
        operator => 'equal',
    }],
};

my $view = GADS::View->new(
    name        => 'View with alerts',
    filter      => encode_json($rules),
    instance_id => $layout->instance_id,
    layout      => $layout,
    schema      => $schema,
    columns => [$columns->{string1}->id],
);
$view->write;

my $alert = GADS::Alert->new(
    user      => $sheet->user_normal2,
    layout    => $layout,
    schema    => $schema,
    frequency => 24,
    view_id   => $view->id,
);
$alert->write;

is($schema->resultset('AlertCache')->count, 2, "Correct alert cache");
is($schema->resultset('AlertSend')->count, 0, "Correct alert send");

my $record = GADS::Record->new(
    user   => $user,
    layout => $layout,
    schema => $schema,
);
$record->initialise;
$record->fields->{$columns->{string1}->id}->set_value("Foo2");
$record->fields->{$columns->{date1}->id}->set_value("2014-10-10");
$record->write;

is($schema->resultset('AlertCache')->count, 3, "Correct alert cache");
is($schema->resultset('AlertSend')->count, 1, "Correct alert send");

done_testing();
