use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use lib 't/lib';
use Test::GADS::DataSheet;

my $data = [
    {
        string1 => ['Bar1','Bar2','Bar3'],
    },
];

my $sheet   = Test::GADS::DataSheet->new(
    data             => $data,
    multivalue       => 1,
    calc_code        => "
        function evaluate (L1string1)
            return L1string1
        end
    ",
    calc_return_type => 'string',
);
$sheet->create_records;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
my $schema  = $sheet->schema;

my $calc1 = $columns->{calc1};
my $calc2 = GADS::Column::Calc->new(
    schema      => $schema,
    user        => $sheet->user,
    layout      => $layout,
    name        => 'calc2',
    return_type => 'integer',
    multivalue  => 1,
    code        => "function evaluate (_id) \n return {10,20,30} \nend",
);
$calc2->write;
$layout->clear;

my $record = GADS::Record->new(
    user    => $sheet->user,
    layout  => $layout,
    schema  => $schema,
);
$record->find_current_id(1);

is($record->fields->{$calc1->id}->as_string, "Bar1, Bar2, Bar3", "Multivalue string calc field correct");
is($record->fields->{$calc2->id}->as_string, "10, 20, 30", "Multivalue integer calc field correct");

done_testing();
