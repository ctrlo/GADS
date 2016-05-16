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
    $records->search;
    my @results = @{$records->results};
    is( scalar @results, $count, "Check number of records in retrieved dataset");
    @results;
}

my $sheet   = t::lib::DataSheet->new();
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
my $string1_id = $columns->{string1}->id;
is( $parent->fields->{$string1_id}->as_string, $child->fields->{$string1_id}->as_string, "Parent and child strings are the same");
my $rag1_id = $columns->{rag1}->id;
isnt( $parent->fields->{$rag1_id}->as_string, $child->fields->{$rag1_id}->as_string, "Parent and child rags are different");

# Now update parent daterange and strings and check relevant changes in child
$parent->fields->{$daterange1_id}->set_value(['2000-01-01', '2000-02-02']);
$parent->fields->{$string1_id}->set_value('foo2');
$parent->write(no_alerts => 1);

# And fetch records again for testing
($parent, $other, $child) = _records($schema, $layout, 3);
isnt( $parent->fields->{$daterange1_id}->as_string, $child->fields->{$daterange1_id}->as_string, "Parent and child date ranges are different");
isnt( $parent->fields->{$calc1_id}->as_string, $child->fields->{$calc1_id}->as_string, "Parent and child calc values are different");
is( $parent->fields->{$string1_id}->as_string, $child->fields->{$string1_id}->as_string, "Parent and child strings are the same");
is( $child->fields->{$rag1_id}->as_string, 'b_red', "Child rag is red"); # Same as parent even though DR different

# Now change unique field and check values
$child->fields->{$daterange1_id}->child_unique(0);
$child->fields->{$string1_id}->set_value('foo3');
$child->fields->{$string1_id}->child_unique(1);
$child->write(no_alerts => 1);

($parent, $other, $child) = _records($schema, $layout, 3);
is( $parent->fields->{$daterange1_id}->as_string, $child->fields->{$daterange1_id}->as_string, "Parent and child date ranges are the same");
is( $parent->fields->{$calc1_id}->as_string, $child->fields->{$calc1_id}->as_string, "Parent and child calc values are the same");
isnt( $parent->fields->{$string1_id}->as_string, $child->fields->{$string1_id}->as_string, "Parent and child strings are different");
is( $parent->fields->{$rag1_id}->as_string, $child->fields->{$rag1_id}->as_string, "Parent and child rags are the same");

done_testing();
