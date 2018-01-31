use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use t::lib::DataSheet;

my $values = {
    string1 => {
        old_as_string => 'foo', # The initial value
        new           => 'bar', # The value it's changed to
        new_as_string => 'bar', # The string representation of the new value
    },
    integer1 => {
        old_as_string  => '100',
        new            => 200,
        new_as_string  => '200',
        addable        => '(+ 25)',
        addable_result => '225',
    },
    enum1 => {
        old_as_string => 'foo1',
        new           => 8,
        new_as_string => 'foo2',
    },
    tree1 => {
        old_as_string => 'tree1',
        new           => 11,
        new_as_string => 'tree2',
    },
    date1 => {
        old_as_string  => '2010-10-10',
        new            => '2011-10-10',
        new_as_string  => '2011-10-10',
        addable        => '+ 1 year',
        addable_result => '2012-10-10',
    },
    daterange1 => {
        old_as_string  => '2000-10-10 to 2001-10-10',
        new            => ['2000-11-11', '2001-11-11'],
        new_as_string  => '2000-11-11 to 2001-11-11',
        addable        => ['+ 1 week', '+ 5 years'],
        addable_result => '2000-11-18 to 2006-11-11',
    },
    curval1 => {
        old_as_string => 'Foo, 50, foo1, , 2014-10-10, 2012-02-10 to 2013-06-15, , , c_amber, 2012',
        new           => 2,
        new_as_string => 'Bar, 99, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
    },
    person1 => {
        old_as_string => 'User1, User1',
        new           => {
            id       => 2,
            username => "user2\@example.com",
            email    => "user2\@example.com",
            value    => 'User2, User2',

        },
        new_as_string => 'User2, User2',
        new_html      => 'User2, User2',
        },
    file1 => {
        old_as_string => 'file1.txt',
        new => {
            name     => 'file2.txt',
            mimetype => 'text/plain',
            content  => 'Text file2',
        },
        new_as_string => 'file2.txt',
        new_html      => qr(<a href="/file/[0-9]+">file2\.txt</a>),
    },
};

my $data = {
    blank => [
        {
            string1    => '',
            integer1   => '',
            enum1      => '',
            tree1      => '',
            date1      => '',
            daterange1 => ['', ''],
            curval1    => '',
            file1      => '',
            person1    => '',
        },
    ],
    changed => [
        {
            string1    => 'foo',
            integer1   => '100',
            enum1      => 7,
            tree1      => 10,
            date1      => '2010-10-10',
            daterange1 => ['2000-10-10', '2001-10-10'],
            curval1    => 1,
            person1    => 1,
            file1      => {
                name     => 'file1.txt',
                mimetype => 'text/plain',
                content  => 'Text file1',
            },
        },
    ],
    nochange => [
        {
            string1    => 'bar',
            integer1   => '200',
            enum1      => 8,
            tree1      => 11,
            date1      => '2011-10-10',
            daterange1 => ['2000-11-11', '2001-11-11'],
            curval1    => 2,
            person1    => 2,
            file1      => {
                name     => 'file2.txt',
                mimetype => 'text/plain',
                content  => 'Text file2',
            },
        },
    ],
};

# First check that we can create new record and access its blank values
foreach my $multivalue (0..1)
{
    my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
    $curval_sheet->create_records;
    my $sheet = t::lib::DataSheet->new(
        curval     => 2,
        schema     => $curval_sheet->schema,
        multivalue => $multivalue,
    );
    $sheet->columns; # Force columns to build
    my $record_new = GADS::Record->new(
        user     => undef,
        layout   => $sheet->layout,
        schema   => $sheet->schema,
    );
    $record_new->initialise;
    foreach my $type (keys %$values)
    {
        my $col = $sheet->columns->{$type};
        is( $record_new->fields->{$col->id}->as_string, '', 'New record $type is empty string' );
        if ($col->multivalue)
        {
            is_deeply( $record_new->fields->{$col->id}->value, [], 'Multivalue of new record $type is empty array' )
                if $record_new->fields->{$col->id}->can('value');
            is_deeply( $record_new->fields->{$col->id}->ids, [], 'Multivalue of new record $type is empty array' )
                if $record_new->fields->{$col->id}->can('ids');
        }
        else {
            is( $record_new->fields->{$col->id}->value, undef, 'Value of new record $type is undef' )
                if $record_new->fields->{$col->id}->can('value');
            is( $record_new->fields->{$col->id}->id, undef, 'ID of new record $type is undef' )
                if $record_new->fields->{$col->id}->can('id');
        }
        # Check that id_hash can be generated correctly
        is( ref $record_new->fields->{$col->id}->id_hash, 'HASH', '$type has id_hash' )
            if $record_new->fields->{$col->id}->can('id_hash');
    }
}

