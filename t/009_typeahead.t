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

my $data = [
    {
        curval1    => 2,
        daterange1 => ['2012-02-10', '2013-06-15'],
    },
    {
        curval1    => 1,
        daterange1 => ['2012-02-10', '2013-06-15'],
    },
];

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = t::lib::DataSheet->new(data => $data, schema => $schema, curval => 2);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $column = $columns->{enum1};
my @values = $column->values_beginning_with('foo');
is (scalar @values, 3, "Typeahead returned correct number of results");
is ("@values", "foo1 foo2 foo3", "Typeahead returned correct values");
@values = $column->values_beginning_with('foo1');
is (scalar @values, 1, "Typeahead returned correct number of results");
is ("@values", "foo1", "Typeahead returned correct values");
@values = $column->values_beginning_with('');
is (scalar @values, 3, "Typeahead returns all results for blank string");

$column = $columns->{curval1};
@values = $column->values_beginning_with('bar');
is (scalar @values, 1, "Typeahead returned correct number of results");
my ($value) = @values;
is (ref $value, 'HASH', "Typeahead returns hashref for curval");
is ($value->{id}, 2, "Typeahead result has correct ID");
is ($value->{name}, "Bar, 99, , , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, ", "Typeahead returned correct values");
@values = $column->values_beginning_with('foo');
is (scalar @values, 1, "Typeahead returned correct number of results");
@values = $column->values_beginning_with('');
is (scalar @values, 2, "Typeahead returns all results for blank search");

$column = $columns->{calc1};
@values = $column->values_beginning_with('2');
is (scalar @values, 0, "Typeahead on calculated integer does not search as string begins with");

done_testing();
