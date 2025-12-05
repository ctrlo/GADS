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

with 'GADS::DateTime';

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
my $yellow = 'FCFC4B';
my $green  = '5CB85C';
my $grey   = '8C8C8C';
my $purple = '4B0F44';
my $blue   = '3B3AF2';
my $attention = $red;

has _colors => (
    is      => 'ro',
    default => sub {
        {
            "7A221B"   => 1,
            "D1D3D4"   => 1,
            "34C3E0"   => 1,
            "FFDD00"   => 1,
            "9F6512"   => 1,
            "F0679E"   => 1,
            "2C4269"   => 1,
            "7F3F98"   => 1,
            "1C75BC"   => 1,
            "51417B"   => 1,
            "F26522"   => 1,
            "BDE0E9"   => 1,
            "B0B11A"   => 1,
            "4D4C4C"   => 1,
            "007B45"   => 1,
            "F37970"   => 1,
            "EE2D72"   => 1,
            "F9DDB6"   => 1,
            "97C9B3"   => 1,
            "FFED7D"   => 1,
            $red       => 1,
            $amber     => 1,
            $yellow    => 1,
            $green     => 1,
            $grey      => 1,
            $purple    => 1,
            $blue      => 1,
            $attention => 1,
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
               : $value eq 'c_yellow'
               ? $yellow
               : $value eq 'd_green'
               ? $green
               : $value eq 'e_purple'
               ? $purple
               : $value eq 'd_blue'
               ? $blue
               : $value eq 'b_attention'
               ? $attention
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

sub as_json
{   my $self = shift;
    encode_json {
        points  => $self->points,
        labels  => $self->labels_encoded,
        xlabels => $self->xlabels,
        options => $self->options,
    };
}

my $dgf = {
    day   => '%d %B %Y',
    month => '%B %Y',
    year  => '%Y',
};

sub x_axis_col
{   my $self = shift;
    $self->records->layout->column($self->x_axis);
}

sub x_axis_grouping_calculated
{   my $self = shift;

    # Only try grouping by date for valid date column
    return undef if !$self->x_axis;
    return undef if !$self->trend
            && $self->x_axis_col->return_type ne 'date' && $self->x_axis_col->return_type ne 'daterange';

    return $self->x_axis_grouping
        if ($self->x_axis_range && $self->x_axis_range eq 'custom')
            || (!$self->trend && $self->x_axis_grouping);

    return undef
        if !$self->from && !$self->to && !$self->x_axis_range;

    # Work out suitable intervals: short range: day, medium: month, long: year
    my $amount = $self->trend_range_amount;
    return $amount == 1
        ? 'day'
        : $amount <= 24
        ? 'month'
        : 'year';
}

sub from_calculated
{   my $self = shift;

    my $interval = $self->x_axis_grouping_calculated
        or return;

    # If we are plotting a trend and have custom dates, round them down to
    # ensure correct sample set is plotted
    return $self->from->clone->truncate(to => $interval)
        if $self->from && $self->trend;

    return $self->from->clone
        if $self->from;

    return undef if !$self->trend_range_amount;

    my $from = DateTime->now->truncate(to => $interval);

    # Either start now and move forwards or start in the past and move to now
    $from->subtract(months => $self->trend_range_amount)
        if $self->x_axis_range < 0;

    return $from;
}

sub to_calculated
{   my $self = shift;

    my $interval = $self->x_axis_grouping_calculated
        or return;

    return $self->to->clone->truncate(to => $interval)
        if $self->to && $self->trend;

    return $self->to->clone
        if $self->to;

    return undef if !$self->trend_range_amount;

    $self->from_calculated->clone->add(months => $self->trend_range_amount);
}

sub group_by_col
{   my $self = shift;
    return undef if $self->type eq 'pie' || !$self->group_by;
    $self->records->layout->column($self->group_by);
}

sub y_axis_col
{   my $self = shift;
    $self->records->layout->column($self->y_axis);
}

sub trend_range_amount
{   my $self = shift;
    return undef if !$self->x_axis_range;
    $self->x_axis_range < 0 ? $self->x_axis_range * -1 : $self->x_axis_range;
}

sub _build_data
{   my $self = shift;

    # Columns is either the x-axis, or if not defined, all the columns in the view
    my @columns = $self->x_axis
        ? ($self->x_axis)
        : $self->view
        ? @{$self->view->columns}
        : (map $_->id, $self->records->layout->all(user_can_read => 1));

    @columns = map {
        +{
            id        => $_,
            operator  => 'max',
            parent_id => ($self->x_axis && $_ == $self->x_axis && $self->x_axis_link)
        }
    } @columns;

    my $layout      = $self->records->layout;
    my $x_axis      = $self->x_axis_col;
    # Whether the x-axis is a daterange data type. If so, we need to treat it
    # specially and span values from single records across dates.
    my $x_daterange = $x_axis && $x_axis->return_type eq 'daterange';

    my $group_by_db = [];
    push @columns, {
        id        => $self->x_axis,
        group     => 1,
        pluck     => $self->x_axis_grouping_calculated, # Whether to group x-axis dates
        parent_id => $self->x_axis_link, # What the parent curval is, if we're picking a field from within a curval
    } if !$x_daterange && $self->x_axis;

    push @columns, {
        id    => $self->group_by,
        group => 1,
    } if $self->group_by_col;

    my $records = $self->records;
    if (!$self->trend) # If a trend, the from and to will be set later
    {
        $records->from($self->from_calculated);
        $records->to($self->to_calculated);
    }

    # If the x-axis field is one from a curval, make sure we are also
    # retrieving the parent curval field (called the link)
    my $link = $self->x_axis_link && $self->records->layout->column($self->x_axis_link);

    if ($x_daterange)
    {
        $records->dr_interval($self->x_axis_grouping_calculated);
        $records->dr_column($x_axis->id);
        $records->dr_column_parent($link);
        $records->dr_y_axis_id($self->y_axis);
    }

    $records->view($self->view);
    push @columns, +{
        id       => $self->y_axis,
        operator => $self->y_axis_stack,
    } if $self->y_axis;

    $records->columns(\@columns);

    $self->records->results # Do now so as to populate dr_from and dr_to
        if $x_daterange;

    # The view of this graph
    my $view = $self->records->view;

    # All the sources of the x values. May only be one column, may be several columns,
    # or may be lots of dates.
    my @x;
    if ($x_daterange)
    {
        if ($records->dr_from && $records->dr_to)
        {
            # If this is a daterange x-axis, then use the start date
            # as calculated by GADS::Records, then interpolate
            # until the end date. These same values will have been retrieved
            # in the resultset.
            my $pointer = $records->dr_from->clone;
            while ($pointer->epoch <= $records->dr_to->epoch)
            {
                push @x, $pointer->clone;
                $pointer->add($self->x_axis_grouping_calculated.'s' => 1);
            }
        }
    }
    elsif ($self->x_axis_range && $self->x_axis_grouping_calculated)
    {
        my $interval = $self->x_axis_grouping_calculated;
        my %add = ($interval.'s' => 1);

        # Produce a set of dates spanning the required range
        my $pointer = $self->from_calculated->clone;
        while ($pointer <= $self->to_calculated)
        {
            push @x, $pointer->clone;
            $pointer->add(%add);
        }
    }
    elsif ($x_axis)
    {
        push @x, $x_axis;
    }
    elsif ($view)
    {
        push @x, @{$self->records->columns_render};
    }
    else {
        push @x, $layout->all(user_can_read => 1);
    }

    # Now go into each of the retrieved database results, and create a more
    # useful hash with all the series on, which we can use to create the
    # graphs. At this point, we do not know what the x-axis values will be,
    # so we need to wait until we've retrieved them all first (we know the
    # source of the values, but not the value or quantity of them).
    #
    # $results - overall results hash
    # $series_keys - the names of all of the series for the graph. May only be one
    # $datemin and $datemax - for x-axis dates, min and max retrieved

    my @xlabels;
    my ($results, $series_keys, $datemin, $datemax);
    if ($self->trend)
    {
        # Force current IDs as of today (without rewind set) to be calculated
        # first, otherwise the current IDs as at the start of the period will
        # be used
        $records->generate_cid_query;

        my $search = $records->search; # Retain quick search across historical queries

        foreach my $x (@x)
        {
            $records->clear(retain_current_ids => 1); # Retain record IDs across results
            $records->search($search);

            # The period to retrieve ($x) will be at the beginning of the
            # period. Move to the end of the period, by adding on one unit
            # (e.g. month) and then moving into the previous day by a second
            my $rewind = $x->clone->add($self->x_axis_grouping_calculated.'s' => 1)->subtract(seconds => 1);
            $records->rewind($rewind);
            my $this_results; my $this_series_keys;
            ($this_results, $this_series_keys, $datemin, $datemax) = $self->_records_to_results($records,
                x_daterange => $x_daterange,
                x           => [$self->x_axis_col],
                values_only => 1,
            );
            my $df = $dgf->{$self->x_axis_grouping_calculated};
            my $label = $x->strftime($df);
            push @xlabels, $label;
            $results->{$label} = $this_results;
            $series_keys->{$_} = 1
                foreach keys %$this_series_keys;
        }
    }
    else {
        ($results, $series_keys, $datemin, $datemax) = $self->_records_to_results($records,
            x_daterange => $x_daterange,
            x           => \@x,
        );
    }

    # Work out the labels for the x-axis. We now know this having processed
    # all the values.
    if ($self->x_axis_grouping_calculated && $datemin && $datemax)
    {
        @xlabels = ();
        my $inc = $datemin->clone;
        my $add = $self->x_axis_grouping_calculated.'s';
        while ($inc->epoch <= $datemax->epoch)
        {
            my $df = $dgf->{$self->x_axis_grouping_calculated};
            push @xlabels, $inc->strftime($df);
            $inc->add( $add => 1 );
        }
    }
    elsif (!$self->x_axis) # Multiple columns, use column name
    {
        @xlabels = map { $_->name } @x;
    }
    elsif ($self->trend)
    {
        # Do nothing, already added
    }
    else {
        @xlabels = sort keys %$results;
    }

    # Now that we have all the values retrieved and know the quantity
    # of the x-axis values, we can map these into individual series
    my $series;
    foreach my $serial (keys %$series_keys)
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
        if ($self->group_by_col)
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
            $metrics->{lc $y_axis_grouping_value}->{lc $metric->x_axis_value} = $metric->target;
        }

        # Now go into each data item and recalculate against the metric
        foreach my $line (keys %$series)
        {
            my @data = @{$series->{$line}->{data}};
            for my $i (0 .. $#data)
            {
                my $x = $xlabels[$i];
                my $target = $metrics->{lc $line}->{lc $x};
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
                encode_entities($_), ($data[$idx++]||0),
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
        xlabels => \@xlabels, # Populated, but not used for donut or pie
        points  => \@points,
        labels  => \@labels, # Not used for pie/donut
        options => $options,
    }
}

sub _records_to_results
{   my ($self, $records, %params) = @_;

    my $x_daterange = $params{x_daterange};
    my $x           = $params{x};

    my ($results, $series_keys, $datemin, $datemax);

    my $records_results = $self->records->results;

    my $df = $self->x_axis_grouping_calculated && $dgf->{$self->x_axis_grouping_calculated};

    # If we have a specified x-axis range but only a date field, then we need
    # to pre-populate the range of x values. This is not needed with a
    # daterange, as when results are retrieved for a daterange it includes each
    # x-axis value in each row retrieved (dates only include the single value)
    if (!$self->trend && $self->x_axis_range && $self->x_axis_col->type eq 'date')
    {
        foreach my $x (@$x)
        {
            my $x_value = $self->_group_date($x);
            $datemin = $x_value if !defined $datemin; # First loop
            $datemax = $x_value if !defined $datemax || $datemax->epoch < $x_value->epoch;
            $x_value = $x_value->strftime($df);
            $results->{$x_value} = {};
        }
    }

    # For each line of results from the SQL query
    foreach my $line (@$records_results)
    {
        # For each x-axis point get the value.  For a normal graph this will be
        # the list of retrieved values. For a daterange graph, all of the
        # x-axis points will be datetime values.  For a normal date field with
        # a specified date range, we have already interpolated the points
        # (above) and we just need to get each individual value, not every
        # x-axis point (which will not be available in the results)
        my @for = $self->x_axis_range && $self->x_axis_col->type eq 'date' ? $self->x_axis_col : @$x;
        foreach my $x (@for)
        {
            my $col     = $x_daterange ? $x->epoch : $x->field;
            my $x_value = $line->get_column($col);
            $x_value ||= $line->get_column("${col}_link")
                if !$x_daterange && $x->link_parent;

            if (!$x_daterange && $x->is_curcommon && $x_value)
            {
                $x_value = $self->_format_curcommon($x, $line);
            }

            if (!$self->trend && $self->x_axis_grouping_calculated) # Group by date, round to required interval
            {
                !$x_value and next;
                my $x_dt = $x_daterange
                         ? $x
                         : $self->parse_datetime($x_value, source => 'db');
                $x_value = $self->_group_date($x_dt);
                $datemin = $x_value if !defined $datemin || $datemin->epoch > $x_value->epoch;
                $datemax = $x_value if !defined $datemax || $datemax->epoch < $x_value->epoch;
                $x_value = $x_value->strftime($df) if $x_value;
            }
            elsif (!$self->x_axis) # Multiple column x-axis
            {
                $x_value = $x->name;
            }

            $x_value ||= '<no value>';

            # The column name to retrieve from SQL record
            my $fname = $x_daterange
                      ? $x->epoch
                      : !$self->x_axis
                      ? $x->field
                      : $self->y_axis_stack eq 'count'
                      ? 'id_count' # Don't use field count as NULLs are not counted
                      : $self->y_axis_col->field."_".$self->y_axis_stack;
            my $val = $line->get_column($fname);

            # Add on the linked column from another datasheet, if applicable
            my $include_linked = !$self->x_axis && (!$x->numeric || !$x->link_parent); # Multi x-axis
            my $val_linked     = $self->y_axis_stack eq 'sum' && $self->y_axis_col->link_parent
                && $line->get_column("${fname}_link");

            no warnings 'numeric', 'uninitialized';
            if ($params{values_only}) {
                $series_keys->{$x_value} = 1;
                $results->{$x_value} += $val + $val_linked;
            }
            else {
                # The key for this series. May only be one (use "1")
                my $k = $self->group_by_col && $self->group_by_col->is_curcommon
                      ? $self->_format_curcommon($self->group_by_col, $line)
                      : $self->group_by_col
                      ? $line->get_column($self->group_by_col->field)
                      : 1;
                $k ||= $line->get_column($self->group_by_col->field."_link")
                      if $self->group_by_col && $self->group_by_col->link_parent;
                $k ||= '<blank value>';

                $series_keys->{$k} = 1; # Hash to kill duplicate values
                # Store all the results for each x value together, by series
                $results->{$x_value} ||= {};
                $results->{$x_value}->{$k} += $val + $val_linked;
            }
        }
    }

    return ($results, $series_keys, $datemin, $datemax);
}
# Take a date and round it down according to the grouping
sub _group_date
{   my ($self, $val) = @_;
    $val or return;
    my $grouping = $self->x_axis_grouping_calculated;
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

