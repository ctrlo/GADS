use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Record;

use lib 't/lib';
use Test::GADS::DataSheet;

my $config = {
    gads => {
        uploads => './uploads'
    }
};

GADS::Config->instance->config($config);

my $data = [
    {
        string1    => 'Foobar',
        date1      => '2014-10-10',
        daterange1 => ['2000-10-10', '2001-10-10'],
        enum1      => 'foo1',
        tree1      => 'tree1',
        integer1   => 10,
        person1    => 1,
        curval1    => 1,
        file1 => {
            name     => 'file.txt',
            mimetype => 'text/plain',
            content  => 'Text file content',
        },
    },
];

my %as_string = (
    string1    => 'Foobar',
    date1      => '2014-10-10',
    daterange1 => '2000-10-10 to 2001-10-10',
    enum1      => 'foo1',
    tree1      => 'tree1',
    integer1   => 10,
    person1    => 'User1, User1',
    curval1    => 'Foo',
    file1      => 'file.txt',
);

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = Test::GADS::DataSheet->new(
    data             => $data,
    schema           => $schema,
    curval           => 2,
    curval_field_ids => [$curval_sheet->columns->{string1}->id],
    multivalue       => 1,
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $layout,
);
$record->find_current_id(3);

foreach my $field (keys %as_string)
{
    my $string = $record->fields->{$columns->{$field}->id}->as_string;
    is($string, $as_string{$field}, "Correct value retrieved for $field");
}

# Tests to ensure correct curval values in record
$record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $layout,
);
$record->find_current_id(3);
my $datum = $record->fields->{$columns->{curval1}->id};
my $fields = {map { $_->name_short => 1 } grep $_->name_short, $curval_sheet->layout->all};
my $for_code = $datum->for_code(fields => $fields);
is(@$for_code, 1, "Correct number of initial curval fields");
my $field_values = $for_code->[0]->{field_values};
is(keys %$field_values, 7, "Correct number of initial curval fields");
is($datum->as_string, "Foo", "Correct value of curval field");

# Check that a curval without fields selected shows as blank. Simulate this by
# removing all permissions from the curval's field
my $curval = $sheet->columns->{curval1};
my $string = $curval_sheet->columns->{string1};
$string->set_permissions({$sheet->group->id => []});
$string->write;
$layout->clear;
$record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $layout,
);
$record->find_current_id(3);
is($record->fields->{$curval->id}->as_string, '', "Curval field blank when no fields selected");
my $record_id = $record->record_id;
$record->clear;
$record->find_record_id($record_id);
is($record->fields->{$curval->id}->as_string, '', "Curval field blank when no fields selected (via record_id)");

done_testing();
