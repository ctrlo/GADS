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

package GADS::Graph;

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use GADS::View;
use GADS::Util    qw(item_value);
use Ouch;
use Scalar::Util qw(looks_like_number);
# use String::CamelCase qw(camelize);
schema->storage->debug(1);

use GADS::Schema;

sub all
{   my ($class, $params) = @_;

    my @graphs;
    if (my $user = $params->{user})
    {
        @graphs = rset('Graph')->search({
            'user_graphs.user_id' => $user->{id},
        },{
            join => 'user_graphs',
        })->all;

        if ($params->{all})
        {
            my @g;
            foreach my $g (rset('Graph')->all)
            {
                my $selected = grep { $_->id == $g->id } @graphs;
                push @g, {
                    id          => $g->id,
                    title       => $g->title,
                    description => $g->description,
                    selected    => $selected,
                };
            }
            @graphs = @g;
        }
    }
    else {
        @graphs = rset('Graph')->all unless @graphs;
    }

    \@graphs;
}

sub dategroup
{
    {
        day   => '%d %B %Y',
        month => '%B %Y',
        year  => '%Y',
    }
}

sub graphtypes
{
    qw(bar line donut scatter pie);
}

sub graph
{   my ($class, $args) = @_;
    my $graph;
    if($args->{submit})
    {
        my $newgraph;
        $newgraph->{title}           = $args->{title} or ouch 'badvalue', "Please enter a title";
        $newgraph->{description}     = $args->{description};
        $newgraph->{y_axis}          = $args->{y_axis} or ouch 'badvalue', "Please select a Y-axis";
        $args->{y_axis_stack} eq 'count' || $args->{y_axis_stack} eq 'sum'
            or ouch 'badvalue', "$args->{y_axis_stack} is an invalid value for Y-axis";
        $newgraph->{y_axis_stack}    = $args->{y_axis_stack};
        $newgraph->{x_axis}          = $args->{x_axis} or ouch 'badvalue', "Please select a field for X-axis";
        if ($args->{x_axis_grouping})
        {
            grep { $args->{x_axis_grouping} eq $_ } keys dategroup
                or ouch 'badvalue', "$args->{x_axis_grouping} is an invalid value for X-axis grouping";
        }
        $newgraph->{x_axis_grouping} = $args->{x_axis_grouping};
        $newgraph->{group_by}        = $args->{group_by} ? $args->{group_by} : undef;
        $newgraph->{stackseries}     = $args->{stackseries} ? 1 : 0;
        grep { $args->{type} eq $_ } graphtypes
            or ouch 'badvalue', "Invalid graph type $newgraph->{type}";
        $newgraph->{type} = $args->{type};
        if ($args->{id})
        {
            my $g = rset('Graph')->find($args->{id})
                or ouch 'notfound', "Requested graph ID $args->{id} not found";
            $g->update($newgraph);
        }
        else {
            $args->{id} = rset('Graph')->create($newgraph)->id;
        }

        # Add to all users default graphs if needed
        if ($args->{addgraphusers})
        {
            my @existing = rset('UserGraph')->search({ graph_id => $args->{id} })->all;
            foreach my $user (@{GADS::User->all})
            {
                unless (grep { $_->user_id == $user->id } @existing)
                {
                    rset('UserGraph')->create({
                        graph_id => $args->{id},
                        user_id  => $user->id,
                    }) or ouch 'dbfail', "There was an error adding a graph to a user";
                }
            }
        }
    }
    
    rset('Graph')->find($args->{id})
        or ouch 'notfound', "Unable to find graph ID $args->{id}";
}


