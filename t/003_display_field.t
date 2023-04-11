use Test::More; # tests => 1;
use strict;
use warnings;

use GADS::Filter;
use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Tests to check that fields that depend on another field for their display are
# blanked if they should not have been shown

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;

my $sheet   = Test::GADS::DataSheet->new(
    schema             => $schema,
    curval             => 2,
    curval_field_ids   => [$curval_sheet->columns->{string1}->id],
    multivalue         => 1,
    multivalue_columns => { string => 1, tree => 1 },
    column_count       => { integer => 2 },
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

sub _filter
{   my %params = @_;
    my $col_id   = $params{col_id};
    my $regex    = $params{regex};
    my $operator = $params{operator} || 'equal';
    my @rules = ({
        id       => $col_id,
        operator => $operator,
        value    => $regex,
    });
    my $as_hash = {
        condition => undef,
        rules     => \@rules,
    };
    return GADS::Filter->new(
        layout  => $layout,
        as_hash => $as_hash,
    );
}

my $string1  = $columns->{string1};
my $enum1    = $columns->{enum1};
my $integer1 = $columns->{integer1};
$integer1->display_fields(_filter(col_id => $string1->id, regex => 'foobar'));
$integer1->write;
$layout->clear;

my $record = GADS::Record->new(
    user   => $sheet->user,
    layout => $layout,
    schema => $schema,
);

$record->find_current_id(3);

# Initial checks
{
    is($record->fields->{$string1->id}->as_string, 'Foo', 'Initial string value is correct');
    is($record->fields->{$integer1->id}->as_string, '50', 'Initial integer value is correct');
}

my @types = (
    {
        type   => 'equal',
        normal => "foobar",
        blank  => "xxfoobarxx",
    },
    {
        type   => 'contains',
        normal => "xxfoobarxx",
        blank  => "foo",
    },
    {
        type   => 'not_equal',
        normal => "foo",
        blank  => "foobar",
    },
    {
        type   => 'not_contains',
        normal => "foo",
        blank  => "xxfoobarxx",
    },
    {
        type          => 'equal',
        normal        => ['foo', 'bar', 'foobar'],
        string_normal => 'bar, foo, foobar',
        blank         => ["xxfoobarxx", 'abc'],
        string_blank  => 'abc, xxfoobarxx',
    },
    {
        type          => 'contains',
        normal        => ['foo', 'bar', 'xxfoobarxx'],
        string_normal => 'bar, foo, xxfoobarxx',
        blank         => "fo",
    },
    {
        type          => 'not_equal',
        normal        => ['foo', 'foobarx'],
        string_normal => 'foo, foobarx',
        blank         => ['foobar', 'foobar2'],
        string_blank  => 'foobar, foobar2',
    },
    {
        type          => 'not_contains',
        normal        => ['fo'],
        string_normal => 'fo',
        blank         => ['foo', 'bar', 'xxfoobarxx'],
        string_blank  => 'bar, foo, xxfoobarxx',
    },
);

foreach my $test (@types)
{
    $integer1->display_fields(_filter(col_id => $string1->id, regex => 'foobar', operator => $test->{type}));
    $integer1->write;
    $layout->clear;

    # Need to reload record for internal datums to reference column with
    # updated settings
    $record->clear;
    $record->find_current_id(3);

    # Test write of value that should be shown
    {
        $record->fields->{$string1->id}->set_value($test->{normal});
        $record->fields->{$integer1->id}->set_value('150');
        $record->write(no_alerts => 1);

        $record->clear;
        $record->find_current_id(3);

        is($record->fields->{$string1->id}->as_string, $test->{string_normal} || $test->{normal}, "Updated string value is correct (normal $test->{type})");
        is($record->fields->{$integer1->id}->as_string, '150', "Updated integer value is correct (normal $test->{type})");
    }

    # Test write of value that shouldn't be shown (string)
    {
        $record->fields->{$string1->id}->set_value($test->{blank});
        $record->fields->{$integer1->id}->set_value('200');
        $record->write(no_alerts => 1);

        $record->clear;
        $record->find_current_id(3);

        is($record->fields->{$string1->id}->as_string, $test->{string_blank} || $test->{blank}, "Updated string value is correct (blank $test->{type})");
        is($record->fields->{$integer1->id}->as_string, '', "Updated integer value is correct (blank $test->{type})");
    }
}

# Multiple field tests
@types = (
    {
        display_condition => 'AND',
        filters => [
            {
                type  => 'equal',
                field => 'string1',
                regex => 'foobar',
            },
            {
                type  => 'equal',
                field => 'enum1',
                regex => 'foo1',
            },
        ],
        values => [
            {
                normal => {
                    string1 => 'foobar',
                    enum1   => 7,
                },
                blank => {
                    string1 => 'xxfoobarxx',
                    enum1   => 8,
                },
            },
            {
                blank => {
                    string1 => 'foobar',
                    enum1   => 8,
                },
            },
            {
                blank => {
                    string1 => 'xxfoobarxx',
                    enum1   => 7,
                },
            },
        ],
    },
    {
        display_condition => 'OR',
        filters => [
            {
                type  => 'equal',
                field => 'string1',
                regex => 'foobar',
            },
            {
                type  => 'equal',
                field => 'enum1',
                regex => 'foo1',
            },
        ],
        values => [
            {
                normal => {
                    string1 => 'foobar',
                    enum1   => 7,
                },
                blank => {
                    string1 => 'xxfoobarxx',
                    enum1   => 8,
                },
            },
            {
                normal => {
                    string1 => 'foobar',
                    enum1   => 8,
                },
            },
            {
                normal => {
                    string1 => 'xxfoobarxx',
                    enum1   => 7,
                },
            },
        ],
    },
);

foreach my $test (@types)
{
    my @rules = map {
        {
            id       => $columns->{$_->{field}}->id,
            operator => $_->{type},
            value    => $_->{regex},
        }
    } @{$test->{filters}};
    my $as_hash = {
        condition => $test->{display_condition},
        rules     => \@rules,
    };
    my $filter = GADS::Filter->new(
        layout  => $layout,
        as_hash => $as_hash,
    );
    $integer1->display_fields($filter);
    $integer1->write;
    $layout->clear;

    # Need to reload record for internal datums to reference column with
    # updated settings
    $record->clear;
    $record->find_current_id(3);

    foreach my $value (@{$test->{values}})
    {
        # Test write of value that should be shown
        if ($value->{normal})
        {
            $record->fields->{$string1->id}->set_value($value->{normal}->{string1});
            $record->fields->{$enum1->id}->set_value($value->{normal}->{enum1});
            $record->fields->{$integer1->id}->set_value('150');
            $record->write(no_alerts => 1);

            $record->clear;
            $record->find_current_id(3);

            is($record->fields->{$string1->id}->as_string, $value->{normal}->{string1}, "Updated string value is correct");
            is($record->fields->{$integer1->id}->as_string, '150', "Updated integer value is correct");
        }

        # Test write of value that shouldn't be shown (string)
        if ($value->{blank})
        {
            $record->fields->{$string1->id}->set_value($value->{blank}->{string1});
            $record->fields->{$enum1->id}->set_value($value->{blank}->{enum1});
            $record->fields->{$integer1->id}->set_value('200');
            $record->write(no_alerts => 1);

            $record->clear;
            $record->find_current_id(3);

            is($record->fields->{$string1->id}->as_string, $value->{blank}->{string1}, "Updated string value is correct");
            is($record->fields->{$integer1->id}->as_string, '', "Updated integer value is correct");
        }
    }
}

# Reset
$integer1->display_fields(_filter(col_id => $string1->id, regex => 'foobar', operator => 'equal'));
$integer1->write;
$layout->clear;

# Test that mandatory field is not required if not shown by regex
{
    $integer1->optional(0);
    $integer1->write;
    $layout->clear;

    # Start with new record, otherwise existing blank value will not bork
    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record->initialise;
    $record->fields->{$string1->id}->set_value('foobar');
    $record->fields->{$integer1->id}->set_value('');
    try { $record->write(no_alerts => 1) };
    like($@, qr/is not optional/, "Record failed to be written with shown mandatory blank");

    $record->fields->{$string1->id}->set_value('foo');
    $record->fields->{$integer1->id}->set_value('');
    try { $record->write(no_alerts => 1) };
    ok(!$@, "Record successfully written with hidden mandatory blank");

    # Reset
    $integer1->optional(1);
    $integer1->write;
    $layout->clear;
}

# Test each field type
my @fields = (
    {
        field       => 'string1',
        regex       => 'apples',
        value_blank => 'foobar',
        value_match => 'apples',
    },
    {
        field       => 'enum1',
        regex       => 'foo3',
        value_blank => 8,
        value_match => 9,
    },
    {
        field       => 'tree1',
        regex       => 'tree1',
        value_blank => 11,
        value_match => 10,
    },
    {
        field       => 'integer2',
        regex       => '250',
        value_blank => '240',
        value_match => '250',
    },
    {
        field       => 'curval1',
        regex       => 'Bar',
        value_blank => 1, # Foo
        value_match => 2, # Bar
    },
    {
        field       => 'date1',
        regex       => '2010-10-10',
        value_blank => '2011-10-10',
        value_match => '2010-10-10',
    },
    {
        field       => 'daterange1',
        regex       => '2010-12-01 to 2011-12-02',
        value_blank => ['2011-01-01', '2012-01-01'],
        value_match => ['2010-12-01', '2011-12-02'],
    },
    {
        field       => 'person1',
        regex       => 'User1, User1',
        value_blank => 2,
        value_match => 1,
    },
);
foreach my $field (@fields)
{
    my $col = $columns->{$field->{field}};

    $integer1->display_fields(_filter(col_id => $col->id, regex => $field->{regex}));
    $integer1->write;
    $layout->clear;

    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record->initialise;
    $record->fields->{$col->id}->set_value($field->{value_blank});
    $record->fields->{$integer1->id}->set_value(838);
    try { $record->write(no_alerts => 1) };
    my $cid = $record->current_id;
    $record->clear;
    $record->find_current_id($cid);
    is($record->fields->{$integer1->id}->as_string, '', "Value not written for blank regex match (column $field->{field})");

    $record->clear;
    $record->initialise;
    $record->fields->{$col->id}->set_value($field->{value_match});
    $record->fields->{$integer1->id}->set_value(839);
    try { $record->write(no_alerts => 1) };
    $cid = $record->current_id;
    $record->clear;
    $record->find_current_id($cid);
    is($record->fields->{$integer1->id}->as_string, '839', "Value written for regex match (column $field->{field})");
}

# Test blank value match
{
    $integer1->display_fields(_filter(col_id => $string1->id, regex => ''));
    $integer1->write;
    $layout->clear;
    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record->initialise;
    $record->fields->{$string1->id}->set_value('');
    $record->fields->{$integer1->id}->set_value(789);
    $record->write(no_alerts => 1);
    my $cid = $record->current_id;
    $record->clear;
    $record->find_current_id($cid);
    is($record->fields->{$integer1->id}->as_string, '789', "Value written for blank regex match");

    $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record->initialise;
    $record->fields->{$string1->id}->set_value('foo');
    $record->fields->{$integer1->id}->set_value(234);
    $record->write(no_alerts => 1);
    $cid = $record->current_id;
    $record->clear;
    $record->find_current_id($cid);
    is($record->fields->{$integer1->id}->as_string, '', "Value not written for blank regex match");
}

# Test value that depends on tree. Full levels of tree values can be tested
# using the nodes separated by hashes
{
    # Set up columns
    my $tree1 = $columns->{tree1};
    $integer1->display_fields(_filter(col_id => $tree1->id, regex => '(.*#)?tree3'));
    $integer1->write;
    $layout->clear;

    $record->clear;
    $record->find_current_id(3);

    # Set value of tree that should blank int
    $record->fields->{$tree1->id}->set_value(10); # value: tree1
    $record->fields->{$integer1->id}->set_value('250');
    $record->write(no_alerts => 1);

    $record->clear;
    $record->find_current_id(3);

    is($record->fields->{$tree1->id}->as_string, 'tree1', 'Initial tree value is correct');
    is($record->fields->{$integer1->id}->as_string, '', 'Updated integer value is correct');

    # Set matching value of tree - int should be written
    $record->fields->{$tree1->id}->set_value(12);
    $record->fields->{$integer1->id}->set_value('350');
    $record->write(no_alerts => 1);

    $record->clear;
    $record->find_current_id(3);

    is($record->fields->{$tree1->id}->as_string, 'tree3', 'Updated tree value is correct');
    is($record->fields->{$integer1->id}->as_string, '350', 'Updated integer value is correct');

    # Same but multivalue - int should be written
    $record->fields->{$tree1->id}->set_value([10,12]);
    $record->fields->{$integer1->id}->set_value('360');
    $record->write(no_alerts => 1);

    $record->clear;
    $record->find_current_id(3);

    is($record->fields->{$tree1->id}->as_string, 'tree1, tree3', 'Updated tree value is correct');
    is($record->fields->{$integer1->id}->as_string, '360', 'Updated integer value is correct');

    # Now test 2 tree levels
    $integer1->display_fields(_filter(col_id => $tree1->id, regex => 'tree2#tree3'));
    $integer1->write;
    $layout->clear;
    # Set matching value of tree - int should be written
    $record->fields->{$tree1->id}->set_value(12);
    $record->fields->{$integer1->id}->set_value('400');
    $record->write(no_alerts => 1);

    $record->clear;
    $record->find_current_id(3);

    is($record->fields->{$tree1->id}->as_string, 'tree3', 'Tree value is correct');
    is($record->fields->{$integer1->id}->as_string, '400', 'Updated integer value with full tree path is correct');

    # Same but reversed - int should not be written
    $record->fields->{$tree1->id}->set_value(11);
    $record->fields->{$integer1->id}->set_value('500');
    $record->write(no_alerts => 1);

    $record->clear;
    $record->find_current_id(3);

    is($record->fields->{$tree1->id}->as_string, 'tree2', 'Tree value is correct');
    is($record->fields->{$integer1->id}->as_string, '', 'Updated integer value with full tree path is correct');

    # Same, but test higher level of full tree path
    $integer1->display_fields(_filter(col_id => $tree1->id, regex => 'tree2#', operator => 'contains'));
    $integer1->write;
    $layout->clear;
    $record->clear;
    $record->find_current_id(3);
    # Set matching value of tree - int should be written
    $record->fields->{$tree1->id}->set_value(12);
    $record->fields->{$integer1->id}->set_value('600');
    $record->write(no_alerts => 1);

    $record->clear;
    $record->find_current_id(3);

    is($record->fields->{$tree1->id}->as_string, 'tree3', 'Tree value is correct');
    is($record->fields->{$integer1->id}->as_string, '600', 'Updated integer value with full tree path is correct');
}

# Test for fields that are not visible to the user. In this case, even if the
# field depended-on has a value, the field should be assumed blank (this is
# how the HTML form works - behaviour needs to be consistent)
{
    # Before changing permissions, set up required value in record
    $record->clear;
    $record->find_current_id(3);
    $record->fields->{$string1->id}->set_value('Foobar');
    $record->write(no_alerts => 1);

    # Set up columns
    $integer1->display_fields(_filter(col_id => $string1->id, regex => 'Foobar'));
    $integer1->write;

    # Drop permissions from string1
    $string1->set_permissions({$sheet->group->id => []});
    $string1->write;
    $layout->clear;

    $record->clear;
    $record->find_current_id(3);
    # Even though regex matches, values should be blanked as it's not visible to user
    $record->fields->{$integer1->id}->set_value('250');
    $record->write(no_alerts => 1);

    $record->clear;
    $record->find_current_id(3);

    is($record->fields->{$integer1->id}->as_string, '', 'Field depending on non-visible field is correct');

    # Reverse test

    # Update filter
    $integer1->display_fields(_filter(col_id => $string1->id, regex => 'Foobar', operator => 'not_equal'));
    $integer1->write;

    $record->clear;
    $record->find_current_id(3);
    # Even though display condition does not show field, value should still be written
    $record->fields->{$integer1->id}->set_value('250');
    $record->write(no_alerts => 1);

    $record->clear;
    $record->find_current_id(3);

    is($record->fields->{$integer1->id}->as_string, '250', 'Field depending on non-visible field - reverse');

    # Now test that no write access to either field does not alter values. To
    # do this we will set up the fields so that integer1 will not show based on
    # the current value of string1. Both values should be retained as the user
    # does not have access to either.
    # Drop permissions from integer1 and update display condition.
    $integer1->display_fields(_filter(col_id => $string1->id, regex => 'ABC')); # integer1 not shown
    $integer1->set_permissions({$sheet->group->id => []});
    $integer1->write;
    $layout->clear;
    $record->clear;
    $record->find_current_id(3);
    # Modify unrelated field that the user does have access to
    my $date1 = $columns->{date1};
    $record->fields->{$date1->id}->set_value('2018-06-01');
    $record->write(no_alerts => 1);
    $record->clear;
    $record->find_current_id(3);
    # Integer1 and string1 should be unchanged
    is($record->fields->{$string1->id}->as_string, 'Foobar', "String1 unchanged with no write access");
    is($record->fields->{$integer1->id}->as_string, '250', "Integer1 unchanged with no write access");
    is($record->fields->{$date1->id}->as_string, '2018-06-01', "Date1 as entered");

    # Reset permissions for other tests
    $string1->set_permissions({$sheet->group->id => $sheet->default_permissions});
    $string1->write;
    $integer1->set_permissions({$sheet->group->id => $sheet->default_permissions});
    $integer1->write;
    $layout->clear;
}

# Tests for dependent_not_shown
{
    $integer1->display_fields(_filter(col_id => $string1->id, regex => 'Foobar'));
    $integer1->write;
    $layout->clear;

    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record->initialise;
    $record->fields->{$string1->id}->set_value('Foobar');
    $record->fields->{$integer1->id}->set_value('100');
    $record->write(no_alerts => 1);

    my $current_id = $record->current_id;
    $record->clear;
    $record->find_current_id($current_id);
    ok(!$record->fields->{$string1->id}->dependent_not_shown, "String shown in view");
    ok(!$record->fields->{$integer1->id}->dependent_not_shown, "Integer shown in view");

    $record->fields->{$string1->id}->set_value('Foo');
    $record->fields->{$integer1->id}->set_value('200');
    $record->write(no_alerts => 1);
    ok(!$record->fields->{$string1->id}->dependent_not_shown, "String still shown in view");
    ok($record->fields->{$integer1->id}->dependent_not_shown, "Integer not shown in view");

    $record->fields->{$string1->id}->set_value('Foobarbar');
    $record->fields->{$integer1->id}->set_value('200');
    $record->write(no_alerts => 1);
    ok(!$record->fields->{$string1->id}->dependent_not_shown, "String still shown in view");
    ok($record->fields->{$integer1->id}->dependent_not_shown, "Integer not shown in view");

    # Although dependent_not_shown is not used in table view, it is still
    # generated as part of the presentation layer
    my $records = GADS::Records->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
        columns => [$integer1->id],
    );
    while (my $rec = $records->single)
    {
        # Will always be shown as the column it depends on is not in the view
        ok(!$rec->fields->{$integer1->id}->dependent_not_shown, "Integer not shown in view");
    }

    # Reset
    $integer1->display_fields(undef);
    $integer1->write;
    $layout->clear;
}

