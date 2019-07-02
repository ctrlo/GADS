package Test::GADSDriver;

use v5.24.0;
use Moo;

use GADSDriver ();
use Test2::API 'context';
use Test2::Tools::Compare qw( is like unlike );

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
    my $test = context();

    my $result = $self->_assert_error( $name, 0 );
    $test->release;
    return $result;
}

=head3 assert_error_present

An error message is visible.

=cut

sub assert_error_present {
    my ( $self, $name ) = @_;
    $name //= 'An error message is visible';
    my $test = context();

    my $result = $self->_assert_error( $name, 1 );
    $test->release;
    return $result;
}

=head3 assert_success_absent

No success message is visible.

=cut

sub assert_success_absent {
    my ( $self, $name ) = @_;
    $name //= 'No success message is visible';
    my $test = context();

    my $result = $self->_assert_success( $name, 0 );
    $test->release;
    return $result;
}

=head3 assert_success_present

A success message is visible.

=cut

sub assert_success_present {
    my ( $self, $name ) = @_;
    $name //= 'A success message is visible';
    my $test = context();

    my $result = $self->_assert_success( $name, 1 );
    $test->release;
    return $result;
}

sub _assert_error {
    my ( $self, $name, $expect_present ) = @_;
    my $test = context();

    my $error_el = $self->_assert_element(
        '.messages .alert-danger',
        $expect_present,
        qr/\bERROR: /,
        $name,
    );

    my $error_text = $error_el->text;
    $test->note("The error message is '${error_text}'") if $error_text;

    $test->release;
    return $self;
}

sub _assert_success {
    my ( $self, $name, $expect_present ) = @_;
    my $test = context();

    my $success_el = $self->_assert_element(
        '.messages .alert-success',
        $expect_present,
        qr/\bNOTICE: /,
        $name,
    );

    my $success_text = $success_el->text;
    $test->note("The success message is '${success_text}'") if $success_text;

    $test->release;
    return $self;
}

=head3 assert_field_exists

On the I<< Manage fields >> page, takes two named arguments, C<< name >>
and C<< type >> and asserts that a field with the given name of the
given type is listed as existing on the current table.

=cut

sub assert_field_exists {
    my ( $self, $name, $args_ref ) = @_;
    my %arg = %$args_ref;
    $name //= "A field named '$arg{name}' of type '$arg{type}' exists";
    my $test = context();
    my $webdriver = $self->gads->webdriver;

    my $type_el = $webdriver->find(
        # TODO: "contains" isn't the same as "equals"
       "//main//tr/td[2][ contains( ., '$arg{name}' ) ]/../td[3]",
       method => 'xpath',
       dies => 0,
    );
    my $success = $self->_check_only_one( $type_el, "field named $arg{name}" );

    if ( $success && $type_el ) {
        is( $type_el->text, $arg{type}, $name );
    }
    else {
        $test->ok( 0, $name );
    }

    $test->release;
    return $self;
}

=head3 assert_new_record_fields

On the I<< New record >> page, takes an array of hash references
describing all data entry fields that should exist.

Each hash reference contains the following fields:

=over

=item label

The text contents of the human readable label element

=item type

The value of the C<< data-column-type >> attribute on the element in the
C<< form-group >> class.

=back

=cut

sub assert_new_record_fields {
    my ( $self, $name, $expected ) = @_;
    $name //= "The new record page shows only the expected fields";
    my $test = context();
    my $webdriver = $self->gads->webdriver;

    my $form_group_el = $webdriver->find('.edit-form .form-group');
    my $found = [
        map {
            {
                label => $_->find('label')->text,
                type => $_->attr('data-column-type'),
            },
        } $form_group_el->split,
    ];

    is( $found, $expected, $name );

    $test->release;
    return $self;
}

=head3 assert_table_not_listed

On the I<< Manage tables >> page, takes one argument containing the name
of a table and asserts that no table with the given name is listed.

=cut

sub assert_table_not_listed {
    my ( $self, $name, $table_name ) = @_;
    $name //= "The table named '$table_name' is not listed";
    my $test = context();

    my $table_el = $self->_find_named_table_or_field_el($table_name);

    my $name_selector = '../../td[ not( descendant::a ) ]';
    my @table_name = map {$_->find( $name_selector, method => 'xpath' )->text }
        $table_el->split;
    is( \@table_name, [], $name );

    $test->release;
    return $self;
}

=head3 assert_navigation_present

Assert that the navigation displayed on logged in pages is visible.

