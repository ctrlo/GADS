#!perl

use v5.24.0;
use warnings;

=head1 NAME

create_view.t - Test creating a view and retrieving records

=head1 SEE ALSO

L<< Test::GADSDriver >>

=cut

use lib 'webdriver/t/lib';

use Test::GADSDriver ();
use Test::More 'no_plan';

my $group_name = "TESTGROUPWD $$";
my $table_name = "TESTWD $$";
my $text_field_name = "MytestName";
my $int_field_name = "MytestInt";
my $view_name = 'Less than 100';
my @record = (
    {
        name => 'One hundred and twenty three',
        fields => [ 'One hundred and twenty three', 123 ],
    },
    {
        name => 'Twenty four',
        fields =>  [ 'Twenty four', 24 ],
    },
);

my $gads = Test::GADSDriver->new;

$gads->go_to_url('/');

$gads->submit_login_form_ok;

# Create a new group
$gads->navigate_ok(
    'Navigate to the add a group page',
    [ qw( .user-editor [href$="/group/0"] ) ],
);
$gads->assert_on_add_a_group_page;

$gads->submit_add_a_group_form_ok( 'Add a group', $group_name );
$gads->assert_success_present('A success message is visible after adding a group');
$gads->assert_error_absent('No error message is visible after adding a group');

# Add the user to the new group
$gads->navigate_ok(
    'Navigate to the manage users page',
    [ qw( .user-editor [href$="/user/"] ) ],
);
$gads->assert_on_manage_users_page;

$gads->select_current_user_to_edit_ok('Edit the logged in user');
$gads->assert_on_edit_user_page;

$gads->assign_current_user_to_group_ok(
    'Assign the logged in user to the group', $group_name );
$gads->assert_success_present(
    'A success message is visible after adding the user to a group' );
$gads->assert_error_absent(
    'No error message is visible after adding the user to a group' );

# Create a new table
$gads->navigate_ok(
    'Navigate to the add a table page',
    [ qw( .table-editor .table-add ) ],
);
$gads->assert_on_add_a_table_page;

$gads->submit_add_a_table_form_ok( 'Add a table to create the view on',
    { name => $table_name, group_name => $group_name } );
$gads->assert_success_present('A success message is visible after adding a table');
$gads->assert_error_absent('No error message is visible after adding a table');

$gads->select_table_to_edit_ok( 'Prepare to add fields to the new table',
    $table_name );
$gads->assert_on_manage_this_table_page;

# Add fields to the new table
$gads->follow_link_ok( undef, 'Manage fields' );
$gads->assert_on_manage_fields_page;
$gads->follow_link_ok( undef, 'Add a field' );
$gads->assert_on_add_a_field_page;

$gads->submit_add_a_field_form_ok(
    'Add a text field to the new table',
    { name => $text_field_name, type => 'Text', group_name => $group_name },
);

$gads->assert_success_present('A success message is visible after adding a field');
$gads->assert_error_absent('No error message is visible after adding a field');
$gads->follow_link_ok( undef, 'Add a field' );
$gads->assert_on_add_a_field_page;

$gads->submit_add_a_field_form_ok(
    'Add an integer field to the new table',
    { name => $int_field_name, type => 'Integer', group_name => $group_name },
);

$gads->assert_success_present('The integer field was added successfully');
$gads->assert_on_manage_fields_page(
    'On the manage fields page after adding two fields' );
$gads->assert_field_exists( undef, { name => $text_field_name, type => 'Text' } );
$gads->assert_field_exists( undef, { name => $int_field_name, type => 'Integer' } );

# Create records in the table
$gads->navigate_ok(
    'Navigate to the new record page',
    [ qw( .dropdown-records .record-add ) ],
);
$gads->assert_on_new_record_page;
$gads->assert_new_record_fields(
    "The new record page only shows the two fields",
    [
        {
            label => "${text_field_name}*",
            type => 'string',
        },
        {
            label => "${int_field_name}*",
            type => 'intgr',
        },
    ],
);
$gads->submit_new_record_form_ok(
    'Create the first new record',
    $record[0]{fields},
);
$gads->assert_success_present('The first record was added successfully');
$gads->assert_error_absent(
    'No error message is visible after adding the first record' );
$gads->assert_on_see_records_page;

$gads->navigate_ok(
    'Navigate to the new record page again',
    [ qw( .dropdown-records .record-add ) ],
);
$gads->assert_on_new_record_page;
$gads->submit_new_record_form_ok(
    'Create the second new record',
    $record[1]{fields},
);
$gads->assert_success_present('The second record was added successfully');
$gads->assert_error_absent(
    'No error message is visible after adding the second record' );
