use Test::More; # tests => 1;
use strict;
use warnings;

use GADS::Records;
use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

my $sheet   = Test::GADS::DataSheet->new(data => [{ string1 => 'foobar1' }]);
my $layout  = $sheet->layout;
my $schema  = $sheet->schema;
$sheet->create_records;
my $columns = $sheet->columns;
my $string  = $columns->{string1};
my $created_col = $layout->column_by_name_short('_created_user');

my $records = GADS::Records->new(
    layout => $layout,
    user   => $sheet->user_normal1,
    schema => $schema,
);

is($records->count, 1, "Initial record created");

# Update record as different user
my $record = $records->single;
$record->fields->{$string->id}->set_value('foobar2');
$record->write(no_alerts => 1);

$records = GADS::Records->new(
    layout => $layout,
    user   => $sheet->user,
    schema => $schema,
);

$record = $records->single;
my $current_id = $record->current_id;
is($record->createdby->as_string, "User4, User4", "Record retrieved as group has correct version editor");
is($record->fields->{$created_col->id}->as_string, "User1, User1", "Record retrieved as group has correct createdby");

$record = GADS::Record->new(
    layout => $layout,
    user   => $sheet->user,
    schema => $schema,
);
$record->find_current_id($current_id);
is($record->createdby->as_string, "User4, User4", "Record retrieved as single has correct version editor");
is($record->fields->{$created_col->id}->as_string, "User1, User1", "Record retrieved as group has correct createdby");

# Some legacy records may not have createdby defined (e.g. if they were uploaded)
{
    $schema->resultset('Record')->update({ createdby => undef });
    my $records = GADS::Records->new(
        layout => $layout,
        user   => $sheet->user,
        schema => $schema,
    );

    $record = $records->single;
    my $current_id = $record->current_id;
    is($record->createdby->as_string, "", "Record retrieved as group has blank version editor");
    is($record->fields->{$created_col->id}->as_string, "", "Record retrieved as group has blank createdby");

    $record = GADS::Record->new(
        layout => $layout,
        user   => $sheet->user,
        schema => $schema,
    );
    $record->find_current_id($current_id);
    is($record->createdby->as_string, "", "Record retrieved as single has blank version editor");
    is($record->fields->{$created_col->id}->as_string, "", "Record retrieved as group has blank createdby");
}

done_testing();
