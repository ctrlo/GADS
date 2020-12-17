use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Tests to check that a curval field can refer to the same table

foreach my $multivalue (0..1)
{
    my $data = [
        {
            string1 => 'foo1',
        },
        {
            string1 => 'foo2',
        },
    ];

    my $sheet   = Test::GADS::DataSheet->new(
        data       => $data,
        multivalue => $multivalue,
    );
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;
    $sheet->create_records;
    my $schema = $sheet->schema;
    my $user   = $sheet->user;

    my $string = $columns->{string1};
    # Create another curval fields that would cause a recursive loop. Check that it
    # fails
    my $curval = GADS::Column::Curval->new(
        schema => $schema,
        user   => $user,
        layout => $layout,
    );
    $curval->refers_to_instance_id($layout->instance_id);
    $curval->curval_field_ids([$columns->{string1}->id]);
    $curval->type('curval');
    $curval->name('curval1');
    $curval->set_permissions({$sheet->group->id => $sheet->default_permissions});
    $curval->write;

    my $record = GADS::Record->new(
        user   => $sheet->user,
        schema => $schema,
        layout => $layout,
    );
    $record->initialise;
    $record->fields->{$string->id}->set_value('foo3');
    $record->fields->{$curval->id}->set_value(1);
    $record->write(no_alerts => 1);

    $record->clear;
    $record->find_current_id(3);

    is($record->fields->{$curval->id}->as_string, "foo1", "Curval with ID correct");
}

done_testing();