$gads->assert_on_see_records_page;
$gads->assert_records_shown(
    'The see records page shows the added records',
    [
        {
            $text_field_name => 'One hundred and twenty three',
            $int_field_name => 123,
        },
        {
            $text_field_name => 'Twenty four',
            $int_field_name => 24,
        },
    ],
);

$gads->navigate_ok(
    'Navigate to the add a view page',
    [ qw( [aria-controls~="menu_view"] .view-add ) ],
);
$gads->assert_on_add_a_view_page;

$gads->submit_add_a_view_form_ok(
    name => $view_name,
    fields => [ $text_field_name, $int_field_name ],
    filters => {
        condition => 'AND',
        rules => [
            {
                field => $text_field_name,
                operator => 'begins with',
                value => 'T',
            },
            {
                field => $int_field_name,
                operator => 'less',
                value => 100,
            },
        ],
    },
);

$gads->assert_on_see_records_page( 'Showing the view', $view_name );
$gads->assert_success_present('The view was added successfully');
$gads->assert_records_shown(
    'The view only shows the expected record',
    [
        {
            $text_field_name => 'Twenty four',
            $int_field_name => 24,
        },
    ],
);

# Tidy up: remove the view created earlier
$gads->navigate_ok(
    'Navigate to the edit current view page',
    [ qw( [aria-controls~="menu_view"] .view-edit ) ],
);
$gads->delete_current_view_ok;

$gads->assert_on_see_records_page('Back on the see records page');
$gads->assert_success_present('The view was deleted successfully');

# Tidy up: remove the records created earlier
$gads->select_record_to_view_ok(
    'Select the first record created', $record[0]{name} );
$gads->assert_on_view_record_page;
$gads->assert_record_has_fields(
    'Viewing the first record created',
    {
        $text_field_name => 'One hundred and twenty three',
        $int_field_name => 123,
    },
);

$gads->delete_viewed_record_ok('Delete the first record created');

$gads->assert_success_present('The first record was deleted successfully');
$gads->assert_on_see_records_page;
$gads->assert_records_shown(
    'Only the second record is shown after deleting the first',
    [
        {
            $text_field_name => 'Twenty four',
            $int_field_name => 24,
        },
    ],
);

$gads->select_record_to_view_ok(
    'Select the second record created', $record[1]{name} );
$gads->assert_on_view_record_page;

$gads->delete_viewed_record_ok('Delete the second record created');

$gads->assert_success_present('The second record was deleted successfully');
$gads->assert_on_see_records_page;

$gads->purge_deleted_records_ok;
$gads->assert_success_present('The deleted records were purged successfully');

# Tidy up: remove the table created earlier
$gads->navigate_ok(
    'Navigate to the manage tables page',
    [ qw( .table-editor .tables-manage ) ],
);
$gads->assert_on_manage_tables_page;

$gads->select_table_to_edit_ok( 'Select the table created',
    $table_name );
$gads->assert_on_manage_this_table_page;

$gads->follow_link_ok( undef, 'Manage fields' );
$gads->assert_on_manage_fields_page;
$gads->select_field_to_edit_ok( 'Select the text field created',
    $text_field_name );
$gads->assert_on_edit_field_page(
    'On the Edit field page before deleting the text field');
$gads->confirm_deletion_ok('Delete the text field created');
$gads->assert_on_manage_fields_page(
    'On the manage fields page after deleting the first field' );
$gads->select_field_to_edit_ok( 'Select the integer field created',
    $int_field_name );
$gads->assert_on_edit_field_page(
    'On the Edit field page before deleting the integer field');
$gads->confirm_deletion_ok('Delete the integer field created');
$gads->assert_on_manage_fields_page(
    'On the manage fields page after deleting fields' );

$gads->navigate_ok(
    'Navigate back to the manage tables page',
    [ qw( .table-editor .tables-manage ) ],
);
$gads->assert_on_manage_tables_page;

$gads->select_table_to_edit_ok( 'Select the table created again',
    $table_name );
$gads->assert_on_manage_this_table_page;

$gads->confirm_deletion_ok('Delete the table created');
$gads->assert_success_present;
$gads->assert_error_absent;

$gads->assert_on_manage_tables_page(
    'On the manage tables page after deleting a table' );
$gads->assert_table_not_listed( 'The deleted table is not listed',
    $table_name );

# Tidy up: remove the group created earlier
$gads->navigate_ok(
    'Navigate to the manage groups page',
    [ qw( .user-editor [href$="/group/"] ) ],
);
$gads->assert_on_manage_groups_page;

$gads->select_group_to_edit_ok( 'Select the group created', $group_name);
$gads->confirm_deletion_ok('Delete the group created');
$gads->assert_success_present;
$gads->assert_error_absent;

done_testing();
