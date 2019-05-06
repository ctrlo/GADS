use Test::More; # tests => 1;
use strict;
use warnings;

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime
use DateTime;
use JSON qw(encode_json);
use Log::Report;
use GADS::Graph;
use GADS::Graph::Data;
use GADS::Records;

use t::lib::DataSheet;

set_fixed_time('01/01/2008 01:00:00', '%m/%d/%Y %H:%M:%S');

my $data = [
    {
        string1    => 'Foo',
        date1      => '2013-10-10',
        daterange1 => ['2014-03-21', '2015-03-01'],
        integer1   => 10,
        enum1      => 'foo1',
        curval1    => 1,
    },{
        string1    => 'Bar',
        date1      => '2014-10-10',
        daterange1 => ['2010-01-04', '2011-06-03'],
        integer1   => 15,
        enum1      => 'foo1',
        curval1    => 2,
    },
];

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema = $curval_sheet->schema;
my $sheet = t::lib::DataSheet->new(data => $data, curval => 2, schema => $schema);

my $layout = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $showcols = [ map { $_->id } $layout->all(exclude_internal => 1) ];

my $records = GADS::Records->new(
    from    => DateTime->now,
    user    => undef,
    columns => $showcols,
    layout  => $layout,
    schema  => $schema,
);

# 4 for all main sheet1 values, plus 4 for referenced curval fields
is( @{$records->data_calendar}, 8, "Retrieving all data returns correct number of points to plot for calendar" );
$records->clear;
is( @{$records->data_timeline->{items}}, 8, "Retrieving all data returns correct number of points to plot for timeline" );

# Test from a later date. The records from that date should be retrieved, and
# then the ones before as the total number is less than the threshold
$records = GADS::Records->new(
    from    => DateTime->new(year => 2011, month => 10, day => 01),
    user    => undef,
    columns => $showcols,
    layout  => $layout,
    schema  => $schema,
);
is( @{$records->data_timeline->{items}}, 8, "Retrieving all data returns correct number of points to plot for timeline" );

# Add a filter and only retrieve one column
my $rules = encode_json({
    rules     => [{
        id       => $columns->{string1}->id,
        type     => 'string',
        value    => 'Foo',
        operator => 'equal',
    }],
    # condition => 'AND', # Default
});

my $view = GADS::View->new(
    name        => 'Test view',
    columns     => [$columns->{date1}->id],
    filter      => $rules,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => undef,
);
$view->write;

$records = GADS::Records->new(
    user   => undef,
    from   => DateTime->now,
    layout => $layout,
    schema => $schema,
    view   => $view,
);

is( @{$records->data_calendar}, 1, "Filter and single column returns correct number of points to plot for calendar" );
$records->clear;
is( @{$records->data_timeline->{items}}, 1, "Filter and single column returns correct number of points to plot for timeline" );

# When a timeline includes a label, that column should be automatically
# included even if it's not part of the view. Also include invalid group and
# color and check it has no effect.
$records->clear;
my $items = $records->data_timeline(label => $columns->{string1}->id, group => 999, color => 999)->{items};
like( $items->[0]->{content}, qr/Foo/, "Label included in output even if not in view" );

# Now use the same filter and restrict by date
my $fromdt = DateTime->new(
    year       => 2010,
    month      => 01,
    day        => 01,
);
my $todt = DateTime->new(
    year       => 2020,
    month      => 01,
    day        => 01,
);

$records = GADS::Records->new(
    user   => undef,
    layout => $layout,
    schema => $schema,
    view   => $view,
    from   => $fromdt,
    to     => $todt,
);

is( @{$records->data_calendar}, 1, "Filter, single column and limited range returns correct number of points to plot for calendar" );
$records->clear;
is( @{$records->data_timeline->{items}}, 1, "Filter, single column and limited range returns correct number of points to plot for timeline" );

