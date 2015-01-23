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

use Scalar::Util qw(looks_like_number);
use JSON qw(decode_json encode_json);

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

has points => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_data->{points} },
);

has showlegend => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_data->{showlegend} },
);

# Function to fill out the series of data that will be plotted on a graph
has _data => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_build_data },
);

sub _build_data
{   my $self = shift;

    # XXX A lot of this would probably be better done by the database...

    my $layout   = $self->records->layout;
    my $x_axis   = $layout->column($self->x_axis);
    my $y_axis   = $layout->column($self->y_axis);
    my $group_by = $self->group_by && $layout->column($self->group_by);

    # $y_group_index used to count y_group unique values
    my $y_group_index = 0;

    my @colors = ('#FF6961', '#77DD77', '#FFB347', '#AEC6CF', '#FDFD96');

    # Go through each record, and count how many unique values
    # there are for the field in question. Then define the key
    # of the xy_values hash using the index count
    my %xy_values; my %y_group_values;
    my ($datemin, $datemax);
    foreach my $record (@{$self->records->results})
    {
        my $xval = $record->fields->{$x_axis->id};
        if ($x_axis->return_type && $x_axis->return_type eq 'date')
        {
            $xval = _group_date($xval->value, $self->x_axis_grouping);
        }
        next unless $xval;

        my $gval = $group_by && $record->fields->{$group_by->id};

        if (!defined $xy_values{$xval})
        {
            $xy_values{"$xval"} = 1;
        }
        if ($group_by && !defined $y_group_values{$gval})
        {
            $y_group_values{$gval} = { color => $colors[$y_group_index], defined => 0 };
            $y_group_index++;
        }
        if ($x_axis->return_type && $x_axis->return_type eq 'date')
        {
            $datemin = $xval if !defined $datemin || $datemin > $xval;
            $datemax = $xval if !defined $datemax || $datemax < $xval;
        }
    }

    my $dg = {
        day   => '%d %B %Y',
        month => '%B %Y',
        year  => '%Y',
    };

    my @xlabels = sort keys %xy_values;
    my $count = 0;
    if ($datemin && $datemax)
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
    else
    {
        # Generate unique index numbers for all the x-values
        foreach my $l (@xlabels)
        {
            $xy_values{$l} = $count;
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
        my $x_value     = $record->fields->{$x_axis->id};
        if ($x_axis->return_type && $x_axis->return_type eq 'date')
        {
            $x_value = _group_date($x_value->value, $self->x_axis_grouping);
        }
        next unless $x_value;
        my $y_value     = $record->fields->{$y_axis->id};
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
            # XXX Not sure why this line of code was written. Possibly leaves a bug
            # $key = $self->y_axis_stack eq 'count' ? $x_value : $groupby_val;
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
        my $idx = $xy_values{$x_value};
        if ($self->y_axis_stack eq 'count')
        {
            $series->{$key}->{data}->[$idx]++;
        }
        elsif(looks_like_number $y_value) {
            $series->{$key}->{data}->[$idx] += $y_value if $y_value;
        }
        else {
            $series->{$key}->{data}->[$idx] = 0 unless $series->{$key}->{data}->[$idx];
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
            my @row;
            my $s = $series->{$k}->{data};
            foreach my $point (@$s)
            {
                my $label = $point ? $k : '';
                push @row, $label;
            }
            my $y_group = $series->{$k}->{y_group} || '';
            my $showlabel;
            if (!$y_group || $y_group_values{$y_group}->{defined})
            {
                $showlabel = 'false';
            }
            else {
                $showlabel = 'true';
                $y_group_values{$y_group}->{defined} = 1;
            }
            $series->{$k}->{label} = {
                color         => $y_group_values{$y_group}->{color},
                showlabel     => $showlabel,
                showline      => $self->type eq "scatter" ? 'false' : 'true',
                markeroptions => $markeroptions,
                label         => $y_group
            };
        }

        # Sort the series by y_group, so that the groupings appear together on the chart
        my @all_series = values $series;
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
         ? DateTime->new(year => $val->year)->epoch
         : $grouping eq 'month'
         ? DateTime->new(year => $val->year, month => $val->month)->epoch
         : $grouping eq 'day'
         ? DateTime->new(year => $val->year, month => $val->month, day => $val->month)->epoch
         : $val->epoch
}

1;