# Tests for dependent_not_shown within curval record, with mixed permissions
{
    # Curval on main table
    my $curval1 = $columns->{curval1};

    # Make this editable
    $curval1->show_add(1);
    $curval1->write(no_alerts => 1);
    $curval_sheet->layout->clear;

    # Add a curval to the curval field back to the main table
    my $cc = GADS::Column::Curval->new(
        schema => $schema,
        user   => $sheet->user,
        layout => $curval_sheet->layout,
    );
    $cc->refers_to_instance_id(1);
    $cc->curval_field_ids([$columns->{string1}->id]);
    $cc->type('curval');
    $cc->name('Curval back to main table');
    $cc->name_short('L2curval1');
    $cc->set_permissions({$sheet->group->id => $sheet->default_permissions});
    $cc->write;
    $layout->clear;

    my $curval_integer1 = $curval_sheet->columns->{integer1};
    my $curval_string1 = $curval_sheet->columns->{string1};
    # Add display condition to curval in master table curval field
    $cc->display_fields(_filter(col_id => $curval_string1->id, regex => 'Apple', operator => 'contains'));
    $cc->write;
    $layout->clear;

    # Create new record on master table
    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record->initialise;
    $record->fields->{$string1->id}->set_value('Master');
    $record->fields->{$curval1->id}->set_value([$curval_string1->field."=Apple&".$curval_integer1->field."=100&".$cc->field."=4"]);
    $record->write(no_alerts => 1);

    # Write master record
    my $current_id = $record->current_id;
    $record->clear;
    $record->find_current_id($current_id);

    # Check values in curval record
    my $curval_current_id = $record->fields->{$curval1->id}->ids->[0];
    $record->clear;
    $record->find_current_id($curval_current_id);
    is($record->fields->{$curval_string1->id}->as_string, "Apple", "String shown in view");
    is($record->fields->{$curval_integer1->id}->as_string, "100", "Integer shown in view");
    is($record->fields->{$cc->id}->as_string, "Bar", "Integer shown in view"); # Back to value in master table

    # Now that record is written, remove write_new permissions
    $cc->set_permissions({$sheet->group->id => [qw/read write_existing write_existing_no_approval/]});
    $cc->write;
    $layout->clear;

    # Make update to master record, updating curval at same time
    $record->clear;
    $record->find_current_id($current_id);
    $record->fields->{$string1->id}->set_value('Master2');
    $record->fields->{$curval1->id}->set_value([$curval_string1->field."=Apples&".$curval_integer1->field."=200&".$cc->field."=3&current_id=".$curval_current_id]);
    $record->write(no_alerts => 1);

    # Check values
    $record->clear;
    $record->find_current_id($curval_current_id);
    is($record->fields->{$curval_string1->id}->as_string, "Apples", "Integer shown in view");
    # Value is back to master table, record on master table has been updated in previous test
    is($record->fields->{$cc->id}->as_string, "Foobar", "Integer shown in view2");

    # Reset
    $curval_integer1->display_fields(undef);
    $curval_integer1->write;
    $layout->clear;
}

