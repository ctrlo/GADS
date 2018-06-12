use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;

use t::lib::DataSheet;

my $sheet   = t::lib::DataSheet->new;
my $schema  = $sheet->schema;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
my $user    = $sheet->user_normal1;
$sheet->create_records;

$columns->{string1}->optional(0);
$columns->{string1}->write;
$columns->{integer1}->optional(0);
$columns->{integer1}->write;
$columns->{date1}->optional(0);
$columns->{date1}->write;

$layout->clear;

my $records = GADS::Records->new(
    user    => $user,
    layout  => $layout,
    schema  => $schema,
);

# Check normal initial record and draft count
my $record_rs = $schema->resultset('Current')->search({ draftuser_id => undef });
is($record_rs->count, 2, "Correct number of initial records");
my $draft_rs = $schema->resultset('Current')->search({ draftuser_id => {'!=' => undef} });
is($draft_rs->count, 0, "No draft records to start");

# Write a draft and check record numbers
my $record = GADS::Record->new(
    user   => $user,
    layout => $layout,
    schema => $schema,
);
$record->initialise;
my $string1 = $layout->column_by_name('string1');
$record->fields->{$string1->id}->set_value("Draft1");
my $integer1 = $layout->column_by_name('integer1');
$record->fields->{$integer1->id}->set_value(450);
$record->write(draft => 1); # Missing date1 should not matter

is($draft_rs->count, 1, "One draft saved");
is($record_rs->count, 2, "Same normal records after draft save");

# Check draft not showing in normal view
$records = GADS::Records->new(
    user    => $user,
    layout  => $layout,
    schema  => $schema,
);
is($records->count, 2, "Draft not showing in normal records count");

# Load the draft and check values
$record = GADS::Record->new(
    user   => $user,
    layout => $layout,
    schema => $schema,
);
$record->load_remembered_values;
is($record->fields->{$string1->id}->as_string, "Draft1", "Draft string saved");
is($record->fields->{$integer1->id}->as_string, 450, "Draft integer saved");

# Write a new proper record
$record = GADS::Record->new(
    user   => $user,
    layout => $layout,
    schema => $schema,
);
$record->initialise;
$record->fields->{$string1->id}->set_value("Perm1");
$record->fields->{$integer1->id}->set_value(650);
my $date1 = $layout->column_by_name('date1');
try { $record->write(no_alerts => 1) };
# Check missing value borks
like($@, qr/date1.* is not optional/, "Missing date1 cannot be written with full write");
$record->fields->{$date1->id}->set_value('2010-10-10');
# Write normal record
$record->write(no_alerts => 1);
my $current_id = $record->current_id;
$record->clear;
# Check cannot write draft from saved record
$record->find_current_id($current_id);
try { $record->write(draft => 1) };
like($@, qr/Cannot save draft of existing/, "Unable to write draft for normal record");

# Check numbers after proper record save
is($draft_rs->count, 0, "No drafts after proper save");
is($record_rs->count, 3, "Additional normal record written");

done_testing();
