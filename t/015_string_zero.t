use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;

use t::lib::DataSheet;

# Test for zero vs empty string in string
foreach my $value ('', '0')
{
    my $sheet   = t::lib::DataSheet->new(data => []);
    my $schema  = $sheet->schema;
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;
    $sheet->create_records;
    my $record = GADS::Record->new(
        user   => undef,
        layout => $layout,
        schema => $schema,
    );
    $record->initialise;
    my $string1 = $layout->column_by_name('string1');
    $record->fields->{$string1->id}->set_value($value);
    my $integer1 = $layout->column_by_name('integer1');
    $record->fields->{$integer1->id}->set_value($value);
    $record->write(no_alerts => 1);
    my $records = GADS::Records->new(
        user    => undef,
        layout  => $layout,
        schema  => $schema,
    );
    my $written = $records->single;
    is($written->fields->{$string1->id}->as_string, $value, "value '$value' correctly written for string");
    is($written->fields->{$integer1->id}->as_string, $value, "value '$value' correctly written for integer");
}

done_testing();
