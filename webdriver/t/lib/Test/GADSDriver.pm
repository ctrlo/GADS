package Test::GADSDriver;

use v5.24.0;
use Moo;

use GADSDriver ();
use List::MoreUtils 'zip';
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
        '.alert-danger',
        $expect_present,
        qr/\bERROR: /,
        $name,
    );

    my $error_text = $error_el->text;
    if ($error_text) {
        my $diagnostic_text = "The error message is '${error_text}'";
        if ($expect_present) {
            $test->note($diagnostic_text);
        }
        else {
            $test->diag($diagnostic_text);
        }
    }

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
    if ($success_text) {
        my $diagnostic_text = "The success message is '${success_text}'";
        if ($expect_present) {
            $test->note($diagnostic_text);
        }
        else {
            $test->diag($diagnostic_text);
        }
    }

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

    my $table_el = $self->_find_named_item_row_el($table_name);

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
        'nav .nav',
        1,
        qr/\bHome\b/,
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
        $name,
        'body.layout\\/0',
        # TODO: Check the table name appears in the h2 text
        { selector => 'h2', match => '\\AAdd a field to ' },
        { selector => '#basic-panel h3', text => 'Field properties' },
    );

    $test->release;
    return $self;
}

=head3 assert_on_add_a_group_page

The I<< Add a group >> page is visible.

=cut

sub assert_on_add_a_group_page {
    my ( $self, $name ) = @_;
    $name //= 'The add a group page is visible';
    my $test = context();

    $self->_assert_on_page(
        $name,
        'body.group\\/0',
        { selector => 'h2', text => 'Add a group' },
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
        $name,
        'body.table\\/0',
        { selector => 'h2', text => 'Add a table' },
    );

    $test->release;
    return $self;
}
=head3 assert_on_add_a_view_page

The I<< Add a view >> page is visisble.

=cut

sub assert_on_add_a_view_page {
    my ( $self, $name ) = @_;
    $name //= 'The add a view page is visible';
    my $test = context();

    $self->_assert_on_page(
        $name,
        'body.view\\/0',
        { selector => 'h2', text => 'Add a customised view' },
    );

    $test->release;
    return $self;
}

=head3 assert_on_edit_field_page

The I<< Edit field >> page is visible

=cut

sub assert_on_edit_field_page {
    my ( $self, $name ) = @_;
    $name //= 'The edit field page is visible';
    my $test = context();

    $self->_assert_on_page(
        $name,
        'body.layout',
        '#basic-panel',
        { selector => 'h2', match => '\\AEdit field\\s*' },
    );

    $test->release;
    return $self;
}

=head3 assert_on_edit_user_page

The user editing page is visible

=cut

sub assert_on_edit_user_page {
    my ( $self, $name ) = @_;
    $name //= 'The edit user page is visible';
    my $test = context();

    $self->_assert_on_page(
        $name,
        'body.user',
        # TODO Check the user's name appears in the heading text
        { selector => 'h1', match => '\\AEdit: ' },
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
    my $test = context();

    $self->_assert_element(
        '.login__title',
        1,
        qr/\A(?i)Please Sign In\b/,
        $name,
    );

    $test->release;
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
        $name,
        'body.layout',
        # TODO: Check the table name appears in the h2 text
        { selector => 'h2.list-fields', match => '\\AManage fields in ' },
    );

    $test->release;
    return $self;
}

=head3 assert_on_manage_groups_page

The I<< Groups >> page is visible.

=cut

sub assert_on_manage_groups_page {
    my ( $self, $name ) = @_;
    $name //= 'The manage groups page is visible';
    my $test = context();

    $self->_assert_on_page(
        $name,
        'body.group',
        { selector => 'h2', text => 'Groups' },
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
        $name,
        'body.table',
        { selector => 'h2', text => 'Manage tables' },
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
        $name,
        'body.this_table',
        { selector => 'h2', text => 'Manage this table' },
    );

    $test->release;
    return $self;
}

=head3 assert_on_manage_users_page

The I<< Manage users >> page is visible.

=cut

