use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Basic approval tests
my $data = [
    {
        string1 => 'Foo1',
        date1   => '2004-01-01',
    },
    {
        string1 => 'Foo4',
        date1   => '2001-01-01',
    },
    {
        string1 => 'Foo3',
        date1   => '2002-01-01',
    },
    {
        string1 => 'Foo2',
        date1   => '2003-01-01',
    },
];

my $sheet = Test::GADS::DataSheet->new(data => $data);
$sheet->create_records;

my $schema = $sheet->schema;
my $layout = $sheet->layout;
my $columns = $sheet->columns;

my $records = GADS::Records->new(
    user    => $sheet->user,
    layout  => $layout,
    schema  => $schema,
);
is($records->count, 4, "Correct number of records to begin");

# Make date1 a field that needs approval
my $date1 = $columns->{date1};
$date1->set_permissions({$sheet->group->id, [qw/read write_new write_existing/]});
# Approval permissions are currently removed. Temporarily re-enable to test
# functionality
$date1->write(include_approval_perms => 1);
$layout->clear;
my $string1 = $columns->{string1};

# Write a record, one value needs approving, one is written immediately
my $record = GADS::Record->new(
    user   => $sheet->user,
    layout => $layout,
    schema => $schema,
);
$record->find_current_id(1);
$record->fields->{$string1->id}->set_value('Foo5');
$record->fields->{$date1->id}->set_value('2000-01-02');
$record->write(no_alerts => 1);

is($schema->resultset('Record')->search({approval => 0})->count, 5, "Correct number of normal versions");
is($schema->resultset('Record')->search({approval => 1})->count, 1, "Correct number of versions for approval");
$records->clear;
is($records->count, 4, "Correct record count after write");
is(@{$records->results}, 4, "Correct number of records after write");

# Now sort by the field that needs approval. Check that the correct value is
# used for the sort and that only one version is retrieved
my $view = GADS::View->new(
    name        => 'Sort view',
    columns     => [$date1->id, $string1->id],
    instance_id => $layout->instance_id,
    layout      => $layout,
    schema      => $schema,
    user        => $sheet->user,
    set_sorts   => {fields => [$date1->id], types => ['asc']},
);
$view->write;
$records = GADS::Records->new(
    view    => $view,
    user    => $sheet->user,
    layout  => $layout,
    schema  => $schema,
);
is($records->count, 4, "Correct number of records to begin");
is(@{$records->results}, 4, "Correct number of records to begin");
is($records->results->[0]->current_id, 2, "Correct first record");

done_testing();