# Tests to ensure that a value that was previously blank does not need to
# be completed, but only if it was displayed when the record is opened for
# edit
{
    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record->initialise;

    # Set only the string to have a value. Integer not mandatory
    $record->fields->{$string1->id}->set_value('Foo1');
    $record->write(no_alerts => 1);
    my $current_id = $record->current_id;

    # Set integer to be mandatory
    $integer1->optional(0);
    $integer1->write;
    $layout->clear;

    # Edit should be written as integer was displayed and blank already
    $record->clear;
    $record->find_current_id($current_id);
    $record->fields->{$string1->id}->set_value('Foo2');
    $record->fields->{$integer1->id}->set_value('');
    try { $record->write(no_alerts => 1) };
    my ($warning) = grep $_->reason eq 'MISTAKE', $@->exceptions;
    like($warning, qr/no longer optional/, "Record written successfully with mandatory field empty, only warning");

    # Set integer to be display-conditional
    $integer1->display_fields(_filter(col_id => $string1->id, regex => 'Foobar'));
    $integer1->write;
    $layout->clear;

    # Not shown should write as normal
    $record->clear;
    $record->find_current_id($current_id);
    $record->fields->{$string1->id}->set_value('Foo3');
    try { $record->write(no_alerts => 1) };
    ok(!$@, "Record written successfully with mandatory field not shown");

    # Now shown dependent on value, should not write empty
    $record->clear;
    $record->find_current_id($current_id);
    $record->fields->{$string1->id}->set_value('Foobar');
    $record->fields->{$integer1->id}->set_value('');
    try { $record->write(no_alerts => 1) };
    like($@, qr/is not optional/, "Record not written with mandatory field now shown");
}