=cut

sub assert_navigation_present {
    my ( $self, $name ) = @_;
    $name //= 'The site navigation is visible';
    my $test = context();

    $self->_assert_element(
        'nav #dataset-navbar',
        1,
        qr/\bData\b/,
        $name,
    );

    $test->release;
    return $self;
}

=head3 assert_on_add_a_field_page

The I<< Add a field >> page is visible.

=cut

sub assert_on_add_a_field_page {
    my ( $self, $name ) = @_;
    $name //= 'The add a field page is visible';
    my $test = context();

    $self->_assert_on_page(
        'body.layout\\/0',
        [
            # TODO: Check the table name appears in the h2 text
            { selector => 'h2', match => '\\AAdd a field to ' },
            { selector => '#basic-panel h3', text => 'Field properties' },
        ],
        $name,
    );

    $test->release;
    return $self;
}

=head3 assert_on_add_a_table_page

The I<< Add a table >> page is visible.

=cut

sub assert_on_add_a_table_page {
    my ( $self, $name ) = @_;
    $name //= 'The add a table page is visible';
    my $test = context();

    $self->_assert_on_page(
        'body.table\\/0',
        [ { selector => 'h2', text => 'Add a table' } ],
        $name,
    );

    $test->release;
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

=head3 assert_on_manage_fields_page

The I<< Manage fields >> page is visible.

=cut

sub assert_on_manage_fields_page {
    my ( $self, $name ) = @_;
    $name //= 'The manage fields page is visible';
    my $test = context();

    $self->_assert_on_page(
        'body.layout',
        # TODO: Check the table name appears in the h2 text
        [ { selector => 'h2.list-fields', match => '\\AManage fields in ' } ],
        $name,
    );

    $test->release;
    return $self;
}

=head3 assert_on_manage_tables_page

The I<< Manage tables >> page is visible.

=cut

sub assert_on_manage_tables_page {
    my ( $self, $name ) = @_;
    $name //= 'The manage tables page is visible';
    my $test = context();

    $self->_assert_on_page(
        'body.table',
        [ { selector => 'h2', text => 'Manage tables' } ],
        $name,
    );

    $test->release;
    return $self;
}

=head3 assert_on_manage_this_table_page

The I<< Manage this table >> page is visible.

=cut

sub assert_on_manage_this_table_page {
    my ( $self, $name ) = @_;
    $name //= 'The manage this table page is visible';
    my $test = context();

    $self->_assert_on_page(
        'body.table',
        [ { selector => 'h2', text => 'Manage this table' } ],
        $name,
    );

    $test->release;
    return $self;
}

=head3 assert_on_new_record_page

The I<< New record >> page is visible.

=cut

sub assert_on_new_record_page {
    my ( $self, $name ) = @_;
    $name //= 'The new record page is visible';
    my $test = context();

    $self->_assert_on_page(
        'body.edit',
        [ { selector => 'h2', text => 'New record' } ],
        $name,
    );

    $test->release;
    return $self;
}

=head3 assert_on_see_records_page

The I<< See records >> page is visible.

=cut

sub assert_on_see_records_page {
    my ( $self, $name ) = @_;
    $name //= 'The see records page is visible';
    my $test = context();

    $self->_assert_on_page(
        'body.page.data_table',
        [ { selector => 'h1', match => '\\AAll data\\s*' } ],
        $name,
    );

    $test->release;
    return $self;
}

=head3 assert_on_view_record_page

The I<< View record >> page is visible.

=cut

sub assert_on_view_record_page {
    my ( $self, $name ) = @_;
    $name //= 'The view record page is visible';
    my $test = context();

    $self->_assert_on_page(
        # TODO: Check the field values appear in the page content
        'body.record',
        [ { selector => 'h2', match => '\\ARecord ID ' } ],
        $name,
    );

    $test->release;
    return $self;
}

sub _assert_element {
    my( $self, $selector, $expect_present, $expected_re, $name ) = @_;
    my $test = context();

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
            like( $matching_text, $expected_re, $name );
        }
        else {
            unlike( $matching_text, $expected_re, $name );
        }
    }

    $test->release;
    return $matching_el;
}

