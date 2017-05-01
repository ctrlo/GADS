use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;

use t::lib::DataSheet;

my $sheet = t::lib::DataSheet->new(user_count => 3);

my $schema = $sheet->schema;
my $layout = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $user_normal1 = { id => 1, value => 'User1, User1' };
my $user_normal2 = { id => 2, value => 'User2, User2' };
my $user_admin   = { id => 3, value => 'User3, User3', permission => { layout => 1 } };

my %view = (
    name        => 'view1',
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $user_normal1,
    global      => 0,
    columns     => [$columns->{string1}->id],
);

my $view = GADS::View->new(%view);

# Create normal view as normal user
try { $view->write };
ok(!$@, "Created normal view as normal user");

# Try and read view as other user
my $view2 = GADS::View->new(id => $view->id, schema => $schema, instance_id => 1, layout => $layout, user => $user_normal2);
try { $view2->filter };
ok($@, "Failed to read view as normal user of other user view");

foreach my $test (qw/is_admin global is_admin/) # Do test, change, then back again
{
    # Create global view as normal user, should fail
    $view->$test(1);
    try { $view->write };
    ok($@, "Failed to write $test view as normal user");

    # Now as admin user
    $view->user($user_admin);
    try { $view->write };
    ok(!$@, "Created $test view as admin user");

    # Read global view as normal user
    $view2 = GADS::View->new(id => $view->id, schema => $schema, instance_id => 1, layout => $layout, user => $user_normal2);
    try { $view2->filter };
    ok(!$@, "Read view as normal user of $test view");

    # Put back to normal. Need to remove global/admin first, then change to normal user
    $view = GADS::View->new(%view);
    $view->write;
}

done_testing();