# Tests for recursive display fields
{
    my $date1 = $columns->{date1};
    my @rules = (
        {
            id       => $string1->id,
            operator => 'equal',
            value    => 'Foobar',
        },
        {
            id       => $date1->id,
            operator => 'equal',
            value    => '2013-02-02',
        },
    );
    my $as_hash = {
        condition => 'OR',
        rules     => \@rules,
    };
    my $filter = GADS::Filter->new(
        layout  => $layout,
        as_hash => $as_hash,
    );
    $string1->display_fields($filter);
    $string1->write;
    $layout->clear;

    # Write initial record
    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record->initialise;
    $record->fields->{$string1->id}->set_value('Foobar');
    $record->fields->{$date1->id}->set_value('2013-02-02');
    $record->fields->{$integer1->id}->set_value('1234'); # Mandatory field
    $record->write(no_alerts => 1);
    my $cid = $record->current_id;

    # Check written values
    $record->clear;
    $record->find_current_id($cid);
    is($record->fields->{$string1->id}->as_string, "Foobar", "String correct initially");

    # Now remove first condition of date
    $record->fields->{$date1->id}->set_value('2013-02-01');
    $record->write(no_alerts => 1);
    $record->clear;
    $record->find_current_id($cid);
    is($record->fields->{$string1->id}->as_string, "Foobar", "String correct after removing first condition");

    # Now remove first condition of string
    $record->fields->{$string1->id}->set_value('Foobar2');
    $record->write(no_alerts => 1);
    $record->clear;
    $record->find_current_id($cid);
    is($record->fields->{$string1->id}->as_string, "", "String blank after removing second condition");
}

# Finally check that columns with display fields can be deleted
{
    try { $string1->delete };
    like($@, qr/remove these conditions before deletion/, "Correct error when deleting depended field");
    try { $integer1->delete };
    ok(!$@, "Correctly deleted independent display field");
}

done_testing();
