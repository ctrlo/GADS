use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use lib 't/lib';
use Test::GADS::DataSheet;

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

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = Test::GADS::DataSheet->new(data => $data, schema => $schema, curval => 2);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $column = $columns->{enum1};
my @values = map $_->{label}, $column->values_beginning_with('foo');
is (scalar @values, 3, "Typeahead returned correct number of results");
is ("@values", "foo1 foo2 foo3", "Typeahead returned correct values");
@values = map $_->{label}, $column->values_beginning_with('foo1');
is (scalar @values, 1, "Typeahead returned correct number of results");
is ("@values", "foo1", "Typeahead returned correct values");
@values = $column->values_beginning_with('');
is (scalar @values, 3, "Typeahead returns all results for blank string");

$column = $columns->{curval1};
$column->value_selector('typeahead');
$column->write;

# A curval typeahead often has many thousands of values. It should therefore
# not return any values if calling the values function (e.g. in the edit page)
# otherwise it may hang for a long time
is (@{$column->all_values}, 0, "Curval typeahead returns no values without search");
is (@{$column->filtered_values}, 0, "Curval typeahead returns no filtered values without search");

@values = $column->values_beginning_with('bar');
is (scalar @values, 1, "Typeahead returned correct number of results");
my ($value) = @values;
is (ref $value, 'HASH', "Typeahead returns hashref for curval");
is ($value->{id}, 2, "Typeahead result has correct ID");
is ($value->{label}, "Bar, 99, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008", "Typeahead returned correct values");
@values = $column->values_beginning_with('bar');
is (scalar @values, 1, "Typeahead returned correct number of results");
@values = $column->values_beginning_with('');
is (scalar @values, 2, "Typeahead returns all results for blank search");
# Test searching multiple values in the same record
@values = $column->values_beginning_with('bar foo');
is (scalar @values, 1, "Typeahead allows search to match multiple conditions");
is ($value->{id}, 2, "Typeahead result has correct ID");

# Add a filter to the curval
$column->filter(GADS::Filter->new(
    as_hash => {
        rules     => [{
            id       => $curval_sheet->columns->{integer1}->id,
            type     => 'string',
            value    => '50',
            operator => 'equal',
        }],
    },
    layout => $layout,
));
$column->write;
@values = $column->values_beginning_with('50');
is (scalar @values, 1, "Typeahead returned correct number of results (with matching filter)");
@values = $column->values_beginning_with('99');
is (scalar @values, 0, "Typeahead returned correct number of results (with no match filter)");
# Add a filter which has record sub-values in. This should be ignored.
$column->filter(GADS::Filter->new(
    as_hash => {
        rules     => [{
            id       => $curval_sheet->columns->{integer1}->id,
            type     => 'string',
            value    => '$L1string1',
            operator => 'equal', # String1 field in main sheet
        }],
    },
    layout => $layout,
));
$column->write;
@values = $column->values_beginning_with('50');
is (scalar @values, 1, "Typeahead returned correct number of results (with matching filter)");
@values = $column->values_beginning_with('99');
is (scalar @values, 1, "Typeahead returned correct number of results (with no match filter)");

$column = $columns->{calc1};
@values = $column->values_beginning_with('2');
is (scalar @values, 0, "Typeahead on calculated integer does not search as string begins with");

done_testing();
