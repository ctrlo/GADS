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
        string1    => '',
        integer1   => '',
        enum1      => '',
        tree1      => '',
        date1      => '',
        daterange1 => ['', ''],
    }
];

my $sheet = t::lib::DataSheet->new(data => $data);

my $schema = $sheet->schema;
my $layout = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $records = GADS::Records->new(
    user    => undef,
    layout  => $layout,
    schema  => $schema,
);
$records->search;
my $results = $records->results;

is( scalar @$results, 1, "One record in test dataset");

my ($record) = @$results;

my $string1 = $columns->{'string1'};
$string1->force_regex('[0-9]+');
try { $record->fields->{$string1->id}->set_value("foo") };
ok( $@, "Failed to write bad string value for force_regex settings" );

my $integer1 = $columns->{'integer1'};
try { $record->fields->{$integer1->id}->set_value("bar") };
ok( $@, "Failed to write non-integer value" );

my $date1 = $columns->{'date1'};
try { $record->fields->{$date1->id}->set_value("20-10-10") };
ok( $@, "Failed to write invalid date" );

my $daterange1 = $columns->{'daterange1'};
try { $record->fields->{$daterange1->id}->set_value(["2010-10-10",""]) };
ok( $@, "Failed to write daterange with missing date" );

try { $record->fields->{$daterange1->id}->set_value(["2015-10-10","2011-10-10"]) };
ok( $@, "Failed to write daterange with dates in wrong order" );

try { $record->fields->{$daterange1->id}->set_value(["20-10-10","2011-10-10"]) };
ok( $@, "Failed to write daterange with invalid date" );

done_testing();
