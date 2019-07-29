use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;

use t::lib::DataSheet;

# Test for zero vs empty string in string
foreach my $value ('', '0')
{
    my $sheet   = t::lib::DataSheet->new(data => [], calc_code => "function evaluate (L1integer1)\nreturn L1integer1\nend");
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
    my $calc1 = $layout->column_by_name('calc1');

    if ($value eq '0') {
        ok(!$record->fields->{$string1->id}->blank, "value '0' is not blank for string before write");
        ok(!$record->fields->{$integer1->id}->blank, "value '0' is not blank for integer before write");
        ok(!$record->fields->{$calc1->id}->blank, "value '0' is not blank for calc before write");
    }
    else {
        ok($record->fields->{$string1->id}->blank, "value '' is blank for string before write");
        ok($record->fields->{$integer1->id}->blank, "value '' is blank for integer before write");
        ok($record->fields->{$calc1->id}->blank, "value '' is blank for calc before write");
    }
    $record->write(no_alerts => 1);
    my $records = GADS::Records->new(
        user    => undef,
        layout  => $layout,
        schema  => $schema,
    );
    my $written = $records->single;
    is($written->fields->{$string1->id}->as_string, $value, "value '$value' correctly written for string");
    is($_, $value, "value '$value' correctly written for string")
        foreach @{$written->fields->{$string1->id}->html_form};
    if ($value eq '0') {
        ok(!$written->fields->{$string1->id}->blank, "value '0' is not blank for string after write");
        ok(!$written->fields->{$integer1->id}->blank, "value '0' is not blank for integer after write");
        ok(!$written->fields->{$calc1->id}->blank, "value '0' is not blank for calc after write");
    }
    else {
        ok($written->fields->{$string1->id}->blank, "value '' is blank for string after write");
        ok($written->fields->{$integer1->id}->blank, "value '' is blank for integer after write");
        ok($written->fields->{$calc1->id}->blank, "value '' is blank for calc after write");
    }
    is($written->fields->{$integer1->id}->as_string, $value, "value '$value' correctly written for integer");
    is($written->fields->{$calc1->id}->as_string, $value, "value '$value' correctly written for calc");
    is($_, $value, "value '$value' correctly written for string")
        foreach @{$written->fields->{$integer1->id}->html_form};

    # Check filters
    foreach my $col_id ($string1->id, $integer1->id, $calc1->id)
    {
        next if $col_id == $integer1->id && $value eq '';
        my $rules = GADS::Filter->new(
            as_hash => {
                rules => [
                    {
                        id       => $col_id,
                        type     => 'string',
                        value    => $value,
                        operator => 'equal',
                    },
                ],
            },
        );

        my $view = GADS::View->new(
            name        => 'Zero view',
            filter      => $rules,
            columns     => [$col_id],
            instance_id => 1,
            layout      => $layout,
            schema      => $schema,
            user        => $sheet->user,
        );
        $view->write;

        $records = GADS::Records->new(
            user    => $sheet->user,
            view    => $view,
            layout  => $layout,
            schema  => $schema,
        );
        is($records->count, 1, qq(One zero record for value "$value" col ID $col_id));
    }
}

done_testing();
