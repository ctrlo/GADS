use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use t::lib::DataSheet;

sub _records
{   my ($schema, $layout, $count) = @_;
    my $records = GADS::Records->new(
        user    => undef,
        layout  => $layout,
        schema  => $schema,
    );
    my @results = @{$records->results};
    is( scalar @results, $count, "Check number of records in retrieved dataset");
    @results;
}

my $sheet   = t::lib::DataSheet->new(multivalue => 1);
my $schema  = $sheet->schema;
my $columns = $sheet->columns;
my $layout  = $sheet->layout;
ok(!$layout->has_children, "Layout does not have children initially");
$sheet->create_records;

my ($parent) = _records($schema, $layout, 2);

# Create child
my $child = GADS::Record->new(
    user     => undef,
    layout   => $layout,
    schema   => $schema,
);
$child->parent_id($parent->current_id);
$child->initialise;
# First try writing without selecting any unique values. Should bork.
try { $child->write };
ok( $@, "Failed to write child record with no unique columns defined" );
# Only set unique daterange. Should affect daterange field and dependent calc
my $daterange1 = $columns->{daterange1};
$daterange1->set_can_child(1);
$daterange1->write;
$layout->clear;
ok($layout->has_children, "Layout has children after creating child column");
my $daterange1_id = $daterange1->id;
$child->fields->{$daterange1_id}->set_value(['2011-10-10','2015-10-10']);
$child->write(no_alerts => 1);

# Force refetch of everything from database
my $other;
($parent, $other, $child) = _records($schema, $layout, 3);
isnt( $parent->fields->{$daterange1_id}->as_string, $child->fields->{$daterange1_id}->as_string, "Parent and child date ranges are different");
my $calc1_id = $columns->{calc1}->id;
isnt( $parent->fields->{$calc1_id}->as_string, $child->fields->{$calc1_id}->as_string, "Parent and child calc values are different");
is( $parent->fields->{$calc1_id}->as_string, 2012, "Parent calc value is correct after first write");
is( $child->fields->{$calc1_id}->as_string, 2011, "Child calc value is correct after first write");
my $string1 = $columns->{string1};
my $string1_id = $string1->id;
is( $parent->fields->{$string1_id}->as_string, $child->fields->{$string1_id}->as_string, "Parent and child strings are the same");
my $enum1_id = $columns->{enum1}->id;
is( $parent->fields->{$enum1_id}->as_string, $child->fields->{$enum1_id}->as_string, "Parent and child enums are the same");
my $tree1_id = $columns->{tree1}->id;
is( $parent->fields->{$tree1_id}->as_string, $child->fields->{$tree1_id}->as_string, "Parent and child trees are the same");
my $date1_id = $columns->{date1}->id;
is( $parent->fields->{$date1_id}->as_string, $child->fields->{$date1_id}->as_string, "Parent and child dates are the same");
my $rag1_id = $columns->{rag1}->id;
isnt( $parent->fields->{$rag1_id}->as_string, $child->fields->{$rag1_id}->as_string, "Parent and child rags are different");

# Now update parent daterange and strings and check relevant changes in child
$parent->fields->{$daterange1_id}->set_value(['2000-01-01', '2000-02-02']);
$parent->fields->{$string1_id}->set_value('foo2');
$parent->fields->{$enum1_id}->set_value('2');
$parent->fields->{$tree1_id}->set_value('5');
$parent->fields->{$date1_id}->set_value('2017-04-05');
$parent->write(no_alerts => 1);

# And fetch records again for testing
($parent, $other, $child) = _records($schema, $layout, 3);
isnt( $parent->fields->{$daterange1_id}->as_string, $child->fields->{$daterange1_id}->as_string, "Parent and child date ranges are different");
isnt( $parent->fields->{$calc1_id}->as_string, $child->fields->{$calc1_id}->as_string, "Parent and child calc values are different");
is( $parent->fields->{$calc1_id}->as_string, 2000, "Parent calc value is correct after second write");
is( $child->fields->{$calc1_id}->as_string, 2011, "Child calc value is correct after second write");
is( $parent->fields->{$string1_id}->as_string, $child->fields->{$string1_id}->as_string, "Parent and child strings are the same");
is( $parent->fields->{$enum1_id}->as_string, $child->fields->{$enum1_id}->as_string, "Parent and child enums are the same");
is( $parent->fields->{$tree1_id}->as_string, $child->fields->{$tree1_id}->as_string, "Parent and child trees are the same");
is( $parent->fields->{$date1_id}->as_string, $child->fields->{$date1_id}->as_string, "Parent and child dates are the same");
is( $child->fields->{$rag1_id}->as_string, 'b_red', "Child rag is red"); # Same as parent even though DR different

# Test multivalue field
# First, a second value
$parent->fields->{$enum1_id}->set_value([qw/2 3/]);
$parent->write(no_alerts => 1);
($parent, $other, $child) = _records($schema, $layout, 3);
is( $parent->fields->{$enum1_id}->as_string, $child->fields->{$enum1_id}->as_string, "Parent and child enums are the same");
# And second, back to a single value
$parent->fields->{$enum1_id}->set_value('3');
$parent->write(no_alerts => 1);
($parent, $other, $child) = _records($schema, $layout, 3);
is( $parent->fields->{$enum1_id}->as_string, $child->fields->{$enum1_id}->as_string, "Parent and child enums are the same");

# Now change unique field and check values
$daterange1 = $layout->column($daterange1_id);
$daterange1->set_can_child(0);
$daterange1->write;
$string1 = $layout->column($string1_id);
$string1->set_can_child(1);
$string1->write;
$layout->clear;
$child->fields->{$string1_id}->set_value('foo3');
$child->write(no_alerts => 1);

