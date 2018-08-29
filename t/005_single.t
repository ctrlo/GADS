use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Record;

use t::lib::DataSheet;

my $data = [
    {
        string1    => 'Foobar',
        date1      => '2014-10-10',
        daterange1 => ['2000-10-10', '2001-10-10'],
        enum1      => 'foo1',
        tree1      => 'tree1',
        integer1   => 10,
        person1    => 1,
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
    file1      => 'file.txt',
);

my $sheet   = t::lib::DataSheet->new(data => $data);
my $schema  = $sheet->schema;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $layout,
);
$record->find_current_id(1);

foreach my $field (keys %as_string)
{
    my $string = $record->fields->{$columns->{$field}->id}->as_string;
    is($string, $as_string{$field}, "Correct value retrieved for $field");
}

done_testing();
