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

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2, no_groups => 1);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = t::lib::DataSheet->new(data => $data->{a}, schema => $schema, curval => 2, no_groups => 1);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

# Create users
my %users = (
    read      => { id => $sheet->create_user->{id} },
    limited   => { id => $sheet->create_user->{id} },
    readwrite => { id => $sheet->create_user->{id} },
);

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
    $usero->groups($schema->resultset('User')->find($sheet->user->{id}), [$group->id]);
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
    $column->set_permissions(%$permissions);
}
# Turn off the permission override on the curval sheet so that permissions are
# actually tested (turned on initially to populate records)
$curval_sheet->layout->user_permission_override(0);

foreach my $user_type (qw/readwrite read limited/)
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
        _set_data($data->{b}->[0], $layout, $rec, $user_type);
        my $record_max = $schema->resultset('Record')->get_column('id')->max;
        try { $rec->write(no_alerts => 1) };
        if ($user_type eq 'read')
        {
            ok( $@, "Write failed to read-only user" );
        }
        else {
            ok( !$@, "Write for user with write access did not bork" );
            my $record_max_new = $schema->resultset('Record')->get_column('id')->max;
            is( $record_max_new, $record_max + 1, "Change in record's values took place for user $user_type" );
            # Reset values to previous
            _set_data($data->{a}->[0], $layout, $rec, $user_type);
            $rec->write(no_alerts => 1);
        }
    }
    # Delete created record unless one shouldn't have been created (read only test)
    unless ($user_type eq 'read')
    {
        $record->user(undef); # undef users are allowed to delete records
        $record->delete_current;
        $records = GADS::Records->new(
            user    => undef,
            layout  => $layout,
            schema  => $schema,
        );
        is( $records->count, 1, "Record deleted correctly" );
    }
}

# Check deletion of read permissions also updates dependent values
foreach my $test (qw/single all/)
{
    my $sheet   = t::lib::DataSheet->new;
    my $schema  = $sheet->schema;
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;
    my $group1  = $sheet->group;
    my $string1 = $columns->{string1};
    $sheet->create_records;

    my $group2 = GADS::Group->new(schema => $schema);
    $group2->name('group2');
    $group2->write;

    $string1->set_permissions(
        $group1->id => [qw/read write_new write_existing/],
        $group2->id => [qw/read write_new write_existing/],
    );

    my $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $string1->id,
                type     => 'string',
                value    => 'Foo',
                operator => 'equal',
            }],
        },
    );

    my $view = GADS::View->new(
        name        => 'Foo',
        filter      => $rules,
        columns     => [$string1->id],
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => undef,
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

    my $filter = $schema->resultset('View')->find($view->id)->filter;
    like($filter, qr/Foo/, "Filter initially contains Foo search");

    my $alert_rs = $schema->resultset('AlertCache')->search({ layout_id => $string1->id });
    ok($alert_rs->count, "Alert cache contains string1 column");

    my $view_layout_rs = $schema->resultset('ViewLayout')->search({
        view_id   => $view->id,
        layout_id => $string1->id,
    });
    is($view_layout_rs->count, 1, "String column initially in view");

    # Start by always keeping one set of permissions
    my %new_permissions = ($group1->id => [qw/read write_new write_existing/]);
    # Add second set if required
    $new_permissions{$group2->id} = [qw/write_new write_existing/]
        if $test eq 'single';
    # Should be no change as still as read access
    $string1->set_permissions(%new_permissions);
    is($view_layout_rs->count, 1, "View still has column with read access remaining");
    $filter = $schema->resultset('View')->find($view->id)->filter;
    like($filter, qr/Foo/, "Filter still contains Foo search");
    ok($alert_rs->count, "Alert cache still contains string1 column");

    $layout->clear;

    # Now remove read from all groups
    %new_permissions = $test eq 'all' ? () : ($group2->id => [qw/write_new write_existing/]);
    $string1->set_permissions(%new_permissions);
    is($view_layout_rs->count, 0, "String column removed from view when permissions removed");
    $filter = $schema->resultset('View')->find($view->id)->filter;
    unlike($filter, qr/Foo/, "Filter no longer contains Foo search");
    ok(!$alert_rs->count, "Alert cache no longer contains string1 column");
}

done_testing();

sub _set_data
{   my ($data, $layout, $rec, $user_type) = @_;
    foreach my $column ($layout->all(userinput => 1))
    {
        next if $user_type eq 'limited' && $column->name ne 'string1';
        my $datum = $rec->fields->{$column->id};
        $datum->set_value($data->{$column->name});
    }
}
