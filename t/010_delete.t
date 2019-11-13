use Test::More; # tests => 1;
use strict;
use warnings;

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime
use GADS::Records;
use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

set_fixed_time('10/10/2014 01:00:00', '%m/%d/%Y %H:%M:%S');

my $sheet   = Test::GADS::DataSheet->new;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
my $schema  = $sheet->schema;
$sheet->create_records;

my $records = GADS::Records->new(
    layout => $layout,
    user   => $sheet->user,
    schema => $schema,
);

# Check quick search matches
$records->search('foo1');
is ($records->count, 1, 'Quick search for first record count');
is (@{$records->results}, 1, 'Quick search for first record');
$records->clear;

is($records->count, 2, "Initial records created");

my $record = $records->single;
my $deleted_current_id = $record->current_id;
my $deleted_record_id  = $record->record_id;
$record->delete_current;
$records->clear;
is($records->count, 1, "Record deleted");
$records->clear;

# Check that record cannot be found via quick search
$records->search('foo1');
is ($records->count, 0, 'Quick search for deleted record count');
is (@{$records->results}, 0, 'Quick search for deleted record');
$records->clear;

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
