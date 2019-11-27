use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Record;

use lib 't/lib';
use Test::GADS::DataSheet;

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
foreach my $initial_fetch (0..1)
{
    $record = GADS::Record->new(
        user   => $sheet->user,
        schema => $schema,
        layout => $layout,
        curcommon_all_fields => $initial_fetch,
    );
    $record->find_current_id(3);
    my $datum = $record->fields->{$columns->{curval1}->id};
    is(@{$datum->field_values}, 1, "Correct number of initial curval fields");
    my $for_code = $datum->field_values_for_code(level => 1)->{1};
    is(keys %$for_code, 7, "Correct number of initial curval fields");
    my ($value) = values %{$datum->field_values->[0]};
    is($value->as_string, "Foo", "Correct value of curval field");
}

done_testing();
