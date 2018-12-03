package Test::GADSDriver;

use v5.24.0;
use Moo;

extends 'Test::Builder::Module';

use GADSDriver ();
use Test::Builder ();

has gads => (
    is => 'ro',
    default => \&_default_gads,
    handles => [ 'go_to_url' ],
);

sub _default_gads {
    GADSDriver->new;
}

sub assert_error_absent {
    my ( $self, $name ) = @_;
    $name //= 'No error message is visible';

    return $self->_assert_error( $name, 0 );
}

sub assert_error_present {
    my ( $self, $name ) = @_;
    $name //= 'An error message is visible';

    return $self->_assert_error( $name, 1 );
}

sub _assert_error {
    my ( $self, $name, $expect_present ) = @_;

    my $test = __PACKAGE__->builder;

    my $selector = '.messages .alert-danger';
    my $error_el = $self->gads->webdriver->find( $selector, dies => 0 );

    if ( 0 == $error_el->size ) {
        $test->ok( !$expect_present, $name );
        if ($expect_present) {
            $test->diag( "No element matching '${selector}' found" );
        }
    }
    else {
        my $error_text = $error_el->text;
        if ($expect_present) {
            $test->like( $error_text, qr/\bERROR: /, $name );
        }
        else {
            $test->unlike( $error_text, qr/\bERROR: /, $name );
        }
        $test->note("The error message is '${error_text}'") if $error_text;
    }

    return $self;
}

sub assert_on_login_page {
    my ( $self, $name ) = @_;
    $name //= 'The login page is visible';

    my $test = __PACKAGE__->builder;

    my $selector = 'h1';
    my $heading_el = $self->gads->webdriver->find( $selector, dies => 0 );

    if ( 0 == $heading_el->size ) {
        $test->ok( 0, $name );
        $test->diag( "No element matching '${selector}' found" );
    }
    else {
        my $heading_text = $heading_el->text;
        $heading_text =~ s/\A\s+|\s+\z//g;
        $test->is_eq( $heading_text, 'Please Sign In', $name );
    }

    return $self;
}

sub submit_login_form_ok {
    my ( $self, $name, $args_ref ) = @_;
    $name //= 'Submit the login form';
    my %arg = %$args_ref if ref $args_ref;

    my $test = __PACKAGE__->builder;

    my $gads = $self->gads;
    my $username = $arg{username} // $gads->username;
    my $password = $arg{password} // $gads->password;

    $test->note("About to log in as ${username} with password ${password}");
    my $success = $self->_fill_in_field( '#username', $username, $name );
    $success &&= $self->_fill_in_field( '#password', $password, $name );
    $gads->webdriver->find('[type=submit][name=signin')->click;

    $test->ok( $success, $name );
}

sub _fill_in_field {
    my ( $self, $selector, $value, $name ) = @_;

    my $result = $self->gads->type_into_field( $selector, $value );
    if ( !defined $result ) {
        __PACKAGE__->builder->diag("No '${selector}' element found");
    }
    return ( defined $result ) ? 1 : 0;
}

1;
