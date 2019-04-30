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

# TODO: Instead of relying on an existing named group, create a group to
# use.
my $group_name = $ENV{GADS_GROUPNAME} //
    die 'Set the GADS_GROUPNAME environment variable';
my $table_name = "TESTWD $$";
my $text_field_name = "MytestName";
my $int_field_name = "MytestInt";

my $gads = Test::GADSDriver->new;

$gads->go_to_url('/');

$gads->submit_login_form_ok;

# Create a new table for testing
$gads->navigate_ok(
    'Navigate to the add a table page',
    [ qw( .table-editor .table-add ) ],
);
$gads->assert_on_add_a_table_page;

$gads->submit_add_a_table_form_ok( 'Add a table to create the view on',
    { name => $table_name, group_name => $group_name } );
$gads->assert_success_present('A success message is visible after adding a table');
$gads->assert_error_absent('No error message is visible after adding a table');

# Set permissions on the new table
$gads->select_table_to_edit_ok( 'Prepare to set permissions on the new table',
    $table_name );
$gads->assert_on_manage_this_table_page;

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

$gads->submit_add_a_field_form_ok(
    'Add an integer field to the new table',
    { name => $int_field_name, type => 'Integer', group_name => $group_name },
);

$gads->assert_success_present('The integer field was added successfully');
$gads->assert_on_manage_fields_page(
    'On the manage fields page after adding two fields' );
$gads->assert_field_exists( undef, { name => $text_field_name, type => 'Text' } );
$gads->assert_field_exists( undef, { name => $int_field_name, type => 'Integer' } );

# TODO: write main tests here

# Tidy up: remove the table created earlier
$gads->navigate_ok(
    'Navigate to the manage tables page',
    [ qw( .table-editor .tables-manage ) ],
);
$gads->assert_on_manage_tables_page;

$gads->select_table_to_edit_ok( 'Select the table created for testing',
    $table_name );
$gads->assert_on_manage_this_table_page;

$gads->follow_link_ok( undef, 'Manage fields' );
$gads->assert_on_manage_fields_page;
$gads->select_field_to_edit_ok( 'Select the text field created for testing',
    $text_field_name );
$gads->confirm_deletion_ok('Delete the text field created for testing');
$gads->assert_on_manage_fields_page(
    'On the manage fields page after deleting the first field' );
$gads->select_field_to_edit_ok( 'Select the integer field created for testing',
    $int_field_name );
$gads->confirm_deletion_ok('Delete the integer field created for testing');
$gads->assert_on_manage_fields_page(
    'On the manage fields page after deleting fields' );

$gads->navigate_ok(
    'Navigate to the manage tables page',
    [ qw( .table-editor .tables-manage ) ],
);
$gads->assert_on_manage_tables_page;

$gads->select_table_to_edit_ok( 'Select the table created for testing',
    $table_name );
$gads->assert_on_manage_this_table_page;

$gads->confirm_deletion_ok('Delete the table created for testing');
$gads->assert_success_present;
$gads->assert_error_absent;

$gads->assert_on_manage_tables_page(
    'On the manage tables page after deleting a table' );
$gads->assert_table_not_listed( 'The deleted table is not listed',
    $table_name );

done_testing();
