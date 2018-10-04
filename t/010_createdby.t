use Test::More; # tests => 1;
use strict;
use warnings;

use GADS::Records;
use Log::Report;

use t::lib::DataSheet;

my $sheet   = t::lib::DataSheet->new;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
my $schema  = $sheet->schema;
$sheet->create_records;

my $records = GADS::Records->new(
    layout => $layout,
    user   => $sheet->user,
    schema => $schema,
);

is($records->count, 2, "Initial records created");

my $record = $records->single;
my $current_id = $record->current_id;
is($record->createdby->as_string, "User1, User1", "Record retrieved as group has correct createdby");

$record = GADS::Record->new(
    layout => $layout,
    user   => $sheet->user,
    schema => $schema,
);
$record->find_current_id($current_id);
is($record->createdby->as_string, "User1, User1", "Record retrieved as single has correct createdby");

done_testing();
