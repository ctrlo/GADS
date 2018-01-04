use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(decode_json encode_json);
use Log::Report;
use MIME::Base64;

use t::lib::DataSheet;

my $sheet = t::lib::DataSheet->new(user_permission_override => 0);

my $schema = $sheet->schema;
$schema->storage->debug(0);
my $layout = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

# Standard users with permission to create views
my $user_create1 = $sheet->create_user(permissions => [qw/view_create/]);
my $user_create2 = $sheet->create_user(permissions => [qw/view_create/]);
# Super-admin user
my $user_admin   = $sheet->user;
# User with manage fields permission
my $user_layout  = $sheet->create_user(permissions => [qw/layout/]);
# User with no manage view permissions
my $user_nothing = $sheet->create_user;

my %view_template = (
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
);

my %view = (
    %view_template,
    name    => 'view1',
    global  => 0,
    columns => [$columns->{string1}->id],
);

my $view = GADS::View->new(%view);

# Try to create a view as a user without permissions
$layout->user($user_nothing);
$layout->clear;
try { $view->write };
like($@, qr/does not have permission to create new views/, "Failed to create view as user without permissions");

# Create normal view as normal user
$layout->user($user_create1);
$layout->clear;
try { $view->write };
ok(!$@, "Created normal view as normal user");

# Try and read view as other user
my $view2 = GADS::View->new(%view_template, id => $view->id);
$layout->user($user_create2);
$layout->clear;
try { $view2->filter };
ok($@, "Failed to read view as normal user of other user view");

foreach my $test (qw/is_admin global is_admin/) # Do test, change, then back again
{
    # Create global view as normal user, should fail
    $view->$test(1);
    try { $view->write };
    ok($@, "Failed to write $test view as normal user");

    # Now as admin user
    $layout->user($user_admin);
    $layout->clear;
    try { $view->write };
    ok(!$@, "Created $test view as admin user");

    # Read global view as normal user
    $view2 = GADS::View->new(%view_template, id => $view->id);
    $layout->user($user_create2);
    $layout->clear;
    try { $view2->filter };
    ok(!$@, "Read view as normal user of $test view");

    # Put back to normal. Need to remove global/admin first, then change to normal user
    $view = GADS::View->new(%view);
    $layout->user($user_create1);
    $layout->clear;
    $view->write;
}

# Check that view can be deleted, with alerts
$view = GADS::View->new(%view);
$view->write;
my $alert = GADS::Alert->new(
    user      => $sheet->user,
    layout    => $layout,
    schema    => $schema,
    frequency => 24,
    view_id   => $view->id,
);
$alert->write;
my $view_count = $schema->resultset('View')->count;
$view->delete;
is($schema->resultset('View')->count, $view_count - 1, "View deleted successfully");

# Try and load invalid view. Should return GADS::View with nothing in.
# Sometimes the app will try and load an invalid view, for example a saved view
# that no longer exists or a view from a different instance
$view = GADS::View->new(%view_template, id => -10);
is($view->name, undef, "Blank name for invalid view");
is(@{$view->columns}, 0, "No columns for invalid view");

# Try and load a view with an invalid column in the filter (e.g. deleted)
my $filter = GADS::Filter->new(
    as_hash => {
        rules => [
            {
                id       => 100,
                type     => 'string',
                value    => 'foo2',
                operator => 'equal',
            },
        ],
        condition => 'equal',
    },
);
$view = GADS::View->new(
    name        => 'Test',
    filter      => $filter,
    instance_id => $layout->instance_id,
    layout      => $layout,
    schema      => $schema,
    user        => $user_admin,
);
try { $view->write };
like($@, qr/does not exist/, "Sensible error message for invalid field ID");
# Remove invalid filter to allow view to be written
$view->filter(undef);
$view->write;
# Force it into database (as if field deleted since view written)
$schema->resultset('View')->find($view->id)->update({
    filter => $filter->as_json,
});
$view = GADS::View->new(
    id          => $view->id,
    instance_id => $layout->instance_id,
    layout      => $layout,
    schema      => $schema,
    user        => $user_admin,
);
# Check the invalid column as been removed for the base64 representation going
# to the template.
# Need to compare as hash to ensure consistency
my $hash = {rules => [{}], condition => 'equal'};
is_deeply(decode_json(decode_base64($view->filter->base64)), $hash, "Invalid rule removed from base64 of filter");

# Check view names that are too long for the DB
my $long = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum';

$view = GADS::View->new(
    %view_template,
    name    => $long,
);

# Create normal view as normal user
try { $view->write };
like($@, qr/View name must be less than/, "Failed to create view with name too long");
done_testing();
