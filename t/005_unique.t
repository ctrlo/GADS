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
    enum1      => 1,
    tree1      => 4,
    daterange1 => ['2008-05-04', '2008-07-14'],
    person1    => 1,
    file1 => {
        name     => 'file1.txt',
        mimetype => 'text/plain',
        content  => 'Text file1',
    },
};

my $sheet = t::lib::DataSheet->new(data => [$data]);
$sheet->create_records;
my $columns = $sheet->columns;
my $layout  = $sheet->layout;

my $record = GADS::Record->new(
    user     => $sheet->user,
    layout   => $sheet->layout,
    schema   => $sheet->schema,
);
$record->initialise;

foreach my $col ($layout->all(userinput => 1))
{
    $col->isunique(1);
    $col->write;
    $layout->clear;
    $record->fields->{$col->id}->set_value($data->{$col->name});
    try { $record->write(no_alerts => 1) };
    like($@, qr/must be unique but value .* already exists/, "Failed to write unique existing value for ".$col->name);
    $col->isunique(0);
    $col->write;
}
$layout->clear;

done_testing();
