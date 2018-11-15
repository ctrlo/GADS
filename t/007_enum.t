use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;
use GADS::Layout;
use GADS::Column::Calc;
use GADS::Filter;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use t::lib::DataSheet;

foreach my $num_deleted (0..1)
{
    my $sheet   = t::lib::DataSheet->new;
    my $schema  = $sheet->schema;
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;
    $sheet->create_records;

    my $enum = $columns->{enum1};
    if ($num_deleted)
    {
        $enum->enumvals([
            {
                value => 'foo2',
                id    => 2,
            },
            {
                value => 'foo3',
                id    => 3,
            }
        ]);
        $enum->write;
    }

    my $record = GADS::Records->new(
        user    => $sheet->user,
        layout  => $layout,
        schema  => $schema,
    )->single;

    is($record->fields->{$enum->id}->as_string, "foo1", "Initial enum value correct");
    is(@{$record->fields->{$enum->id}->deleted_values}, $num_deleted, "Deleted values correct for record edit");

    $record = GADS::Record->new(
        user    => $sheet->user,
        layout  => $layout,
        schema  => $schema,
    );
    $record->initialise;
    is(@{$record->fields->{$enum->id}->deleted_values}, 0, "Deleted values always zero for new record");
}

done_testing();