sub _assert_on_page {
    my ( $self, $page_selector, $expectations, $name ) = @_;
    my $test = context();
    my $webdriver = $self->gads->webdriver;

    # TODO: Move 'tries' to configuration
    my %find_arg = ( dies => 0, tries => 50 );
    my $page_el = $webdriver->find( $page_selector, %find_arg );

    my @failure;
    if ( 0 == $page_el->size ) {
        push @failure, "No elements matching '${page_selector}' found";
    }
    else {
        foreach my $expect_ref ( @$expectations ) {
            my $selector = $expect_ref->{selector};
            my $matching_el = $webdriver->find( $selector, %find_arg );
            if ( 0 == $matching_el->size ) {
                push @failure, "No elements matching '${selector}' found";
            }
            else {
                push @failure, $self->_check_element_against_expectation(
                    $matching_el, $expect_ref );
            }
        }
    }
    $test->ok( !@failure, $name );
    $test->diag($_) foreach @failure;

    $test->release;
    return $page_el;
}

sub _check_element_against_expectation {
    my ( $self, $matching_el, $expect_ref ) = @_;
    my $matching_text = $matching_el->text;
    my %expect = %$expect_ref;

    my @failure;
    if ( exists $expect{text} && exists $expect{match} ) {
        push @failure, "Both 'match' and 'text' expectations stated";
    }
    elsif ( exists $expect{text} ) {
        if ( $matching_text ne $expect{text} ) {
            push @failure, "Found '${matching_text}' in $expect{selector}, expected '$expect{text}'";
        }
    }
    elsif ( exists $expect{match} ) {
        if ( $matching_text !~ /$expect{match}/ ) {
            push @failure, "Found '${matching_text}' in $expect{selector}, expected '$expect{match}'";
        }
    }
    else {
        push @failure, "No 'match' or 'text' expectation stated";
    }

    return @failure;
}

=head2 Action Methods

These test methods perform actions against the user interface.

=head3 confirm_deletion_ok

Delete the current table from the I<< Manage this table >> page.

Commonly used to delete a field or table.

=cut

sub confirm_deletion_ok {
    my ( $self, $name ) = @_;
    $name //= 'Approve the "Confirm deletion" modal';
    my $test = context();
    my $webdriver = $self->gads->webdriver;

    my $entity_name = $webdriver->find('input[name="name"]')->attr('value');

    my $delete_button_el = $webdriver->find(
        # TODO: Use a better selector
        'form a[data-target="#myModal"]',
        dies => 0,
    );

    my $success = $self->_check_only_one( $delete_button_el, 'delete button' );
    if ($success) {
        $delete_button_el->click;

        my $selector = '.modal-content button[name=delete]';
        my $confirm_button_el = $webdriver->find( $selector, dies => 0 );

        if ( 1 == $confirm_button_el->size ) {
            $test->note( qq{About to delete "$entity_name"} );
            $confirm_button_el->click;
        }
        else {
            $success = 0;
            $test->diag("No confirm button found");
        }
    }
    $test->ok( $success, $name );

    $test->release;
    return $self;
}

=head3 delete_viewed_record_ok

Delete the currently viewed record

=cut

sub delete_viewed_record_ok {
    my ( $self, $name ) = @_;
    $name //= 'Delete the currently viewed record';
    my $test = context();
    my $webdriver = $self->gads->webdriver;

    my @failure = $self->_find_and_click( [ qw( .btn-action .btn-delete ) ] );

    my $modal_title_el = $webdriver->find('h4#myModalLabel');
    if ( $modal_title_el->size && 'Delete record' eq $modal_title_el->text ) {
        # TODO: note() that we're about to delete the record
        $webdriver->find('#modaldelete .btn-primary.submit_button')->click;
    }
    else {
        push @failure, "No 'Delete record' modal found";
    }

    $test->ok( !@failure, $name );
    $test->diag($_) foreach @failure;

    $test->release;
    return $self
}

=head3 follow_link_ok

Takes a string and follows a link containing that string's text.

=cut

sub follow_link_ok {
    my ( $self, $name, $link_text ) = @_;
    $name //= "Follow the link containing '${link_text}'";
    my $test = context();
    my $webdriver = $self->gads->webdriver;

    my $link_el = $webdriver->find(
        # TODO: "contains" isn't the same as "equals"
        "//main//a[ contains( ., '${link_text}') ]",
        method => 'xpath',
        dies => 0,
    );

    my $success = $self->_check_only_one(
        $link_el, "link containing '${link_text}'"); ;
    $link_el->click if $success;

    my $result = $test->ok( $success, $name );
    $test->release;
    return $result;
}

=head3 navigate_ok

Takes an array reference of selectors to click on in the site navigation.

=cut

