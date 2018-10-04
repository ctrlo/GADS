=pod
GADS - Globally Accessible Data Store
Copyright (C) 2014 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

package GADS::Graph::Data;

use HTML::Entities;
use JSON qw(decode_json encode_json);
use List::Util qw(sum);
use Math::Round qw(round);
use Text::CSV::Encoded;
use Scalar::Util qw(looks_like_number);

use Moo;

extends 'GADS::Graph';

has records => (
    is       => 'rw',
    required => 1,
);

has view => (
    is => 'ro',
);

has xlabels => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_data->{xlabels} },
);

has labels => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_data->{labels} },
);

has labels_encoded => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my @labels = @{$_[0]->_data->{labels}};
        @labels = map { $_->{label} = encode_entities $_->{label}; $_ } @labels;
        \@labels;
    },
);

has points => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_data->{points} },
);

has options => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { $_[0]->_data->{options} },
);

# Function to fill out the series of data that will be plotted on a graph
has _data => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_build_data },
);

has csv => (
    is => 'lazy',
);

# Define specific colours to match rag fields
my $red    = 'D9534F';
my $amber  = 'F0AD4E';
my $green  = '5CB85C';
my $grey   = '8C8C8C';
my $purple = '4B0F44';

has _colors => (
    is      => 'ro',
    default => sub {
        {
            "7A221B" => 1,
            "D1D3D4" => 1,
            "34C3E0" => 1,
            "FFDD00" => 1,
            "9F6512" => 1,
            "F0679E" => 1,
            "2C4269" => 1,
            "7F3F98" => 1,
            "1C75BC" => 1,
            "51417B" => 1,
            "F26522" => 1,
            "BDE0E9" => 1,
            "B0B11A" => 1,
            "4D4C4C" => 1,
            "007B45" => 1,
            "F37970" => 1,
            "EE2D72" => 1,
            "F9DDB6" => 1,
            "97C9B3" => 1,
            "FFED7D" => 1,
            $red     => 1,
            $amber   => 1,
            $green   => 1,
            $grey    => 1,
            $purple  => 1,
        },
    },
);

has _colors_in_use => (
    is      => 'ro',
    default => sub { +{} },
);

sub _build_csv
{   my $self = shift;
    my $csv = Text::CSV::Encoded->new({ encoding  => undef });

    my $csvout = "";
    my $rows;
    if ($self->type eq "pie" || $self->type eq "donut")
    {
        foreach my $ring (@{$self->points})
        {
            my $count = 0;
            foreach my $segment (@{$ring})
            {
                my $name = $segment->[0];
                $rows->[$count] ||= [$name];
                push @{$rows->[$count]}, $segment->[1];
                $count++;
            }
        }
    }
    else {
        foreach my $series (@{$self->points})
        {
            my $count = 0;
            foreach my $x (@{$self->xlabels})
            {
                $rows->[$count] ||= [$x];
                my $value = shift @$series;
                push @{$rows->[$count]}, $value;
                $count++;
            }
        }
    }
    if ($self->group_by)
    {
        my @row = map {$_->{label}} @{$self->labels};
        $csv->combine("", @row);
        $csvout .= $csv->string."\n";
    }
    foreach my $row (@$rows)
    {
        $csv->combine(@$row);
        $csvout .= $csv->string."\n";
    }
    $csvout;
}

sub get_color
{   my ($self, $value) = @_;

    # Make sure value doesn't exceed the length of the name column,
    # otherwise we won't match when trying to find it.
    my $gc_rs = $self->schema->resultset('GraphColor');
    my $size = $gc_rs->result_source->column_info('name')->{size};
    $value = substr $value, 0, $size - 1;
    return "#".$self->_colors_in_use->{$value}
        if exists $self->_colors_in_use->{$value};

    # $@ may be the result of a previous Log::Report::Dispatcher::Try block (as
    # an object) and may evaluate to an empty string. If so, txn_scope_guard
    # warns as such, so undefine to prevent the warning
    undef $@;
    my $guard = $self->schema->txn_scope_guard;

    my $existing = $self->schema->resultset('GraphColor')->find($value, { key => 'ux_graph_color_name' });
    my $color;
    if ($existing && $self->_colors->{$existing->color})
    {
        $color = $existing->color;
    }
    else {
        $color = $value eq 'a_grey'
               ? $grey
               : $value eq 'b_red'
               ? $red
               : $value eq 'c_amber'
               ? $amber
               : $value eq 'd_green'
               ? $green
               : $value eq 'e_purple'
               ? $purple
               : (keys %{$self->_colors})[0];
        $self->schema->resultset('GraphColor')->update_or_create({
            name  => $value,
            color => $color,
        }, {
            key => 'ux_graph_color_name'
        }) if $color; # May have run out of colours
    }
    $guard->commit;
    if ($color)
    {
        $self->_colors_in_use->{$value} = $color;
        delete $self->_colors->{$color};
        $color = "#$color";
    }
    $color;
}

