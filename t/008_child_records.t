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

my $sheet   = t::lib::DataSheet->new(multivale => 1);
my $schema  = $sheet->schema;
my $columns = $sheet->columns;
my $layout  = $sheet->layout;
$sheet->create_records;

my ($parent) = _records($schema, $layout, 2);

# Create child
my $child = GADS::Record->new(
    user     => undef,
    layout   => $layout,
    schema   => $schema,
);
$child->initialise;
$child->parent_id($parent->current_id);
# First try writing without selecting any unique values. Should bork.
try { $child->write };
ok( $@, "Failed to write child record with no unique values" );
# Only set unique daterange. Should affect daterange field and dependent calc
my $daterange1_id = $columns->{daterange1}->id;
$child->fields->{$daterange1_id}->set_value(['2011-10-10','2015-10-10']);
$child->fields->{$daterange1_id}->child_unique(1);
$child->write(no_alerts => 1);

# Force refetch of everything from database
my $other;
($parent, $other, $child) = _records($schema, $layout, 3);
isnt( $parent->fields->{$daterange1_id}->as_string, $child->fields->{$daterange1_id}->as_string, "Parent and child date ranges are different");
my $calc1_id = $columns->{calc1}->id;
isnt( $parent->fields->{$calc1_id}->as_string, $child->fields->{$calc1_id}->as_string, "Parent and child calc values are different");
is( $parent->fields->{$calc1_id}->as_string, 2012, "Parent calc value is correct after first write");
is( $child->fields->{$calc1_id}->as_string, 2011, "Child calc value is correct after first write");
my $string1_id = $columns->{string1}->id;
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
$child->fields->{$daterange1_id}->child_unique(0);
$child->fields->{$string1_id}->set_value('foo3');
$child->fields->{$string1_id}->child_unique(1);
$child->write(no_alerts => 1);

($parent, $other, $child) = _records($schema, $layout, 3);
is( $parent->fields->{$daterange1_id}->as_string, $child->fields->{$daterange1_id}->as_string, "Parent and child date ranges are the same");
is( $parent->fields->{$calc1_id}->as_string, 2000, "Parent calc value is correct after writing new daterange to parent after child unique change");
is( $child->fields->{$calc1_id}->as_string, 2000, "Child calc value is correct after removing daterange as unique");
isnt( $parent->fields->{$string1_id}->as_string, $child->fields->{$string1_id}->as_string, "Parent and child strings are different");
is( $parent->fields->{$rag1_id}->as_string, $child->fields->{$rag1_id}->as_string, "Parent and child rags are the same");

# Set new daterange value in parent, check it propagates to child calc and alerts set correctly
$ENV{GADS_NO_FORK} = 1;
my $view = GADS::View->new(
    name        => 'view1',
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $sheet->user,
    global      => 1,
    columns     => [$columns->{calc1}->id],
);
$view->write;
my $alert = GADS::Alert->new(
    user      => $sheet->user,
    layout    => $layout,
    schema    => $schema,
    frequency => 24,
    view_id   => $view->id,
);
$alert->write;
is( $schema->resultset('AlertSend')->count, 0, "Correct number");
$parent->fields->{$daterange1_id}->set_value(['2005-01-01', '2006-02-02']);
$parent->write;
($parent, $other, $child) = _records($schema, $layout, 3);
is( $parent->fields->{$calc1_id}->as_string, 2005, "Parent calc value is correct after writing new daterange to parent");
is( $child->fields->{$calc1_id}->as_string, 2005, "Child calc value is correct after writing new daterange to parent");
is( $schema->resultset('AlertSend')->count, 2, "Correct number");

# Set new daterange value in parent but one that doesn't affect calc value
$parent->fields->{$daterange1_id}->set_value(['2005-02-01', '2006-03-02']);
$parent->write(no_alerts => 1);
($parent, $other, $child) = _records($schema, $layout, 3);
is( $schema->resultset('AlertSend')->count, 2, "Correct number");

done_testing();