# Test limited display of many timeline records
{
    my @data;
    my $start = DateTime->now;
    my %group_values;
    for my $count (1..300)
    {
        push @data, {
            string1 => 'Foo'.int rand(1000),
            date1   => $start->ymd,
            enum1   => 'foo'.(($count % 3) + 1),
        };
        $group_values{$count} = ($count % 3) + 1;
        $start->add(days => 1);
    }

    my $sheet = t::lib::DataSheet->new(data => \@data);
    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $columns  = $sheet->columns;
    my $showcols = [ map { $_->id } $layout->all(exclude_internal => 1) ];

    # Run 2 tests - sorted by string1 and enum1. string1 will randomise the
    # results to make sure the correct ones are pulled out by date; enum1 will
    # test the sorting of groups on the timeline
    foreach my $sort (qw/string1 enum1/)
    {
        my $view = GADS::View->new(
            name        => 'Foobar',
            columns     => [$columns->{string1}->id, $columns->{date1}->id],
            instance_id => $layout->instance_id,
            layout      => $layout,
            schema      => $schema,
            user        => $sheet->user,
        );
        $view->write;
        $view->set_sorts([$sheet->columns->{$sort}->id], ['asc']);

        my $records = GADS::Records->new(
            from   => DateTime->now->add(days => 100),
            user   => undef,
            view   => $view,
            layout => $layout,
            schema => $schema,
        );

        # 99 records/days from start, 49 records/days back from start. Each extreme
        # is not counted, so that the range can be loaded from that date (as there
        # may be more records of the same date)
        my $group_id = $sort eq 'enum1' && $columns->{enum1}->id;
        my $timeline = $records->data_timeline(group => $group_id);
        my @items = @{$timeline->{items}};
        is( @items, 148, "Retrieved correct subset of records for large timeline" );
        if ($sort eq 'enum1')
        {
            # Check for groups in correct order
            foreach my $g (@{$timeline->{groups}})
            {
                if ($g->{content} eq 'foo1') {
                    is($g->{order}, 1, "foo1 group order correct");
                } elsif ($g->{content} eq 'foo2') {
                    is($g->{order}, 2, "foo2 group order correct");
                } elsif ($g->{content} eq 'foo3') {
                    is($g->{order}, 3, "foo1 group order correct");
                } else {
                    panic "Something's wrong";
                }
            }

        }
        foreach my $item (@items)
        {
            if ($sort eq 'enum1')
            {
                # Test group value of item
                my $cid = $item->{current_id};
                is($item->{group}, $group_values{$cid}, "Correct group for item");
            }
            my $time = DateTime->from_epoch(epoch => $item->{single} / 1000);
            # Centre is at now + 100 days. Should have items 50 days to the left
            # and 100 days to the right
            cmp_ok($time, '>', DateTime->now->add(days => 50), "Item after minimum date expected");
            cmp_ok($time, '<', DateTime->now->add(days => 200), "Item before maximum date expected");
        }
    }

    $records = GADS::Records->new(
        from    => DateTime->now, # Rounded down to midnight 1st Jan 2018
        to      => DateTime->now->add(days => 10), # Rounded up to midnight 12th Jan 2018
        user    => undef,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    # 10 days, plus one either side including rounding up/down
    is( @{$records->data_timeline->{items}}, 12, "Retrieved correct subset of records for large timeline" );

    # Test from exactly midnight - should be no rounding
    $records = GADS::Records->new(
        from    => DateTime->new(year => 2008, month => 1, day => 1),
        to      => DateTime->new(year => 2008, month => 1, day => 10),
        user    => undef,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    is( @{$records->data_timeline->{items}}, 10, "Retrieved correct subset of records for large timeline" );
}

# Test exclusive functionality
{
    my $data = [
        {
            string1    => 'foo1',
            daterange1 => ['2009-01-01', '2009-06-01'],
        },
        {
            string1    => 'foo2',
            daterange1 => ['2010-01-01', '2010-06-01'],
        },
        {
            string1    => 'foo3',
            daterange1 => ['2011-01-01', '2011-06-01'],
        },
    ];

    my $sheet = t::lib::DataSheet->new(data => $data);
    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $dr1      = $sheet->columns->{daterange1}->id;
    my $showcols = [ map { $_->id } $layout->all(exclude_internal => 1) ];

    my $records = GADS::Records->new(
        from    => DateTime->new(year => 2009, month => 03, day => 01),
        to      => DateTime->new(year => 2011, month => 03, day => 01),
        user    => undef,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    # Normal - should include dateranges that go over the from/to values
    is( @{$records->data_timeline->{items}}, 3, "Records retrieved inclusive" );
    $records->clear;
    # Should not include dateranges that go over the to
    $records->exclusive('to');
    my $items = $records->data_timeline->{items};
    is( @$items, 2, "Records retrieved exclusive to" );
    like( $items->[0]->{content}, qr/foo1/, "Correct first record for exclusive to" );
    $records->clear;
    # Should not include dateranges that go over the from
    $records->exclusive('from');
    $items = $records->data_timeline->{items};
    is( @$items, 2, "Records retrieved exclusive from" );
    like( $items->[0]->{content}, qr/foo2/, "Correct first record for exclusive from" );
}

# Date from a calc field
{
    my $data = [
        {
            string1    => 'foo1',
            daterange1 => ['2009-01-01', '2009-06-01'],
        },
        {
            string1    => 'foo2',
            daterange1 => ['2010-01-01', '2010-06-01'],
        },
    ];

    my $year = 86400 * 365;
    my $sheet = t::lib::DataSheet->new(
        data             => $data,
        calc_code        => "function evaluate (L1daterange1) \n return L1daterange1.from.epoch - $year \nend",
        calc_return_type => 'date',
    );

    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $dr1      = $sheet->columns->{daterange1}->id;
    my $showcols = [ map { $_->id } $layout->all(exclude_internal => 1) ];

    my $records = GADS::Records->new(
        from    => DateTime->new(year => 2007, month => 01, day => 01),
        to      => DateTime->new(year => 2008, month => 12, day => 31),
        user    => undef,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    # Normal - should include dateranges that go over the from/to values
    is( @{$records->data_timeline->{items}}, 1, "Records retrieved inclusive" );
}

# No records to display
{
    my $sheet = t::lib::DataSheet->new(data => []);
    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $showcols = [ map { $_->id } $layout->all(exclude_internal => 1) ];

    my $records = GADS::Records->new(
        from    => DateTime->now,
        user    => undef,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    is( @{$records->data_timeline->{items}}, 0, "No timeline entries for no records" );
}

# Calc field as group
{
    my $data = [
        {
            string1    => 'foo1',
            daterange1 => ['2009-01-01', '2009-06-01'],
        },
        {
            string1    => 'foo2',
            daterange1 => ['2010-01-01', '2010-06-01'],
        },
    ];
    my $sheet = t::lib::DataSheet->new(data => $data);

    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $showcols = [ map { $_->id } $layout->all(exclude_internal => 1) ];

    my $records = GADS::Records->new(
        user    => undef,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    my $return = $records->data_timeline(group => $sheet->columns->{calc1}->id);

    # Normal - should include dateranges that go over the from/to values
    is( @{$return->{items}}, 2, "Correct number of items for group by calc" );
    foreach my $item (@{$return->{items}})
    {
        unlike($item->{content}, qr/(2009|2010)/, "Item does not contain group value");
    }
    is( @{$return->{groups}}, 2, "Correct number of groups for group by calc" );
}

# DST. Check that dates which fall on DST changes are okay.
{
    my $data = [
        {
            string1 => 'foo1',
            date1   => '2018-03-26',
        },
    ];
    my $sheet = t::lib::DataSheet->new(data => $data);

    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $showcols = [ map { $_->id } $layout->all(exclude_internal => 1) ];

    my $records = GADS::Records->new(
        from    => DateTime->now,
        user    => $sheet->user,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    my $return = $records->data_timeline;

    # Normal - should include dateranges that go over the from/to values
    is( @{$return->{items}}, 1, "Correct number of items for timeline with DST value" );
}

# Curval as group field does not show curval items on timeline labels
{
    my $data = [
        {
            string1    => 'foobar1',
        },
        {
            string1    => 'foobar4', # Test ordering
        },
        {
            string1    => 'foobar3',
        },
    ];
    my $curval_sheet = t::lib::DataSheet->new(data => $data, instance_id => 2);
    $curval_sheet->create_records;
    my $schema   = $curval_sheet->schema;

    $data = [
        {
            string1    => 'Foo',
            date1      => '2013-10-10',
            curval1    => 1,
        },{
            string1    => 'Bar',
            date1      => '2014-10-10',
            curval1    => 2,
        },{
            string1    => 'FooBar',
            date1      => '2015-10-10',
            curval1    => [2,3],
        },
    ];

    my $sheet    = t::lib::DataSheet->new(
        data             => $data,
        curval           => 2,
        schema           => $schema,
        curval_field_ids => [$curval_sheet->columns->{string1}->id],
    );
    $sheet->create_records;
    my $layout   = $sheet->layout;


    my $view = GADS::View->new(
        name        => 'Test',
        columns     => [ map { $_->id } $layout->all(exclude_internal => 1) ],
        instance_id => $layout->instance_id,
        layout      => $layout,
        schema      => $schema,
        user        => undef,
    );
    $view->write;
    my $sort_field = $sheet->columns->{curval1}->id .'_'. $curval_sheet->columns->{string1}->id;
    $view->set_sorts([$sort_field], ['asc']);

    my $records = GADS::Records->new(
        user   => undef,
        view   => $view,
        layout => $layout,
        schema => $schema,
    );

    my $return = $records->data_timeline(group => $sheet->columns->{curval1}->id);

    # Normal - should include dateranges that go over the from/to values
    is( @{$return->{items}}, 4, "Correct number of items for group by curval" );

    # Check that the pop-up values include all fields
    foreach my $item_values (map { $_->{values} } @{$return->{items}})
    {
        my $cols = join ',', map { $_->{name} } @$item_values;
        # Should be all non-blank, non-date fields in view
        is($cols, 'string1,curval1,rag1', "Correct columns in pop-up");
    }

    foreach my $item (@{$return->{items}})
    {
        unlike($item->{content}, qr/foobar/, "Item does not contain curval group value");
    }
    is( @{$return->{groups}}, 3, "Correct number of groups for group by curval" );
    my $g = join ',', map { $_->{content} } sort { $a->{order} <=> $b->{order} } @{$return->{groups}};
    is($g, 'foobar1,foobar3,foobar4', "Curval group values correct");
}

# View with no date column. XXX This test doesn't actually check the bug that
# prompted its inclusion, which was a PostgreSQL error as a result of comparing
# an integer (current_id field) with a date. Sqlite does not enforce typing.
{
    my $sheet = t::lib::DataSheet->new;
    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $showcols = [ map { $_->id } $layout->all(exclude_internal => 1) ];

    my $view = GADS::View->new(
        name        => 'Test view',
        columns     => [$sheet->columns->{string1}->id],
        instance_id => $layout->instance_id,
        layout      => $layout,
        schema      => $schema,
        user        => undef,
    );
    $view->write;

    my $records = GADS::Records->new(
        view   => $view,
        from   => DateTime->now,
        user   => undef,
        layout => $layout,
        schema => $schema,
    );

    is( @{$records->data_timeline->{items}}, 0, "No timeline entries for no records" );
}

done_testing();
