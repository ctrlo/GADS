use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Filter;
use GADS::Group;
use GADS::Groups;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use lib 't/lib';
use Test::GADS::DataSheet;

my $sheet   = Test::GADS::DataSheet->new(user_permission_override => 0);
my $schema  = $sheet->schema;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $superadmin = $sheet->user;
ok($superadmin->permission->{superadmin}, "Superadmin has correct permission");

my $user_normal1 = $sheet->user_normal1;
my $user_normal2 = $sheet->user_normal2;

my $group1 = $sheet->group;
my $group2 = GADS::Group->new(schema => $schema);
$group2->from_id;
$group2->name('group2');
$group2->write;

# Add first normal user to second group
$schema->resultset('UserGroup')->create({
    user_id  => $user_normal1->id,
    group_id => $group2->id,
});

ok($user_normal1->has_group->{$group1->id}, "Normal user has first group");
ok($user_normal1->has_group->{$group2->id}, "Normal user has second group");
ok($user_normal2->has_group->{$group1->id}, "Normal user has first group");
ok(!$user_normal2->has_group->{$group2->id}, "Normal user does not have second group");

ok(!$schema->resultset('Graph')->count, "No graphs created");

my %graph_template = (
    title        => 'Test',
    type         => 'bar',
    x_axis       => $columns->{string1}->id,
    y_axis       => $columns->{enum1}->id,
    y_axis_stack => 'count',
    layout       => $layout,
    schema       => $schema,
);

# Create all users shared graph by superadmin
GADS::Graph->new(
    %graph_template,
    is_shared    => 1,
    current_user => $superadmin,
)->write;

is($schema->resultset('Graph')->count, 1, "Superadmin created graph");

is(_graph_count($user_normal1), 1, "Normal user can see graph");

# Create personal graph by superadmin
GADS::Graph->new(
    %graph_template,
    is_shared    => 0,
    current_user => $superadmin,
)->write;

is(_graph_count($user_normal1), 1, "Normal user can see same graphs");

# Create shared group graph by superadmin
GADS::Graph->new(
    %graph_template,
    is_shared    => 1,
    group_id     => $group2->id,
    current_user => $superadmin,
)->write;

is(_graph_count($user_normal1), 2, "First user can see shared graph");
is(_graph_count($user_normal2), 1, "Second user cannot");

# Attempt to create shared graph by first user
$layout->user($user_normal1);
$layout->clear;
try {
    GADS::Graph->new(
        %graph_template,
        is_shared    => 1,
        group_id     => $group1->id,
        current_user => $user_normal1,
    )->write;
};
like($@, qr/do not have permission/, "Unable to create shared graph as normal user");

# Add group graph creation to normal user and try again
$schema->resultset('InstanceGroup')->create({
    instance_id => $layout->instance_id,
    group_id    => $group1->id,
    permission => 'view_group',
});
$layout->clear;
GADS::Graph->new(
    %graph_template,
    is_shared    => 1,
    group_id     => $group1->id,
    current_user => $user_normal1,
)->write;
$layout->user($user_normal2);
$layout->clear;
is(_graph_count($user_normal2), 2, "Normal user can see other user shared graph");
# Try creating all user shared graph
try {
    GADS::Graph->new(
        %graph_template,
        is_shared    => 1,
        current_user => $user_normal1,
    )->write;
};
like($@, qr/do not have permission/, "Unable to create all user shared graph as group user");

# Finally check what groups each user can see for sharing
# Create new table with 2 new groups, which should not be shown to anyone but
# superadmin to begin with
my $sheet2 = Test::GADS::DataSheet->new(schema => $schema, instance_id => 2, data => []);
$sheet2->create_records;
# Group3 is a group with normal read permissions on a field in the table
my $group3 = GADS::Group->new(schema => $schema);
$group3->from_id;
$group3->name('group3');
$group3->write;
is($schema->resultset('Instance')->count, 2, "New table created");
# Group4 is a group which has layout permissions on the new table
$schema->resultset('LayoutGroup')->create({
    group_id   => $group3->id,
    layout_id  => $sheet2->columns->{string1}->id,
    permission => 'read',
});
my $group4 = GADS::Group->new(schema => $schema);
$group4->from_id;
$group4->name('group4');
$group4->write;
$schema->resultset('InstanceGroup')->create({
    instance_id => 2,
    group_id    => $group4->id,
    permission  => 'layout',
});

# Finally a third sheet with its own group to check this group is only shown to
# superadmin
my $sheet3 = Test::GADS::DataSheet->new(schema => $schema, instance_id => 3, data => []);
$sheet3->create_records;
my $group5 = GADS::Group->new(schema => $schema);
$group5->from_id;
$group5->name('group5');
$group5->write;
is($schema->resultset('Instance')->count, 3, "New table created");
$schema->resultset('LayoutGroup')->create({
    group_id   => $group5->id,
    layout_id  => $sheet3->columns->{string1}->id,
    permission => 'read',
});

# Check viewable groups
# First normal user should see group1 and group2 that it's a member of
my $g1 = join ' ', sort grep /^group/, map $_->name, $user_normal1->groups_viewable;
# Only group1 for second normal user
my $g2 = join ' ', sort grep /^group/, map $_->name, $user_normal2->groups_viewable;
# All groups for superadmin
my $g3 = join ' ', sort grep /^group/, map $_->name, $superadmin->groups_viewable;

is($g1, 'group1 group2', "First normal user has correct groups");
is($g2, 'group1', "Second normal user has correct groups");
is($g3, 'group1 group2 group3 group4 group5', "Superadmin has correct groups");

# Now add group4 to the normal user. This should then allow the normal user to
# also see group3 which is used in the table that group4 has layour permission
# on
$schema->resultset('UserGroup')->create({
    user_id  => $user_normal1->id,
    group_id => $group4->id,
});
$g1 = join ' ', sort grep /^group/, map $_->name, $user_normal1->groups_viewable;
is($g1, 'group1 group2 group3 group4', "Normal user has access to groups in its tables");


done_testing();

sub _graph_count
{   my $user = shift;
    return scalar @{GADS::Graphs->new(
        current_user => $user,
        schema       => $schema,
        layout       => $layout,
    )->all};
}
