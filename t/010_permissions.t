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

use t::lib::DataSheet;

# 2 sets of data to alternate between for changes
my $data = {
    a => [
        {
            string1    => 'foo',
            integer1   => '100',
            enum1      => 7,
            tree1      => 10,
            date1      => '2010-10-10',
            daterange1 => ['2000-10-10', '2001-10-10'],
            curval1    => 1,
        },
    ],
    b => [
        {
            string1    => 'bar',
            integer1   => '200',
            enum1      => 8,
            tree1      => 11,
            date1      => '2011-10-10',
            daterange1 => ['2000-11-11', '2001-11-11'],
            curval1    => 2,
        },
    ],
};

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2, no_groups => 1, user_count => 0);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = t::lib::DataSheet->new(data => $data->{a}, schema => $schema, curval => 2, no_groups => 1, user_count => 0);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

# Create users
my %users = (
    read      => { id => 1},
    limited   => { id => 2},
    readwrite => { id => 3},
);
my $delete_user_id = 4;
$schema->resultset('User')->populate([
    {
        id       => $users{read}->{id}, # Read only
        username => 'user1@example.com',
        email    => 'user1@example.com',
    },
    {
        id       => $users{limited}->{id}, # Limited write
        username => 'user2@example.com',
        email    => 'user2@example.com',
    },
    {
        id       => $users{readwrite}->{id}, # Read/write
        username => 'user3@example.com',
        email    => 'user3@example.com',
    },
    {
        id         => $delete_user_id, # User to delete records
        username   => 'user4@example.com',
        email      => 'user4@example.com',
    },
]);

# Groups
foreach my $group_name (qw/read limited readwrite/)
{
    my $group  = GADS::Group->new(schema => $schema);
    $group->name($group_name);
    $group->write;
}

# Check groups and add users
my $groups = GADS::Groups->new(schema => $schema);
is( scalar @{$groups->all}, 3, "Groups created successfully");
my %groups;
foreach my $group (@{$groups->all})
{
    my $usero = $schema->resultset('User')->find($users{$group->name}->{id});
    $usero->groups([$group->id]);
    $groups{$group->name} = $group->id;
}

# Should be 3 groups rows now
is( $schema->resultset('UserGroup')->count, 3, "Correct number of permissions added");

# Write groups such that the limited group only has read/write access to one
# field in the main sheet, but not the curval sheet
foreach my $column ($layout->all, $curval_sheet->layout->all)
{
    # Read only
    my $read = [qw/read/];
    my $all  = [qw/read write_new write_existing approve_new approve_existing
        write_new_no_approval write_existing_no_approval
    /];
    my $permissions = {
        $groups{read} => $read,
    };
    $permissions->{$groups{limited}} = $all
        if $column->name eq 'string1' && $column->layout->instance_id != $curval_sheet->instance_id;
    $permissions->{$groups{readwrite}} = $all;
    $column->set_permissions(permissions => $permissions);
}
# Turn off the permission override on the curval sheet so that permissions are
# actually tested (turned on initially to populate records)
$curval_sheet->layout->user_permission_override(0);

my $data_set = 'b';
foreach my $user_type (keys %users)
{
    my $user = $users{$user_type};
    # Need to build layout each time, to get user permissions
    # correct
    my $layout = GADS::Layout->new(
        user        => $user,
        schema      => $schema,
        config      => GADS::Config->instance,
        instance_id => $sheet->instance_id,
    );
    my $layout_curval = GADS::Layout->new(
        user        => $user,
        schema      => $schema,
        config      => GADS::Config->instance,
        instance_id => $curval_sheet->instance_id,
    );

    # Check overall layout permissions. Having all the columns built in a
    # layout will affect how permissions are checked, so test both
    foreach my $with_columns (0..1)
    {
        if ($with_columns)
        {
            $layout->columns;
            $layout_curval->columns;
        }
        if ($user_type eq 'read')
        {
            ok(!$layout->user_can('write_existing'), "User $user_type cannot write to anything");
        }
        else {
            ok($layout->user_can('write_existing'), "User $user_type can write to something in layout");
        }
        if ($user_type eq 'readwrite')
        {
            ok($layout_curval->user_can('write_existing'), "User $user_type can write to something in layout");
        }
        else {
            ok(!$layout_curval->user_can('write_existing'), "User $user_type cannot write to anything");
        }
        $layout->clear;
        $layout_curval->clear;
    }

    # Check that user has access to all curval values
    my $curval_column = $columns->{curval1};
    is( @{$curval_column->filtered_values}, 2, "User has access to all curval values (filtered)" );
    is( @{$curval_column->all_values}, 2, "User has access to all curval values (all)" );

    # Now apply a filter. Correct number of curval values should be
    # retrieved, regardless of user perms
    $curval_column->filter(GADS::Filter->new(
        as_hash => {
            rules => [{
                id       => $curval_sheet->columns->{string1}->id,
                type     => 'string',
                value    => 'Foo',
                operator => 'equal',
            }],
        },
    ));
    $curval_column->write;
    is( @{$curval_column->filtered_values}, 1, "User has access to all curval values after filter" );
    # Reset for next test
    $curval_column->clear_filter;
    $curval_column->write;


    # First try writing to existing record
    my $records = GADS::Records->new(
        user    => $user,
        layout  => $layout,
        schema  => $schema,
    );
    my @records = @{$records->results};

    is( scalar @records, 1, "One record in test dataset");

    # Add another blank one
    my $record = GADS::Record->new(
        user     => $user,
        layout   => $layout,
        schema   => $schema,
    );
    $record->initialise;
    push @records, $record;

    foreach my $rec (@records)
    {
        my $new = $data->{$data_set}->[0];
        foreach my $column ($layout->all(userinput => 1))
        {
            next if $user_type eq 'limited' && $column->name ne 'string1';
            my $datum = $rec->fields->{$column->id};
            $datum->set_value($new->{$column->name});
        }
        my $record_max = $schema->resultset('Record')->get_column('id')->max;
        try { $rec->write(no_alerts => 1) };
        if ($user_type eq 'read')
        {
            ok( $@, "Write failed to read-only user" );
        }
        else {
            ok( !$@, "Write for user with write access did not bork" );
            my $record_max_new = $schema->resultset('Record')->get_column('id')->max;
            is( $record_max_new, $record_max + 1, "Change in record's values took place" );
        }
    }
    unless ($user_type eq 'read')
    {
            $data_set = $data_set eq 'a' ? 'b' : 'a';
        # First try deleting record as user without permission
        try { $record->delete_current };
        ok( $@, "User without permission failed to delete record" );
        # Now user with
        $record->user({ permission => { delete_noneed_approval => 1 } });
        $record->delete_current;
        $records = GADS::Records->new(
            user    => undef,
            layout  => $layout,
            schema  => $schema,
        );
        is( $records->count, 1, "Record deleted correctly" );
    }
}


done_testing();