sub assert_on_manage_users_page {
    my ( $self, $name ) = @_;
    $name //= 'The manage users page is visible';
    my $test = context();

    $self->_assert_on_page(
        $name,
        'body.user',
        { selector => 'h1', match => '\AManage users\s*\z' },
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
        $name,
        'body.edit',
        { selector => 'h2', text => 'New record' },
    );

    $test->release;
    return $self;
}

=head3 assert_on_see_records_page

The I<< See records >> page is visible.  Takes two optional arguments,
the test name and an expected page title.

=cut

sub assert_on_see_records_page {
    my ( $self, $name, $page_title ) = @_;
    $name //= 'The see records page is visible';
    $page_title //= 'All data';     # Default title for no view
    my $title = quotemeta $page_title;
    my $test = context();

    $self->_assert_on_page(
        $name,
        'body.page.data_table',
        { selector => 'h1', match => "\\A${title}\\s*\\z" },
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
        $name,
        # TODO: Check the field values appear in the page content
        'body.page.edit',
        { selector => 'h2', match => '\\ARecord ID ' },
    );

    $test->release;
    return $self;
}

=head3 assert_record_has_fields

On the I<< View record >> page, check that a record with the specified
fields and values is shown.

=cut

sub assert_record_has_fields {
    my ( $self, $name, $expected_fields_ref ) = @_;
    $name //= 'A record with the specified fields is visible';
    my $test = context();

    my $table_el = $self->gads->webdriver->find( '#topic_show table', dies => 0 );
    my $success = $self->_check_only_one( $table_el, 'table of fields' );

    my %field_found;
    foreach my $row_el ( $table_el->find('tr')->split ) {
        my $field_el = $row_el->find('th');
        $success &&= $self->_check_only_one( $field_el, 'field name' );
        my $value_el = $row_el->find('td');
        $success &&= $self->_check_only_one( $value_el, 'field value' );

        $field_found{ $field_el->text } = $value_el->text;
    }

    if ($success) {
        is( \%field_found, $expected_fields_ref, $name );
    }
    else {
        $test->ok( 0, $name );
    }

    $test->release;
    return $self;
}

=head3 assert_records_shown

On the I<< See Records >> page, check which records are shown.  Any
unexpected records, duplicate records, or records displayed in an
unexpected order cause this to fail.

=cut

