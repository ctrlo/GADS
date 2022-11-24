use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

my $data1 = [
    {
        string1 => 'foo1',
    },
    {
        string1 => 'foo2',
    },
    {
        string1 => 'foo3',
    },
    {
        string1 => 'foo4',
    },
];

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, data => $data1);
$curval_sheet->create_records;
my $curval_string_id = $curval_sheet->columns->{string1}->id;
my $schema  = $curval_sheet->schema;

my $data2 = [
    {
        string1 => 'foo',
        curval1 => [1,2,3,4],
    },
];

my $sheet   = Test::GADS::DataSheet->new(
    data               => $data2,
    schema             => $schema,
    curval             => 2,
    curval_offset      => 6,
    curval_field_ids   => [ $curval_sheet->columns->{string1}->id ],
    multivalue         => 1,
    multivalue_columns => { curval => 1},
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

foreach my $order (qw/asc desc/)
{
    $layout->clear;

    my $instance = $schema->resultset('Instance')->find(2);
    $instance->update({
        sort_layout_id => $curval_string_id,
        sort_type      => $order,
    });

    my $record = GADS::Record->new(
        user   => $sheet->user,
        schema => $schema,
        layout => $layout,
    );
    $record->find_current_id(5);

    my $curval = $layout->column($columns->{curval1}->id);
    my $cells = [ map { $_->{values}->[0] } @{$record->fields->{$curval->id}->values} ];

    if ($order eq 'asc')
    {
        is_deeply($cells, [qw/foo1 foo2 foo3 foo4/], "Curvals in correct order for sort $order");
    }
    else {
        is_deeply($cells, [qw/foo4 foo3 foo2 foo1/], "Curvals in correct order for sort $order");
    }

    $record = GADS::Records->new(
        user   => $sheet->user,
        schema => $schema,
        layout => $layout,
    )->single;

    $cells = [ map { $_->{values}->[0] } @{$record->fields->{$curval->id}->values} ];

    if ($order eq 'asc')
    {
        is_deeply($cells, [qw/foo1 foo2 foo3 foo4/], "Curvals in correct order for sort $order");
    }
    else {
        is_deeply($cells, [qw/foo4 foo3 foo2 foo1/], "Curvals in correct order for sort $order");
    }

    # Check order in dropdown
    my $values = [map $_->{value}, @{$curval->all_values}];
    if ($order eq 'asc')
    {
        my $expected = [qw/foo1 foo2 foo3 foo4/];
        is_deeply($values, $expected, "Order of field values correct");
    }
    else {
        my $expected = [qw/foo4 foo3 foo2 foo1/];
        is_deeply($values, $expected, "Order of field values correct");
    }
}

done_testing();
