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
use Text::CSV::Encoded;
use Scalar::Util qw(looks_like_number);

use Moo;

extends 'GADS::Graph';

has records => (
    is       => 'rw',
    required => 1,
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

# Function to fill out the series of data that will be plotted on a graph
has _data => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_build_data },
);

has csv => (
    is => 'lazy',
);

has _colors => (
    is      => 'ro',
    default => sub {
        {
            "34C3E0" => 1,
            "62BB46" => 1,
            "FFDD00" => 1,
            "D1D3D4" => 1,
            "F99D1C" => 1,
            "F0679E" => 1,
            "2C4269" => 1,
            "7F3F98" => 1,
            "1C75BC" => 1,
            "EF4136" => 1,
            "2BB673" => 1,
            "51417B" => 1,
            "F26522" => 1,
            "8C8C8C" => 1,
            "97CEDD" => 1,
            "DCDD20" => 1,
            "4D4C4C" => 1,
            "447CBF" => 1,
            "F5C316" => 1,
            "007B45" => 1,
            "F37970" => 1,
            "4B0F44" => 1,
            "EE2D72" => 1,
        },
    },
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
    # $@ may be the result of a previous Log::Report::Dispatcher::Try block (as
    # an object) and may evaluate to an empty string. If so, txn_scope_guard
    # warns as such, so undefine to prevent the warning
    undef $@;
    my $guard = $self->schema->txn_scope_guard;

    # Make sure value doesn't exceed the length of the name column,
    # otherwise we won't match when trying to find it.
    my $gc_rs = $self->schema->resultset('GraphColor');
    my $size = $gc_rs->result_source->column_info('name')->{size};
    $value = substr $value, 0, $size - 1;
    my $existing = $self->schema->resultset('GraphColor')->find($value, { key => 'ux_graph_color_name' });
    my $color;
    if ($existing && $self->_colors->{$existing->color})
    {
        $color = $existing->color;
    }
    else {
        ($color) = keys %{$self->_colors};
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
        delete $self->_colors->{$color};
        $color = "#$color";
    }
    $color;
}

