package Test::GADSDriver;

use v5.24.0;
use Moo;

extends 'Test::Builder::Module';

use GADSDriver ();
use Test::Builder ();

=head1 NAME

Test::GADSDriver - GADS WebDriver integration test library

=head1 EXAMPLES

See files with the C<< .t >> suffix in the F<< webdriver/t >> directory.

=head1 CONSTRUCTOR METHOD

=head2 new

A standard L<< Moo >> constructor which takes the following attributes,
all of which also provide read-only accessor methods:

=head3 gads

A L<< GADSDriver >> object.

=cut

has gads => (
    is => 'ro',
    default => \&_default_gads,
    # TODO: Callers shouldn't need to access any delegated methods, but
    # this is convenient in the absence of suitable test methods.
    handles => [ 'go_to_url' ],
);

sub _default_gads {
    GADSDriver->new;
}

=head1 TEST METHODS

All test methods take an optional first argument of a test name.  In the
absence of this argument, each test provides a reasonable default name.

Some methods take additional arguments.

=head2 Assertion Tests

These test methods verify that the user interface is in a given state.

=head3 assert_error_absent

No error message is visible.

=cut

sub assert_error_absent {
    my ( $self, $name ) = @_;
    $name //= 'No error message is visible';

    return $self->_assert_error( $name, 0 );
}

=head3 assert_error_present

An error message is visible.

=cut

sub assert_error_present {
    my ( $self, $name ) = @_;
    $name //= 'An error message is visible';

    return $self->_assert_error( $name, 1 );
}

sub _assert_error {
    my ( $self, $name, $expect_present ) = @_;

    my $error_el = $self->_assert_element(
        '.messages .alert-danger',
        $expect_present,
        qr/\bERROR: /,
        $name,
    );

    my $test = __PACKAGE__->builder;
    my $error_text = $error_el->text;
    $test->note("The error message is '${error_text}'") if $error_text;

    return $self;
}

=head3 assert_navigation_present

Assert that the navigation displayed on logged in pages is visible.

=cut

sub assert_navigation_present {
    my ( $self, $name ) = @_;
    $name //= 'The site navigation is visible';

    $self->_assert_element(
        'nav #dataset-navbar',
        1,
        qr/\bData\b/,
        $name,
    );

    return $self;
}

=head3 assert_on_login_page

The login page is visible.

=cut

sub assert_on_login_page {
    my ( $self, $name ) = @_;
    $name //= 'The login page is visible';

    $self->_assert_element(
        'h1',
        1,
        qr/\APlease Sign In\b/,
        $name,
    );

    return $self;
}

sub _assert_element {
    my( $self, $selector, $expect_present, $expected_text, $name ) = @_;
    my $test = __PACKAGE__->builder;

    my $matching_el = $self->gads->webdriver->find( $selector, dies => 0 );

    if ( 0 == $matching_el->size ) {
        $test->ok( !$expect_present, $name );
        if ($expect_present) {
            $test->diag( "No element matching '${selector}' found" );
        }
    }
    else {
        my $matching_text = $matching_el->text;
        if ($expect_present) {
            $test->like( $matching_text, $expected_text, $name );
        }
        else {
            $test->unlike( $matching_text, $expected_text, $name );
        }
    }

    return $matching_el;
}

=head2 Action Methods

These test methods perform actions against the user interface.

=head3 submit_login_form_ok

Submit the login form.  This takes an optional hashref argument of C<<
username >> and C<< password >>.  In the absence of either, values
provided by the L<< /gads >> attribute are used.

=cut

sub submit_login_form_ok {
    my ( $self, $name, $args_ref ) = @_;
    $name //= 'Submit the login form';
    my %arg = %$args_ref if ref $args_ref;

    my $test = __PACKAGE__->builder;

    my $gads = $self->gads;
    my $username = $arg{username} // $gads->username;
    my $password = $arg{password} // $gads->password;

    $test->note("About to log in as ${username} with password ${password}");
    my $success = $self->_fill_in_field( '#username', $username );
    $success &&= $self->_fill_in_field( '#password', $password );
    $gads->webdriver->find('[type=submit][name=signin')->click;

    $test->ok( $success, $name );
}

sub _fill_in_field {
    my ( $self, $selector, $value ) = @_;

    my $result = $self->gads->type_into_field( $selector, $value );
    if ( !defined $result ) {
        __PACKAGE__->builder->diag("No '${selector}' element found");
    }
    return ( defined $result ) ? 1 : 0;
}

1;
