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
is($record->edited_user->as_string, "User4, User4", "Record retrieved as group has correct version editor");
is($record->get_field_value($created_col)->as_string, "User1, User1", "Record retrieved as group has correct createdby");

$record = GADS::Record->new(
    layout => $layout,
    user   => $sheet->user,
    schema => $schema,
);
$record->find_current_id($current_id);
is($record->edited_user->as_string, "User4, User4", "Record retrieved as single has correct version editor");
is($record->get_field_value($created_col)->as_string, "User1, User1", "Record retrieved as group has correct createdby");

# Add another record and check that sorting by created field works
{
    # First ensure that we have more records than the standard page size of 100
    for (1..200)
    {
        my $record = GADS::Record->new(
            layout => $layout,
            user   => $sheet->user_normal1,
            schema => $schema,
        );
        $record->initialise;
        $record->fields->{$string->id}->set_value('foobar3');
        $record->write(no_alerts => 1);
    }
    # Add on a final record that will appear at one end of the sort
    my $record = GADS::Record->new(
        layout => $layout,
        user   => $sheet->user_normal2,
        schema => $schema,
    );
    $record->initialise;
    $record->fields->{$string->id}->set_value('foobar3');
    $record->write(no_alerts => 1);

    my $view = GADS::View->new(
        name        => 'Test view',
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view->set_sorts({fields => [$created_col->id], types => ['asc']});
    $view->write;

    my $records = GADS::Records->new(
        user    => $sheet->user,
        view    => $view,
        layout  => $layout,
        schema  => $schema,
    );

    is($records->single->current_id, 1, "First record correct (ascending)");
    $view->set_sorts({fields => [$created_col->id], types => ['desc']});
    $view->write;
    $records->clear;
    is($records->single->current_id, 202, "First record correct (descending)");
}

# Test searching by created user
{
    my $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $created_col->id,
                type     => 'string',
                value    => 'User1, User1',
                operator => 'equal',
            }],
        },
    );
    my $view = GADS::View->new(
        name        => 'Test view',
        filter      => $rules,
        instance_id => 1,
        layout      => $layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view->write;

    my $records = GADS::Records->new(
        user    => $sheet->user,
        view    => $view,
        layout  => $layout,
        schema  => $schema,
    );

    is($records->count, 1, "Correct number of records for search by created user");
    is($records->single->current_id, 1, "Record correct, search by created user");
}

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
    is($record->edited_user->as_string, "", "Record retrieved as group has blank version editor");
    is($record->get_field_value($created_col)->as_string, "", "Record retrieved as group has blank createdby");

    $record = GADS::Record->new(
        layout => $layout,
        user   => $sheet->user,
        schema => $schema,
    );
    $record->find_current_id($current_id);
    is($record->edited_user->as_string, "", "Record retrieved as single has blank version editor");
    is($record->get_field_value($created_col)->as_string, "", "Record retrieved as group has blank createdby");
}

done_testing();
