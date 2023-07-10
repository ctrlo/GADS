use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use lib 't/lib';
use Test::GADS::DataSheet;

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
        filter_value   => '2000-11-11 to 2001-11-11',
        addable        => ['+ 1 week', '+ 5 years'],
        addable_result => '2000-11-18 to 2006-11-11',
    },
    curval1 => {
        old_as_string => 'Foo, 50, foo1, , 2014-10-10, 2012-02-10 to 2013-06-15, , , c_amber, 2012',
        new           => 2,
        new_as_string => 'Bar, 99, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
    },
    curval2 => {
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
        new_html_form => 2,
        new_html      => 'User2, User2',
        filter_value  => 2,
    },
    file1 => {
        old_as_string => 'file1.txt',
        new => {
            name     => 'file2.txt',
            mimetype => 'text/plain',
            content  => 'Text file2',
        },
        new_html_form => 2,
        new_as_string => 'file2.txt',
        new_html      => 'file2.txt',
        filter_value  => 2,
    },
    calc1 => {
        filter_value => '2000',
    },
    rag1 => {
        filter_value => 'b_red',
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
            curval2    => '',
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
            curval2    => 1,
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
            curval2    => 2,
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
    my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
    $curval_sheet->create_records;
    my $sheet = Test::GADS::DataSheet->new(
        curval     => 2,
        schema     => $curval_sheet->schema,
        multivalue => $multivalue,
        column_count => { curval => 2},
    );
    my $user = $curval_sheet->user;
    $sheet->columns; # Force columns to build

    # Add curval column with show_add
    my $curval2 = $sheet->columns->{curval2};
    $curval2->show_add(1);
    $curval2->write;
    $sheet->layout->clear;

    my $record_new = GADS::Record->new(
        user     => $user,
        layout   => $sheet->layout,
        schema   => $sheet->schema,
    );
    $record_new->initialise;
    foreach my $type (keys %$values)
    {
        my $col = $sheet->columns->{$type};
        next if !$col->userinput;
        is( $record_new->fields->{$col->id}->as_string, '', "New record $type is empty string" );
        if ($col->multivalue)
        {
            is_deeply( $record_new->fields->{$col->id}->value, [], "Multivalue of new record $type is empty array" )
                if $record_new->fields->{$col->id}->can('value');
            is_deeply( $record_new->fields->{$col->id}->ids, [], "Multivalue of new record $type is empty array" )
                if $record_new->fields->{$col->id}->can('ids');
        }
        else {
            is( $record_new->fields->{$col->id}->value, undef, "Value of new record $type is undef" )
                if $record_new->fields->{$col->id}->can('value');
            is( $record_new->fields->{$col->id}->id, undef, "ID of new record $type is undef" )
                if $record_new->fields->{$col->id}->can('id') && $col->type ne 'tree';
        }
        # Check that id_hash can be generated correctly
        is( ref $record_new->fields->{$col->id}->id_hash, 'HASH', "$type has id_hash" )
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
                my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, site_id => 1);
                $curval_sheet->create_records;
                my $schema  = $curval_sheet->schema;
                my $sheet   = Test::GADS::DataSheet->new(
                    data       => $data->{$test},
                    multivalue => $multivalue,
                    schema     => $schema,
                    curval     => 2,
                    column_count => { curval => 2},
                );
                my $layout  = $sheet->layout;
                my $columns = $sheet->columns;
                $sheet->create_records;
                my $user = $sheet->user;

                # Add curval column with show_add
                my $curval2 = $sheet->columns->{curval2};
                $curval2->show_add(1);
                $curval2->write;
                $layout->clear;

                if ($deleted)
                {
                    $schema->resultset('Enumval')->update({ deleted => 1 });
                    $layout->clear;
                }

                my $records = GADS::Records->new(
                    user    => $user,
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
                    if ($datum->column->userinput)
                    {
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
                    }
                    if ($test eq 'changed' && !$deleted)
                    {
                        # Check filter value for normal datum
                        my $filter_value = $values->{$type}->{filter_value} || $values->{$type}->{new};
                        is( $datum->filter_value, $filter_value, "Filter value correct for $type" );
                        # Then create datum as it would be for grouped value and check again
                        my $datum_filter = $datum->column->class->new(
                            init_value       => [$filter_value],
                            column           => $datum->column,
                            schema           => $datum->column->schema,
                            layout           => $datum->column->layout, # Only needed for code datums
                        );
                        is( $datum_filter->filter_value, $filter_value, "Filter value correct for $type (grouped datum)" );
                    }
                    next if !$datum->column->userinput;
                    if ($deleted)
                    {
                        if ($test eq 'nochange')
                        {
                            ok(!$@, "No exception when writing deleted same value with test $test");
                        }
                        else {
                            # As it stands, tree gets a specific deleted error
                            # message, enum just errors as invalid
                            my $msg = $type =~ /tree/ ? qr/has been deleted/ : qr/is not a valid/;
                            like($@, $msg, "Unable to write changed value to one that is deleted");
                        }
                        # We don't have any sensible values to test against,
                        # and the subsequent tests are done for a none-deleted
                        # value anyway, so skip the rest
                        next;
                    }
                    else {
                        $@->reportAll;
                    }
                    if ($test eq 'blank' || $test eq 'changed')
                    {
                        ok( $datum->changed, "$type has changed$is_multi" );
                    }
                    else {
                        ok( !$datum->changed, "$type has not changed$is_multi" );
                    }
                    if ($test eq 'changed' || $test eq 'nochange')
                    {
                        if ($type ne 'curval2')
                        {
                            ok( $datum->oldvalue, "$type oldvalue exists$is_multi" );
                            my $old = $test eq 'changed' ? $values->{$type}->{old_as_string} : $values->{$type}->{new_as_string};
                            is( $datum->oldvalue && $datum->oldvalue->as_string, $old, "$type oldvalue exists and matches for test $test$is_multi" );
                            my $html_form = $values->{$type}->{new_html_form} || $values->{$type}->{new};
                            $html_form = [$html_form] if ref $html_form ne 'ARRAY';
                            is_deeply( $datum->html_form, $html_form, "html_form value correct" );
                        }
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
                        # Test writing of addable value applied to an blank existing value.
                        if (my $addable = $values->{$type}->{addable})
                        {
                            $datum->set_value($addable, bulk => 1);
                            ok( $datum->blank, "$type is blank after writing addable value$is_multi" );
                        }
                    }
                    elsif ($test eq 'changed') # Doesn't really matter which write test, as long as has value
                    {
                        if (my $addable = $values->{$type}->{addable})
                        {
                            $datum->set_value($addable, bulk => 1);
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
my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = Test::GADS::DataSheet->new(schema => $schema, curval => 2, column_count => { curval => 2 });
my $layout  = $sheet->layout;
my $columns = $sheet->columns;

# Add curval column with show_add
my $curval2 = $sheet->columns->{curval2};
$curval2->show_add(1);
$curval2->write;
$layout->clear;

$sheet->create_records;

foreach my $c (keys %$values)
{
    my $column = $columns->{$c};
    next if !$column->userinput;
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

# Test madatory fields
{
    my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
    $curval_sheet->create_records;
    my $sheet = Test::GADS::DataSheet->new(
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
        $string1->set_permissions({$sheet->group->id => []});
        $string1->write;
        $sheet->layout->clear;
        try { $record->write(no_alerts => 1) };
        ok(!$@, "No error when writing record without permission to mandatory value");
        $string1->set_permissions({$sheet->group->id => $sheet->default_permissions});
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
                layout => $sheet->layout,
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
    my $string1 = $sheet->columns->{string1};
    $record->fields->{$string1->id}->set_value('foobar');
    try { $record->write(no_alerts => 1) };
    like($@, qr/curval1/, "Error for missing curval filtered field value after string write");

    # Test a mandatory field on the second page which the user does not have
    # write access to
    my $curval1 = $sheet->columns->{curval1};
    my $group = $sheet->group;
    $curval1->set_permissions({$sheet->group->id => []});
    $curval1->write;
    $sheet->layout->clear;
    $record_count = $sheet->schema->resultset('Record')->count;
    $record->write(no_alerts => 1);
    my $record_count_new = $sheet->schema->resultset('Record')->count;
    is($record_count_new, $record_count + 1, "One record written");
}

# Test setting person field as textual value instead of ID
{
    my $sheet = Test::GADS::DataSheet->new(user_count => 2);
    $sheet->create_records;
    my $record = GADS::Records->new(
        user    => $sheet->user,
        layout  => $sheet->layout,
        schema  => $sheet->schema,
    )->single;
    my $person_id = $sheet->columns->{person1}->id;

    my $datum = $record->fields->{$person_id};
    ok(!@{$record->fields->{$person_id}->ids}, "Person field initially blank" );

    # Standard format (surname, forename)
    $datum->set_value('User1, User1');
    my $current_id = $record->current_id;
    $record->write(no_alerts => 1);
    $record->clear;
    $record->find_current_id($current_id);
    is($record->fields->{$person_id}->id, 1, "Person field correctly updated using textual name" );

    # Forename then surname, format without a comma
    $record->fields->{$person_id}->set_value('User2 User2');
    $record->write(no_alerts => 1);
    $record->clear;
    $record->find_current_id($current_id);
    is($record->fields->{$person_id}->id, 2, "Person field correctly updated using textual name (2)" );
}

# Final special test for file with only ID number the same (no new content)
$sheet = Test::GADS::DataSheet->new(
    data => [
        {
            file1 => undef, # This will create default dummy file
        },
    ],
);
$sheet->create_records;
$layout = $sheet->layout;
my $record = GADS::Records->new(
    user    => $sheet->user,
    layout  => $layout,
    schema  => $sheet->schema,
)->single;
my $datum = $record->fields->{$sheet->columns->{file1}->id};
$datum->set_value(1); # Same ID has existing one
ok( !$datum->changed, "Update with same file ID has not changed" );

# Test other blank values work whilst we're here
ok( !$record->fields->{$layout->column_id->id}->blank, "ID is not blank for existing records" );
ok( !$record->fields->{$layout->column_by_name_short('_version_datetime')->id}->blank, "Version time is not blank for existing records" );
ok( !$record->fields->{$layout->column_by_name_short('_version_user')->id}->blank, "Version user is not blank for existing records" );
ok( !$record->fields->{$layout->column_by_name_short('_created')->id}->blank, "Created is not blank for existing records" );
ok( !$record->fields->{$layout->column_by_name_short('_serial')->id}->blank, "Serial is not blank for existing records" );

done_testing();
