use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;

use t::lib::DataSheet;

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2, data => []);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;

my $sheet   = t::lib::DataSheet->new(schema => $schema, curval => 2);
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

$curval_sheet->layout->user($user);
$curval_sheet->layout->clear;
$layout->user($user);
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

# Test saving of draft with sub-record
{
    # First create a standard draft in the subrecord table
    my $record = GADS::Record->new(
        user   => $user,
        layout => $curval_sheet->layout,
        schema => $schema,
    );
    $record->initialise;
    my $string_curval = $curval_sheet->layout->column_by_name('string1');
    $record->fields->{$string_curval->id}->set_value("Draft2");
    $record->write(draft => 1); # Missing date1 should not matter

    # Count records as of now
    my $main_count = $schema->resultset('Current')->search({
        instance_id => 1,
    })->count;
    my $curval_count = $schema->resultset('Current')->search({
        instance_id => 2,
    })->count;

    # Set show_add option for curval field
    my $curval = $columns->{curval1};
    $curval->show_add(1);
    $curval->write;
    $layout->clear;

    # Create draft for the main record, containing 2 draft subrecords
    $record = GADS::Record->new(
        user   => $user,
        layout => $layout,
        schema => $schema,
    );
    $record->initialise;
    my $string1 = $layout->column_by_name('string1');
    $record->fields->{$string1->id}->set_value("Draft3");
    my $curval_columns = $curval_sheet->columns;
    my $val  = $curval_columns->{string1}->field.'=foo&'.$curval_columns->{integer1}->field.'=25';
    my $val2 = $curval_columns->{string1}->field.'=bar&'.$curval_columns->{integer1}->field.'=50';
    $record->fields->{$curval->id}->set_value([$val, $val2]);
    $record->write(draft => 1);

    # Check record counts
    my $main_count_new = $schema->resultset('Current')->search({
        instance_id => 1,
    })->count;
    my $curval_count_new = $schema->resultset('Current')->search({
        instance_id => 2,
    })->count;
    is($main_count_new, $main_count + 1, "One main draft record");
    is($curval_count_new, $curval_count + 2, "Two subrecord draft records");

    # Check that the previously created subrecord draft is retrieved (not drafts from main record)
    $record = GADS::Record->new(
	user   => $user,
	layout => $curval_sheet->layout,
	schema => $schema,
    );
    $record->load_remembered_values;
    is($record->fields->{$string_curval->id}->as_string, "Draft2", "Draft sub-record retrieved");

    # Update subrecord draft
    $record->fields->{$string_curval->id}->set_value("Draft4");
    $record->write(draft => 1); # Missing date1 should not matter
    $record->clear;
    $record->load_remembered_values;
    is($record->fields->{$string_curval->id}->as_string, "Draft4", "Draft sub-record retrieved");

    $record = GADS::Record->new(
        user   => $user,
        layout => $layout,
        schema => $schema,
    );
    $record->load_remembered_values;
    is($record->fields->{$curval->id}->as_string, "bar, 50, , , , , , , , ; foo, 25, , , , , , , , ", "Remembered subrecord curval");
    my ($id) = @{$record->fields->{$curval->id}->ids};
    $curval_count = $schema->resultset('Current')->search({
        instance_id  => 2,
        draftuser_id => $user->id,
    })->count;
    is($curval_count, 3, "Correct number of sub-record drafts"); # One direct plus 2 from above record draft

    # Now write the main record. The 2 sub-record drafts should be written and removed
    $record->fields->{$curval->id}->set_value([$val,$val2]);
    $record->fields->{$columns->{integer1}->id}->set_value(10);
    $record->fields->{$columns->{date1}->id}->set_value('2015-01-01');
    $record->write(no_alerts => 1);
    $curval_count_new = $schema->resultset('Current')->search({
        instance_id  => 2,
        draftuser_id => $user->id,
    })->count;
    is($curval_count_new, 1, "No draft sub-records after write"); # One direct left only

    # Check that written record is correct - should have used existing curval
    # drafts
    my $current_id = $record->current_id;
    $record = GADS::Record->new(
        user   => $user,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id($current_id);
    is($record->fields->{$curval->id}->as_string, "bar, 50, , , , , , , a_grey, ; foo, 25, , , , , , , a_grey, ", "Remembered subrecord curval");

    # Check the single remaining draft is the correct one
    $record = GADS::Record->new(
	user   => $user,
	layout => $curval_sheet->layout,
	schema => $schema,
    );
    $record->load_remembered_values;
    is($record->fields->{$string_curval->id}->as_string, "Draft4", "Draft sub-record retrieved");
}

done_testing();
