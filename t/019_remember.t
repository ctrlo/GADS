use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Record;

use t::lib::DataSheet;

my $data = {
    string1    => 'Bar',
    integer1   => 99,
    date1      => '2009-01-02',
    enum1      => 'foo1',
    tree1      => 'tree1',
    daterange1 => ['2008-05-04', '2008-07-14'],
    person1    => 1,
};
my $expected = {
    daterange1 => '2008-05-04 to 2008-07-14',
    person1    => 'User1, User1',
};

my $sheet = t::lib::DataSheet->new(data => [$data]);
$sheet->create_records;
my $columns = $sheet->columns;
my $layout  = $sheet->layout;

foreach my $col ($layout->all(userinput => 1))
{
    $col->remember(1);
    $col->write;
}
$layout->clear;

my $record = GADS::Record->new(
    user     => $sheet->user,
    layout   => $sheet->layout,
    schema   => $sheet->schema,
);
$record->initialise;
$record->load_remembered_values;

foreach my $c (keys %$data)
{
    my $col = $columns->{$c};
    my $datum = $record->fields->{$col->id};
    my $expected = $expected->{$col->name} || $data->{$col->name};
    is($datum->as_string, $expected);
}

# Check that trying to load a deleted record returns blank
$record = GADS::Record->new(
    user     => $sheet->user,
    layout   => $sheet->layout,
    schema   => $sheet->schema,
);
$record->find_current_id($sheet->user->user_lastrecords->next->record->current_id);
$record->delete_current;
$record->clear;
$record->initialise;
$record->load_remembered_values;

done_testing();
