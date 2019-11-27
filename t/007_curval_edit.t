use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

foreach my $test (qw/delete_not_used typeahead normal/)
{
    my $delete_not_used = $test eq 'delete_not_used' ? 1 : 0;
    my $value_selector  = $test eq 'typeahead' ? 'typeahead' : 'noshow';

    my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, site_id => 1);
    $curval_sheet->create_records;
    my $schema  = $curval_sheet->schema;

    # Officially we do not set multivalue, which means that all fields should
    # be single value. However, opting for a value_selector of no_show for a
    # curval will automatically make it multivalue. Also, when a curval field
    # is single value, it still allows multiple values to be set via set_value.
    # Therefore, for the code values, we assume values can be either
    my $sheet   = Test::GADS::DataSheet->new(
        schema           => $schema,
        curval           => 2,
        curval_offset    => 6,
        curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
        calc_return_type => 'string',
        calc_code        => qq{function evaluate (L1curval1)
            if L1curval1 == nil then
                return ""
            end
            ret = ""
            -- Allow values to be single or multi value
            if L1curval1.field_values ~= nil then
                ret = ret .. L1curval1.field_values.L2string1
            else
                for _, curval in ipairs(L1curval1) do
                    ret = ret .. curval.field_values.L2string1
                end
            end
            return ret
        end},
    );
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;
    $sheet->create_records;

    # Add autocur and calc of autocur to curval sheet, to check that gets
    # updated on main sheet write
    my $autocur = $curval_sheet->add_autocur(
        refers_to_instance_id => 1,
        related_field_id      => $columns->{curval1}->id,
        curval_field_ids      => [$columns->{string1}->id],
    );
    my $calc = $curval_sheet->columns->{calc1};
    $calc->code("
        function evaluate (L2autocur1)
            return_value = ''
            for _, v in pairs(L2autocur1) do
                return_value = return_value .. v.field_values.L1integer1
            end
            return return_value
        end
    ");
    $calc->write;
    $layout->clear;

    # Calc from main sheet
    my $calcmain = $columns->{calc1};

    # Set up curval to be allow adding and removal
    my $curval = $columns->{curval1};
    $curval->delete_not_used($delete_not_used);
    $curval->show_add(1);
    $curval->value_selector($value_selector);
    $curval->write(no_alerts => 1, force => 1);

    my $record = GADS::Record->new(
        user   => $sheet->user_normal1,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id(3);
    my $curval_datum = $record->fields->{$curval->id};
    is( $curval_datum->as_string, '', "Curval blank to begin with");

    # Add a value to the curval on write
    my $curval_count = $schema->resultset('Current')->search({ instance_id => 2 })->count;
    my $curval_string = $curval_sheet->columns->{string1};
    $curval_datum->set_value([$curval_string->field."=foo1"]);
    $record->write(no_alerts => 1);
    is($record->fields->{$calcmain->id}->as_string, "foo1", "Main calc correct");
    my $curval_count2 = $schema->resultset('Current')->search({ instance_id => 2 })->count;
    is($curval_count2, $curval_count + 1, "New curval record created");
    $record->clear;
    $record->find_current_id(3);
    is($record->fields->{$calcmain->id}->as_string, "foo1", "Main calc correct after load");
    $curval_datum = $record->fields->{$curval->id};
    is($curval_datum->as_string, 'foo1', "Curval value contains new record");
    my $curval_record_id = $curval_datum->ids->[0];

    # Check full curval field that has been written
    my $curval_record = GADS::Record->new(
        user   => $curval_sheet->user_normal1,
        layout => $curval_sheet->layout,
        schema => $schema,
    );
    $curval_record->find_current_id($curval_record_id);
    is($curval_record->fields->{$calc->id}->as_string, 50, "Calc from autocur of curval correct");

    # Add a new value, keep existing
    $curval_count = $schema->resultset('Current')->search({ instance_id => 2 })->count;
    $curval_datum->set_value([$curval_string->field."=foo2", $curval_record_id]);
    $record->write(no_alerts => 1);
    is($record->fields->{$calcmain->id}->as_string, "foo1foo2", "Main calc correct");
    $curval_count2 = $schema->resultset('Current')->search({ instance_id => 2 })->count;
    is($curval_count2, $curval_count + 1, "Second curval record created");
    $record->clear;
    $record->find_current_id(3);
    is($record->fields->{$calcmain->id}->as_string, "foo1foo2", "Main calc correct");
    $curval_datum = $record->fields->{$curval->id};
    like($curval_datum->as_string, qr/^(foo1; foo2|foo2; foo1)$/, "Curval value contains second new record");
    $record->clear;
    # Check autocur from added curval
    $record->find_current_id(6);
    is($record->fields->{$calc->id}->as_string, "50", "Autocur calc correct");

    # Edit existing
    $record->clear;
    $record->find_current_id(3);
    $curval_datum = $record->fields->{$curval->id};
    $curval_count = $schema->resultset('Current')->search({ instance_id => 2 })->count;
    my ($d) = map { $_->{id} } grep { $_->{field_values}->{L2string1} eq 'foo2' }
        @{$curval_datum->for_code};
    $curval_datum->set_value([$curval_string->field."=foo5&current_id=$d", $curval_record_id]);
    $record->write(no_alerts => 1);
    $curval_count2 = $schema->resultset('Current')->search({ instance_id => 2 })->count;
    is($curval_count2, $curval_count, "No new curvals created");
    $record->clear;
    $record->find_current_id(3);
    is($record->fields->{$calcmain->id}->as_string, "foo1foo5", "Main calc correct");
    $curval_datum = $record->fields->{$curval->id};
    like($curval_datum->as_string, qr/^(foo1; foo5|foo5; foo1)$/, "Curval value contains updated record");

    # Edit existing - one edited via query but no changes, other changed as normal
    $curval_count = $schema->resultset('Current')->search({ instance_id => 2 })->count;
    my ($d1) = map { $_->{id} } grep { $_->{field_values}->{L2string1} eq 'foo1' }
        @{$curval_datum->for_code};
    my ($d2) = map { $_->{id} } grep { $_->{field_values}->{L2string1} eq 'foo5' }
        @{$curval_datum->for_code};
    $curval_datum->set_value([$curval_string->field."=foo1&current_id=$d1", $curval_string->field."=foo6&current_id=$d2"]);
    $record->write(no_alerts => 1);
    $curval_count2 = $schema->resultset('Current')->search({ instance_id => 2 })->count;
    is($curval_count2, $curval_count, "No new curvals created");
    $record->clear;
    $record->find_current_id(3);
    is($record->fields->{$calcmain->id}->as_string, "foo1foo6", "Main calc correct");
    $curval_datum = $record->fields->{$curval->id};
    like($curval_datum->as_string, qr/^(foo1; foo6|foo6; foo1)$/, "Curval value contains updated and unchanged records");

    # Edit existing - no actual change
    $record = GADS::Record->new(
        user                 => $sheet->user_normal1,
        layout               => $layout,
        schema               => $schema,
        curcommon_all_fields => 1,
    );
    $record->find_current_id(3);
    $curval_datum = $record->fields->{$curval->id};
    $curval_count = $schema->resultset('Current')->search({ instance_id => 2 })->count;
    $curval_datum->set_value([
        # Construct a query equivalent to what it would be if a user edited a
        # curval edit field and then saved it without any changes. That is, the
        # query string of the form, plus the current_id parameter
        map {
            $_->{record}->as_query . "&current_id=" . $_->{record}->current_id
        } @{$curval_datum->values}
    ]);
    # Set other value to ensure main record is flagged as changed and full write happens
    $record->fields->{$columns->{date1}->id}->set_value('2020-10-10');
    $record->write(no_alerts => 1);
    $curval_count2 = $schema->resultset('Current')->search({ instance_id => 2 })->count;
    is($curval_count2, $curval_count, "No new curvals created");
    $record->clear;
    $record->find_current_id(3);
    is($record->fields->{$calcmain->id}->as_string, "foo1foo6", "Main calc correct");
    $curval_datum = $record->fields->{$curval->id};
    like($curval_datum->as_string, qr/^(foo1; foo6|foo6; foo1)$/, "Curval value still contains same values");

    # Delete existing
    $curval_count = $schema->resultset('Current')->search({ instance_id => 2 })->count;
    $curval_datum->set_value([$curval_record_id]);
    $record->write(no_alerts => 1);
    $curval_count2 = $schema->resultset('Current')->search({ instance_id => 2 })->count;
    is($curval_count2, $curval_count, "Curval record not removed from table");
    $curval_count2 = $schema->resultset('Current')->search({ instance_id => 2, deleted => undef })->count;
    is($curval_count2, $curval_count - $delete_not_used, "Curval record removed from live records");
    $curval_count2 = $schema->resultset('Current')->search({ instance_id => 2, deleted => { '!=' => undef } })->count;
    is($curval_count2, $delete_not_used, "Correct number of deleted records in curval sheet");
    $record->clear;
    $record->find_current_id(3);
    is($record->fields->{$calcmain->id}->as_string, "foo1", "Main calc correct");
    $curval_datum = $record->fields->{$curval->id};
    is($curval_datum->as_string, 'foo1', "Curval value has lost value");
    # Check that previous version still refers to deleted value
    my $version = ($record->versions)[1];
    $record->clear;
    $record->find_record_id($version->id);
    $curval_datum = $record->fields->{$curval->id};
    is($curval_datum->as_string, 'foo1; foo6', "Curval old version still has old value");

    # Save draft
    $record = GADS::Record->new(
        user   => $sheet->user_normal1,
        layout => $layout,
        schema => $schema,
        curcommon_all_fields => 1,
    );
    $record->initialise(instance_id => $layout->instance_id);
    $curval_datum = $record->fields->{$curval->id};
    $curval_datum->set_value([$curval_string->field."=foo10", $curval_string->field."=foo20"]);
    $record->fields->{$columns->{integer1}->id}->set_value(10); # Prevent calc warnings
    $record->write(draft => 1);
    $record->clear;
    $record->load_remembered_values(instance_id => $layout->instance_id);
    $curval_datum = $record->fields->{$curval->id};
    $curval_record_id = $curval_datum->ids->[0];
    my @form_values = @{$curval_datum->html_form};
    my @qs = ("field8=foo10&field9=&field10=&field15=", "field8=foo20&field9=&field10=&field15=");
    foreach my $form_value (@form_values)
    {
        # Draft record, so draft curval edits should not have an ID as they
        # will be submitted afresh
        ok(!$form_value->{id}, "Draft curval edit does not have an ID");
        is($form_value->{as_query}, shift @qs, "Valid query data for draft curval edit");
    }
    @form_values = map { $_->{as_query} =~ s/foo20/foo30/; $_->{as_query} } @form_values;
    $curval_datum->set_value([@form_values]);
    $record->write(no_alerts => 1);
    my $current_id = $record->current_id;
    $record->clear;
    $record->find_current_id($current_id);
    $curval_datum = $record->fields->{$curval->id};
    is($curval_datum->as_string, 'foo10; foo30', "Curval value contains new record");

    # Check that autocur calc field is correct before main record write
    $record->clear;
    $record->find_current_id(3);
    $curval_datum = $record->fields->{$curval->id};
    $curval_datum->set_value([$curval_string->field."=foo10"]);
    $curval_record = $curval_datum->values->[0]->{record};
    is($curval_record->fields->{$curval_string->id}->as_string, 'foo10', "Curval value contains correct string value");
    is($curval_record->fields->{$calc->id}->as_string, '50', "Curval value contains correct autocur before write");
    is($curval_record->fields->{$autocur->id}->as_string, 'Foo', "Autocur value is correct");
}

done_testing();
