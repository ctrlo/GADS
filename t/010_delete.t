use Test::More; # tests => 1;
use strict;
use warnings;

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime
use GADS::Records;
use Log::Report;

use t::lib::DataSheet;

set_fixed_time('10/10/2014 01:00:00', '%m/%d/%Y %H:%M:%S');

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
my $deleted_current_id = $record->current_id;
my $deleted_record_id  = $record->record_id;
$record->delete_current;
$records->clear;
is($records->count, 1, "Record deleted");

# Find deleted record via current ID
$record = GADS::Record->new(
    layout => $layout,
    user   => $sheet->user,
    schema => $schema,
);
$record->find_current_id($deleted_current_id, deleted => 1);
is($record->deletedby, $sheet->user->value, "Record by current ID deleted by correct person");
is($record->deleted, '2014-10-10T01:00:00', "Record by current ID deleted date correct");

# Find deleted record via historical record ID
$record->clear;
$record->find_record_id($deleted_record_id, deleted => 1);
is($record->deletedby, $sheet->user->value, "Record by record ID deleted by correct person");
is($record->deleted, '2014-10-10T01:00:00', "Record by record ID deleted date correct");

# Find deleted record via all records
$records = GADS::Records->new(
    is_deleted => 1,
    layout     => $layout,
    user       => $sheet->user,
    schema     => $schema,
);
$record = $records->single;
is($record->deletedby, $sheet->user->value, "Record by all records deleted by correct person");
is($record->deleted, '2014-10-10T01:00:00', "Record by all records deleted date correct");

done_testing();
