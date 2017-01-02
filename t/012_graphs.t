use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Graph;
use GADS::Graph::Data;
use GADS::Records;
use GADS::RecordsGroup;

use t::lib::DataSheet;

my $linked_value = 10; # See below

my $data = [
    {
        # No integer1 - the value will be taken from a linked record ($linked_value)
        string1    => 'Foo',
        date1      => '2013-10-10',
        daterange1 => ['2014-03-21', '2015-03-01'],
        enum1      => 7,
        curval1    => 1,
    },{
        string1    => 'Bar',
        date1      => '2014-10-10',
        daterange1 => ['2010-01-04', '2011-06-03'],
        integer1   => 15,
        enum1      => 7,
        curval1    => 2,
    },{
        string1    => 'Bar',
        integer1   => 35,
        enum1      => 8,
        curval1    => 1,
    },{
        string1    => 'FooBar',
        date1      => '2016-10-10',
        daterange1 => ['2009-01-04', '2017-06-03'],
        integer1   => 20,
        enum1      => 8,
        curval1    => 2,
    },
];

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = t::lib::DataSheet->new(data => $data, schema => $schema, curval => 2);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

# Add linked record sheet, which will contain the integer1 value for the first
# record of the first sheet
my $sheet2 = t::lib::DataSheet->new(data => [], instance_id => 3, schema => $schema);
my $layout2 = $sheet2->layout;
my $columns2 = $sheet2->columns;

# Set link field of first sheet integer1 to integer1 of second sheet
$columns->{integer1}->link_parent_id($columns2->{integer1}->id);
$columns->{integer1}->write;
$layout->clear; # Need to rebuild columns to get link_parent built

# Create the single record of the second sheet, which will contain the single
# integer1 value
my $child = GADS::Record->new(
    user   => undef,
    layout => $layout2,
    schema => $schema,
);
$child->initialise;
$child->fields->{$columns2->{integer1}->id}->set_value($linked_value);
$child->write(no_alerts => 1);
# Set the first record of the first sheet to take its value from the linked sheet
my $parent = GADS::Records->new(
    user   => undef,
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
        data         => [[ 50, 10, 20 ]],
    },
    {
        name         => 'String x-axis, integer sum y-axis with view filter',
        type         => 'bar',
        x_axis       => $columns->{string1}->id,
        y_axis       => $columns->{integer1}->id,
        y_axis_stack => 'sum',
        data         => [[ 15, 10 ]],
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
        name            => 'Date x-axis, integer count y-axis',
        type            => 'bar',
        x_axis          => $columns->{date1}->id,
        x_axis_grouping => 'year',
        y_axis          => $columns->{string1}->id,
        y_axis_stack    => 'count',
        data            => [[ 1, 1, 0, 1 ]],
    },
    {
        name         => 'String x-axis, sum y-axis, group by enum',
        type         => 'bar',
        x_axis       => $columns->{string1}->id,
        y_axis       => $columns->{integer1}->id,
        y_axis_stack => 'sum',
        group_by     => $columns->{enum1}->id,
        data         => [[ 35, 0, 20 ], [ 15, 10, 0 ]],
    },
    {
        name         => 'Curval on x-axis',
        type         => 'bar',
        x_axis       => $columns->{curval1}->id,
        y_axis       => $columns->{integer1}->id,
        y_axis_stack => 'sum',
        data         => [[ 45, 35 ]],
    },
    {
        name         => 'Curval on x-axis grouped by enum',
        type         => 'bar',
        x_axis       => $columns->{curval1}->id,
        y_axis       => $columns->{integer1}->id,
        y_axis_stack => 'sum',
        group_by     => $columns->{enum1}->id,
        data         => [[35, 20], [ 10, 15 ]],
    },
    {
        name         => 'Graph grouped by curvals',
        type         => 'bar',
        x_axis       => $columns->{string1}->id,
        y_axis       => $columns->{integer1}->id,
        y_axis_stack => 'sum',
        group_by     => $columns->{curval1}->id,
        data         => [[ 15, 0, 20 ], [ 35, 10, 0 ]],
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
            user   => undef,
            layout => $layout2,
            schema => $schema,
        );
        $child2->initialise;
        $child2->fields->{$columns2->{integer1}->id}->set_value($child2_value);
        $child2->write(no_alerts => 1);
        # Set the first record of the first sheet to take its value from the linked sheet
        $parent2 = GADS::Record->new(
            user   => undef,
            layout => $layout,
            schema => $schema,
        )->find_current_id(4);
        $parent2->write_linked_id($child2->current_id);
    }

    my $graph = GADS::Graph->new(
        layout => $layout,
        schema => $schema,
    );
    $graph->title($g->{name});
    $graph->type($g->{type});
    $graph->x_axis($g->{x_axis});
    $graph->x_axis_grouping($g->{x_axis_grouping})
        if $g->{x_axis_grouping};
    $graph->y_axis($g->{y_axis});
    $graph->y_axis_stack($g->{y_axis_stack});
    $graph->group_by($g->{group_by})
        if $g->{group_by};
    $graph->write;

    my $view;
    if (my $r = $g->{rules})
    {
        my $rules = encode_json({
            rules     => $r,
            # condition => 'AND', # Default
        });

        $view = GADS::View->new(
            name        => 'Test view',
            filter      => $rules,
            instance_id => 1,
            layout      => $layout,
            schema      => $schema,
            user        => undef,
        );
        $view->write;
    }

    my $records = GADS::RecordsGroup->new(
        user              => undef,
        layout            => $layout,
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
    if ($child2)
    {
        $parent2->write_linked_id(undef);
        $parent2->delete; # Just the record, revert to previous version
        $child2->delete_current;
    }
}

done_testing();
