use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Record;

use lib 't/lib';
use Test::GADS::DataSheet;

my $data = {
    string1    => 'Bar',
    integer1   => 99,
    date1      => '2009-01-02',
    enum1      => 'foo1',
    tree1      => 'tree1',
    daterange1 => ['2008-05-04', '2008-07-14'],
    person1    => 1,
};
my $expected = {
    daterange1 => '2008-05-04 to 2008-07-14',
    person1    => 'User1, User1',
};

my $sheet = Test::GADS::DataSheet->new(data => [$data]);
$sheet->create_records;
my $columns = $sheet->columns;
my $layout  = $sheet->layout;

foreach my $col ($layout->all(userinput => 1))
{
    $col->remember(1);
    $col->write;
}
$layout->clear;

my $record = GADS::Record->new(
    user     => $sheet->user,
    layout   => $sheet->layout,
    schema   => $sheet->schema,
);
$record->initialise;
$record->load_remembered_values;

foreach my $c (keys %$data)
{
    my $col = $columns->{$c};
    my $datum = $record->fields->{$col->id};
    my $expected = $expected->{$col->name} || $data->{$col->name};
    is($datum->as_string, $expected);
}

# Check that a user can still load previous values from a record they no longer
# have access to
{
    # Create view limit
    my $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $columns->{string1}->id,
                type     => 'string',
                value    => 'Foobar', # No match
                operator => 'equal',
            }],
        },
    );

    my $view_limit = GADS::View->new(
        name        => 'Limit to view',
        filter      => $rules,
        instance_id => 1,
        layout      => $sheet->layout,
        schema      => $sheet->schema,
        user        => $sheet->user,
        is_admin    => 1,
    );
    $view_limit->write;

    $sheet->user->set_view_limits([$view_limit->id]);
    $record = GADS::Record->new(
        user     => $sheet->user,
        layout   => $sheet->layout,
        schema   => $sheet->schema,
    );
    $record->initialise;
    $record->load_remembered_values;

    foreach my $c (keys %$data)
    {
        my $col = $columns->{$c};
        my $datum = $record->fields->{$col->id};
        my $expected = $expected->{$col->name} || $data->{$col->name};
        is($datum->as_string, $expected);
    }

    $sheet->user->set_view_limits([]);
}

# Check that trying to load a deleted record returns blank
$record = GADS::Record->new(
    user     => $sheet->user,
    layout   => $sheet->layout,
    schema   => $sheet->schema,
);
$record->find_current_id($sheet->user->user_lastrecords->next->record->current_id);
$record->delete_current;
$record->clear;
$record->initialise;
$record->load_remembered_values;
foreach my $c (keys %$data)
{
    my $col = $columns->{$c};
    my $datum = $record->fields->{$col->id};
    is($datum->as_string, '');
}

done_testing();
