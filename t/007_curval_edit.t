use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

foreach my $test (qw/delete_not_used typeahead dropdown noshow/)
{
    my $delete_not_used = $test eq 'delete_not_used' ? 1 : 0;
    my $value_selector  = $test eq 'delete_not_used' ? 'noshow' : $test;

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
        column_count     => { curval => 2 },
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

    # A second "parent" sheet which has a curval field that refers to the same
    # table as the curval field of the first parent sheet. This is to test for
    # a curval table having autocurs back to 2 tables.
    my $mainsheet2 = Test::GADS::DataSheet->new(
        instance_id      => 3,
        site_id          => 1,
        schema           => $schema,
        curval_offset    => 12,
        curval           => 2,
        curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
        data             => [],
    );
    $mainsheet2->create_records;

    $layout->user($sheet->user_normal1);

    # Add a curval field in the curval layout that refers back to the main
    # table
    $curval_sheet->layout->clear;
    my $cc = GADS::Column::Curval->new(
        schema => $schema,
        user   => $sheet->user,
        layout => $curval_sheet->layout,
    );
    $cc->refers_to_instance_id(1);
    $cc->curval_field_ids([$columns->{string1}->id]);
    $cc->type('curval');
    $cc->name('Curval back to main table');
    $cc->name_short('L2curval2');
    $cc->set_permissions({$sheet->group->id => $sheet->default_permissions});
    $cc->write(force => 1);
    $layout->clear;

    # Remove permissions from one of the curval fields to check for errors
    # relating to lack of permissions for a curval subfield
    $curval_sheet->columns->{daterange1}->set_permissions({});
    $curval_sheet->columns->{daterange1}->write;

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

    # See comments about about second autocur to second main table
    my $autocur2 = $curval_sheet->add_autocur(
        refers_to_instance_id => 3,
        related_field_id      => $mainsheet2->columns->{curval1}->id,
        curval_field_ids      => [$mainsheet2->columns->{string1}->id],
    );

    $layout->clear;

    # Calc from main sheet
    my $calcmain = $columns->{calc1};

    # Set up curval to be allow adding and removal
    my $curval = $columns->{curval1};
    $curval->delete_not_used($delete_not_used);
    $curval->show_add(1);
    $curval->value_selector($value_selector);
    $curval->write(no_alerts => 1, force => 1);

    # Second curval to check same fields in different curvals work correctly
    my $curval2 = $columns->{curval2};
    $curval2->delete_not_used($delete_not_used);
    $curval2->show_add(1);
    $curval2->value_selector($value_selector);
    $curval2->write(no_alerts => 1, force => 1);

    # Set up a unique field for later testing
    my $daterange1 = $columns->{daterange1};
    $daterange1->isunique(1);
    $daterange1->write(force => 1);
    $layout->clear;

    my $curval_string = $curval_sheet->columns->{string1};

    # Test brand new record first
    {
        my $record = GADS::Record->new(
            user   => $sheet->user_normal1,
            layout => $layout,
            schema => $schema,
        );
        $record->initialise;
        $record->fields->{$columns->{integer1}->id}->set_value(10); # Prevent calc warnings
        my $curval_datum = $record->fields->{$curval->id};
        $curval_datum->set_value([$curval_string->field."=foo55"]);
        $record->write(no_alerts => 1);
        is($record->fields->{$calcmain->id}->as_string, "foo55", "Main calc correct");
        my $cid = $record->current_id;
        $record->clear;
        $record->find_current_id($cid);
        is($record->fields->{$calcmain->id}->as_string, "foo55", "Main calc correct after load");
        $curval_datum = $record->fields->{$curval->id};
        is($curval_datum->as_string, 'foo55', "Curval value contains new record");
    }

    my $record = GADS::Record->new(
        user   => $sheet->user_normal1,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id(3);
    my $curval_datum = $record->fields->{$curval->id};
    is( $curval_datum->as_string, '', "Curval blank to begin with");

    if ($value_selector eq 'dropdown')
    {
        my $expected = [
            {
                value_id    => 2,
                selector_id => 2,
                value       => 'Bar',
                html        => 'Bar',
            },
            {
                value_id    => 1,
                selector_id => 1,
                value       => 'Foo',
                html        => 'Foo',
            },
            {
                value_id    => 6,
                selector_id => 6,
                value       => 'foo55',
                html        => 'foo55',
            },
        ];
        _check_values($curval->filtered_values, $expected, "Curval dropdown values initially correct");
    }

    # Add a value to the curval on write
    my $curval_count = $schema->resultset('Current')->search({ instance_id => 2 })->count;
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
    $record->find_current_id(7);
    is($record->fields->{$calc->id}->as_string, "50", "Autocur calc correct");

    # Edit existing
    $record->clear;
    $record->find_current_id(3);
    $curval_datum = $record->fields->{$curval->id};
    $curval_count = $schema->resultset('Current')->search({ instance_id => 2 })->count;
    my $fields = { L2string1 => 1 };
    my ($d) = map { $_->{id} } grep { $_->{field_values}->{L2string1} eq 'foo2' }
        @{$curval_datum->for_code(fields => $fields)};
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
        @{$curval_datum->for_code(fields => $fields)};
    my ($d2) = map { $_->{id} } grep { $_->{field_values}->{L2string1} eq 'foo5' }
        @{$curval_datum->for_code(fields => $fields)};
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
        user   => $sheet->user_normal1,
        layout => $layout,
        schema => $schema,
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

    # Check filtered values can still be retrieved after a write fail due to
    # unique value existing
    if ($value_selector eq 'dropdown')
    {
        my $record = GADS::Record->new(
            user   => $sheet->user_normal1,
            layout => $layout,
            schema => $schema,
        );
        $record->find_current_id(3);
        $record->fields->{$daterange1->id}->set_value(['2020-10-10','2021-10-10']);
        $record->write(no_alerts => 1);

        $record = GADS::Record->new(
            user   => $sheet->user_normal1,
            layout => $layout,
            schema => $schema,
        );
        $record->initialise;
        $record->fields->{$columns->{daterange1}->id}->set_value(['2020-10-10','2021-10-10']);
        try { $record->write(no_alerts => 1) };
        like($@, qr/must be unique/, "Write failed because of unique value existing");
        my @values = @{$record->layout->column($curval->id)->filtered_values};
        is(@values, 5, "Number of filtered values correct");
    }

    # Save draft
    $record = GADS::Record->new(
        user   => $sheet->user_normal1,
        layout => $layout,
        schema => $schema,
    );
    $record->initialise(instance_id => $layout->instance_id);
    my $filval_count = @{$record->layout->column($curval->id)->filtered_values};
    $curval_datum = $record->fields->{$curval->id};
    $curval_datum->set_value([$curval_string->field."=foo10", $curval_string->field."=foo20"]);
    my $curval2_datum = $record->fields->{$curval2->id};
    $curval2_datum->set_value([$curval_string->field."=foo145"]);
    $record->fields->{$columns->{integer1}->id}->set_value(10); # Prevent calc warnings
    $record->write(draft => 1);
    $record->clear;
    $record->load_remembered_values(instance_id => $layout->instance_id);
    if ($value_selector eq 'dropdown')
    {
        # For a dropdown selector, the new values for the curval should be
        # available in the curval dropdown in the draft record
        my @values = @{$record->layout->column($curval->id)->filtered_values};
        is(@values, $filval_count + 3, "Correct number of new curval values");
        my @draft = grep $_->{selector_id} =~ /query/, @values;
        my @draft_ids = map $_->{record}->current_id, @draft;
        my $expected = [{
            value_id    => 'field8=foo10&field9=&field10=&field15=',
            selector_id => 'query_'.shift @draft_ids,
            value       => 'foo10',
            html        => 'foo10',
        },{
            value_id    => 'field8=foo145&field9=&field10=&field15=',
            selector_id => 'query_'.shift @draft_ids,
            value       => 'foo145',
            html        => 'foo145',
        },{
            value_id    => 'field8=foo20&field9=&field10=&field15=',
            selector_id => 'query_'.shift @draft_ids,
            value       => 'foo20',
            html        => 'foo20',
        }];
        _check_values(\@draft, $expected, "Curval contains draft values");

        # Second test to make sure that the pop-up curval add modal can contain
        # a curval that references back to the main record. In particular,
        # draft values should not appear in a curval list of options unless the
        # "show add" button is enabled
        my $curval_layout = $curval_sheet->layout;
        $curval_layout->clear;
        $curval_layout->user($sheet->user_normal1);
        my $modal_record = GADS::Record->new(
            user   => $sheet->user_normal1,
            layout => $curval_layout,
            schema => $schema,
        );
        $modal_record->initialise(instance_id => $layout->instance_id);
        my $filval_count2 = $schema->resultset('Current')->search({
            instance_id  => $layout->instance_id,
            draftuser_id => undef,
            deleted      => undef,
        })->count;
        $modal_record->load_remembered_values(instance_id => $curval_layout->instance_id);
        @values = @{$modal_record->layout->column($cc->id)->filtered_values};
        is(@values, $filval_count2, "Correct number of curval values");

        # Open an existing (non-draft) record and check the filtered values do
        # not contain the draft curvals
        my $existing = GADS::Record->new(
            user   => $sheet->user_normal1,
            layout => $layout,
            schema => $schema,
        );
        $existing->find_current_id(3);
        my @values2 = @{$existing->layout->column($curval->id)->filtered_values};
        is(@values2, $filval_count, "Correct number of new curval values");
    }
    $curval_datum = $record->fields->{$curval->id};
    ok(!$curval_datum->blank, "New draft value not blank");
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

    # Write back exactly same value. Test is whether value is retreieved correctly.
    $curval2_datum = $record->fields->{$curval2->id};
    $curval2_datum->set_value([map $_->{as_query}, @{$curval2_datum->html_form}]);

    $record->write(no_alerts => 1);
    my $current_id = $record->current_id;
    $record->clear;
    $record->find_current_id($current_id);
    $curval_datum = $record->fields->{$curval->id};
    is($curval_datum->as_string, 'foo10; foo30', "Curval value contains new record");
    $curval2_datum = $record->fields->{$curval2->id};
    is($curval2_datum->as_string, 'foo145', "Second curval value contains correct value");

    # Check that autocur calc field is correct before main record write
    $record->clear;
    $record->find_current_id(3);
    $curval_datum = $record->fields->{$curval->id};
    $curval_datum->set_value([$curval_string->field."=foo10"]);
    $curval_record = $curval_datum->values->[0]->{record};
    is($curval_record->fields->{$curval_string->id}->as_string, 'foo10', "Curval value contains correct string value");

    # Try writing a record that will fail, and check values of fields returned to form.
    # Do this firstly for a brand new record, and then for a record that was
    # saved as draft and then submitted.
    foreach my $is_draft (0..2) # 0 - normal write, 1 - draft, 2 - submit draft
    {
        $columns->{string1}->optional(0);
        $columns->{string1}->write(force => 1);
        $layout->clear;
        $record = GADS::Record->new(
            user   => $sheet->user_normal1,
            layout => $layout,
            schema => $schema,
        );
        $record->initialise(instance_id => $layout->instance_id);
        $filval_count = @{$record->layout->column($curval->id)->filtered_values};
        $curval_datum = $record->fields->{$curval->id};
        $curval_datum->set_value([$curval_string->field."=foo99"]);
        $record->fields->{$columns->{integer1}->id}->set_value(50);
        if ($is_draft == 1)
        {
            $record->write(no_alerts => 1, draft => 1);
        }
        else {
            try { $record->write(no_alerts => 1) };
            like($@, qr/is not optional/, "Failed to write record because of missing value");
            my $selector_id;
            $curval_datum = $record->fields->{$curval->id};
            if ($value_selector eq 'dropdown')
            {
                my @values = @{$record->layout->column($curval->id)->filtered_values};
                is(@values, $filval_count + 1, "Correct number of new curval values");
                my @draft = grep $_->{selector_id} =~ /new/, @values;
                is(@draft, 1, "Correct draft values");
                $selector_id = $draft[0]->{selector_id};
                like($selector_id, qr/^new/, "Selector ID correct for draft value");
                my $expected = [{
                    value_id    => 'field8=foo99&field9=&field10=&field15=',
                    selector_id => $selector_id,
                    value       => 'foo99',
                    html        => 'foo99',
                }];
                _check_values(\@draft, $expected, "Curval contains draft values");
            }
            else {
                ($selector_id) = map $_->{record}->selector_id, @{$curval_datum->values};
            }
            ok($curval_datum->id_hash->{$selector_id}, "New draft value selected");
            ok(!$curval_datum->blank, "New draft value not blank");
        }
    }
}

# Test to check curval value within curval subfield
{
    # The outer curval
    my $curval_sheet2 = Test::GADS::DataSheet->new(instance_id => 4);
    $curval_sheet2->create_records;
    my $schema  = $curval_sheet2->schema;

    # The standard curval which will include the above outer curval
    my $curval_sheet1 = Test::GADS::DataSheet->new(
        data             => [],
        curval           => 4,
        curval_field_ids => [ $curval_sheet2->columns->{string1}->id ],
        instance_id      => 2,
        schema           => $schema,
    );
    $curval_sheet1->create_records;

    # The standard table including the standard curval
    my $sheet   = Test::GADS::DataSheet->new(
        data             => [],
        schema           => $schema,
        curval           => 2,
        curval_field_ids => [ $curval_sheet1->columns->{string1}->id ],
    );
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;
    $layout->user($sheet->user_normal1);
    $sheet->create_records;

    # Update the curval so that it's a showadd curval
    my $curval = $columns->{curval1};
    $curval->show_add(1);
    $curval->value_selector('noshow');
    $curval->write(no_alerts => 1, force => 1);

    # Create new draft record
    my $curval_curval = $curval_sheet1->columns->{curval1};
    my $curval_string = $curval_sheet1->columns->{string1};
    my $record = GADS::Record->new(
        user   => $sheet->user_normal1,
        layout => $layout,
        schema => $schema,
    );
    $record->initialise(instance_id => $layout->instance_id);
    my $curval_datum = $record->fields->{$curval->id};
    $curval_datum->set_value([$curval_curval->field."=1&".$curval_string->field."=foobars"]);
    $record->write(draft => 1);
    $record->clear;

    # Load it back in and check that the inner curval is remembered
    $record->load_remembered_values(instance_id => $layout->instance_id);
    $curval_datum = $record->fields->{$curval->id};
    my $curval_record_id = $curval_datum->ids->[0];
    my ($form_value) = @{$curval_datum->html_form};
    my $q = "field25=foobars&field26=&field27=&field32=&field33=1";
    ok(!$form_value->{id}, "Draft curval edit does not have an ID");
    is($form_value->{as_query}, $q, "Valid query data for draft curval edit");
    $record->fields->{$curval->id}->set_value($form_value->{as_query});

    # Save it and check the curval is saved too
    $record->write(no_alerts => 1);
    my $cid = $record->current_id;
    $record->clear;
    $record->find_current_id($cid);
    is($record->fields->{$curval->id}->as_string, "foobars");
}

sub _check_values
{   my ($got, $expected, $test) = @_;
    foreach (@$got)
    {
        delete $_->{record};
        delete $_->{values};
        delete $_->{id};
    }
    is_deeply($got, $expected, $test);
}

done_testing();
