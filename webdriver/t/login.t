#!perl

use v5.24.0;
use warnings;

=head1 NAME

login.t - Test the login form

=head1 SEE ALSO

L<< Test::GADSDriver >>

=cut

use lib 'webdriver/t/lib';

use Test::GADSDriver ();
use Test::More 'no_plan';

my $gads = Test::GADSDriver->new;

$gads->go_to_url('/');
$gads->assert_on_login_page;
$gads->assert_error_absent;

$gads->submit_login_form_ok( 'Submit the login form with a bad password',
    { password => 'thisisnotmypassword' } );
$gads->assert_on_login_page('The login page is visible after a bad login');
$gads->assert_error_present;

$gads->submit_login_form_ok;
$gads->assert_navigation_present(
    'The site navigation is visible after logging in' );
$gads->assert_error_absent('No error message is visible after logging in');
$gads->assert_success_absent('No success message is visible after logging in');

done_testing();
