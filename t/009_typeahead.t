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
        string1    => 'Foo',
        curval1    => 2,
        daterange1 => ['2012-02-10', '2013-06-15'],
        person1    => 1,
    },
    {
        string1    => 'Bar',
        curval1    => 1,
        daterange1 => ['2012-02-10', '2013-06-15'],
    },
];

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, site_id => 1);
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

# Person typeahead
$column = $columns->{person1};
@values = map $_->{label}, $column->values_beginning_with('User1');
is (scalar @values, 1, "Person typeahead returned correct number of results");
is ("@values", "User1, User1", "Typeahead returned correct values");
# Test for person field with filter
# Add new org
my $org = $schema->resultset('Organisation')->create({
    name => 'Another Organisation',
});
# Set single user to new org
$schema->resultset('User')->find(2)->update({ organisation => $org->id });
$column->filter(GADS::Filter->new(
    as_hash => {
        rules     => [{
            field    => 'organisation',
            type     => 'string',
            value    => 'Another Organisation',
            operator => 'equal',
        }],
    },
));
$column->write;
@values = map $_->{label}, $column->values_beginning_with('User');
is (scalar @values, 1, "Person typeahead returned correct number of results");
is ("@values", "User2, User2", "Typeahead returned correct values");

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
# Test searching for values contains (experimental, depending on performance)
@values = $column->values_beginning_with('ar oo');
is (scalar @values, 1, "Typeahead allows search to match values containing");
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

my $calc1 = $columns->{calc1};
my $string1 = $columns->{string1};
@values = $calc1->values_beginning_with('2');
is (scalar @values, 0, "Typeahead on calculated integer does not search as string begins with");

# Check typeahead of text calc
$calc1->code("function evaluate (L1string1) \n return L1string1 \nend");
$calc1->return_type('string');
$calc1->write;

@values = $calc1->values_beginning_with('F');
is (scalar @values, 1, "Typeahead on calculated integer does not search as string begins with");
is ($values[0], 'Foo', "Correct typeahead value");

# Write value and check that old value no longer appears in typeahead
my $record = GADS::Record->new(
    user    => $sheet->user,
    layout  => $layout,
    schema  => $schema,
);
$record->find_current_id(3);
$record->fields->{$string1->id}->set_value("Foo2");
$record->write(no_alerts => 1);

@values = $calc1->values_beginning_with('F');
is (scalar @values, 1, "Typeahead on calculated integer does not search as string begins with");
is ($values[0], 'Foo2', "Correct typeahead value");

done_testing();