# Function to fill out the series of data that will be plotted on a graph
sub data
{
    my ($class, $options) = @_;
    my $graph   = $options->{graph};

    my @columns; my $y_axis_stack;
    if ($graph->y_axis_stack eq 'count')
    {
        # The count graph groups and counts values. As such, it's
        # only possible to display one field, so take only the first column
        push @columns, shift GADS::View->columns({ id => $graph->y_axis->id });
        $y_axis_stack = 'count';
    }
    elsif($graph->y_axis_stack eq 'sum') {
        push @columns, shift GADS::View->columns({ id => $graph->y_axis->id });
        $y_axis_stack = 'sum';
    }
    else {
        ouch 'badparam', "Unknown graph y_axis_stack value ".$graph->y_axis_stack;
    }

    my $series;
    my @xlabels; my @ylabels;

    # $fieldgroup is the field to group by
    my $x_axis  = shift GADS::View->columns({ id => $graph->x_axis->id });
    my $group_by;
    $group_by = shift GADS::View->columns({ id => $graph->group_by->id })
        if $graph->group_by;

    my $dtgroup;
    my ($datemin, $datemax);
    if ($x_axis->{type} eq 'date')
    {
        my $date_fields;
        if ($graph->x_axis_grouping eq 'year')
        {
            $date_fields = {year => 1};
        }
        elsif ($graph->x_axis_grouping eq 'month')
        {
            $date_fields = {year => 1, month => 1};
        }
        elsif ($graph->x_axis_grouping eq 'day')
        {
            $date_fields = {year => 1, month => 1, day => 1};
        }
        else {
            ouch 'badparam', "Unknown grouping for date: ".$graph->x_axis_grouping;
        }
        $dtgroup = {
            date_fields => $date_fields,
            epoch       => 1,
            interval    => $graph->x_axis_grouping
        };
    }

    # $y_group_index used to count y_group unique values
    my $y_group_index = 0;

    my @colors = ('#FF6961', '#77DD77', '#FFB347', '#AEC6CF', '#FDFD96');

    my @additional = ($x_axis);
    push @additional, $group_by if $group_by;
    my @records = GADS::Record->current({ view_id => $options->{view_id}, additional => \@additional });

    # Go through each record, and count how many unique values
    # there are for the field in question. Then define the key
    # of the xy_values hash using the index count
    my %xy_values; my %y_group_values;
    foreach my $record (@records)
    {
        my $val  = item_value($x_axis, $record, $dtgroup);
        my $val2 = item_value($group_by, $record) if $group_by;
        if (!defined $xy_values{$val})
        {
            $xy_values{$val} = 1;
            push @xlabels, $val;
        }
        if ($group_by && !defined $y_group_values{$val2})
        {
            $y_group_values{$val2} = { color => $colors[$y_group_index], defined => 0 };
            $y_group_index++;
        }
        if ($x_axis->{type} eq 'date')
        {
            next unless $val;
            $datemin = $val if !defined $datemin || $datemin > $val;
            $datemax = $val if !defined $datemax || $datemax < $val;
        }
    }

    @xlabels = sort @xlabels;
    my $count = 0;
    if ($dtgroup)
    {
        @xlabels = ();
        my $inc = DateTime->from_epoch( epoch => $datemin );
        my $add = $dtgroup->{interval}.'s';
        while ($inc->epoch <= $datemax)
        {
            $xy_values{$inc->epoch} = $count;
            my $dg = dategroup;
            my $df = $dg->{$dtgroup->{interval}};
            push @xlabels, $inc->strftime($df);
            $inc->add( $add => 1 );
            $count++;
        }
    }
    else
    {
        foreach my $l (@xlabels)
        {
            $xy_values{$l} = $count;
            $count++;
        }
    }
    
    my ($col) = @columns; # Only one column for a count graph
    $col or return;

    # $fieldcol is the field that is used for each column on the graph
    # (i.e. what is being grouped by)
    my $fieldcol = "field".$col->{id};

    # Now go into each record a second time, counting the values for each
    # of the above unique values, and setting the count into the series hash
    foreach my $record (@records)
    {
        my $fieldcolval  = item_value($col, $record); # The actual value of the field
        my $fieldcolval2 = item_value($group_by, $record) if $group_by;

        my $key = $y_axis_stack eq 'count' ? $fieldcolval : $fieldcolval2;
        unless (defined $series->{$key})
        {
            # If not defined, zero out the field's values
            my @zero = (0) x $count;
            $series->{$key}->{data} = \@zero;
            $series->{$key}->{y_group} = $fieldcolval2;
        }
        # Finally increase by one the particlar value count in question
        my $gval = item_value($x_axis, $record, $dtgroup);
        my $idx = $xy_values{$gval};
        if ($y_axis_stack eq 'count')
        {
            $series->{$key}->{data}->[$idx]++;
        }
        elsif(looks_like_number $fieldcolval) {
            $series->{$key}->{data}->[$idx] += $fieldcolval if $fieldcolval;
        }
        else {
            $series->{$key}->{data}->[$idx] = 0;
        }
    }

    my $markeroptions = $graph->type eq "scatter"
                      ? '{ size: 7, style:"x" }'
                      : '{ show: false }';

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
            points        => \@row,
            color         => $y_group_values{$y_group}->{color},
            showlabel     => $showlabel,
            showline      => $graph->type eq "scatter" ? 'false' : 'true',
            markeroptions => $markeroptions,
            label         => $y_group
        };
    }

    # Sort the series by y_group, so that the groupings appear together on the chart
    my @series = values $series;
    @series = sort { $a->{y_group} cmp $b->{y_group} } @series if $group_by;

    # Legend is shown for secondary groupings. No point otherwise.
    my $showlegend = $graph->group_by || $graph->type eq "pie" ? 'true' : false;
    # Other graph options from graph definition
    my $stackseries = $graph->stackseries ? 'true' : false;
    my $type = $graph->type ? $graph->type : 'line';

    # The graph hash
    {
        dbrow       => $graph,
        xlabels     => \@xlabels,
        ylabels     => \@ylabels,
        series      => \@series,
        showlegend  => $showlegend,
        stackseries => $stackseries,
        type        => $type,
    };
}





1;