sub _build_data
{   my $self = shift;

    # XXX A lot of this would probably be better done by the database...

    my $layout   = $self->records->layout;
    my $x_axis   = $self->x_axis ? $layout->column($self->x_axis) : undef;
    my $y_axis   = $layout->column($self->y_axis);
    my $group_by = $self->group_by && $layout->column($self->group_by);

    # $y_group_index used to count y_group unique values
    my $y_group_index = 0;

    # The view of this graph
    my $view    = $self->records->view;
    # All the x values from the records. May only be one, or may be lots if
    # not defined in the graph
    my @x = $x_axis
        ? ($x_axis)
        : $view
        ? $self->records->layout->view($view->id, user_can_read => 1)
        : $layout->all(user_can_read => 1);

    my %xy_values; my %y_group_values;
    my ($datemin, $datemax);
    if ($x_axis)
    {
        # Go through each record, and count how many unique values
        # there are for the field in question. Then define the key
        # of the xy_values hash using the index count
        foreach my $record (@{$self->records->results})
        {
            my $xval = $record->fields->{$x_axis->id};
            if ($xval && $x_axis->return_type eq 'date')
            {
                $xval = _group_date($xval->value, $self->x_axis_grouping);
            }
            next unless $xval && "$xval";

            my $gval = $group_by && $record->fields->{$group_by->id};

            my @xvals = $x_axis->type eq 'daterange'
                      ? _group_dates($xval, $self->x_axis_grouping)
                      : ($xval);

            foreach my $x (@xvals)
            {
                $x = $x->epoch if ref $x eq 'DateTime';
                if (!defined $xy_values{"$x"})
                {
                    $xy_values{"$x"} = 1;
                }
                if ($group_by && !defined $y_group_values{$gval})
                {
                    $y_group_values{$gval} = { defined => 0 };
                    $y_group_index++;
                }
                if ($x_axis->return_type eq 'date' || $x_axis->return_type eq 'daterange')
                {
                    $datemin = $x if !defined $datemin || $datemin > $x;
                    $datemax = $x if !defined $datemax || $datemax < $x;
                }
            }
        }
    }
    else {
        # Showing several columns, so show each as its own x-axis value
        $xy_values{$_->id} = 1
            foreach @x;
    }

    my $dg = {
        day   => '%d %B %Y',
        month => '%B %Y',
        year  => '%Y',
    };

    my @xlabels;

    my $count = 0;
    if ($self->x_axis_grouping && $datemin && $datemax)
    {
        @xlabels = ();
        my $inc = DateTime->from_epoch( epoch => $datemin );
        my $add = $self->x_axis_grouping.'s';
        while ($inc->epoch <= $datemax)
        {
            $xy_values{$inc->epoch} = $count;
            my $df = $dg->{$self->x_axis_grouping};
            push @xlabels, $inc->strftime($df);
            $inc->add( $add => 1 );
            $count++;
        }
    }
    elsif ($x_axis)
    {
        # Generate unique index numbers for all the x-values
        @xlabels = sort keys %xy_values;
        foreach my $l (@xlabels)
        {
            $xy_values{$l} = $count;
            $count++;
        }
    }
    else {
        # x labels will just be field ID numbers. Translate to
        # field names
        @xlabels = map { $_->name } @x;
        foreach my $l (@x)
        {
            $xy_values{$l->id} = $count;
            $count++;
        }
    }
    
    # Now go into each record a second time, counting the values for each
    # of the above unique values, and setting the count into the series hash.
    # $series holds all the info about each series of data. It's kept together
    # so that related data can be sorted together.
    my $series;
    foreach my $record (@{$self->records->results})
    {
        foreach my $x (@x)
        {
            my $x_value = $x_axis ? $record->fields->{$x->id} : $x->id
                or next;
            if ($x_axis && $x_axis->return_type eq 'date')
            {
                $x_value = _group_date($x_value->value, $self->x_axis_grouping)
                    or next;
                $x_value = $x_value->epoch;
            }
            next unless "$x_value";
            my @x_values = $x_axis && $x_axis->type eq 'daterange'
                         ? map { $_->epoch } _group_dates($x_value, $self->x_axis_grouping)
                         : ($x_value);

            my $y_value     = $x_axis ? $record->fields->{$y_axis->id} : $record->fields->{$x->id};
            my $y_field     = $x_axis ? $y_axis : $x; # The field of the y axis value
            my $groupby_val = $group_by && $record->fields->{$group_by->id};

            my $key;
            if ($self->type eq "pie")
            {
                $key = 1; # Only ever one key for the one ring of a pie
            }
            elsif ($self->type eq "donut")
            {
                $key = $groupby_val || 1; # Maybe no grouping will be set
            }
            elsif (!$groupby_val)
            {
                $key = 1; # Only one series
            }
            else {
                $key = $groupby_val;
            }

            unless ($self->type eq "pie" || $self->type eq "donut" || defined $series->{$key})
            {
                # If not defined, zero out the field's values
                my @zero = (0) x $count;
                $series->{$key}->{data} = \@zero;
                $series->{$key}->{y_group} = "$groupby_val" if $group_by;
            }
            # Finally increase by one the particlar value count in question
            foreach my $xv (@x_values)
            {
                my $idx = $xy_values{$xv};
                if ($self->y_axis_stack eq 'count')
                {
                    $series->{$key}->{data}->[$idx]++;
                }
                elsif($y_field->numeric) {
                    $series->{$key}->{data}->[$idx] += $y_value if $y_value;
                }
                else {
                    $series->{$key}->{data}->[$idx] = 0 unless $series->{$key}->{data}->[$idx];
                }
            }
        }
    }

    # If this graph is measuring against a metric, recalculate against that
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
        my %indices = reverse %xy_values;
        foreach my $line (keys %$series)
        {
            my @data = @{$series->{$line}->{data}};
            for my $i (0 .. $#data)
            {
                my $x = $indices{$i};
                $x    = $layout->column($x)->name unless $x_axis;
                my $target = $metrics->{$line}->{$x};
                $series->{$line}->{data}->[$i] = $target ? int ($data[$i] * 100 / $target ) : 0;
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
            my $s = $series->{$k}->{data};
            foreach my $item (keys %xy_values)
            {
                my $idx = $xy_values{$item};
                push @ps, [
                    $item, $s->[$idx],
                ] if $s->[$idx]
            }
            push @points, \@ps;
        }
    }
    else {
        # Now work out the Y labels for each point. Go into each data set and
        # see if there is a value. If there is, set the label, otherwise leave
        # it blank in order to show no label at that point
        foreach my $k (keys %$series)
        {
            my $y_group = $series->{$k}->{y_group} || '<blank value>';
            my ($showlabel, $color);
            if (!$y_group || $y_group_values{$y_group}->{defined})
            {
                $showlabel = 'false';
            }
            else {
                $showlabel = 'true';
                $y_group_values{$y_group}->{defined} = 1;
                $color = $self->get_color($y_group);
            }
            $series->{$k}->{label} = {
                color         => $color,
                showlabel     => $showlabel,
                showline      => $self->type eq "scatter" ? 'false' : 'true',
                markeroptions => $markeroptions,
                label         => $y_group
            };
        }

        # Sort the series by y_group, so that the groupings appear together on the chart
        my @all_series = values %$series;
        @all_series    = sort { $a->{y_group} cmp $b->{y_group} } @all_series if $group_by;
        @points        = map { $_->{data} } @all_series;
        @labels        = map { $_->{label} } @all_series;
    }

    {
        xlabels => \@xlabels,
        points  => \@points,
        labels  => \@labels, # Not used for pie/donut
    }
}

# Take a date and round it down according to the grouping
sub _group_date
{   my ($val, $grouping) = @_;
    $val or return;
    $grouping eq 'year'
         ? DateTime->new(year => $val->year)
         : $grouping eq 'month'
         ? DateTime->new(year => $val->year, month => $val->month)
         : $grouping eq 'day'
         ? DateTime->new(year => $val->year, month => $val->month, day => $val->day)
         : $val
}

sub _group_dates
{   my ($val, $grouping) = @_;
    $val or return;
    my $start  = _group_date($val->from_dt, $grouping);
    my @return = ($start);
    my $range  = $val->from_dt->clone;
    while ($range->epoch < _group_date($val->to_dt, $grouping)->epoch)
    {
        $range->add($grouping."s" => 1);
        push @return, _group_date($range, $grouping);
    }
    @return;
}

1;

