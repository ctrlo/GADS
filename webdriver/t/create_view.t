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

my $gads = Test::GADSDriver->new;

$gads->go_to_url('/');

$gads->submit_login_form_ok;

# Preparation: create a new table for testing
$gads->navigate_ok(
    'Navigate to the add a table page',
    [ qw( .table-editor .table-add ) ],
);
$gads->assert_on_add_a_table_page;

$gads->submit_add_a_table_form_ok( 'Add a table to create the view on',
    { name => $table_name, group_name => $group_name } );
$gads->assert_error_absent('No error message is visible after adding a table');

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

$gads->delete_table_ok;
$gads->assert_success_present;
$gads->assert_error_absent;

done_testing();
