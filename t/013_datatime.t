use Test::More; # tests => 1;
use strict;
use warnings;

use List::Util  qw(min max);
use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime
use DateTime;
use JSON qw(encode_json);
use Log::Report;
use GADS::Records;

use lib 't/lib';
use Test::GADS::DataSheet;

# Hide "mistake" messages emitted during tests
dispatcher PERL => 'default', accept => 'ERROR-';

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

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema = $curval_sheet->schema;
my $sheet = Test::GADS::DataSheet->new(data => $data, curval => 2, schema => $schema);

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

# Add a filter and only retrieve one column. Test both normal date column and
# special created date column (the latter test added as Pg does not support
# subquery column in LEAST clause. Sqlite appears to do so, so need to add Pg
# to tests).
my $view;
foreach my $col_id ($layout->column_by_name_short('_created')->id, $columns->{date1}->id)
{
    my $rules = encode_json({
        rules     => [{
            id       => $columns->{string1}->id,
            type     => 'string',
            value    => 'Foo',
            operator => 'equal',
        }],
        # condition => 'AND', # Default
    });

    $view = GADS::View->new(
        name        => 'Test view',
        columns     => [$col_id],
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
}

is( @{$records->data_calendar}, 1, "Filter and single column returns correct number of points to plot for calendar" );
$records->clear;
is( @{$records->data_timeline->{items}}, 1, "Filter and single column returns correct number of points to plot for timeline" );
ok( !@{$records->data_timeline->{groups}}, "No groups when no group_id set");

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

    my $sheet = Test::GADS::DataSheet->new(data => \@data);
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
        $view->set_sorts({fields => [$sheet->columns->{$sort}->id], types => ['asc']});
        $view->write;

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
        my ($min, $max) = _min_max($timeline);

        # Start at 10 April 01:00, rounded down to and includes first record of 10th April. Retrieve 99 records
        # up to and including 17th July, then 49 records back up to and
        # including 21st Feb
        is($min->ymd, '2008-02-21', "Correct first item");
        is($max->ymd, '2008-07-17', "Correct last item");
        # Minimum is one day less than first item, max is 2 days after last
        is($timeline->{min}->ymd, '2008-02-20', "Correct start range of timeline");
        is($timeline->{max}->ymd, '2008-07-19', "Correct end range of timeline");
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
                    is($g->{order}, 3, "foo3 group order correct");
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
        # 1st Jan 2008 01:00, which because searching on days without times is
        # rounded down to 1st Jan, so include that as first record
        from    => DateTime->now,
        # 10 days on is 11th Jan 01:00, so include 11th
        to      => DateTime->now->add(days => 10),
        user    => undef,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    my $timeline = $records->data_timeline;
    my $count = @{$timeline->{items}};
    is($count, 11, "Retrieved correct subset of records for large timeline" );
    my ($min, $max) = _min_max($timeline);
    is($min->ymd, '2008-01-01', "Correct first item");
    is($max->ymd, '2008-01-11', "Correct last item");

    # Test from exactly midnight - should be no rounding
    $records = GADS::Records->new(
        from    => DateTime->new(year => 2008, month => 1, day => 1), # Include 1st Jan
        to      => DateTime->new(year => 2008, month => 1, day => 10), # Up to and include 10th
        user    => undef,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    $timeline = $records->data_timeline;
    $count = @{$timeline->{items}};
    is($count, 10, "Retrieved correct subset of records for large timeline" );
    ($min, $max) = _min_max($timeline);
    is($min->ymd, '2008-01-01', "Correct first item");
    is($max->ymd, '2008-01-10', "Correct last item");
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

    my $sheet = Test::GADS::DataSheet->new(data => $data);
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
    my $data_timeline = $records->data_timeline;
    $items = $data_timeline->{items};
    is( @$items, 2, "Records retrieved exclusive from" );
    like( $items->[0]->{content}, qr/foo2/, "Correct first record for exclusive from" );

    is($data_timeline->{min}->ymd, '2009-03-01', "Correct start range of timeline");
    is($data_timeline->{max}->ymd, '2011-03-01', "Correct end range of timeline");
}

# Various time tests
{
    my $sheet = Test::GADS::DataSheet->new(data => []);
    $sheet->create_records;
    my $schema       = $sheet->schema;
    my $layout       = $sheet->layout;
    my $string_id    = $sheet->columns->{string1}->id;
    my $date_id      = $sheet->columns->{date1}->id;
    my $daterange_id = $sheet->columns->{daterange1}->id;

    # Write records at different times
    for my $count (1..5)
    {
        set_fixed_time("06/0$count/2008 12:30:00", '%m/%d/%Y %H:%M:%S');
        my $record = GADS::Record->new(
            user   => $sheet->user,
            layout => $layout,
            schema => $schema,
        );
        $record->initialise;
        $record->fields->{$string_id}->set_value("Count $count");
        # Set some date fields so that these records are always retrieved
        $record->fields->{$date_id}->set_value("2008-07-05");
        $record->fields->{$daterange_id}->set_value(["2008-01-01", "2008-02-01"]);
        $record->write(no_alerts => 1);
    }

    my $showcols = [
        $layout->column_by_name_short('_version_datetime')->id,
        $sheet->columns->{date1}->id,
        $sheet->columns->{daterange1}->id,
    ];

    my $records = GADS::Records->new(
        from    => DateTime->new(year => 2008, month => 06, day => 03),
        user    => $sheet->user,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    is( @{$records->data_timeline->{items}}, 15, "All items on timeline" );

    # Created times are now stored in UTC
    $records->clear;
    $records->from(DateTime->new(year => 2008, month => 06, day => 03, hour => 12, minute => 30));
    $records->to(DateTime->new(year => 2008, month => 12, day => 01));
    $records->exclusive('from');
    # Should retrieve 5 date1 fields plus 2 version fields
    is( @{$records->data_timeline->{items}}, 7, "Records retrieved exclusive" );

    $records->clear;
    $records->from(DateTime->new(year => 2007, month => 01, day => 01));
    $records->to(DateTime->new(year => 2008, month => 06, day => 03, hour => 12, minute => 30));
    $records->exclusive('to');
    is( @{$records->data_timeline->{items}}, 7, "Records retrieved exclusive" );

    # Reset
    set_fixed_time('01/01/2008 01:00:00', '%m/%d/%Y %H:%M:%S');
}

# Test set of records all after today, with only from set
{
    my $data = [
        {
            string1 => 'foo1',
            date1   => '2009-01-01',
        },
        {
            string1 => 'foo2',
            date1   => '2008-03-04',
        },
        {
            string1 => 'foo3',
            date1   => '2008-10-04',
        },
    ];

    my $sheet = Test::GADS::DataSheet->new(data => $data);
    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $date1    = $sheet->columns->{date1}->id;
    my $showcols = [ map { $_->id } $layout->all(exclude_internal => 1) ];

    my $records = GADS::Records->new(
        from    => DateTime->now,
        user    => undef,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    # Normal - should include all records
    my $tl = $records->data_timeline;
    is( @{$tl->{items}}, 3, "Records retrieved inclusive" );
    is($tl->{min}->ymd, '2008-03-03', "Correct start range of timeline");
    is($tl->{max}->ymd, '2009-01-03', "Correct end range of timeline");
}

# Test permissions
{
    my $data = [
        {
            string1    => 'Foo',
            enum1      => 1,
            date1      => '2010-01-10',
            daterange1 => ['2009-01-01', '2009-06-01'],
        },
        {
            string1    => 'Bar',
            enum1      => 2,
            date1      => '2010-02-10',
            daterange1 => ['2009-02-01', '2009-05-01'],
        },
    ];

    my $sheet = Test::GADS::DataSheet->new(data => $data, user_permission_override => 0);
    $sheet->create_records;
    my $schema  = $sheet->schema;
    my $layout  = $sheet->layout;
    my $string1 = $sheet->columns->{string1};
    $string1->set_permissions({$sheet->group->id => []});
    $string1->write;
    $layout->clear;

    my $records = GADS::Records->new(
        user    => $sheet->user_normal1,
        layout  => $layout,
        schema  => $schema,
    );

    # Normal - should include dateranges that go over the from/to values
    my @items = @{$records->data_timeline->{items}};
    # 4 items for each record (2 date fields, plus created and edited)
    is(@items, 8, "Correct number of timeline items");
    foreach my $item (@items)
    {
        unlike($item->{content}, qr/(Foo|Bar)/, "String value not in restricted item content");
        my $in_values = grep $_->{name} eq 'string1', @{$item->{values}};
        ok(!$in_values, "String value not in restricted item values");
    }

    # Remove date field permissions and check now excluded
    my $date1 = $sheet->columns->{date1};
    $date1->set_permissions({$sheet->group->id => []});
    $date1->write;
    $layout->clear;
    $records = GADS::Records->new(
        user    => $sheet->user_normal1,
        layout  => $layout,
        schema  => $schema,
    );

    @items = @{$records->data_timeline->{items}};
    # 3 items for each record (1 date field, plus created and edited)
    is(@items, 6, "Correct number of timeline items with date field removed");
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

    my $year = 86400 * 366; # 2008 is a leap year
    my $sheet = Test::GADS::DataSheet->new(
        data             => $data,
        calc_code        => "function evaluate (L1daterange1) \n return L1daterange1.from.epoch - $year \nend",
        calc_return_type => 'date',
    );

    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $showcols = [ map { $_->id } $layout->all(exclude_internal => 1) ];

    my $records = GADS::Records->new(
        from    => DateTime->new(year => 2007, month => 01, day => 01),
        to      => DateTime->new(year => 2008, month => 12, day => 01),
        user    => undef,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    # Normal - should include dateranges that go over the from/to values
    my @items = @{$records->data_timeline->{items}};
    is( @items, 1, "Records retrieved inclusive" );
    my $item = $items[0];
    is($item->{content}, "foo1 (calc1)", "Calc content for item");
    my $time = DateTime->new(year => 2008, month => 1, day => 1);
    is($item->{start}, $time->epoch * 1000, "Correct date for item");
}

# No records to display
{
    my $sheet = Test::GADS::DataSheet->new(data => []);
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
    is($records->data_timeline->{min}, undef, "No min value for no items on timeline");
    is($records->data_timeline->{max}, undef, "No max value for no items on timeline");
}

# No records with date fields to display
{
    my $sheet = Test::GADS::DataSheet->new(data => [{ string1 => 'Foobar' }]);
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

    is( @{$records->data_timeline->{items}}, 0, "No timeline entries for no records" );
    is($records->data_timeline->{min}, undef, "No min value for no items on timeline");
    is($records->data_timeline->{max}, undef, "No max value for no items on timeline");
}

# No records with date fields to display
{
    my @data;
    my $now = DateTime->now;
    my $early = DateTime->now->subtract(years => 10);
    foreach my $count (1..300)
    {
        push @data, {
            date1      => $now->clone,
            daterange1 => [$early->ymd, $early->clone->add(months => 1)->ymd],
        };
        $now->add(days => 1);
    }
    my $sheet = Test::GADS::DataSheet->new(data => \@data);
    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $showcols = [ map { $_->id } $layout->all(exclude_internal => 1) ];

    my $records = GADS::Records->new(
        from    => DateTime->now->add(days => 100),
        user    => $sheet->user,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    my $return = $records->data_timeline;

    is( @{$return->{items}}, 148, "Correct number of timeline items" );
    # Start retrieval from today (2008-01-01) + 100 = 2008-04-10. Time is 1am,
    # which is rounded down to midnight for a date-only field, so first
    # retrieved record will be 2008-04-10. Take 100 records going forward,
    # including the start point. Last retrieved record should not be included,
    # in case the record to be retrieved after that is the same date.  Last
    # record is therefore 2008-04-10 + another 98 days = 2008-07-17 (99 records
    # total, including first, excluding last)
    my ($min, $max) = _min_max($return);
    is($max->ymd, '2008-07-17', "Date of latest item correct");
    # Max of range is last value, plus a day in case of daterange padding (one
    # day is added to a daterange to make it span the whole day), plus a day
    # for padding.
    is($return->{max}->ymd, '2008-07-19', "Max value aligns with end of records");

    # Min value starts with min of previous, then goes back 50 items/days, not
    # including the final item.
    is($min->ymd, '2008-02-21', "Date of earliest item correct");
    is($return->{min}->ymd, '2008-02-20', "Min value is same as start of records");
    # 2008-01-01 + 100 days + 100 days + 2 days
}

# No records with date fields to display
{
    my $sheet = Test::GADS::DataSheet->new;
    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $showcols = [ map { $_->id } $layout->all(exclude_internal => 1) ];

    my $from = DateTime->now->subtract(years => 1);
    my $to   = DateTime->now->add(years => 2);

    my $records = GADS::Records->new(
        from    => $from,
        to      => $to,
        user    => undef,
        columns => $showcols,
        layout  => $layout,
        schema  => $schema,
    );

    my $return = $records->data_timeline;

    # One record (Bar) with 2 date fields (date1 and daterange1)
    is( @{$return->{items}}, 2, "Correct number of timeline items" );
    is($return->{min}, $from, "Min value is same as start of records");
    is($return->{max}, $to, "Max value is same as end of records");
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
    my $sheet = Test::GADS::DataSheet->new(data => $data);

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

    # We didn't specify a from or a to, so the timeline will just plot whatever
    # items it is given
    is($return->{min}, undef, "No min value for no range specification");
    is($return->{max}, undef, "No max value for no range specification");
}

# Multiple items in group field, ordered correctly
{
    # Create a set of data where a multivalue record is in the middle of the
    # right-half of the timeline. The multivalue record contains 2 values that
    # are at the top and bottom of the grouped items. All the other values of
    # the timeline are in the middle of the grouping. Because the multivalue
    # record is in the middle of the date range, both should show on the
    # grouping, one at the begninning and one at the end.
    my $data = [];
    my $date = DateTime->new(year => 2010, month => 1, day => 1);
    for my $i (1..100)
    {
        push @$data, {
            string1 => 'foo2',
            enum1   => [3],
            date1   => $date->add(days => 1)->ymd,
        };
    }
    push @$data,{
            string1 => 'foo1',
            enum1   => [1,4],
            date1   => '2010-07-01',
    };
    $date = DateTime->new(year => 2010, month => 8, day => 1);
    for my $i (1..120)
    {
        push @$data, {
            string1 => 'foo2',
            enum1   => [2],
            date1   => $date->add(days => 1)->ymd,
        };
    }

    my $sheet = Test::GADS::DataSheet->new(data => $data, multivalue => 1, enumvals_count => 4);

    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $enum1    = $sheet->columns->{enum1};

    my $view = GADS::View->new(
        name        => 'Test',
        columns     => [ $sheet->columns->{string1}->id, $sheet->columns->{date1}->id ],
        instance_id => $layout->instance_id,
        layout      => $layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view->set_sorts({fields => [$enum1->id], types => ['asc']});
    $view->write;

    my $records = GADS::Records->new(
        view    => $view,
        user    => undef,
        layout  => $layout,
        from    => DateTime->new(year => 2010, month => 6, day => 1),
        schema  => $schema,
    );

    my $return = $records->data_timeline(group => $enum1->id);

    # 148 normal results as per other tests plus 1 extra result for multivalue
    is( @{$return->{items}}, 149, "Correct number of items for group ordering" );

    # Check that the groups are in the right order. Because we are ordering by
    # the enumvals (foo1, foo2, foo3) then number in the value should match the
    # grouping order
    my @groups = @{$return->{groups}};
    is( @groups, 4, "Correct number of groups" );

    ok( $_->{content} eq "foo$_->{order}", "Ordering matches content" )
        foreach @groups;
}

# DST. Check that dates which fall on DST changes are okay.
{
    my $data = [
        {
            string1 => 'foo1',
            date1   => '2018-03-26',
        },
    ];
    my $sheet = Test::GADS::DataSheet->new(data => $data);

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
        {
            string1    => '', # Test blank
        },
    ];
    my $curval_sheet = Test::GADS::DataSheet->new(data => $data, instance_id => 2);
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
        },{
            string1    => 'Blank curval',
            date1      => '2015-03-10',
        },{
            string1    => 'Blank curval string',
            date1      => '2015-04-10',
            curval1    => 4,
        },
    ];

    my $sheet    = Test::GADS::DataSheet->new(
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
    my $sort_field = $sheet->columns->{curval1}->id .'_'. $curval_sheet->columns->{string1}->id;
    $view->set_sorts({fields => [$sort_field], types => ['asc']});
    $view->write;

    my $records = GADS::Records->new(
        user   => undef,
        view   => $view,
        layout => $layout,
        schema => $schema,
    );

    my $return = $records->data_timeline(group => $sheet->columns->{curval1}->id);

    # Normal - should include dateranges that go over the from/to values
    is( @{$return->{items}}, 6, "Correct number of items for group by curval" );

    foreach my $item (@{$return->{items}})
    {
        ok($item->{group}, "Item has a group defined");
        # Check that the pop-up values include all fields
        # If the curval is blank, then don't expect it to appear in the pop-up
        my $expected = $item->{current_id} == 8 || $item->{current_id} == 9 ? 'string1,rag1' : 'string1,curval1,rag1';
        my $cols = join ',', map { $_->{name} } @{$item->{values}};
        # Should be all non-blank, non-date fields in view
        is($cols, $expected, "Correct columns in pop-up");
    }

    foreach my $item (@{$return->{items}})
    {
        unlike($item->{content}, qr/foobar/, "Item does not contain curval group value");
    }
    is( @{$return->{groups}}, 4, "Correct number of groups for group by curval" );
    my $g = join ',', map { $_->{content} } sort { $a->{order} <=> $b->{order} } @{$return->{groups}};
    is($g, '&lt;blank&gt;,foobar1,foobar3,foobar4', "Curval group values correct");
}

# Test ranges of timeline when only specifying from, with only dates from a
# curval. This is rather an edge-case, but has caused problems in the past.
{
    my $data = [
        {
            string1 => 'foo1',
            curval1 => 1,
        },
        {
            string1 => 'foo1',
            curval1 => 2,
        },
    ];
    my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
    $curval_sheet->create_records;
    my $schema = $curval_sheet->schema;
    my $sheet = Test::GADS::DataSheet->new(data => $data, curval => 2, schema => $schema);
    $sheet->create_records;

    my $layout = $sheet->layout;
    my $columns = $sheet->columns;

    my $records = GADS::Records->new(
        from    => DateTime->new(year => 2011, month => 06, day => 01),
        user    => $sheet->user,
        columns => [$columns->{string1}->id, $columns->{curval1}->id],
        layout  => $layout,
        schema  => $schema,
    );

    my $return = $records->data_timeline;
    is($return->{min}->ymd, '2008-05-03', "Correct start range of timeline");
    is($return->{max}->ymd, '2014-10-12', "Correct end range of timeline");

    # Normal - should include dateranges that go over the from/to values
    is( @{$return->{items}}, 4, "Correct number of items for timeline with only curval dates" );
}

# Test ranges of timeline when only specifying from, with only dates from a
# curval. This is rather an edge-case, but has caused problems in the past.
{
    my @curval_data;
    my @data;
    my $start = DateTime->now;

    # Create a set of data around today's date (1/1/2008) and a set of data
    # much before then. Only the set of data around today's date should be
    # retrieved
    for my $count (1..300)
    {
        push @curval_data, {
            string1 => "Foo $count",
            date1   => $start->ymd,
        };
        $start->add(days => 1);
        push @data, {
            string1 => "Bar $count",
            curval1 => $count,
        };
    }
    $start = DateTime->new(year => 1990, month => 1, day => 1);
    for my $count (1..100)
    {
        push @curval_data, {
            string1 => "Foo $count",
            date1   => $start->ymd,
        };
        $start->add(days => 1);
        push @data, {
            string1 => "Bar $count",
            curval1 => $count + 300,
        };
    }

    my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, data => \@curval_data);
    $curval_sheet->create_records;
    my $schema = $curval_sheet->schema;
    my $sheet = Test::GADS::DataSheet->new(data => \@data, curval => 2, schema => $schema);
    $sheet->create_records;

    my $layout = $sheet->layout;
    my $columns = $sheet->columns;

    my $view = GADS::View->new(
        name        => 'Test view',
        columns     => [$columns->{string1}->id, $columns->{curval1}->id],
        instance_id => $layout->instance_id,
        layout      => $layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view->set_sorts({fields => [$sheet->columns->{string1}->id], types => ['asc']});
    $view->write;

    my $records = GADS::Records->new(
        view    => $view,
        from    => DateTime->now->add(days => 100), # 10th April 2008
        user    => $sheet->user,
        layout  => $layout,
        schema  => $schema,
    );

    my $return = $records->data_timeline;
    # Normal - should include dateranges that go over the from/to values
    is( @{$return->{items}}, 148, "Correct number of items for timeline with only curval dates" );
    my ($min, $max) = _min_max($return);
    # Start 10th April 2008 01:00 (rounded down, included) + 100 days, do not
    # include final record = 17th July 2008
    is($max->ymd, '2008-07-17', "Correct last item");
    # Plus 1 day for width plus 1 day to show range
    is($return->{max}->ymd, '2008-07-19', "Correct end range of timeline");
    # Min starts at 10th April 2008 01:00 (not included) - 50 days = 20th
    # February 2008 (not included).
    is($min->ymd, '2008-02-21', "Correct first item");
    # Minus 1 day to show range = 20th Feb
    is($return->{min}->ymd, '2008-02-20', "Correct start range of timeline");

}

# View with no date column. XXX This test doesn't actually check the bug that
# prompted its inclusion, which was a PostgreSQL error as a result of comparing
# an integer (current_id field) with a date. Sqlite does not enforce typing.
{
    my $sheet = Test::GADS::DataSheet->new;
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

# Test to check that date fields in a curval that the user does not have access
# to are not included in the timeline calculations.
# Assume a "from" date of 2010-01-01. Create 200 records starting at that date,
# with normal dates ascending from there and curval dates the inverse. The
# curval dates are not accessible by the user, and should therefore not affect
# the records pulled.
{
    my @data;
    my $start = DateTime->new(year => 2010, month => 1, day => 1);
    my $from = $start->clone;

    # Create a set of data around today's date (1/1/2008) and a set of data
    # much before then. Only the set of data around today's date should be
    # retrieved
    for my $count (1..200)
    {
        push @data, {
            string1 => "Bar $count",
            date1   => $start->ymd,
            curval1 => $count,
        };
        $start->add(days => 1);
    }
    my @curval_data;
    for my $count (1..200)
    {
        push @curval_data, {
            string1 => "Foo $count",
            date1   => $start->ymd,
        };
        $start->subtract(days => 1);
    }

    my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, data => \@curval_data, user_permission_override => 0, multivalue => 1);
    $curval_sheet->create_records;
    my $curval_date = $curval_sheet->columns->{date1};
    $curval_date->set_permissions({});
    $curval_date->write;
    $curval_sheet->layout->clear;

    my $schema = $curval_sheet->schema;
    my $sheet = Test::GADS::DataSheet->new(data => \@data, curval => 2, schema => $schema, user_permission_override => 0, multivalue => 1);
    $sheet->create_records;

    my $layout = $sheet->layout;
    $layout->clear;
    $layout->user($sheet->user_normal1);
    $curval_sheet->layout->user($sheet->user_normal1);

    my $columns = $sheet->columns;

    my $records = GADS::Records->new(
        from    => $from,
        user    => $sheet->user_normal1,
        layout  => $curval_sheet->layout,
        schema  => $schema,
    );

    my $return = $records->data_timeline;
    # No records after the "from" are retrieved, as we don't have permission to
    # them (date1 of the curval sheet only). The other dates available (created
    # date) are all the same and therefore not retrieved as we only use values
    # after the minimum date retrieved (see comments in GADS::Records)
    is( @{$return->{items}}, 0, "Correct number of items for timeline for curval table" );

    $records = GADS::Records->new(
        from    => $from,
        user    => $sheet->user_normal1,
        layout  => $layout,
        schema  => $schema,
    );

    $return = $records->data_timeline;
    # Full set of records after the from date, nothing before as above
    is( @{$return->{items}}, 99, "Correct number of items for timeline with no access to curval dates" );
    # Min retrieved is 2010-01-01 minus one day for padding
    is($return->{min}->ymd, '2009-12-31', "Correct start range of timeline");
    # 1st Jan 2010 + 98 days (99 records total) = 9th April 2010, plus 1 day for width plus 1 day to show range
    is($return->{max}->ymd, '2010-04-11', "Correct end range of timeline");
}

done_testing();

sub _min_max
{   my $timeline = shift;
    my @items = @{$timeline->{items}};
    my $max = max map $_->{start}, @items;
    my $max_dt = DateTime->from_epoch(epoch => $max / 1000);
    my $min = min map $_->{start}, @items;
    my $min_dt = DateTime->from_epoch(epoch => $min / 1000);
    ($min_dt, $max_dt);
}
