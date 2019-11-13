use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Don't create users, as the normal find_or_create check won't find the
# existing user at that ID due to the site_id constraint and will then fail
my $sheet_site1 = Test::GADS::DataSheet->new(site_id => 1);
my $schema      = $sheet_site1->schema;
$sheet_site1->create_records;
# Set the site_id. This should be use throughout the next data sheet creation
$schema->site_id(2);
my $sheet_site2 = Test::GADS::DataSheet->new(schema => $schema, instance_id => 2, curval_offset => 6);
$sheet_site2->create_records;

# Check site 1 records
$schema->site_id(1);
my $records_site1 = GADS::Records->new(
    user    => $sheet_site1->user,
    layout  => $sheet_site1->layout,
    schema  => $schema,
);
is( $records_site1->count, 2, "Correct number of records in site 1" );
my @current_ids = map { $_->current_id } @{$records_site1->results};
is( "@current_ids", "1 2", "Current IDs correct for site 1" );
# Try and access record from site 2
my $record = GADS::Record->new(
    user   => $sheet_site1->user,
    layout => $sheet_site1->layout,
    schema => $schema,
);
is( $record->find_current_id(1)->current_id, 1, "Retrieved record from same site (1)" );
$record->clear;
try {$record->find_current_id(3)};
ok( $@, "Failed to retrieve record from other site (2)" );

# Site 2 tests
$schema->site_id(2);
my $records_site2 = GADS::Records->new(
    user    => $sheet_site2->user,
    layout  => $sheet_site2->layout,
    schema  => $schema,
);

is( $records_site2->count, 2, "Correct number of records in site 2" );
@current_ids = map { $_->current_id } @{$records_site2->results};
is( "@current_ids", "3 4", "Current IDs correct for site 2" );

# Try and access record from site 1
$record = GADS::Record->new(
    user   => $sheet_site2->user,
    layout => $sheet_site2->layout,
    schema => $schema,
);
is( $record->find_current_id(3)->current_id, 3, "Retrieved record from same site (2)" );
$record->clear;
try {$record->find_current_id(1)};
ok( $@, "Failed to retrieve record from other site (1)" );

# Try and access columns between layouts using ID
my $string_site1 = $sheet_site1->columns->{string1};
ok(!$sheet_site2->layout->column($string_site1->id), "Failed to access column from other site by ID");
# And reverse
my $string_site2 = $sheet_site2->columns->{string1};
ok(!$sheet_site1->layout->column($string_site2->id), "Failed to access column from other site by ID - reverse");

# Then same with short name
ok(!$sheet_site2->layout->column_by_name_short($string_site1->name_short), "Failed to access column from other site by short name");

# Check that only one site's instances are returned
my $instances = GADS::Instances->new(schema => $schema, user => undef, user_permission_override => 1);
is(@{$instances->all}, 1, "Only one instance returned for site");

done_testing();