foreach my $multivalue (0..1)
{
    for my $test ('blank', 'nochange', 'changed')
    {
        # Values can be set as both array ref and scalar. Test both.
        foreach my $arrayref (0..1)
        {
            foreach my $deleted (0..1) # Test for deleted values of field, where applicable
            {
                my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
                $curval_sheet->create_records;
                my $schema  = $curval_sheet->schema;
                my $sheet   = t::lib::DataSheet->new(
                    data       => $data->{$test},
                    multivalue => $multivalue,
                    schema     => $schema,
                    curval     => 2
                );
                my $layout  = $sheet->layout;
                my $columns = $sheet->columns;
                $sheet->create_records;

                if ($deleted)
                {
                    $schema->resultset('Enumval')->update({ deleted => 1 });
                    $layout->clear;
                }

                my $records = GADS::Records->new(
                    user    => undef,
                    layout  => $layout,
                    schema  => $schema,
                );
                my $results = $records->results;

                my $is_multi = $multivalue ? " for multivalue" : '';

                is( scalar @$results, 1, "One record in test dataset$is_multi");

                my ($record) = @$results;

                foreach my $type (keys %$values)
                {
                    next if $deleted && $type !~ /(enum1|tree1)/;

                    next if $arrayref && $type eq 'daterange1';
                    my $datum = $record->fields->{$columns->{$type}->id};
                    ok( !$datum->written_to, "$type has not been written to$is_multi" );
                    if ($test eq 'blank')
                    {
                        ok( $datum->blank, "$type is blank$is_multi" );
                    }
                    else {
                        ok( !$datum->blank, "$type is not blank$is_multi" );
                    }
                    if ($arrayref)
                    {
                        try { $datum->set_value([$values->{$type}->{new}]) };
                    }
                    else {
                        try { $datum->set_value($values->{$type}->{new}) };
                    }
                    if ($deleted)
                    {
                        if ($test eq 'nochange')
                        {
                            ok(!$@, "No exception when writing deleted same value with test $test");
                        }
                        else {
                            like($@, qr/is not a valid/, "Unable to write changed value to one that is deleted");
                        }
                        # We don't have any sensible values to test against,
                        # and the subsequent tests are done for a none-deleted
                        # value anyway, so skip the rest
                        next;
                    }
                    else {
                        $@->reportAll;
                    }
                    ok( $datum->written_to, "$type has been written to$is_multi" );
                    if ($test eq 'blank' || $test eq 'changed')
                    {
                        ok( $datum->changed, "$type has changed$is_multi" );
                    }
                    else {
                        ok( !$datum->changed, "$type has not changed$is_multi" );
                    }
                    if ($test eq 'changed' || $test eq 'nochange')
                    {
                        ok( $datum->oldvalue, "$type oldvalue exists$is_multi" );
                        my $old = $test eq 'changed' ? $values->{$type}->{old_as_string} : $values->{$type}->{new_as_string};
                        is( $datum->oldvalue && $datum->oldvalue->as_string, $old, "$type oldvalue exists and matches for test $test$is_multi" );
                        ok( $datum->written_valid, "$type is written valid for non-blank$is_multi" );
                    }
                    elsif ($test eq 'blank')
                    {
                        ok( $datum->oldvalue && $datum->oldvalue->blank, "$type was blank$is_multi" );
                    }
                    my $new_as_string = $values->{$type}->{new_as_string};
                    is( $datum->as_string, $new_as_string, "$type is $new_as_string$is_multi for test $test" );
                    my $new_html = $values->{$type}->{new_html} || $new_as_string;
                    if (ref $new_html eq 'Regexp')
                    {
                        like( $datum->html, $new_html, "$type is $new_html$is_multi for test $test" );
                    }
                    else {
                        is( $datum->html, $new_html, "$type is $new_html$is_multi for test $test" );
                    }
                    # Check that setting a blank value works
                    if ($test eq 'blank')
                    {
                        if ($arrayref)
                        {
                            $datum->set_value([$data->{blank}->[0]->{$type}]);
                        }
                        else {
                            $datum->set_value($data->{blank}->[0]->{$type});
                        }
                        ok( $datum->blank, "$type has been set to blank$is_multi" );
                        # Blank values should not be counted as a valid written value
                        ok( !$datum->written_valid, "$type is not written valid for blank$is_multi" );
                        # Test writing of addable value applied to an blank existing value.
                        if (my $addable = $values->{$type}->{addable})
                        {
                            $datum->set_value($addable, bulk => 1);
                            ok( $datum->written_valid, "$type is written valid for addable value$is_multi" );
                            ok( $datum->blank, "$type is blank after writing addable value$is_multi" );
                        }
                    }
                    elsif ($test eq 'changed') # Doesn't really matter which write test, as long as has value
                    {
                        if (my $addable = $values->{$type}->{addable})
                        {
                            $datum->set_value($addable, bulk => 1);
                            ok( $datum->written_valid, "$type is written valid for addable value$is_multi" );
                            is( $datum->as_string, $values->{$type}->{addable_result}, "$type is correct after writing addable change$is_multi" );
                        }
                    }
                }
            }
        }
    }
}

