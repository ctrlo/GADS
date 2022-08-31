use Test::More; # tests => 1;
use strict;
use warnings;

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime

use JSON qw(encode_json);
use Log::Report;
use GADS::Graph;
use GADS::Graph::Data;
use GADS::Records;
use GADS::RecordsGraph;

use lib 't/lib';
use Test::GADS::DataSheet;

set_fixed_time('01/01/2015 12:00:00', '%m/%d/%Y %H:%M:%S');

foreach my $multivalue (0..1)
{
    my $linked_value = 10; # See below
    my $linked_enum  = 13; # ID for foo1

    my $data = [
        {
            # No integer1 or enum1 - the value will be taken from a linked record ($linked_value).
            # integer1 will be 10, enum1 will be equivalent of 7.
            string1    => 'Foo',
            date1      => '2013-10-10',
            daterange1 => ['2014-03-21', '2015-03-01'],
            tree1      => 'tree1',
            curval1    => 1,
            integer2   => 8,
        },{
            string1    => $multivalue ? ['Bar', 'FooBar'] : 'Bar',
            date1      => '2014-10-10',
            daterange1 => ['2010-01-04', '2011-06-03'],
            integer1   => 150, # Changed to 15
            enum1      => 7,
            tree1      => 'tree1',
            curval1    => 2,
            integer2   => 80, # Changed to 8
        },{
            string1    => 'Bar',
            integer1   => 35,
            enum1      => 8,
            tree1      => 'tree1',
            curval1    => 1,
            integer2   => 24,
        },{
            string1    => 'FooBar',
            date1      => '2016-10-10',
            daterange1 => ['2009-01-04', '2017-06-03'],
            integer1   => 20,
            enum1      => $multivalue ? [8, 9] : 8,
            tree1      => 'tree1',
            curval1    => 2,
            integer2   => 13,
        },
    ];

    my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, multivalue => $multivalue);
    $curval_sheet->create_records;
    my $schema  = $curval_sheet->schema;

    # Make an edit to a curval record, to make sure that only the latest
    # version is used in the graphs
    my $cr = GADS::Record->new(
        user   => $curval_sheet->user,
        layout => $curval_sheet->layout,
        schema => $schema,
    );
    $cr->find_current_id(2);
    $cr->fields->{$curval_sheet->columns->{integer1}->id}->set_value(132);
    $cr->write(no_alerts => 1);

    my $sheet   = Test::GADS::DataSheet->new(
        data               => $data,
        schema             => $schema,
        curval             => 2,
        multivalue         => $multivalue,
        column_count       => {integer => 2},
        multivalue_columns => { enum => 1, string => 1 },
    );
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;
    $sheet->create_records;

    my $autocur = $curval_sheet->add_autocur(
        refers_to_instance_id => 1,
        related_field_id      => $sheet->columns->{curval1}->id,
        curval_field_ids      => [$sheet->columns->{string1}->id],
    );

    my $calc2 = GADS::Column::Calc->new(
        schema         => $schema,
        user           => $sheet->user,
        layout         => $layout,
        name           => 'calc2',
        return_type    => 'integer',
        code           => "function evaluate (L1integer2) \n return {L1integer2, L1integer2 * 2} \nend",
        multivalue     => 1,
    );
    $calc2->set_permissions({$sheet->group->id => $sheet->default_permissions});
    $calc2->write;
    $layout->clear;

    # Make an edit to a curval record, to make sure that only the latest
    # version is used in the graphs
    my $r = GADS::Record->new(
        user   => $sheet->user,
        layout => $sheet->layout,
        schema => $schema,
    );
    $r->find_current_id(4);
    $r->fields->{$sheet->columns->{integer1}->id}->set_value(15);
    $r->fields->{$sheet->columns->{integer2}->id}->set_value(8);
    $r->write(no_alerts => 1);

    # Add linked record sheet, which will contain the integer1 value for the first
    # record of the first sheet
    my $sheet2 = Test::GADS::DataSheet->new(data => [], instance_id => 3, schema => $schema);
    my $layout2 = $sheet2->layout;
    my $columns2 = $sheet2->columns;

    # Set link field of first sheet integer1 to integer1 of second sheet
    $columns->{integer1}->link_parent_id($columns2->{integer1}->id);
    $columns->{integer1}->write;
    $columns->{enum1}->link_parent_id($columns2->{enum1}->id);
    $columns->{enum1}->write;
    $layout->clear; # Need to rebuild columns to get link_parent built

    # Create the single record of the second sheet, which will contain the single
    # integer1 value
    my $child = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout2,
        schema => $schema,
    );
    $child->initialise;
    $child->fields->{$columns2->{integer1}->id}->set_value($linked_value);
    $child->fields->{$columns2->{enum1}->id}->set_value($linked_enum);
    $child->write(no_alerts => 1);
    # Set the first record of the first sheet to take its value from the linked sheet
    my $parent = GADS::Records->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    )->single;
    #$parent->linked_id($child->current_id);
    $parent->write_linked_id($child->current_id);

    my $graphs = [
        {
            name         => 'String x-axis, integer sum y-axis',
            type         => 'bar',
            x_axis       => $columns->{string1}->id,
            y_axis       => $columns->{integer1}->id,
            y_axis_stack => 'sum',
            data         => [[ 50, 10, $multivalue ? 35 : 20 ]],
        },
        {
            name         => 'String x-axis, multi-integer sum y-axis',
            type         => 'bar',
            x_axis       => $columns->{string1}->id,
            y_axis       => $calc2->id, #$columns->{calc2}->id,
            y_axis_stack => 'sum',
            data         => [[ 96, 24, $multivalue ? 63 : 39 ]],
            xlabels      => [qw/Bar Foo FooBar/],
        },
        {
            name         => 'String x-axis, multi-integer sum y-axis, filtered',
            type         => 'bar',
            x_axis       => $columns->{string1}->id,
            y_axis       => $calc2->id, #$columns->{calc2}->id,
            y_axis_stack => 'sum',
            data         => [[ 72, 26 ]],
            xlabels      => [qw/Bar FooBar/],
            rules => [
                {
                    id       => $calc2->id,
                    type     => 'string',
                    value    => '20',
                    operator => 'greater',
                }
            ],
        },
        {
            name         => 'Integer x-axis, count y-axis',
            type         => 'bar',
            x_axis       => $columns->{integer2}->id,
            y_axis       => $columns->{string1}->id,
            y_axis_stack => 'count',
            data         => [[ 1, 1, 2 ]],
            xlabels      => [qw/13 24 8/],
        },
        {
            name         => 'String x-axis, integer sum y-axis as percent',
            type         => 'bar',
            x_axis       => $columns->{string1}->id,
            y_axis       => $columns->{integer1}->id,
            y_axis_stack => 'sum',
            as_percent   => 1,
            data         => $multivalue ? [[ 53, 11, 37 ]] : [[ 63, 13, 25 ]],
        },
        {
            name         => 'Pie as percent',
            type         => 'pie',
            x_axis       => $columns->{string1}->id,
            y_axis       => $columns->{integer1}->id,
            y_axis_stack => 'sum',
            as_percent   => 1,
            data         => $multivalue
                ? [[[ 'Bar', 53 ], [ 'Foo', 11 ], ['FooBar', 37 ]]]
                : [[[ 'Bar', 63 ], [ 'Foo', 13 ], ['FooBar', 25 ]]],
        },
        {
            name         => 'Pie with blank value',
            type         => 'pie',
            x_axis       => $columns->{date1}->id,
            y_axis       => $columns->{string1}->id,
            y_axis_stack => 'count',
            # Jqplot seems to want labels encoded only for pie graphs
            data         => [[['2013-10-10', 1], ['2014-10-10', 1], ['2016-10-10', 1], ['&lt;no value&gt;', 1]]],
        },
        {
            name         => 'String x-axis, integer sum y-axis with view filter',
            type         => 'bar',
            x_axis       => $columns->{string1}->id,
            y_axis       => $columns->{integer1}->id,
            y_axis_stack => 'sum',
            data         => $multivalue ? [[ 15, 10, 15 ]] : [[ 15, 10 ]],
            rules => [
                {
                    id       => $columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo1',
                    operator => 'equal',
                }
            ],
        },
        {
            name            => 'Date range x-axis, integer sum y-axis',
            type            => 'bar',
            x_axis          => $columns->{daterange1}->id,
            x_axis_grouping => 'year',
            y_axis          => $columns->{integer1}->id,
            y_axis_stack    => 'sum',
            data            => [[ 20, 35, 35, 20, 20, 30, 30, 20, 20 ]],
        },
        {
            name            => 'Date range x-axis, integer sum y-axis, limited time period by dates',
            type            => 'bar',
            x_axis          => $columns->{daterange1}->id,
            x_axis_grouping => 'year',
            y_axis          => $columns->{integer1}->id,
            y_axis_stack    => 'sum',
            from            => DateTime->new(year => 2013, month => 8, day => 15),
            to              => DateTime->new(year => 2016, month => 6, day => 15),
            data            => [[ 20, 30, 30, 20 ]],
            xlabels         => [qw/2013 2014 2015 2016/],
        },
        {
            name            => 'Date range x-axis, integer sum y-axis, limited time period by length',
            type            => 'bar',
            x_axis          => $columns->{daterange1}->id,
            x_axis_range    => 6,
            y_axis          => $columns->{integer1}->id,
            y_axis_stack    => 'sum',
            data            => [[ 30, 30, 30, 20, 20, 20, 20 ]],
            xlabels         => ['January 2015', 'February 2015', 'March 2015', 'April 2015', 'May 2015', 'June 2015', 'July 2015'],
        },
        {
            name            => 'Date range x-axis, integer sum y-axis, limited time period by length negative',
            type            => 'bar',
            x_axis          => $columns->{daterange1}->id,
            x_axis_range    => -6,
            y_axis          => $columns->{integer1}->id,
            y_axis_stack    => 'sum',
            data            => [[ 30, 30, 30, 30, 30, 30, 30 ]],
            xlabels         => ['July 2014', 'August 2014', 'September 2014', 'October 2014', 'November 2014', 'December 2014', 'January 2015'],
        },
        {
            name            => 'Date range x-axis from curval, integer sum y-axis',
            type            => 'bar',
            x_axis          => $curval_sheet->columns->{daterange1}->id,
            x_axis_link     => $columns->{curval1}->id,
            x_axis_grouping => 'year',
            y_axis          => $columns->{integer1}->id,
            y_axis_stack    => 'sum',
            data            => [[ 35, 0, 0, 0, 45, 45 ]],
        },
        {
            name            => 'Date range x-axis from curval, integer sum y-axis, group by curval',
            type            => 'bar',
            x_axis          => $curval_sheet->columns->{daterange1}->id,
            x_axis_link     => $columns->{curval1}->id,
            x_axis_grouping => 'year',
            y_axis          => $columns->{integer1}->id,
            y_axis_stack    => 'sum',
            group_by        => $columns->{curval1}->id,
            data            => [[ 0, 0, 0, 0, 45, 45 ], [ 35, 0, 0, 0, 0, 0 ]],
            labels       => [
                'Foo, 50, foo1, , 2014-10-10, 2012-02-10 to 2013-06-15, , , c_amber, 2012',
                'Bar, 132, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
            ],
        },
        {
            name            => 'Date x-axis, integer count y-axis',
            type            => 'bar',
            x_axis          => $columns->{date1}->id,
            x_axis_grouping => 'year',
            y_axis          => $columns->{string1}->id,
            y_axis_stack    => 'count',
            data            => [[ 1, 1, 0, 1 ]],
        },
        {
            name            => 'Date x-axis, integer count y-axis, limited range',
            type            => 'bar',
            x_axis          => $columns->{date1}->id,
            x_axis_grouping => 'year',
            y_axis          => $columns->{string1}->id,
            y_axis_stack    => 'count',
            from            => DateTime->new(year => 2014, month => 1, day => 15),
            to              => DateTime->new(year => 2016, month => 12, day => 15),
            data            => [[ 1, 0, 1 ]],
            xlabels         => [qw/2014 2015 2016/],
        },
        {
            name            => 'Date x-axis, integer sum y-axis, limited range by length',
            type            => 'bar',
            x_axis          => $columns->{date1}->id,
            x_axis_range    => 120,
            y_axis          => $columns->{integer1}->id,
            y_axis_stack    => 'sum',
            data            => [[ 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]],
            xlabels         => [qw/2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025/],
        },
        {
            name            => 'Date x-axis, integer sum y-axis, limited range by length, grouped',
            type            => 'bar',
            x_axis          => $columns->{date1}->id,
            x_axis_range    => -120,
            y_axis          => $columns->{integer1}->id,
            y_axis_stack    => 'sum',
            group_by        => $columns->{enum1}->id,
            data            => [
                [ 0, 0, 0, 0, 0, 0, 0, 0, 10, 15, 0 ],
            ],
            xlabels         => [qw/2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015/],
            labels          => [qw/foo1/],
        },
        {
            name            => 'Date x-axis, integer sum y-axis, limited range by dates, grouped',
            type            => 'bar',
            x_axis          => $columns->{date1}->id,
            x_axis_grouping => 'year',
            x_axis_range    => 'custom',
            from            => DateTime->new(year => 2012, month => 1, day => 15),
            to              => DateTime->new(year => 2018, month => 12, day => 15),
            y_axis          => $columns->{integer1}->id,
            y_axis_stack    => 'sum',
            group_by        => $columns->{enum1}->id,
            data            => $multivalue
            ? [
                [ 0, 0, 0, 0, 20, 0, 0 ],
                [ 0, 0, 0, 0, 20, 0, 0 ],
                [ 0, 10, 15, 0, 0, 0, 0 ],
            ]
            : [
                [ 0, 0, 0, 0, 20, 0, 0 ],
                [ 0, 10, 15, 0, 0, 0, 0 ],
            ],
            xlabels         => [qw/2012 2013 2014 2015 2016 2017 2018/],
            labels          => $multivalue ? [qw/foo3 foo2 foo1/] : [qw/foo2 foo1/],
        },
        {
            name         => 'String x-axis, sum y-axis, group by enum',
            type         => 'bar',
            x_axis       => $columns->{string1}->id,
            y_axis       => $columns->{integer1}->id,
            y_axis_stack => 'sum',
            group_by     => $columns->{enum1}->id,
            data         => $multivalue ? [[ 0, 0, 20 ], [ 35, 0, 20 ], [ 15, 10, 15 ]] : [[ 35, 0, 20 ], [ 15, 10, 0 ]],
        },
        {
            name         => 'String x-axis, sum y-axis, group by enum as percent',
            type         => 'bar',
            x_axis       => $columns->{string1}->id,
            y_axis       => $columns->{integer1}->id,
            y_axis_stack => 'sum',
            group_by     => $columns->{enum1}->id,
            as_percent   => 1,
            data         => $multivalue ? [[ 0, 0, 36 ], [ 70, 0, 36 ], [ 30, 100, 27 ]] : [[ 70, 0, 100 ], [ 30, 100, 0 ]],
        },
        {
            name         => 'Filter on multi-value enum',
            type         => 'bar',
            x_axis       => $columns->{string1}->id,
            y_axis       => $columns->{integer1}->id,
            y_axis_stack => 'count',
            data         => [[ 1, 1 ]],
            rules => [
                {
                    id       => $columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo2',
                    operator => 'equal',
                },
                {
                    id       => $columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo3',
                    operator => 'equal',
                }
            ],
            condition => 'OR',

        },
        {
            name         => 'Curval on x-axis',
            type         => 'bar',
            x_axis       => $columns->{curval1}->id,
            y_axis       => $columns->{integer1}->id,
            y_axis_stack => 'sum',
            data         => [[ 35, 45 ]],
        },
        {
            name         => 'Field from curval on x-axis',
            type         => 'bar',
            x_axis       => $curval_sheet->columns->{string1}->id,
            x_axis_link  => $columns->{curval1}->id,
            y_axis       => $columns->{integer1}->id,
            y_axis_stack => 'sum',
            data         => [[ 35, 45 ]],
            xlabels      => ['Bar', 'Foo'],
        },
        {
            name         => 'Enum field from curval on x-axis',
            type         => 'bar',
            x_axis       => $curval_sheet->columns->{enum1}->id,
            x_axis_link  => $columns->{curval1}->id,
            y_axis       => $columns->{integer1}->id,
            y_axis_stack => 'sum',
            data         => [[ 45, 35 ]],
            xlabels      => ['foo1', 'foo2'],
        },
        {
            name         => 'Enum field from curval on x-axis, enum on y, with filter',
            type         => 'bar',
            x_axis       => $curval_sheet->columns->{enum1}->id,
            x_axis_link  => $columns->{curval1}->id,
            y_axis       => $columns->{tree1}->id,
            y_axis_stack => 'count',
            data         => [[ 1, 1 ]],
            xlabels      => ['foo1', 'foo2'],
            rules => [
                {
                    id       => $columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo1',
                    operator => 'equal',
                }
            ],
        },
        {
            name         => 'Enum field from curval on x-axis, with filter on whole curval',
            type         => 'bar',
            x_axis       => $curval_sheet->columns->{enum1}->id,
            x_axis_link  => $columns->{curval1}->id,
            y_axis       => $columns->{tree1}->id,
            y_axis_stack => 'count',
            data         => [[ 2 ]],
            xlabels      => ['foo1'],
            rules => [
                {
                    id       => $columns->{curval1}->id,
                    type     => 'string',
                    value    => '1',
                    operator => 'equal',
                }
            ],
        },
        {
            name         => 'Curval on x-axis grouped by enum',
            type         => 'bar',
            x_axis       => $columns->{curval1}->id,
            y_axis       => $columns->{integer1}->id,
            y_axis_stack => 'sum',
            group_by     => $columns->{enum1}->id,
            data         => $multivalue ? [[ 20, 0 ], [ 20, 35 ], [ 15, 10 ]] : [[ 20, 35 ], [ 15, 10 ]],
        },
        {
            name         => 'Enum on x-axis, filter by enum',
            type         => 'bar',
            x_axis       => $columns->{enum1}->id,
            y_axis       => $columns->{string1}->id,
            y_axis_stack => 'count',
            data         => $multivalue ? [[ 2, 2, 1 ]] : [[ 2, 2 ]],
            rules => [
                {
                    id       => $columns->{tree1}->id,
                    type     => 'string',
                    value    => 'tree1',
                    operator => 'equal',
                }
            ],
        },
        {
            name         => 'Curval on x-axis, filter by enum',
            type         => 'bar',
            x_axis       => $columns->{curval1}->id,
            y_axis       => $columns->{string1}->id,
            y_axis_stack => 'count',
            data         => [[ 1, 1 ]],
            rules => [
                {
                    id       => $columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo1',
                    operator => 'equal',
                }
            ],
        },
        {
            name         => 'Graph grouped by curvals',
            type         => 'bar',
            x_axis       => $columns->{string1}->id,
            y_axis       => $columns->{integer1}->id,
            y_axis_stack => 'sum',
            group_by     => $columns->{curval1}->id,
            data         => $multivalue ? [[ 35, 10, 0 ], [ 15, 0, 35 ]] : [[ 35, 10, 0 ], [ 15, 0, 20 ]],
            labels       => [
                'Foo, 50, foo1, , 2014-10-10, 2012-02-10 to 2013-06-15, , , c_amber, 2012',
                'Bar, 132, foo2, , 2009-01-02, 2008-05-04 to 2008-07-14, , , b_red, 2008',
            ],
        },
        {
            name         => 'Linked value on x-axis, count',
            type         => 'bar',
            x_axis       => $columns->{integer1}->id,
            y_axis       => $columns->{string1}->id,
            y_axis_stack => 'count',
            data         => [[ 1, 1, 1, 1 ]],
            xlabels      => [ 10, 15, 20, 35 ],
        },
        {
            name         => 'Linked value on x-axis (multiple linked), count',
            type         => 'bar',
            x_axis       => $columns->{integer1}->id,
            y_axis       => $columns->{string1}->id,
            y_axis_stack => 'count',
            data         => [[ 1, 1, 1, 1 ]],
            xlabels      => [ 10, 20, 35, 55 ],
            child2       => 55,
        },
        {
            name         => 'Linked value on x-axis (same value in normal/linked), sum',
            type         => 'bar',
            x_axis       => $columns->{integer1}->id,
            y_axis       => $columns->{calc1}->id,
            y_axis_stack => 'sum',
            data         => [[ 4024, 2009, 0 ]],
            xlabels      => [ 15, 20, 35 ],
            child        => 15,
        },
        {
            name         => 'All columns x-axis, sum y-axis',
            type         => 'bar',
            x_axis       => undef,
            y_axis       => $columns->{integer1}->id, # Can be anything
            y_axis_stack => 'sum',
            data         => [[ 25 ]],
            view_columns => [$columns->{integer1}->id],
            rules => [
                {
                    id       => $columns->{enum1}->id,
                    type     => 'string',
                    value    => 'foo1',
                    operator => 'equal',
                }
            ],
        },
        {
            name            => 'String on x-axis, group by autocur',
            type            => 'bar',
            x_axis          => $curval_sheet->columns->{string1}->id,
            y_axis_stack    => 'count',
            group_by        => $autocur->id,
            data            => $multivalue ? [[ 2, 0 ], [ 0, 1 ], [ 1, 1 ]] : [[ 1, 0 ], [ 0, 1 ], [ 1, 1 ]],
            layout          => $curval_sheet->layout,
            labels          => ['FooBar', 'Foo', 'Bar'],
            xlabels         => ['Bar', 'Foo'],
        },
        {
            name            => 'Autocur on x-axis',
            type            => 'bar',
            x_axis          => $autocur->id,
            y_axis_stack    => 'count',
            data            => $multivalue ? [[ 2, 1, 2 ]] : [[ 2, 1, 1 ]],
            layout          => $curval_sheet->layout,
            #labels          => ['FooBar', 'Foo', 'Bar'],
            xlabels         => ['Bar', 'Foo', 'FooBar'],
        },
    ];

    foreach my $g (@$graphs)
    {
        # Write new linked value, or reset to original
        my $child_value = $g->{child} || $linked_value;
        my $child_id = $child->current_id;
        $child->clear;
        $child->find_current_id($child_id);
        my $datum = $child->fields->{$columns2->{integer1}->id};
        if ($datum->value != $child_value)
        {
            $datum->set_value($child_value);
            $child->write(no_alerts => 1);
        }

        my $child2; my $parent2;
        if (my $child2_value = $g->{child2})
        {
            $child2 = GADS::Record->new(
                user   => $sheet->user,
                layout => $layout2,
                schema => $schema,
            );
            $child2->initialise;
            $child2->fields->{$columns2->{integer1}->id}->set_value($child2_value);
            $child2->write(no_alerts => 1);
            # Set the first record of the first sheet to take its value from the linked sheet
            $parent2 = GADS::Record->new(
                user   => $sheet->user,
                layout => $layout,
                schema => $schema,
            )->find_current_id(4);
            $parent2->write_linked_id($child2->current_id);
        }

        my $graph = GADS::Graph->new(
            layout       => $g->{layout} || $layout,
            schema       => $schema,
            current_user => $sheet->user,
        );
        $graph->title($g->{name});
        $graph->type($g->{type});
        $graph->x_axis($g->{x_axis});
        $graph->x_axis_link($g->{x_axis_link})
            if $g->{x_axis_link};
        $graph->x_axis_grouping($g->{x_axis_grouping})
            if $g->{x_axis_grouping};
        $graph->x_axis_range($g->{x_axis_range})
            if $g->{x_axis_range};
        $graph->from($g->{from});
        $graph->to($g->{to});
        $graph->y_axis($g->{y_axis});
        $graph->y_axis_stack($g->{y_axis_stack});
        $graph->group_by($g->{group_by})
            if $g->{group_by};
        $graph->as_percent($g->{as_percent});
        $graph->write;

        my $view;
        if (my $r = $g->{rules})
        {
            my $rules = encode_json({
                rules     => $r,
                condition => $g->{condition} || 'AND',
            });

            $view = GADS::View->new(
                name        => 'Test view',
                filter      => $rules,
                instance_id => 1,
                layout      => $g->{layout} || $layout,
                schema      => $schema,
                user        => $sheet->user,
                columns     => $g->{view_columns} || [],
            );
            $view->write;
        }

        my $records = GADS::RecordsGraph->new(
            user              => $sheet->user,
            layout            => $g->{layout} || $layout,
            schema            => $schema,
        );
        my $graph_data = GADS::Graph::Data->new(
            id      => $graph->id,
            view    => $view,
            records => $records,
            schema  => $schema,
        );

        is_deeply($graph_data->points, $g->{data}, "Graph data for $g->{name} is correct");
        is_deeply($graph_data->xlabels, $g->{xlabels}, "Graph xlabels for $g->{name} is correct")
            if $g->{xlabels};
        if ($g->{labels})
        {
            my @labels = map { $_->{label} } @{$graph_data->labels};
            is_deeply([@labels], $g->{labels}, "Graph labels for $g->{name} is correct");
        }
        if ($child2)
        {
            $parent2->write_linked_id(undef);
            $parent2->purge; # Just the record, revert to previous version
            $child2->delete_current;
            $child2->purge_current;
        }
    }
}

# Test graph of large number of records
my @data;
push @data, {
    string1  => 'foobar',
    integer1 => 2,
} for (1..1000);

my $sheet = Test::GADS::DataSheet->new(data => \@data);
$sheet->create_records;
my $columns = $sheet->columns;

my $graph = GADS::Graph->new(
    title        => 'Test graph',
    type         => 'bar',
    x_axis       => $columns->{string1}->id,
    y_axis       => $columns->{integer1}->id,
    y_axis_stack => 'sum',
    layout       => $sheet->layout,
    schema       => $sheet->schema,
    current_user => $sheet->user,
);
$graph->write;

my $records = GADS::RecordsGraph->new(
    user   => $sheet->user,
    layout => $sheet->layout,
    schema => $sheet->schema,
);

my $graph_data = GADS::Graph::Data->new(
    id      => $graph->id,
    records => $records,
    schema  => $sheet->schema,
);

is_deeply($graph_data->points, [[2000]], "Graph data for large number of records is correct");

done_testing();
