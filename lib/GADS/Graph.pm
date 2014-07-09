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
        $newgraph->{view_id}         = $args->{view_id} or ouch 'badvalue', "Please select a view";
        $args->{yaxis} eq 'count' || $args->{yaxis} eq 'sum'
            or ouch 'badvalue', "$args->{yaxis} is an invalid value for Y-axis";
        $newgraph->{yaxis}           = $args->{yaxis};
        $newgraph->{layout_id}       = $args->{xaxis} or ouch 'badvalue', "Please select a field for X-axis";
        if ($args->{layout_id_group})
        {
            grep { $args->{layout_id_group} eq $_ } keys dategroup
                or ouch 'badvalue', "$args->{layout_id_group} is an invalid value for X-axis grouping";
        }
        $newgraph->{layout_id_group} = $args->{layout_id_group};
        $newgraph->{layout_id2}      = $args->{layout_id2} ? $args->{layout_id2} : undef;
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
    my $records = $options->{records};

    # Graph columns are taken directly from the view. It may not be possible
    # to display them all though
    my @columns; my $yaxis;
    if ($graph->yaxis eq 'count')
    {
        # The count graph groups and counts values. As such, it's
        # only possible to display one field, so take only the first column
        push @columns, shift GADS::View->columns({ view_id => $graph->view->id });
        $yaxis = 'count';
    }
    elsif($graph->yaxis eq 'sum') {
        push @columns, shift GADS::View->columns({ view_id => $graph->view->id });
        # @columns = GADS::View->columns({ view_id => $graph->view->id });
        $yaxis = 'sum';
    }
    else {
        ouch 'badparam', "Unknown graph yaxis value ".$graph->yaxis;
    }

    my $series;
    my @xlabels; my @ylabels;
    # The unique hash holds each field value as its key, and
    # the array index associated with the field as its value
    my %unique;
    my %unique2;

    # $fieldgroup is the field to group by
    my $groupcol  = shift GADS::View->columns({ id => $graph->layout->id });
    my $groupcoltype = $graph->layout->type;
    my $groupcol2;
    $groupcol2 = shift GADS::View->columns({ id => $graph->layout_id2->id })
        if $graph->layout_id2;

    my $dtgroup;
    my ($datemin, $datemax);
    if ($groupcoltype eq 'date')
    {
        my $only;
        if ($graph->layout_id_group eq 'year')
        {
            $only = {year => 1};
        }
        elsif ($graph->layout_id_group eq 'month')
        {
            $only = {year => 1, month => 1};
        }
        elsif ($graph->layout_id_group eq 'day')
        {
            $only = {year => 1, month => 1, day => 1};
        }
        else {
            ouch 'badparam', "Unknown grouping for date: ".$graph->layout_id_group;
        }
        $dtgroup = {
            only     => $only,
            epoch    => 1,
            interval => $graph->layout_id_group
        };
    }

    my $fieldgroup = "field".$graph->layout->id;

    # $index2 used to count group2 unique values
    my $index2 = 0;

    my @colors = ('#FF6961', '#77DD77', '#FFB347', '#AEC6CF', '#FDFD96');
    # Go through each record, and count how many unique values
    # there are for the field in question. Then define the unique
    # hash value as above using the index count
    foreach my $record (@$records)
    {
        my $val  = item_value($groupcol , $record, $dtgroup);
        my $val2 = item_value($groupcol2, $record) if $groupcol2;
        if (!defined $unique{$val})
        {
            $unique{$val} = 1;
            push @xlabels, $val;
        }
        if ($groupcol2 && !defined $unique2{$val2})
        {
            $unique2{$val2} = { color => $colors[$index2], defined => 0 };
            $index2++;
        }
        if ($groupcoltype eq 'date')
        {
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
            $unique{$inc->epoch} = $count;
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
            $unique{$l} = $count;
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
    foreach my $record (@$records)
    {
        my $fieldcolval  = item_value($col, $record); # The actual value of the field
        my $fieldcolval2 = item_value($groupcol2, $record) if $groupcol2;

        my $key = $yaxis eq 'count' ? $fieldcolval : $fieldcolval2;
        unless (defined $series->{$key})
        {
            # If not defined, zero out the field's values
            my @zero = (0) x $count;
            $series->{$key}->{data} = \@zero;
            $series->{$key}->{group2} = $fieldcolval2;
        }
        # Finally increase by one the particlar value count in question
        my $gval = item_value($groupcol, $record, $dtgroup);
        my $idx = $unique{$gval};
        if ($yaxis eq 'count')
        {
            $series->{$key}->{data}->[$idx]++;
        }
        else {
            $series->{$key}->{data}->[$idx] += $fieldcolval;
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
        my $group2 = $series->{$k}->{group2} || '';
        my $showlabel;
        if (!$group2 || $unique2{$group2}->{defined})
        {
            $showlabel = 'false';
        }
        else {
            $showlabel = 'true';
            $unique2{$group2}->{defined} = 1;
        }
        $series->{$k}->{label} = {
            points        => \@row,
            color         => $unique2{$group2}->{color},
            showlabel     => $showlabel,
            showline      => $graph->type eq "scatter" ? 'false' : 'true',
            markeroptions => $markeroptions,
            label         => $group2
        };
    }

    # Sort the series by group2, so that the groupings appear together on the chart
    my @series = values $series;
    @series = sort { $a->{group2} cmp $b->{group2} } @series if $groupcol2;

    # Legend is shown for secondary groupings. No point otherwise.
    my $showlegend = $graph->layout_id2 || $graph->type eq "pie" ? 'true' : false;
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