# Set of tests to check behaviour when values start as undefined (as happens,
# for example, when a new column is created and not added to existing records)
my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = t::lib::DataSheet->new(schema => $schema, curval => 2);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

foreach my $c (keys %$values)
{
    my $column = $columns->{$c};
    # First check that an empty string replacing the null
    # value counts as not changed
    my $class  = $column->class;
    my $datum = $class->new(
        set_value       => undef,
        column          => $column,
        init_no_value   => 1,
        datetime_parser => $schema->storage->datetime_parser,
        schema          => $schema,
    );
    $datum->set_value($values->{$c}->{new});
    ok( $datum->changed, "$c has changed" );
    # And now that an actual value does count as a change
    $datum = $class->new(
        set_value       => undef,
        column          => $column,
        init_no_value   => 1,
        datetime_parser => $schema->storage->datetime_parser,
        schema          => $schema,
    );
    $datum->set_value($data->{blank}->[0]->{$c});
    ok( !$datum->changed, "$c has not changed" );
}

# Test moving forward and back
{
    my $record = GADS::Record->new(
        user   => undef,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id(3);
    # Write values to all datums
    my @col_ids;
    foreach my $c (keys %$values)
    {
        my $datum = $record->fields->{$columns->{$c}->id};
        $datum->set_value($values->{$c}->{new});
        push @col_ids, $columns->{$c}->id;
    }
    # Check all written to
    foreach my $c (keys %$values)
    {
        my $datum = $record->fields->{$columns->{$c}->id};
        ok( $datum->written_to, "$c is written to after first write" );
    }
    $record->editor_shown_fields([@col_ids]);
    # Move nowhere - should reset written_to
    $record->move_nowhere;
    foreach my $c (keys %$values)
    {
        my $datum = $record->fields->{$columns->{$c}->id};
        ok( !$datum->written_to, "$c is no longer written to written to after move nowhere" );
    }
    # Write values again
    foreach my $c (keys %$values)
    {
        my $datum = $record->fields->{$columns->{$c}->id};
        $datum->set_value($values->{$c}->{new});
        ok( $datum->value_current_page, "$c is current page" );
    }
    # Move forward
    $record->move_forward;
    $record->editor_shown_fields([]);
    $record->editor_previous_fields([@col_ids]);
    foreach my $c (keys %$values)
    {
        my $datum = $record->fields->{$columns->{$c}->id};
        ok( $datum->value_previous_page, "$c is previous page after move forward" );
        ok( !$datum->value_next_page, "$c is previous page after move forward" );
    }
    # Move back to first page. Should no longer be previous page or written to
    $record->move_back;
    foreach my $c (keys %$values)
    {
        my $datum = $record->fields->{$columns->{$c}->id};
        ok( !$datum->value_previous_page, "$c is no longer previous page after move back" );
        ok( !$datum->written_to, "$c is no longer written to after move back" );
    }
    # Now simulate that all values are actually for the next page
    $record->editor_next_fields([@col_ids]);
    foreach my $c (keys %$values)
    {
        # Set the valu, this time it should not be flagged as written to
        my $datum = $record->fields->{$columns->{$c}->id};
        $datum->set_value($values->{$c}->{new});
        ok( !$datum->written_to, "$c is not written to when a next page value" );
    }
}

# Test madatory fields
{
    my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
    $curval_sheet->create_records;
    my $sheet = t::lib::DataSheet->new(
        optional                 => 0,
        data                     => [],
        curval                   => 2,
        schema                   => $curval_sheet->schema,
        user_permission_override => 0,
    );
    $sheet->create_records; # No data, but set up everything else
    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $sheet->layout,
        schema => $sheet->schema,
    );
    $record->initialise;
    foreach my $column ($sheet->layout->all(userinput => 1))
    {
        try { $record->write(no_alerts => 1) };
        my $colname = $column->name;
        like($@, qr/\Q$colname/, "Correctly failed to write without mandatory value");
        # Write a value, so it doesn't stop on same column next time
        $record->fields->{$column->id}->set_value($values->{$colname}->{new});
    }

    # Test if user without write access to a mandatory field can still save
    # record
    {
        foreach my $col ($sheet->layout->all(userinput => 1))
        {
            next if $col->name eq 'string1';
            $col->optional(1);
            $col->write;
        }
        $sheet->layout->clear;
        # First check cannot write
        my $string1 = $sheet->columns->{string1};
        $record->fields->{$string1->id}->set_value('');
        try { $record->write(no_alerts => 1) };
        like($@, qr/is not optional/, "Failed to write with permission to mandatory string value");
        $string1->set_permissions($sheet->group->id, []);
        $string1->write;
        $sheet->layout->clear;
        try { $record->write(no_alerts => 1) };
        ok(!$@, "No error when writing record without permission to mandatory value");
        $string1->set_permissions($sheet->group->id, $sheet->default_permissions);
        $string1->write;
        foreach my $col ($sheet->layout->all(userinput => 1))
        {
            $col->optional(0);
            $col->write;
        }
        $sheet->layout->clear;
    }

    # Now with filtered value for next page - should wait until page shown
    # Count records now to check nothing written
    my $record_count = $sheet->schema->resultset('Record')->count;
    foreach my $col ($sheet->layout->all(userinput => 1))
    {
        if ($col->name eq 'curval1')
        {
            $col->filter(GADS::Filter->new(
                as_hash => {
                    rules => [{
                        id       => $curval_sheet->columns->{string1}->id,
                        type     => 'string',
                        value    => '$L1string1',
                        operator => 'equal',
                    }],
                },
            ));
        }
        else {
            $col->optional(1);
        }
        $col->write;
    }
    $sheet->layout->clear;
    $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $sheet->layout,
        schema => $sheet->schema,
    );
    $record->initialise;
    try { $record->write(no_alerts => 1) };
    is($@, '', "No error when missing curval filtered field value");
    my $record_count_new = $sheet->schema->resultset('Record')->count;
    is($record_count_new, $record_count, "No records written despite no error");
    my $string1 = $sheet->columns->{string1};
    $record->fields->{$string1->id}->set_value('foobar');
    $record->editor_shown_fields([$string1->id]);
    try { $record->write(no_alerts => 1) };
    is($@, '', "Error for missing curval filtered field value after string write");
    my $curval1 = $sheet->columns->{curval1};
    $record->editor_shown_fields([$string1->id, $curval1->id]);
    try { $record->write(no_alerts => 1) };
    like($@, qr/curval1/, "Error for missing curval filtered field value after string write");

    # Test a mandatory field on the second page which the user does not have
    # write access to
    my $group = $sheet->group;
    $curval1->set_permissions($sheet->group->id, []);
    $curval1->write;
    $sheet->layout->clear;
    $record->editor_shown_fields([$string1->id]);
    $record_count = $sheet->schema->resultset('Record')->count;
    $record->write(no_alerts => 1);
    $record_count_new = $sheet->schema->resultset('Record')->count;
    is($record_count_new, $record_count + 1, "One record written");
}

# Final special test for file with only ID number the same (no new content)
$sheet = t::lib::DataSheet->new(
    data => [
        {
            file1 => undef, # This will create default dummy file
        },
    ],
);
$sheet->create_records;
my $record = GADS::Records->new(
    user    => undef,
    layout  => $sheet->layout,
    schema  => $sheet->schema,
)->single;
my $datum = $record->fields->{$sheet->columns->{file1}->id};
$datum->set_value(1); # Same ID has existing one
ok( !$datum->changed, "Update with same file ID has not changed" );

done_testing();
