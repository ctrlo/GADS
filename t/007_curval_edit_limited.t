use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# A test for a quite unique and tricky test whereby:
# - A curval edit field is included
# - Its values are limited by a view on the user's account
# - The view limit is based on autocur values of a calc field on the the main record

# The scenario:
# The main table is "projects"
# There is a sub-table for "offices"
# A project is assigned to an office
# An office is in a region
# A user is restricted access by region
# Another sub-table is used to record the staff of a project, as a curval-edit
# The main projects table extracts the integers from the staff sub-table

# Set of offices, enum1 should be their region
my $data = [
    {
        string1 => 'Newcastle',
        enum1   => 'foo1',
    },
    {
        string1 => 'Liverpool',
        enum1   => 'foo2',
    },
    {
        string1 => 'York',
        enum1   => 'foo1',
    },
];
my $office_sheet = Test::GADS::DataSheet->new(instance_id => 3, site_id => 1, data => $data);
$office_sheet->create_records;
my $schema = $office_sheet->schema;

my $newcastle = GADS::Record->new(
    user   => $office_sheet->user,
    layout => $office_sheet->layout,
    schema => $schema,
);
$newcastle->find_current_id(1);
is($newcastle->fields->{$office_sheet->columns->{string1}->id}->as_string, "Newcastle", "Newcastle record correct");

# Staff within an office, will be used as a curval-edit. Also refers to the
# office sheet
my $staff_sheet = Test::GADS::DataSheet->new(
    schema           => $schema,
    instance_id      => 2,
    site_id          => 1,
    data             => [],
    curval           => 3,
    curval_field_ids => [ $office_sheet->columns->{string1}->id ],
);
$staff_sheet->create_records;

# Main sheet with list of projects, refers to office sheet.
# Make the calc be the region of the project (from office_sheet)
my $project_sheet   = Test::GADS::DataSheet->new(
    schema           => $schema,
    curval           => 3, # Drop-down curval for offices
    data             => [],
    curval_field_ids => [ $office_sheet->columns->{string1}->id ],
);
my $layout  = $project_sheet->layout;
my $columns = $project_sheet->columns;
$project_sheet->create_records;

# Add second curval to main project sheet, which will use the staff sheet. This
# is a curval-edit field.
my $staff_involved = GADS::Column::Curval->new(
    schema => $schema,
    user   => $project_sheet->user,
    layout => $layout,
);
$staff_involved->refers_to_instance_id(2);
$staff_involved->curval_field_ids([$staff_sheet->columns->{string1}->id]);
$staff_involved->type('curval');
$staff_involved->name('Staff involved');
$staff_involved->name_short('staff_involved');
$staff_involved->set_permissions({$project_sheet->group->id => $project_sheet->default_permissions});
# Standard curval-edit settings
$staff_involved->delete_not_used(1);
$staff_involved->show_add(1);
$staff_involved->value_selector('noshow');
$staff_involved->write(no_alerts => 1, force => 1);

# Add a calc field to the main project table which will take values from the
# staff involved curval-edit field. It adds up all the integers from the staff
# involved field
my $staff_ages = GADS::Column::Calc->new(
    schema      => $schema,
    user        => $project_sheet->user,
    layout      => $layout,
    name        => 'Staff ages',
    return_type => 'integer',
    code        => "function evaluate (staff_involved)
        if staff_involved == nil then
            return nil
        end
        ages = 0
        for _,staff in ipairs(staff_involved) do
            if staff.field_values.L2integer1 then
                ages = ages + staff.field_values.L2integer1
            end
        end
        return ages
    end",
);
$staff_ages->set_permissions({$project_sheet->group->id => $project_sheet->default_permissions});
$staff_ages->write;

# Now add the calculated project region, which takes its value from the region
# in the curval for the office. This will be used to restrict access in the
# curval-edit field for the staff.
# Slightly tenuous conditions, but we have to do this last so that it gets
# written last when writing the record (the ordering of dependencies does so
# with IDs if there is no other reason to order). The bug this is catching is
# that this value will not have been written when the curval-edit staff field
# is written, and thus the user does not have access at that point.
my $project_region = GADS::Column::Calc->new(
    schema      => $schema,
    user        => $project_sheet->user,
    layout      => $layout,
    name        => 'Project region',
    return_type => 'string',
    code        => qq{function evaluate (L1curval1)
        if L1curval1 == nil then
            return
        end
        -- Return region (enum1) from office sheet (instance 3)
        return L1curval1.field_values.L3enum1
    end},
);
$project_region->set_permissions({$project_sheet->group->id => $project_sheet->default_permissions});
$project_region->write;

# Add autocur to the staff table. This will refer to the office of the main
# project
my $autocur = $staff_sheet->add_autocur(
    refers_to_instance_id => 1,
    related_field_id      => $staff_involved->id,
    curval_field_ids      => [$staff_sheet->columns->{string1}->id],
);

# Now add a limited view to the curval-edit staff table, only allowing a user
# to see staff associated with projects that are in region "foo1"
my $rules = GADS::Filter->new(
    as_hash => {
        rules     => [{
            id       => $autocur->id."_".$project_region->id,
            type     => 'string',
            value    => 'foo1',
            operator => 'equal',
        }],
    },
);

my $view_limit = GADS::View->new(
    name        => 'Limit to view',
    filter      => $rules,
    instance_id => $staff_sheet->layout->instance_id,
    layout      => $staff_sheet->layout,
    schema      => $schema,
    user        => $project_sheet->user,
    is_admin    => 1,
);
$view_limit->write;

my $normal_user = $project_sheet->user_normal1;
$normal_user->set_view_limits([$view_limit->id]);

$project_sheet->layout->user($normal_user);
$project_sheet->layout->clear;

# Now create a project with some related staff
my $record = GADS::Record->new(
    user   => $normal_user,
    layout => $project_sheet->layout,
    schema => $schema,
);
$record->initialise;
# Project name
$record->fields->{$columns->{string1}->id}->set_value('My project');
# Office
$record->fields->{$columns->{curval1}->id}->set_value($newcastle->current_id);
# Project staff
$record->fields->{$staff_involved->id}->set_value([
    $staff_sheet->columns->{string1}->field."=Smith&"
    .$staff_sheet->columns->{integer1}->field."=65"
]);
$record->write(no_alerts => 1);
my $cid = $record->current_id;

# Check the written values
$record = GADS::Record->new(
    user   => $normal_user,
    layout => $project_sheet->layout,
    schema => $schema,
);
$record->find_current_id($cid);
is($record->fields->{$staff_ages->id}->as_string, "65", "Correct age");
my $staff_ids = $record->fields->{$staff_involved->id}->ids;

# Make an edit
$record->fields->{$columns->{string1}->id}->set_value('New project name');
# Simulate a user submission from a form, which would always involve writing
# back the ID numbers of the curval
$record->fields->{$staff_involved->id}->set_value($staff_ids);
$record->write(no_alerts => 1);
# Check value again
$record = GADS::Record->new(
    user   => $normal_user,
    layout => $project_sheet->layout,
    schema => $schema,
);
$record->find_current_id($cid);
is($record->fields->{$staff_ages->id}->as_string, "65", "Correct age");

done_testing();