sub assert_records_shown {
    my ( $self, $name, $expected_records_ref ) = @_;
    $name //= 'The see records page shows the expected records';
    my $test = context();
    my $webdriver = $self->gads->webdriver;

    # TODO: Replace this and %wanted_fields further down with
    # Test2::Tools::Compare::set().
    my %wanted_heading = map { $_ => undef }
        map { keys %$_ } @$expected_records_ref;
    my @wanted_heading = keys %wanted_heading;

    my $table_el = $webdriver->find( '#data-table', dies => 0 );
    my $success = $self->_check_only_one( $table_el, 'data table' );

    my $headings_el = $table_el->find( 'thead th', dies => 0 );
    my @heading = map
        { $_->attr('data-thlabel') // $_->attr('aria-label') }
        $headings_el->split;

    my @found_record;
    my $records_el = $table_el->find( 'tbody tr', dies => 0 );
    foreach my $record_el ( $records_el->split ) {
        my @value = map $_->text, $record_el->find( 'td', dies => 0 )->split;
        my %record = zip @heading, @value;
        my %wanted_fields = map { $_ => $record{$_} } @wanted_heading;
        push @found_record, \%wanted_fields;
    }

    if ( $success ) {
        is( \@found_record, $expected_records_ref, $name );
    }
    else {
        $test->ok( 0, $name );
    }

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

# Note: the first expression should always be a page ID, not a complex
# hashref selector, as these don't check the full condition in a find()
# call but instead use _check_element_against_expectation().
sub _assert_on_page {
    my ( $self, $name, @expectation ) = @_;
    my $test = context();
    my $webdriver = $self->gads->webdriver;

    my @failure;
    foreach my $expect (@expectation) {
        # Expectations can contain a string or a hashref of arguments
        my $selector = ref($expect) ? $expect->{selector} : $expect;

        # TODO: Move 'tries' to configuration
        my $matching_el = $webdriver->find( $selector, dies => 0, tries => 50 );

        if ( 0 == $matching_el->size ) {
            push @failure, "No elements matching '${selector}' found";
        }
        elsif ( ref $expect ) {
            push @failure, $self->_check_element_against_expectation(
                $matching_el, $expect );
        }
    }
    $test->ok( !@failure, $name );
    $test->diag($_) foreach @failure;

    $test->release;
    return $self;
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

=head3 assign_current_user_to_group_ok

Assign the currently logged in user to a specified group.

=cut

sub assign_current_user_to_group_ok {
    my ( $self, $name, $group_name ) = @_;
    my $test = context();
    my $webdriver = $self->gads->webdriver;

    my $query = "//label[ contains(., '${group_name}') ]/input[
            \@type = 'checkbox'
            and \@name = 'groups'
        ]";
    my $checkbox_el = $webdriver->find( $query,
        method => 'xpath', dies => 0, tries => 40 );

    my $description = "checkbox for group '${group_name}'";
    my $success = $self->_check_only_one( $checkbox_el, $description );
    if ( $checkbox_el->selected ) {
        $success = 0;
        $test->diag("The ${description} is unexpectedly selected");
    }
    $checkbox_el->click;

    my $group_id = $checkbox_el->attr('value');
    $webdriver->find( "input[name='groups'][value='${group_id}']:checked" );
    $success &&= $self->_click_submit_button;

    $test->ok( $success, $name );

    $test->release;
    return $self;
}

=head3 confirm_deletion_ok

Delete the current table from the I<< Manage this table >> page.

Commonly used to delete a field or table.

=cut

sub confirm_deletion_ok {
    my ( $self, $name ) = @_;
    $name //= 'Approve the "Confirm deletion" modal';
    my $test = context();
    my $webdriver = $self->gads->webdriver;

    my $entity_name = $webdriver->find(
        'input[name="name"]',
        tries => 50,
    )->attr('value');

    my $delete_button_el = $webdriver->find(
        # TODO: Use a better selector
        'form a[data-target="#myModal"]',
        dies => 0,
    );

    # Disable Bootstrap transitions to avoid timing issues.  Trying to
    # click on an element whilst it animates fails with an "Element ...
    # could not be scrolled into view" error.
    $webdriver->js( '$.support.transition = false' );

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

=head3 delete_current_view_ok

Delete the currently displayed view

=cut

# Very similar to delete_viewed_record_ok()
sub delete_current_view_ok {
    my ( $self, $name ) = @_;
    $name //= 'Delete the currently displayed view';
    my $test = context();
    my $webdriver = $self->gads->webdriver;

    my $view_name = $webdriver->find('input#name')->attr('value');

    # Disable Bootstrap transitions to avoid timing issues.  Trying to
    # click on an element whilst it animates fails with an "Element ...
    # could not be scrolled into view" error.
    $webdriver->js( '$.support.transition = false' );

    my @failure = $self->_find_and_click( [ 'a[data-target="#myModal"]' ] );

    $test->note("About to delete view ${view_name}");
    $webdriver->find('#myModal .modal-dialog .btn-primary')->click;

    $test->ok( !@failure, $name );
    $test->diag($_) foreach @failure;

    $test->release;
    return $self
}

=head3 delete_viewed_record_ok

Delete the currently viewed record

=cut

# Very similar to delete_current_view_ok()
sub delete_viewed_record_ok {
    my ( $self, $name ) = @_;
    $name //= 'Delete the currently viewed record';
    my $test = context();
    my $webdriver = $self->gads->webdriver;
    my $record_title = $webdriver->find('h2')->text;

    # Disable Bootstrap transitions to avoid timing issues.  Trying to
    # click on an element whilst it animates fails with an "Element ...
    # could not be scrolled into view" error.
    $webdriver->js( '$.support.transition = false' );

    my @failure = $self->_find_and_click( [ '.btn-delete' ], jquery => 1 );

    $test->note("About to delete $record_title");
    $webdriver->find('#modaldelete .btn-primary.submit_button')->click;

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
    my ( $self, $selectors_ref, %arg ) = @_;
    my $webdriver = $self->gads->webdriver;

    my @failure;
    foreach my $selector (@$selectors_ref) {
        # TODO: Move 'tries' to configuration
        my $found_el = $webdriver->find( $selector, dies => 0, tries => 25 );
        if ( 0 == $found_el->size ) {
            push @failure, "No elements matching '${selector}' found";
        }
        elsif ( !$found_el->visible ) {
            push @failure, "No visible elements matching '${selector}' found";
        }
        else {
            # TODO: Avoid using a special approach for when jQuery and
            # WebDriver handle clicks differently
            if ( exists $arg{jquery} and $arg{jquery} ) {
                $webdriver->js( qq[ \$("${selector}").click() ]);
            }
            else {
                $found_el->click;
            }
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

    # Disable Bootstrap transitions to avoid timing issues.  Trying to
    # click on an element whilst it animates fails with an "Element ...
    # could not be scrolled into view" error.
    $webdriver->js( '$.support.transition = false' );

    push @failure, $self->_find_and_click([
        '#selectall',
        'button[data-target="#purge"]',
    ]);
    $webdriver->find('button[type="submit"][name="purge"]')->click;

    $test->ok( !@failure, $name );
    $test->diag($_) foreach @failure;
    $test->release;

    return $self;
}

=head3 select_current_user_to_edit_ok

From the I<< Manage users >> page, select the currently logged in user.

=cut

sub select_current_user_to_edit_ok {
    my ( $self, $name ) = @_;
    my $test = context();

    my $result = $self->_select_item_row_to_edit_ok(
        $name, $self->gads->username, 'user' );

    $test->release;
    return $result;
}

=head3 select_field_to_edit_ok

From the I<< Manage fields >> page, select a named field to edit.

=cut

sub select_field_to_edit_ok {
    my $self = shift;
    my $test = context();

    my $result = $self->_select_item_row_to_edit_ok( @_, 'field' );

    $test->release;
    return $result;
}

=head3 select_group_to_edit_ok

From the I<< Groups >> page, select a named group to edit.

=cut

sub select_group_to_edit_ok {
    my $self = shift;
    my $test = context();

    my $result = $self->_select_item_row_to_edit_ok( @_, 'group' );

    $test->release;
    return $result;
}

=head3 select_table_to_edit_ok

From the I<< Manage tables >> page, select a named table to edit.

=cut

sub select_table_to_edit_ok {
    my $self = shift;
    my $test = context();

    my $result = $self->_select_item_row_to_edit_ok( @_, 'table' );

    $test->release;
    return $result;
}

sub _select_item_row_to_edit_ok {
    my ( $self, $name, $item_row_name, $type_name ) = @_;
    $name //= "Select the '${item_row_name}' ${type_name} to edit";
    my $test = context();

    my $edit_el = $self->_find_named_item_row_el($item_row_name);
    my $success = $self->_check_only_one(
        $edit_el, "${type_name} named '${item_row_name}'" );
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
        "//*[ \@id = 'type' ]/option[ text() = '$arg{type}' ]",
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

=head3 submit_add_a_group_form_ok

Submit the I<< Add a group >> form.

=cut

sub submit_add_a_group_form_ok {
    my ( $self, $name, $group_name ) = @_;
    $name //= 'Submit the add a group form';

    my $test = context();
    my $success = $self->_fill_in_field( 'input[name=name]', $group_name );

    $test->note("About to add a group named ${group_name}");
    $success &&= $self->_click_submit_button;

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
    $success &&= $self->_click_submit_button;

    my $result = $test->ok( $success, $name );
    $test->release;
    return $result;
}

=head3 submit_add_a_view_form_ok

Submit the I<< Add a view >> form.  Takes a hash reference of arguments
where C<< name >> contains the name of the new field to add, C<< fields
>> contains an array reference of human readable field names to show,
and C<< filters >> contains a hash reference of filters, including an
array reference of rules keyed on C<< rules >>.

=cut

# Does not (yet) handle the "Add group" filter option, sorting or
# grouping.
sub submit_add_a_view_form_ok {
    my ( $self, %arg ) = @_;
    $arg{name} //= 'Submit the add a view form';

    my $test = context();

    # Name the view
    my $success = $self->_fill_in_field( 'input#name', $arg{name} );

    # Select fields to include
    my $webdriver = $self->gads->webdriver;
    foreach my $field_label ( @{ $arg{fields} // [] } ) {
        my $checkbox_el = $webdriver->find(
            qq|//input[ \@class="col_check" and contains( .., "${field_label}" )]|,
            method => 'xpath',
            dies => 0,
        );
        $success &&= $self->_check_only_one( $checkbox_el, "checkbox titled $field_label" );
        $checkbox_el->click;
    }

    my $filters_el = $webdriver->find('#builder');
    my $filter_rule_el = $filters_el->find('.rules-list .rule-container');
    my $add_rule_el = $filters_el->find('.rules-group-header button[data-add="rule"]');

    # HACK: Prevent the .navbar-fixed-bottom from obscuring the filter
    # specification fields.
    my $scroll_to_el = $filter_rule_el // $add_rule_el;
    if (defined $scroll_to_el) {
        $self->gads->webdriver->js(
            'arguments[0].scrollIntoView(true)',
            $scroll_to_el,
        );
    }

    # Specify fields to show in the view
    $success &&= $self->_check_only_one( $filters_el, "#builder filter element" );
    {
        my $condition_label = $arg{filters}{condition};
        my $condition_el = $filters_el->find(
            "input[type=radio][value='${condition_label}']",
            dies => 0,
        );
        $success &&= $self->_check_only_one( $condition_el, "condition titled $condition_label" );
        $condition_el->click;
    }

    $success &&= $self->_check_only_one( $filter_rule_el, "filter rule" );
    $success &&= $self->_check_only_one( $add_rule_el, "Add rule" );

    # Specify filters for the view
    my $add_a_rule = 0;
    foreach my $rule ( @{ $arg{filters}{rules} } ) {
        if ($add_a_rule) {
            $add_rule_el->click;
            $filter_rule_el = $filter_rule_el->find(
                './following-sibling::li',
                method => 'xpath',
            );
        }
        $success &&= $self->_specify_filter( $filter_rule_el, $rule );
        $add_a_rule = 1;
    }

    $test->note("About to add a view named $arg{name}");
    $webdriver->find('#saveview')->click;

    my $result = $test->ok( $success, "Add a view named $arg{name}" );
    $test->release;
    return $result;
}

sub _specify_filter {
    my ( $self, $filter_rule_el, $rules_ref ) = @_;
    my %rule = %$rules_ref;
    my $success = 1;

    my @option_field = (
        {
            type => 'filter',
            value => $rule{field},
        },
        {
            type => 'operator',
            value => $rule{operator},
        },
    );
    foreach my $option_ref (@option_field) {
        my %option = %$option_ref;

        my $selector =
            qq|.//*[\@class = "rule-$option{type}-container"]//option[ text() = "$option{value}" ]|;
        my $field_el = $filter_rule_el->find( $selector, method => 'xpath' );
        $success &&= $self->_check_only_one( $field_el, "$option{type} filter" );
        $field_el->click;
    }

    my $value_el = $filter_rule_el->find(
        './/*[ @class = "rule-value-container" ]//input[ @type = "text" ]',
        method => 'xpath',
    );
    $success &&= $self->_check_only_one( $value_el, "text value container" );
    $value_el->send_keys( $rule{value} );

    return $success;
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
    $success &&= $self->_click_submit_button( name_attr => 'signin' );

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
    $success &&= $self->_click_submit_button( value_attr => 'submit' );

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

sub _find_named_item_row_el {
    my ( $self, $name ) = @_;

    my $webdriver = $self->gads->webdriver;
    my $xpath = "//tr[ contains( ., '$name' ) ]//a";
    my $found_el = $webdriver->find( $xpath,
        method => 'xpath', dies => 0, tries => 10 );

    return $found_el;
}

sub _click_submit_button {
    my ( $self, %arg ) = @_;
    $arg{name_attr} //= 'submit';
    my $webdriver = $self->gads->webdriver;

    my $selector = "[type='submit'][name='$arg{name_attr}']";
    if ( exists $arg{value_attr} ) {
        $selector .= "[value='$arg{value_attr}']";
    }
    my $submit_el = $webdriver->find( $selector, dies => 0 );

    my $success = $self->_check_only_one(
        $submit_el, "$arg{name_attr} button" );

    $submit_el->click;
    return $success;
}

1;
