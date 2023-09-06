use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

my $data1 = [
    {
        string1 => 'foobar',
    },
];

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, data => $data1);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;

my $data2 = [
    {
        string1 => 'foo1',
        curval1 => [1],
    },
    {
        string1 => 'foo2',
        curval1 => [1],
    },
    {
        string1 => 'foo3',
        curval1 => [1],
    },
    {
        string1 => 'foo4',
        curval1 => [1],
    },
];

my $sheet   = Test::GADS::DataSheet->new(
    data               => $data2,
    schema             => $schema,
    curval => 2,
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $autocur = $curval_sheet->add_autocur(
    refers_to_instance_id => 1,
    related_field_id      => $sheet->columns->{curval1}->id,
    curval_field_ids      => [$sheet->columns->{string1}->id],
);

foreach my $order (qw/asc desc/)
{
    $curval_sheet->layout->clear;

    my $instance = $schema->resultset('Instance')->find(1);
    $instance->update({
        sort_layout_id => $columns->{string1}->id,
        sort_type      => $order,
    });

    my $record = GADS::Record->new(
        user   => $sheet->user,
        schema => $schema,
        layout => $curval_sheet->layout,
    );
    $record->find_current_id(1);

    my $cells = [ map { $_->{values}->[0] } @{$record->fields->{$autocur->id}->values} ];

    if ($order eq 'asc')
    {
        is_deeply($cells, [qw/foo1 foo2 foo3 foo4/], "Autocurs in correct order for sort $order");
    }
    else {
        is_deeply($cells, [qw/foo4 foo3 foo2 foo1/], "Autocurs in correct order for sort $order");
    }

    $record = GADS::Records->new(
        user   => $sheet->user,
        schema => $schema,
        layout => $curval_sheet->layout,
    )->single;

    $cells = [ map { $_->{values}->[0] } @{$record->fields->{$autocur->id}->values} ];

    if ($order eq 'asc')
    {
        is_deeply($cells, [qw/foo1 foo2 foo3 foo4/], "Autocurs in correct order for sort $order");
    }
    else {
        is_deeply($cells, [qw/foo4 foo3 foo2 foo1/], "Autocurs in correct order for sort $order");
    }
}

done_testing();