sub navigate_ok {
    my ( $self, $name, $selectors_ref ) = @_;
    $name //= "Navigate to " . join " ", @$selectors_ref;
    my $test = context();
    my $webdriver = $self->gads->webdriver;

    my @failure = $self->_find_and_click($selectors_ref);
    $test->ok( !@failure, $name );
    $test->diag($_) foreach @failure;

    $test->release;
    return $self;
}

sub _find_and_click {
    my ( $self, $selectors_ref ) = @_;
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

    return @failure;
}

=head3 purge_deleted_records_ok

Purge all deleted records from the current table.

=cut

sub purge_deleted_records_ok {
    my ( $self, $name ) = @_;
    $name //= 'Purge all deleted records from the current table';
    my $test = context();
    my $webdriver = $self->gads->webdriver;

    $test->note('About to purge the deleted records');
    my @failure = $self->_find_and_click( [ "#admin-menu", ".manage-deleted" ] );
    my $title_el = $webdriver->find( 'h2', dies => 0, tries => 10 );
    push @failure, $self->_check_element_against_expectation(
        $title_el, { text => 'Manage deleted records' } );

    $webdriver->find('#selectall')->click;
    $webdriver->find('button[data-target="#purge"]')->click;
    $webdriver->find('button[type="submit"][name="purge"]')->click;

    $test->ok( !@failure, $name );
    $test->diag($_) foreach @failure;
    $test->release;

    return $self;
}

=head3 select_field_to_edit_ok

From the I<< Manage fields >> page, select a named field to edit.

=cut

sub select_field_to_edit_ok {
    my $self = shift;
    return $self->_select_table_or_field_to_edit_ok( @_, 'field' );
}

=head3 select_table_to_edit_ok

From the I<< Manage tables >> page, select a named table to edit.

=cut

sub select_table_to_edit_ok {
    my $self = shift;
    return $self->_select_table_or_field_to_edit_ok( @_, 'table' );
}

sub _select_table_or_field_to_edit_ok {
    my ( $self, $name, $table_or_field_name, $type_name ) = @_;
    $name //= "Select the '${table_or_field_name}' ${type_name} to edit";
    my $test = context();

    my $edit_el = $self->_find_named_table_or_field_el($table_or_field_name);
    my $success = $self->_check_only_one(
        $edit_el, "${type_name} named '${table_or_field_name}'" );
    $edit_el->click if $success;
    $test->ok( $success, $name );

    $test->release;
    return $self;
}

=head3 select_record_to_view_ok

From the I<< See records >> page, select a named record to view.

=cut

sub select_record_to_view_ok {
    my ( $self, $name, $record_name ) = @_;
    $name //= "Select the '${record_name}' record to view";
    my $test = context();

    my $webdriver = $self->gads->webdriver;
    my $xpath = "//tr[ contains( ., '${record_name}') ]//td[1]//a[1]";
    my $link_el = $webdriver->find( $xpath, method => 'xpath', dies => 0 );
    my $success = $self->_check_only_one(
        $link_el, "record named '${record_name}'" );

    $link_el->click if $success;
    $test->ok( $success, $name );

    $test->release;
    return $self;
}

=head3 submit_add_a_field_form_ok

Submit the I<< Add a field >> form.  Takes a hash reference of arguments
where C<< name >> contains the name of the new field to add, C<< type >>
the name of its type, and C<< group_name >> contains the name of an
existing group to assign all permissions to.

=cut

sub submit_add_a_field_form_ok {
    my ( $self, $name, $args_ref ) = @_;
    $name //= 'Submit the add a field form';
    my %arg = %$args_ref;

    my $test = context();
    my $webdriver = $self->gads->webdriver;

    my $success = $self->_fill_in_field( 'input#name', $arg{name} );
    my $type_el = $webdriver->find(
        # TODO: "contains" isn't the same as "equals"
        "//*[ \@id = 'type' ]/option[ contains( ., '$arg{type}' ) ]",
        method => 'xpath',
    );
    $success &&= $self->_check_only_one(
        $type_el, "type named '$arg{type}'" );
    $type_el->click if $success;

    # Fill in checkboxes to give the specified group all permissions
    my $permissions_tab_el = $webdriver->find('#permissions-tab')->click;
    # Check the Permissions tab heading is shown
    $webdriver->find(
        '//h3[ contains( ., "Permissions" ) ]',
        method => 'xpath',
    );
    # Click "Add permissions" button
    $webdriver->find('#configure-permissions')->click;
    # Select the desired group from the drop-down
    my $group_option_el = $webdriver->find(
        # TODO: "contains" isn't the same as "equals"
        "//select[ \@id = 'select-permission-group' ]/option[ contains( ., '$arg{group_name}' ) ]",
        method => 'xpath',
        dies => 0,
    );
    $success &&= $self->_check_only_one(
        $group_option_el, "group named '$arg{group_name}'" );
    if ($success) {
        $group_option_el->click;
        # Tick all "access rights" checkboxes, then submit the form
        $_->click foreach $webdriver->find('.permission-rule input[name^=permission_]');
        $webdriver->find('#add-permission-rule')->click;
    }

    $test->note("About to add a field named $arg{name}");
    $webdriver->find('#submit_save')->click;

    my $result = $test->ok( $success, $name );
    $test->release;
    return $result;
}

