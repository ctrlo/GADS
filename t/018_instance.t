use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Instances;
use GADS::Users;

use t::lib::DataSheet;

my $sheet   = t::lib::DataSheet->new(user_count => 2);
$sheet->create_records;
my $schema = $sheet->schema;
my $layout = $sheet->layout;

# Set up one normal user, one layout admin user
my $users = GADS::Users->new(schema => $schema);
my ($user_normal, $user_admin) = @{$users->all};
my $perm = $schema->resultset('Permission')->create({ name => 'layout' });
$schema->resultset('UserPermission')->create({
    user_id       => $user_admin->id,
    permission_id => $perm->id,
});

is($schema->resultset('Instance')->count, 1, "One instance created initially");

# Create second table
my $instance2 = $schema->resultset('Instance')->new({});
$instance2->name('Table2');
$instance2->insert;

is($schema->resultset('Instance')->count, 2, "Second instance created");

# layout for second table
my $layout2 = GADS::Layout->new(
    user        => undef,
    schema      => $schema,
    config      => $layout->config,
    instance_id => $instance2->id,
);

# Admin user has access to both
my $instances = GADS::Instances->new(schema => $schema, user => { permission => { 'layout' => 1 } });
is(@{$instances->all}, 2, "Correct number of tables for admin");
# Normal user has access to one
$instances = GADS::Instances->new(schema => $schema, user => { id => $user_normal->id });
is(@{$instances->all}, 1, "Correct number of tables for normal user");
# Add a field to second table that normal user has access to
my $string1 = GADS::Column::String->new(
    schema   => $schema,
    user     => undef,
    layout   => $layout2,
);
$string1->type('string');
$string1->name('string1');
$string1->write;
$string1->set_permissions($sheet->group->id, [qw/read/]);
$instances = GADS::Instances->new(schema => $schema, user => { id => $user_normal->id });
is(@{$instances->all}, 2, "Correct number of tables for normal user after field added");

done_testing();