($parent, $other, $child) = _records($schema, $layout, 3);
is( $parent->fields->{$daterange1_id}->as_string, $child->fields->{$daterange1_id}->as_string, "Parent and child date ranges are the same");
is( $parent->fields->{$calc1_id}->as_string, 2000, "Parent calc value is correct after writing new daterange to parent after child unique change");
is( $child->fields->{$calc1_id}->as_string, 2000, "Child calc value is correct after removing daterange as unique");
isnt( $parent->fields->{$string1_id}->as_string, $child->fields->{$string1_id}->as_string, "Parent and child strings are different");
is( $parent->fields->{$rag1_id}->as_string, $child->fields->{$rag1_id}->as_string, "Parent and child rags are the same");

# Set new daterange value in parent, check it propagates to child calc and
# alerts set correctly. Run 2 tests, one with a calc value that is different in
# the child, and one that is the same
$ENV{GADS_NO_FORK} = 1;
foreach my $calc_depend (0..1)
{
    my $data = [
        {
            string1  => 'Foo',
            integer1 => 50,
        },
    ];
    my $code = $calc_depend
        ? "function evaluate (L1string1, L1integer1) \n return string.sub(L1string1, 1, 3) .. L1integer1 \n end"
        : "function evaluate (L1string1) \n return 'XX' .. string.sub(L1string1, 1, 3) \n end";
    my $sheet = t::lib::DataSheet->new(
        data             => $data,
        calc_code        => $code,
        calc_return_type => 'string',
    );
    my $schema  = $sheet->schema;
    my $columns = $sheet->columns;
    my $layout  = $sheet->layout;
    $sheet->create_records;

    my $string1 = $columns->{string1};
    my $string1_id = $string1->id;
    if ($calc_depend)
    {
        $columns->{string1}->set_can_child(1);
        $columns->{string1}->write;
    }
    else {
        $columns->{integer1}->set_can_child(1);
        $columns->{integer1}->write;
    }
    my $calc1_id = $columns->{calc1}->id;
    $layout->clear;

    my $parent = GADS::Record->new(
        schema => $schema,
        layout => $layout,
        user   => $sheet->user,
    );
    my $parent_id = 1;
    $parent->find_current_id($parent_id);
    my $v = $calc_depend ? 'Foo50' : 'XXFoo';
    is($parent->fields->{$calc1_id}->as_string, $v, 'Initial double calc correct');

    my $child = GADS::Record->new(
        user     => undef,
        layout   => $layout,
        schema   => $schema,
    );
    $child->parent_id($parent->current_id);
    $child->initialise;
    if ($calc_depend)
    {
        $child->fields->{$string1_id}->set_value('Bar');
    }
    else {
        # Doesn't really matter what we write here for these tests
        $child->fields->{$columns->{integer1}->id}->set_value(100);
    }
    $child->write;
    my $child_id = $child->current_id;
    $child->clear;
    $child->find_current_id($child_id);
    $v = $calc_depend ? 'Bar50' : 'XXFoo';
    is($child->fields->{$calc1_id}->as_string, $v, 'Calc correct for child record');

    my $view = GADS::View->new(
        name        => 'view1',
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => $sheet->user,
        global      => 1,
        columns     => [$calc1_id],
    );
    $view->write;

    # Calc field can be different in child, so should see child in view
    my $records = GADS::Records->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
        view   => $view,
    );
    my $count = $calc_depend ? 2 : 1;
    is($records->count, $count, "Correct parent and child in view");

    my $alert = GADS::Alert->new(
        user      => $sheet->user,
        layout    => $layout,
        schema    => $schema,
        frequency => 24,
        view_id   => $view->id,
    );
    $alert->write;

    is( $schema->resultset('AlertSend')->count, 0, "Correct number");

    $parent->fields->{$string1_id}->set_value('Baz');
    $parent->write;

    is( $schema->resultset('AlertSend')->count, $count, "Correct number");
    $schema->resultset('AlertSend')->delete;

    # Set new string value in parent but one that doesn't affect calc value
    $parent->clear;
    $parent->find_current_id($parent_id);
    $parent->fields->{$string1_id}->set_value('Bazbar');
    $parent->write;
    is( $schema->resultset('AlertSend')->count, 0, "Correct number");

    # And now one that does affect it
    $parent->fields->{$string1_id}->set_value('Baybar');
    $parent->write;
    is( $schema->resultset('AlertSend')->count, $count, "Correct number");
}

# Check that each record's parent/child IDs are correct
{
    my $parent_id        = $parent->current_id;
    my $child_id         = $child->current_id;
    my $parent_record_id = $parent->current_id;
    my $child_record_id  = $child->current_id;

    # First as single fetch
    my $child = GADS::Record->new(
        user     => undef,
        layout   => $layout,
        schema   => $schema,
    );
    $child->find_current_id($child_id);

    my $parent = GADS::Record->new(
        user     => undef,
        layout   => $layout,
        schema   => $schema,
    );
    $parent->find_current_id($parent_id);

    is($child->parent_id, $parent_id, "Child record has correct parent ID");
    my $chid = pop @{$parent->child_record_ids};
    is($chid, $child_id, "Parent record has correct child ID");

    # Then single record_id
    $child->clear;
    $child->find_record_id($child_record_id);
    $parent->clear;
    $parent->find_record_id($parent_record_id);

    is($child->parent_id, $parent_id, "Child record has correct parent ID");
    $chid = pop @{$parent->child_record_ids};
    is($chid, $child_id, "Parent record has correct child ID");

    # Now as bulk retrieval
    ($parent, $other, $child) = _records($schema, $layout, 3);
    is($child->parent_id, $parent_id, "Child record has correct parent ID");
    $chid = pop @{$parent->child_record_ids};
    is($chid, $child_id, "Parent record has correct child ID");
}

done_testing();