=head3 submit_add_a_table_form_ok

Submit the I<< Add a table >> form.  Takes similar arguments to L<<
/submit_add_a_field_form_ok >> except for a table instead of a field.

=cut

sub submit_add_a_table_form_ok {
    my ( $self, $name, $args_ref ) = @_;
    $name //= 'Submit the add a table form';
    my %arg = %$args_ref;

    my $test = context();

    my $success = $self->_fill_in_field( 'input[name=name]', $arg{name} );

    # Fill in checkboxes to give the specified group all permissions
    my $webdriver = $self->gads->webdriver;
    my $group_row_el = $webdriver->find(
        # TODO: "contains" isn't the same as "equals"
        "//tr/td[1][ contains( ., '$arg{group_name}') ]/..",
        method => 'xpath',
        dies => 0,
    );
    $success &&= $self->_check_only_one(
        $group_row_el, "group named '$arg{group_name}'" );
    if ($success) {
        $_->click foreach $group_row_el->find('input[name=permissions]');
    }

    $test->note("About to add a table named $arg{name}");
    $webdriver->find('[type=submit][name=submit]')->click;

    my $result = $test->ok( $success, $name );
    $test->release;
    return $result;
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

    my $test = context();

    my $gads = $self->gads;
    my $username = $arg{username} // $gads->username;
    my $password = $arg{password} // $gads->password;

    $test->note("About to log in as ${username} with password ${password}");
    my $success = $self->_fill_in_field( '#username', $username );
    $success &&= $self->_fill_in_field( '#password', $password );
    $gads->webdriver->find('[type=submit][name=signin]')->click;

    my $result = $test->ok( $success, $name );
    $test->release;
    return $result;
}

=head3 submit_new_record_form_ok

Submit the I<< New record >> form.  Takes an array reference of values
to input.

=cut

sub submit_new_record_form_ok {
    my ( $self, $name, $args_ref ) = @_;
    $name //= 'Submit the new record form';
    my @arg = @$args_ref;

    my $test = context();

    {
        local $\ = ", ";
        $test->note("About to create a record with values @arg");
    }
    my $success = $self->_fill_in_field(
        $self->_new_record_selector(1), $arg[0] );
    $success &&= $self->_fill_in_field(
        $self->_new_record_selector(2), $arg[1] );
    $self->gads->webdriver->find('[type=submit][name=submit]')->click;

    my $result = $test->ok( $success, $name );
    $test->release;
    return $result;
}

sub _new_record_selector {
    my ( $self, $offset ) = @_;
    return ".edit-form .form-group:nth-child(${offset}) input";
}

sub _check_only_one {
    my ( $self, $element, $element_type_name ) = @_;
    my $test = context();

    my $success = 1;

    my $element_count = $element->size;
    if ( 0 == $element_count ) {
        $success = 0;
        $test->diag("No $element_type_name found");
    }
    elsif ( 1 != $element_count ) {
        $success = 0;
        $test->diag("More than one $element_type_name found");
    }

    $test->release;
    return $success;
}

sub _fill_in_field {
    my ( $self, $selector, $value ) = @_;

    my $result = $self->gads->type_into_field( $selector, $value );
    if ( !defined $result ) {
        my $test = context();
        $test->diag("No '${selector}' element found");
        $test->release;
    }
    return ( defined $result ) ? 1 : 0;
}


sub _find_named_table_or_field_el {
    my ( $self, $name ) = @_;

    my $webdriver = $self->gads->webdriver;
    my $xpath = "//tr[ contains( ., '$name' ) ]//a";
    my $found_el = $webdriver->find( $xpath, method => 'xpath', dies => 0 );

    return $found_el;
}

1;
