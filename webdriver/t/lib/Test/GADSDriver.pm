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

=head3 assert_success_absent

No success message is visible.

=cut

sub assert_success_absent {
    my ( $self, $name ) = @_;
    $name //= 'No success message is visible';

    return $self->_assert_success( $name, 0 );
}

=head3 assert_success_present

An success message is visible.

=cut

sub assert_success_present {
    my ( $self, $name ) = @_;
    $name //= 'A success message is visible';

    return $self->_assert_success( $name, 1 );
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

sub _assert_success {
    my ( $self, $name, $expect_present ) = @_;

    my $success_el = $self->_assert_element(
        '.messages .alert-success',
        $expect_present,
        qr/\bNOTICE: /,
        $name,
    );

    my $test = __PACKAGE__->builder;
    my $success_text = $success_el->text;
    $test->note("The success message is '${success_text}'") if $success_text;

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

=head3 assert_on_add_a_table_page

The I<< Add a table >> page is visible.

=cut

sub assert_on_add_a_table_page {
    my ( $self, $name ) = @_;
    $name //= 'The add a table page is visible';

    my $matching_el = $self->_assert_on_page(
        'body.table\\/0',
        [ { selector => 'h2', text => 'Add a table' } ],
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

=head3 assert_on_manage_tables_page

The I<< Manage tables >> page is visible.

=cut

sub assert_on_manage_tables_page {
    my ( $self, $name ) = @_;
    $name //= 'The manage tables page is visible';

    my $matching_el = $self->_assert_on_page(
        'body.table',
        [ { selector => 'h2', text => 'Manage tables' } ],
        $name,
    );

    return $self;
}

=head3 assert_on_manage_this_table_page

The I<< Manage this table >> page is visible.

=cut

sub assert_on_manage_this_table_page {
    my ( $self, $name ) = @_;
    $name //= 'The manage this table page is visible';

    my $matching_el = $self->_assert_on_page(
        'body.table',
        [ { selector => 'h2', text => 'Manage this table' } ],
        $name,
    );

    return $self;
}

sub _assert_element {
    my( $self, $selector, $expect_present, $expected_text, $name ) = @_;
    my $test = __PACKAGE__->builder;

    # Try for longer to find expected elements than unexpected elements.
    # TODO: Move these to configuration
    my $tries = $expect_present ? 30 : 10;

    my $matching_el = $self->gads->webdriver->find(
        $selector,
        dies => 0,
        tries => $tries,
    );

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

sub _assert_on_page {
    my ( $self, $page_selector, $expectations, $name ) = @_;
    my $test = __PACKAGE__->builder;
    my $webdriver = $self->gads->webdriver;

    # TODO: Move 'tries' to configuration
    my $page_el = $webdriver->find( $page_selector, dies => 0, tries => 25 );

    if ( 0 == $page_el->size ) {
        $test->ok( 0, $name );
        $test->diag("No elements matching '${page_selector}' found");
    }
    else {
        my @failure;
        foreach my $expect_ref ( @$expectations ) {
            my %expect = %$expect_ref;
            my $matching_el = $webdriver->find( $expect{selector}, dies => 0 );
            if ( 0 == $matching_el->size ) {
                push @failure, "No elements matching '${page_selector}' found";
            }
            else {
                my $matching_text = $matching_el->text;
                if ( $matching_text ne $expect{text} ) {
                    push @failure,"Found '${matching_text}' in $expect{selector}, expected '$expect{text}'";
                }
            }
        }
        $test->ok( !@failure, $name );
        $test->diag($_) foreach @failure;
    }

    return $page_el;
}

=head2 Action Methods

These test methods perform actions against the user interface.

=head3 delete_table_ok

Delete the current table from the I<< Manage this table >> page.

=cut

sub delete_table_ok {
    my ( $self, $name ) = @_;
    $name //= "Delete the selected table";
    my $test = __PACKAGE__->builder;
    my $webdriver = $self->gads->webdriver;

    my $delete_button_el = $webdriver->find(
        # TODO: Use a better selector
        'form a[data-target="#myModal"]',
        dies => 0,
    );
    if ( 0 == $delete_button_el->size ) {
        $test->ok( 0, $name );
        $test->diag("No delete button found");
    }
    elsif ( 1 != $delete_button_el->size ) {
        $test->ok( 0, $name );
        $test->diag("More than one delete button found");
    }
    else {
        $delete_button_el->click;
        
        my $selector = '.modal-content button[name=delete]';
        my $confirm_button_el = $webdriver->find( $selector, dies => 0 );

        if ( 1 == $confirm_button_el->size ) {
            $confirm_button_el->click;
            $test->ok( 1, $name );
        }
        else {
            $test->ok( 0, $name );
            $test->diag("No confirm button found");
        }
    }
    
    return $self;
}

=head3 navigate_ok

Takes an array reference of selectors to click on in the site navigation.

=cut

sub navigate_ok {
    my ( $self, $name, $selectors_ref ) = @_;
    $name //= "Navigate to " . join " ", @$selectors_ref;
    my $test = __PACKAGE__->builder;
    my $webdriver = $self->gads->webdriver;

    my @failure;
    foreach my $selector (@$selectors_ref) {
        # TODO: Move 'tries' to configuration
        my $found_el = $webdriver->find( $selector, dies => 0, tries => 25 );
        if ( 0 == $found_el->size || !$found_el->visible ) {
            push @failure, "No visible elements matching '${selector}' found";
        }
        else {
            $found_el->click;
        }
    }
    $test->ok( !@failure, $name );
    $test->diag($_) foreach @failure;

    return $self;
}

=head3 select_table_to_edit_ok

From the I<< Manage tables >> page, select a named table to edit.

=cut

sub select_table_to_edit_ok {
    my ( $self, $name, $table_name ) = @_;
    $name //= "Select the '$table_name' table to edit";
    my $test = __PACKAGE__->builder;
    my $webdriver = $self->gads->webdriver;
    
    my $xpath = "//tr[ contains( ., '$table_name' ) ]//a";
    my $table_edit_el = $webdriver->find( $xpath, method => 'xpath', dies => 0 );
    if ( 0 == $table_edit_el->size ) {
        $test->ok( 0, $name );
        $test->diag("No tables named '${table_name}' found");
    }
    elsif ( 1 != $table_edit_el->size ) {
        $test->ok( 0, $name );
        $test->diag("More than one table named '${table_name}' found");
    }
    else {
        $table_edit_el->click;
        $test->ok( 1, $name );
    }

    return $self;
}

=head3 submit_add_a_table_form_ok

Submit the I<< Add a table >> form.  Takes a hash reference of arguments
where C<< name >> contains the name of the new table to add and C<<
group_name >> contains the name of an existing group to assign all
permissions to.

=cut

sub submit_add_a_table_form_ok {
    my ( $self, $name, $args_ref ) = @_;
    $name //= 'Submit the add a table form';
    my %arg = %$args_ref;

    my $test = __PACKAGE__->builder;

    my $success = $self->_fill_in_field( 'input[name=name]', $arg{name} );

    # Fill in checkboxes to give the specified group all permissions
    my $webdriver = $self->gads->webdriver;
    my $group_row_el = $webdriver->find(
        # TODO: "contains" isn't the same as "equals"
        "//tr/td[1][ contains( ., '$arg{group_name}') ]/..",
        method => 'xpath',
        dies => 0,
    );
    if ( 0 == $group_row_el->size ) {
        $success = 0;
        $test->diag("No group named '$arg{group_name}' found");
    }
    elsif ( 1 != $group_row_el->size ) {
        $success = 0;
        $test->diag("More than one group named '$arg{group_name}' found");
    }
    else {
        $_->click foreach $group_row_el->find('input[name=permissions]');
    }

    $test->note("About to add a table named $arg{name}");
    $webdriver->find('[type=submit][name=submit]')->click;

    $test->ok( $success, $name );
}

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
    $gads->webdriver->find('[type=submit][name=signin]')->click;

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
