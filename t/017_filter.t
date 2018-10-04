use Test::More; # tests => 1;
use strict;
use warnings;

use GADS::Filter;
use JSON qw(decode_json encode_json);
use Log::Report;

# Set up same hash and JSON
my $as_hash = {
    rules => [
        {
            id       => 1,
            type     => 'string',
            value    => 'string1',
            operator => 'equal',
        }
    ],
    condition => 'AND',
};
my $as_json = encode_json($as_hash);

# Set and compare
my $filter = GADS::Filter->new(
    as_json => $as_json,
);
# Need to decode otherwise parameters can be in different orders
is_deeply( $filter->as_hash, $as_hash, "Hash of filter from JSON is correct" );

# Update by hash
$filter = GADS::Filter->new(
    as_hash => $as_hash,
);
is_deeply( decode_json($filter->as_json), $as_hash, "JSON of filter from hash is correct" );

# Update by json
$filter->as_json($as_json);
is_deeply( $filter->as_hash, $as_hash, "Hash of filter correct after changing by JSON" );
# Check not changed
ok( !$filter->changed, "Filter has not changed after updates" );

# Now set different data
my $as_hash2 = {
    rules => [
        {
            id       => 2,
            type     => 'string',
            value    => 'string2',
            operator => 'equal',
        }
    ],
    condition => 'OR',
};

my $as_json2 = encode_json($as_hash2);

# Update check and changed
$filter->as_json($as_json2);
is_deeply( $filter->as_hash, $as_hash2, "Hash of filter correct after changing to different JSON" );
ok( $filter->changed, "Filter has changed after update" );

# Check column IDs
is( "@{$filter->column_ids}", "2", "Column IDs of filter correct" );

# Change back to old values by as_hash
$filter->as_hash($as_hash);
is_deeply( decode_json($filter->as_json), $as_hash, "Hash of filter correct after changing to different JSON" );
ok( $filter->changed, "Filter has changed after second update" );

# Check column IDs
is( "@{$filter->column_ids}", "1", "Column IDs of filter correct after change" );

# Start with a blank filter, add filter, and check changed
$filter = GADS::Filter->new;
$filter->as_json; # Cause build of default
$filter->as_hash($as_hash2);
ok( $filter->changed, "Filter has changed after update after new" );

# Check creation of filter and then immediate change
$filter = GADS::Filter->new(as_json => $as_json);
$filter->as_json($as_json2);
ok($filter->changed, "New filter has changed");

done_testing();
