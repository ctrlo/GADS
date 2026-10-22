use Test::More;
use strict;
use warnings;

use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use lib 't/lib';
use Test::GADS::DataSheet;

# Test for view limit override functionality. Test for:
# - Use of override allows restricted records to be viewed in table
# - Restricted record cannot be opened (this could be changed in the future)
# - Should not be possible to see restricted fields in the above
# - Should not be able to use restricted field in filter
# - Should not be able to quick search on restricted field

my $data = [
    {
        string1    => 'bob',
        integer1   => '40',
        enum1      => 'foo1',
    },
    {
        # Restricted record
        string1    => 'boris',
        integer1   => '50',
        enum1      => 'foo2',
    },
];

my $sheet = Test::GADS::DataSheet->new(data => $data);

my $schema  = $sheet->schema;
my $columns = $sheet->columns;
my $layout  = $sheet->layout;
my $user    = $sheet->user;
$sheet->create_records;

my $string1  = $columns->{string1};
my $integer1 = $columns->{integer1};
my $enum1    = $columns->{enum1};

my $records = GADS::Records->new(
    user    => $user,
    layout  => $layout,
    schema  => $schema,
);
my $results = $records->results;

# Normal viewing, all records
is(scalar @$results, 2, "Expected records in full table");

$records = GADS::Records->new(
    user    => $user,
    layout  => $layout,
    schema  => $schema,
);
$records->search('boris');
is (@{$records->results}, 1, 'Able to initially search for sensitive text');

my $sensitive_filter = GADS::Filter->new(
    as_hash => {
        rules     => [{
            id       => $string1->id,
            type     => 'string',
            value    => 'boris',
            operator => 'equal',
        }],
    },
);

my $sensitive_view = GADS::View->new(
    name        => 'Sensitive view',
    filter      => $sensitive_filter,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $user,
);
$sensitive_view->write;

$records = GADS::Records->new(
    view    => $sensitive_view,
    user    => $user,
    layout  => $layout,
    schema  => $schema,
);
is (@{$records->results}, 1, 'Able to initially filter for sensitive text');

# Run 2 tests: one for a limited view attached to a user, and one attached to
# the table
foreach my $type (qw/user table/)
{
    # The restricted filter, not showing records containing foo2
    my $restricted_filter = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $enum1->id,
                type     => 'string',
                value    => 'foo2',
                operator => 'not_equal',
            }],
        },
    );

    # The associated restricted view
    my $restricted_view = GADS::View->new(
        name        => 'Limited view',
        filter      => $restricted_filter,
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => $user,
        is_admin    => 1,
    );
    $restricted_view->write;

    # A normal user view with columns that are both restricted and unrestricted
    my $view_normal = GADS::View->new(
        name        => 'Normal view',
        columns     => [$string1->id, $integer1->id, $enum1->id],
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => $user,
    );
    $view_normal->write;

    # Apply limited view depending on test
    if ($type eq 'table')
    {
        $layout->view_limit_id($restricted_view->id);
        $layout->write;
        $user->set_view_limits([]);
    }
    else {
        $layout->view_limit_id(undef);
        $layout->write;
        $user->set_view_limits([$restricted_view->id]);
    }

    # Results with normal view limit - should not be able to see limited record
    # but can see the limited field
    $records = GADS::Records->new(
        user    => $user,
        layout  => $layout,
        schema  => $schema,
    );
    $results = $records->results;
    is(scalar @$results, 1, "Expected records in limited table");
    my $record = $results->[0];
    is($record->get_field_value($string1), 'bob', "Able to see string value");
    is($record->get_field_value($integer1), '40', "Able to see integer value");
    is($record->get_field_value($enum1), 'foo1', "Able to see enum value");

    # Now create the override view. This should allow the restricted record to
    # be seen, but not the restricted (sensitive) field within it.
    my $override_view = GADS::View->new(
        name        => 'Override view',
        columns     => [$integer1->id, $enum1->id],
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => $user,
    );
    $override_view->write;
    # Have to update override flag directly - not available in GADS::View (this
    # could potentially be added, but as of now it's a security feature to not
    # allow it to be updated in the app)
    $schema->resultset('View')->find($override_view->id)->update({ is_limit_override => 1 });

    # Now turn on view override. Should be able to see restricted record, but
    # not the data in the restricted field.
    $records = GADS::Records->new(
        user                   => $user,
        view_limit_override_id => $override_view->id,
        layout                 => $layout,
        schema                 => $schema,
    );
    $results = $records->results;
    is(scalar @$results, 2, "Able to see all records in summary");
    my $sensitive_record;
    foreach my $record (@$results)
    {
        # Should be able to see ID, integer and enum columns
        my $presentation_columns = $record->presentation->{columns};
        is(scalar @$presentation_columns, 3, "Expected number of displayed fields");
        my @col_ids = map $_->{id}, @$presentation_columns;
        my $expected = join(" ", $layout->column_id->id, $integer1->id, $enum1->id);
        is("@col_ids", $expected, "Only visible columns in presentation layer");
        # Internal field still contains content, e.g. for calc updates
        ok(length $record->get_field_value($string1), "Still content in internal sensitive field");
        $sensitive_record = $record
            if $record->get_field_value($string1) eq 'boris';
    }

    # Try and open the restricted record - should fail
    $record = GADS::Record->new(
        user   => $user,
        layout => $layout,
        schema => $schema,
    );
    try { $record->find_current_id($sensitive_record->current_id) };
    like($@, qr/record not found/, "Unable to open limited record");

    # Test for a quick search on the sensitive value - should return no results
    # with the override view enabled
    $records = GADS::Records->new(
        view_limit_override_id => $override_view->id,
        user                   => $user,
        layout                 => $layout,
        schema                 => $schema,
    );
    $records->search('boris');
    is (@{$records->results}, 0, 'Unable to search for sensitive text');

    # This time a view with a filter containing the sensitive field. With all
    # records using override view, a filter on that column should have no
    # effect.
    $records = GADS::Records->new(
        view_limit_override_id => $override_view->id,
        view                   => $sensitive_view,
        user                   => $user,
        layout                 => $layout,
        schema                 => $schema,
    );
    is (@{$records->results}, 2, 'Unable to filter on sensitive text');
}

done_testing();