sub _build_data
{   my $self = shift;

    # Columns is either the x-axis, or if not defined, all the columns in the view
    my @columns = $self->x_axis
        ? ($self->x_axis)
        : $self->view
        ? @{$self->view->columns}
        : $self->records->layout->all(user_can_read => 1);

    @columns = map {
        +{
            id        => $_,
            operator  => 'max',
            parent_id => ($self->x_axis && $_ == $self->x_axis && $self->x_axis_link)
        }
    } @columns;

    my $layout      = $self->records->layout;
    # $x_axis is undefined if all the fields are to appear on it
    my $x_axis      = $self->x_axis ? $layout->column($self->x_axis) : undef;
    # Whether the x-axis is a daterange data type. If so, we need to treat it
    # specially and span values from single records across dates.
    my $x_daterange = $x_axis && $x_axis->return_type eq 'daterange';
    # Only try grouping by date for valid date column
    my $x_axis_grouping =
        $x_axis &&
        ($x_axis->return_type eq 'date' || $x_axis->return_type eq 'daterange') &&
        $self->x_axis_grouping;

    my $group_by_db = [];
    push @columns, {
        id        => $self->x_axis,
        group     => 1,
        pluck     => $x_axis_grouping, # Whether to group x-axis dates
        parent_id => $self->x_axis_link, # What the parent curval is, if we're picking a field from within a curval
    } if !$x_daterange && $self->x_axis;

    my $group_by_col;
    if ($self->type ne 'pie' && $self->group_by)
    {
        $group_by_col = $layout->column($self->group_by);
        push @columns, {
            id    => $self->group_by,
            group => 1,
        };
    }

    my $records = $self->records;

    # If the x-axis field is one from a curval, make sure we are also
    # retrieving the parent curval field (called the link)
    my $link = $self->x_axis_link && $self->records->layout->column($self->x_axis_link);

    if ($x_daterange)
    {
        $records->dr_interval($x_axis_grouping);
        $records->dr_column($x_axis->id);
        $records->dr_column_parent($link);
        $records->dr_y_axis_id($self->y_axis);
    }

    my $y_axis = $layout->column($self->y_axis);
    $records->view($self->view);
    push @columns, +{
        id       => $self->y_axis,
        operator => $self->y_axis_stack,
    };

    $records->columns(\@columns);
    my $records_results = $self->records->results; # Do now so as to populate dr_from and dr_to

    # The view of this graph
    my $view = $self->records->view;
    # All the sources of the x values. May only be one column, may be several columns,
    # or may be lots of dates.
    my @x = $x_daterange
        ? () # Populated in a moment for daterange x-axis
        : $x_axis
        ? ($x_axis)
        : $view
        ? $self->records->layout->view($view->id, user_can_read => 1)
        : $layout->all(user_can_read => 1);

    if ($x_daterange && $records->dr_from && $records->dr_to)
    {
        # If this is a daterange x-axis, then use the start date
        # as calculated by GADS::RecordsGroup, then interpolate
        # until the end date. These same values will have been retrieved
        # in the resultset.
        my $pointer = $records->dr_from->clone;
        while ($pointer->epoch <= $records->dr_to->epoch)
        {
            push @x, $pointer->clone;
            $pointer->add("${x_axis_grouping}s" => 1);
        }
    }

    my $dgf = {
        day   => '%d %B %Y',
        month => '%B %Y',
        year  => '%Y',
    };

    # Now go into each of the retrieved database results, and create a more
    # useful hash with all the series on, which we can use to create the
    # graphs. At this point, we do not know what the x-axis values will be,
    # so we need to wait until we've retrieved them all first (we know the
    # source of the values, but not the value or quantity of them).
    my $results = {}; # The overall results hash
    my %series; # The names of all of the series for the graph. May only be one.
    my $datemin; my $datemax; # For x-axis dates, min and max retrieved

    # For each line of results from the SQL query
    foreach my $line (@$records_results)
    {
        # For each x-axis source (see above)
        foreach my $x (@x)
        {
            my $col     = $x_daterange ? $x->epoch : $x->field;
            my $x_value = $line->get_column($col);
            $x_value ||= $line->get_column("${col}_link")
                if !$x_daterange && $x->link_parent;

            if (!$x_daterange && $x->type eq 'curval' && $x_value)
            {
                $x_value = $self->_format_curcommon($x, $line);
            }

            if ($x_axis_grouping) # Group by date, round to required interval
            {
                !$x_value and next;
                my $x_dt = $x_daterange
                         ? $x
                         : $self->schema->storage->datetime_parser->parse_date($x_value);
                my $df   = $dgf->{$x_axis_grouping};
                $x_value = $self->_group_date($x_dt);
                $datemin = $x_value if !defined $datemin || $datemin->epoch > $x_value->epoch;
                $datemax = $x_value if !defined $datemax || $datemax->epoch < $x_value->epoch;
                $x_value = $x_value->strftime($df) if $x_value;
            }
            elsif (!$x_axis) # Multiple column x-axis
            {
                $x_value = $x->name;
            }

            $x_value ||= '<no value>';

            # The key for this series. May only be one (use "1")
            my $k = $group_by_col && $group_by_col->is_curcommon
                  ? $self->_format_curcommon($group_by_col, $line)
                  : $group_by_col
                  ? $line->get_column($group_by_col->field)
                  : 1;
            $k ||= $line->get_column($group_by_col->field."_link")
                  if $group_by_col && $group_by_col->link_parent;
            $k ||= '<blank value>';
            $series{$k} = 1; # Hash to kill duplicate values

            # Store all the results for each x value together, by series
            $results->{$x_value} ||= {};

            # The column name to retrieve from SQL record
            my $fname = $x_daterange
                      ? $x->epoch
                      : !$self->x_axis
                      ? $x->field
                      : $self->y_axis_stack eq 'count'
                      ? 'id_count' # Don't use field count as NULLs are not counted
                      : $y_axis->field."_".$self->y_axis_stack;
            no warnings 'numeric', 'uninitialized';
            $results->{$x_value}->{$k} += $line->get_column($fname); # 2 loops for linked values
            # Add on the linked column from another datasheet, if applicable
            next if !$x_axis && (!$x->numeric || !$x->link_parent); # Multi x-axis
            $results->{$x_value}->{$k} += $line->get_column("${fname}_link")
                if $y_axis->link_parent && $self->y_axis_stack eq 'sum';
        }
    }

    # Work out the labels for the x-axis. We now know this having processed
    # all the values.
    my @xlabels;
    if ($x_axis_grouping && $datemin && $datemax)
    {
        @xlabels = ();
        my $inc = $datemin->clone;
        my $add = $x_axis_grouping.'s';
        while ($inc->epoch <= $datemax->epoch)
        {
            my $df = $dgf->{$x_axis_grouping};
            push @xlabels, $inc->strftime($df);
            $inc->add( $add => 1 );
        }
    }
    elsif (!$self->x_axis) # Multiple columns, use column name
    {
        @xlabels = map { $_->name } @x;
    }
    else {
        @xlabels = sort keys %$results;
    }

    # Now that we have all the values retrieved and know the quantity
    # of the x-axis values, we can map these into individual series
    my $series;
    foreach my $serial (keys %series)
    {
        my @xloop = $self->x_axis ? @xlabels : @x;
        foreach my $x (@xloop)
        {
            my $x_val = $self->x_axis ? $x : $x->name;
            # May be a zero y-value for a grouped graph, but the
            # series still needs a zero written, even for a line graph.
            no warnings 'numeric', 'uninitialized';
            my $y = int $results->{$x_val}->{$serial};
            $y = 0 if !$self->x_axis && !$x->numeric;
            push @{$series->{$serial}->{data}}, $y;
        }
    }

    if ($self->as_percent && $self->type ne "pie" && $self->type ne "donut")
    {
        if ($group_by_col)
        {
            my ($random) = keys %$series;
            my $count = @{$series->{$random}->{data}}; # Number of data points for each series
            for my $i (0..$count-1)
            {
                my $sum = _sum( map { $series->{$_}->{data}->[$i] } keys %$series );
                $series->{$_}->{data}->[$i] = _to_percent($sum, $series->{$_}->{data}->[$i])
                    foreach keys %$series;
            }
        }
        else {
            my $sum = _sum( @{$series->{1}->{data}} );
            $series->{1}->{data} = [ map { _to_percent($sum, $_) } @{$series->{1}->{data}} ];
        }
    }

    # If this graph is measuring against a metric, recalculate against that
    my $metric_max;
    if (my $metric_group_id = $self->metric_group_id)
    {
        # Get set of metrics
        my @metrics = $self->schema->resultset('Metric')->search({
            metric_group => $metric_group_id,
        })->all;
        my $metrics;

        # Put all the metrics in an easy to search hash ref
        foreach my $metric (@metrics)
        {
            my $y_axis_grouping_value = $metric->y_axis_grouping_value || 1;
            $metrics->{$y_axis_grouping_value}->{$metric->x_axis_value} = $metric->target;
        }

        # Now go into each data item and recalculate against the metric
        foreach my $line (keys %$series)
        {
            my @data = @{$series->{$line}->{data}};
            for my $i (0 .. $#data)
            {
                my $x = $xlabels[$i];
                my $target = $metrics->{$line}->{$x};
                my $val    = $target ? int ($data[$i] * 100 / $target ) : 0;
                $series->{$line}->{data}->[$i] = $val;
                $metric_max = $val if !$metric_max || $val > $metric_max;
            }
        }
    }

    my $markeroptions = $self->type eq "scatter"
                      ? '{ size: 7, style:"x" }'
                      : '{ show: false }';

    my @points; my @labels;
    if ($self->type eq "pie" || $self->type eq "donut")
    {
        foreach my $k (keys %$series)
        {
            my @ps;
            my @data = @{$series->{$k}->{data}};
            my $idx = 0;
            if ($self->as_percent)
            {
                my $sum = _sum(@data);
                @data = map { _to_percent($sum, $_) } @data;
            }
            push @ps, [
                $_, ($data[$idx++]||0),
            ] foreach @xlabels;
            push @points, \@ps;
        }
        # XXX jqplot doesn't like smaller ring segmant quantities first.
        # Sorting fixes this, but should probably be fixed in jqplot.
        @points = sort { scalar @$b <=> scalar @$a } @points;
    }
    else {
        # Work out the required jqplot labels for each series.
        foreach my $k (keys %$series)
        {
            my $showlabel = 'true';
            my $color = $self->get_color($k);
            $series->{$k}->{label} = {
                color         => $color,
                showlabel     => $showlabel,
                showline      => $self->type eq "scatter" ? 'false' : 'true',
                markeroptions => $markeroptions,
                label         => $k,
            };
        }

        # Sort the names of the series so they appear in order on the
        # graph. For some reason, they need to be in reverse order to
        # appear correctly in jqplot.
        my @all_series = map { $series->{$_} } reverse sort keys %$series;
        @points        = map { $_->{data} } @all_series;
        @labels        = map { $_->{label} } @all_series;
    }

    my $options = {};
    $options->{y_max}     = 100 if defined $metric_max && $metric_max < 100;
    $options->{is_metric} = 1 if defined $metric_max;

    # If we had a curval as a link, then we need to reset its retrieved fields,
    # otherwise anything else using the field after this procedure will be
    # using the reduced columns that we used for the graph
    if ($self->x_axis_link)
    {
        $link->clear_curval_field_ids;
        $link->clear;
    }

    +{
        xlabels => \@xlabels, # Populated, but not used for donut
        points  => \@points,
        labels  => \@labels, # Not used for pie/donut
        options => $options,
    }
}

# Take a date and round it down according to the grouping
sub _group_date
{   my ($self, $val) = @_;
    $val or return;
    my $grouping = $self->x_axis_grouping;
    $val = $grouping eq 'year'
         ? DateTime->new(year => $val->year)
         : $grouping eq 'month'
         ? DateTime->new(year => $val->year, month => $val->month)
         : $grouping eq 'day'
         ? DateTime->new(year => $val->year, month => $val->month, day => $val->day)
         : $val
}

sub _format_curcommon
{   my ($self, $column, $line) = @_;
    $line->get_column($column->field) or return;
    $column->format_value(map { $line->get_column($_->field) } @{$column->curval_fields});
}

sub _to_percent
{   my ($sum, $value) = @_;
    round(($value / $sum) * 100 ) + 0;
}

sub _sum { sum(map {$_ || 0} @_) }

1;

