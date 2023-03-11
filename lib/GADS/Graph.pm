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

use JSON qw(decode_json encode_json);
use GADS::DateTime;
use GADS::Graphs;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'rw',
    required => 1,
);

has layout => (
    is => 'rw',
);

has current_user => (
    is => 'ro',
);

# Internal DBIC object of graph
has _graph => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->id or return;
        $self->id =~ /^[0-9]+$/
            or error __x"Invalid graph ID {id}", id => $self->id;
        my $graph = $self->schema->resultset('Graph')->find({
            'me.id' => $self->id
        },{
            prefetch => [qw/x_axis x_axis_link y_axis group_by/],
        });
        $graph
            or error __x"Requested graph ID {id} not found", id => $self->id;
    },
);

has set_values => (
    is => 'rw',
    trigger => sub {
        my ($self, $original) = @_;
        $self->_set_id($original->{id});
        $self->x_axis($original->{x_axis});
        $self->x_axis_link($original->{x_axis_link});
        $self->x_axis_grouping($original->{x_axis_grouping});
        $self->y_axis($original->{y_axis});
        $self->y_axis_stack($original->{y_axis_stack});
        $self->description($original->{description});
        $self->stackseries($original->{stackseries});
        $self->trend($original->{trend});
        $self->from($original->{from});
        $self->to($original->{to});
        $self->x_axis_range($original->{x_axis_range});
        $self->is_shared($original->{is_shared});
        $self->user_id($original->{user_id});
        $self->group_id($original->{group_id});
        $self->as_percent($original->{as_percent});
        $self->type($original->{type});
        $self->group_by($original->{group_by});
        $self->title($original->{title});
        $self->y_axis_label($original->{y_axis_label});
    },
);

has id => (
    is  => 'rwp',
);

has title => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->title },
);

has description => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->description },
);

sub set_x_axis
{   my ($self, $value) = @_;
    if ($value =~ /^([0-9]+)_([0-9]+)$/)
    {
        $self->x_axis($2);
        $self->x_axis_link($1);
        return;
    }
    $self->x_axis_link(undef);
    $self->x_axis($value);
}

has x_axis => (
    is      => 'rw',
    lazy    => 1,
    coerce  => sub { $_[0] || undef }, # Empty string from form
    builder => sub { $_[0]->_graph && $_[0]->_graph->x_axis && $_[0]->_graph->x_axis->id },
);

has x_axis_link => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->x_axis_link && $_[0]->_graph->x_axis_link->id },
);

sub x_axis_full
{   my $self = shift;
    return $self->x_axis_link."_".$self->x_axis
        if $self->x_axis_link;
    return $self->x_axis;
}

# X-axis is undef for graph showing all columns in view
has x_axis_name => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->x_axis ? $_[0]->layout->column($_[0]->x_axis)->name : "" },
);

has x_axis_grouping => (
    is      => 'rw',
    lazy    => 1,
    coerce  => sub { $_[0] || undef },
    builder => sub { $_[0]->_graph && $_[0]->_graph->x_axis_grouping },
);

has type => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->type },
);

has group_by => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->group_by && $_[0]->_graph->group_by->id },
    coerce  => sub { $_[0] || undef },
);

has stackseries => (
    is      => 'rw',
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub { $_[0]->_graph && $_[0]->_graph->stackseries },
);

has trend => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->trend },
);

my $coerce_datetime = sub {
    GADS::DateTime::parse_datetime(shift);
};

has from => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->from },
    coerce  => $coerce_datetime,
);

sub from_formatted
{   my $self = shift;
    return $self->from if !ref $self->from;
    my $dateformat = GADS::Config->instance->dateformat;
    $self->from && $self->from->format_cldr($dateformat);
}

has to => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->to },
    coerce  => $coerce_datetime,
);

sub to_formatted
{   my $self = shift;
    return $self->to if !ref $self->to;
    my $dateformat = GADS::Config->instance->dateformat;
    $self->to && $self->to->format_cldr($dateformat);
}

has x_axis_range => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->x_axis_range },
);

has is_shared => (
    is      => 'rw',
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub { $_[0]->_graph && $_[0]->_graph->is_shared },
);

has user_id => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->user_id },
);

has group_id => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->group_id },
);

has as_percent => (
    is      => 'rw',
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub { $_[0]->_graph && $_[0]->_graph->as_percent },
);

has y_axis => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->y_axis && $_[0]->_graph->y_axis->id },
);

has y_axis_label => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->y_axis_label },
);

has y_axis_stack => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->y_axis_stack },
);

has showlegend => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $graph = $_[0]->_graph or return;
        # Legend is shown for secondary groupings. No point otherwise.
        $graph->group_by || $graph->type eq "pie"
            || $graph->type eq "donut" || $graph->trend ? 1 : 0;
    },
);

# XXX This could potentially be a metric ID from another instance. This
# doesn't really matter, but would be tidier if it was fixed.
has metric_group_id => (
    is      => 'rw',
    lazy    => 1,
    coerce  => sub { $_[0] || undef }, # blank string from form
    builder => sub { $_[0]->_graph && $_[0]->_graph->get_column('metric_group') },
);

# Whether a user has the graph selected. Used by GADS::Graphs
has selected => (
    is     => 'rw',
    isa    => Bool,
    coerce => sub { $_[0] ? 1 : 0 },
);

sub writable_shared
{   my $self = shift;
    return 1 if $self->layout->user_can("layout");
    return 1 if $self->group_id && $self->layout->user_can("view_group");
    return 0;
}

sub writable
{   my $self = shift;
    return 1 if $GADS::Schema::IGNORE_PERMISSIONS;
    return 1 if $self->writable_shared;
    return 1 if !$self->id && !$self->is_shared; # new graph
    return 1 if $self->user_id && $self->current_user->id == $self->user_id;
    return 0;
}

sub as_json
{   my $self = shift;
    encode_json {
        type         => $self->type,
        x_axis_name  => $self->x_axis_name,
        y_axis_label => $self->y_axis_label,
        stackseries  => \$self->stackseries,
        showlegend   => \$self->showlegend,
        id           => $self->id,
    };
}

sub delete
{   my $self = shift;

    error __"You do not have permission to delete this graph"
        if !$self->writable;

    my $schema = $self->schema;
    my $graph = $schema->resultset('Graph')->find($self->id);
    $schema->resultset('Widget')->search({ graph_id => $self->id })->update({ graph_id => undef });
    $schema->resultset('UserGraph')->search({ graph_id => $self->id })->delete;
    $schema->resultset('Graph')->search({ id => $self->id })->delete;
}

# Write (updated) values to the database
sub write
{   my $self = shift;

    error __"You do not have permission to write to this graph"
        if !$self->writable;

    my $newgraph;
    $newgraph->{title}           = $self->title or error __"Please enter a title";

    $newgraph->{description}     = $self->description;

    if ($newgraph->{y_axis} = $self->y_axis)
    {
        $self->layout->column_this_instance($self->y_axis)
            or error __x"Invalid Y-axis {y_axis}", y_axis => $self->y_axis;
    }

    $newgraph->{y_axis_stack}    = $self->y_axis_stack or error __"A valid value is required for Y-axis stacking";
    !defined $self->y_axis_stack || $self->y_axis_stack eq 'count' || $self->y_axis_stack eq 'sum'
        or error __x"{yas} is an invalid value for Y-axis", yas => $self->y_axis_stack;

    $newgraph->{y_axis_stack} eq 'sum' && !$newgraph->{y_axis}
        and error __"Please select a Y-axis";

    $newgraph->{y_axis_label}    = $self->y_axis_label;

    $newgraph->{x_axis}          = $self->x_axis;
    !defined $self->x_axis || $self->layout->column($self->x_axis)
        or error __x"Invalid X-axis value {x_axis}", x_axis => $self->x_axis;
    $newgraph->{x_axis_link}     = $self->x_axis_link;

    error "Start date of custom range must be before end of custom range"
        if $self->from && $self->to && $self->from > $self->to;

    !$newgraph->{trend} || $newgraph->{trend} eq 'aggregate' || $newgraph->{trend} eq 'individual'
        or error __x"Invalid trend value: {trend}", trend => $newgraph->{trend};
    $newgraph->{trend} = $self->trend;
    $newgraph->{from} = $self->from || undef;
    $newgraph->{to} = $self->to || undef;
    $newgraph->{x_axis_range} = $self->x_axis_range;

    error __"An x-axis range must be selected when plotting historical trends"
        if !$newgraph->{x_axis_range} && $self->trend;

    $newgraph->{x_axis_grouping} = $self->x_axis_grouping;
    !defined $self->x_axis_grouping || grep { $self->x_axis_grouping eq $_ } qw/day month year/
        or error __x"{xas} is an invalid value for X-axis grouping", xas => $self->x_axis_grouping;

    my $x_axis_col = $self->layout->column($self->x_axis);
    error __"Dates and grouping must be entered for a custom range"
        if $x_axis_col && $x_axis_col->return_type =~ /date/
            && $newgraph->{x_axis_range} && $newgraph->{x_axis_range} eq 'custom'
            && (!$newgraph->{from} || !$newgraph->{to} || !$newgraph->{x_axis_grouping});

    error __"A single field must be selected for the x-axis when using the historic trend option"
        if !$newgraph->{x_axis} && $self->trend;

    $newgraph->{group_by}        = $self->group_by;
    !defined $self->group_by || $self->layout->column_this_instance($self->group_by)
        or error __x"Invalid group by value {group_by}", group_by => $self->group_by;

    $newgraph->{metric_group}    = $self->metric_group_id;
    !defined $self->metric_group_id || $self->metric_group_id =~ /^[0-9]+$/
        or error __x"Invalid metric group ID format {id}", id => $self->metric_group_id;
    !defined $self->metric_group_id || $self->schema->resultset('MetricGroup')->find($self->metric_group_id)
        or error __x"Invalid metric group ID {id}", id => $self->metric_group_id;

    $newgraph->{stackseries}     = $self->stackseries;

    $newgraph->{group_by} && $newgraph->{trend}
        and error __"Historical trends cannot be used with y-axis grouping (Group by)";

    error __"You do not have permission to create shared graphs"
        if $self->is_shared && !$self->writable_shared && !$GADS::Schema::IGNORE_PERMISSIONS;

    $newgraph->{is_shared}       = $self->is_shared;

    $newgraph->{group_id}        = $self->group_id || undef;
    $newgraph->{user_id}         = $self->user_id || $self->current_user->id
        unless $self->is_shared;

    $newgraph->{as_percent}      = $self->as_percent;

    $newgraph->{type}            = $self->type;
    grep { $self->type eq $_ } GADS::Graphs->types
        or error __x"Invalid graph type {type}", type => $self->type;

    $newgraph->{instance_id}     = $self->layout->instance_id;

    error __x"For graph {title}, a field returning a numeric value must be used for the Y-axis when calculating the sum of values",
        title => $self->title
            if $self->y_axis_stack eq 'sum' && !$self->layout->column($self->y_axis)->numeric;

    if (my $graph = $self->_graph)
    {
        $graph->update($newgraph);
    }
    else {
        $self->_graph($self->schema->resultset('Graph')->create($newgraph));
        $self->_set_id($self->_graph->id);
    }
}

sub import_hash
{   my ($self, $values, %options) = @_;
    no warnings "uninitialized";
    notice __x"Updating title from {old} to {new} for graph {name}",
        old => $self->title, new => $values->{title}, name => $self->title
            if $options{report_only} && $self->title ne $values->{title};
    $self->title($values->{title});
    notice __x"Updating description from {old} to {new} for graph {name}",
        old => $self->description, new => $values->{description}, name => $self->title
            if $options{report_only} && $self->description ne $values->{description};
    $self->description($values->{description});
    notice __x"Updating y_axis from {old} to {new} for graph {name}",
        old => $self->y_axis, new => $values->{y_axis}, name => $self->title
            if $options{report_only} && $self->y_axis != $values->{y_axis};
    $self->y_axis($values->{y_axis});
    notice __x"Updating y_axis_stack from {old} to {new} for graph {name}",
        old => $self->y_axis_stack, new => $values->{y_axis_stack}, name => $self->title
            if $options{report_only} && $self->y_axis_stack ne $values->{y_axis_stack};
    $self->y_axis_stack($values->{y_axis_stack});
    notice __x"Updating y_axis_label from {old} to {new} for graph {name}",
        old => $self->y_axis_label, new => $values->{y_axis_label}, name => $self->title
            if $options{report_only} && $self->y_axis_label ne $values->{y_axis_label};
    $self->y_axis_label($values->{y_axis_label});
    notice __x"Updating x_axis from {old} to {new} for graph {name}",
        old => $self->x_axis, new => $values->{x_axis}, name => $self->title
            if $options{report_only} && $self->x_axis != $values->{x_axis};
    $self->x_axis($values->{x_axis});
    notice __x"Updating x_axis_link from {old} to {new} for graph {name}",
        old => $self->x_axis_link, new => $values->{x_axis_link}, name => $self->title
            if $options{report_only} && $self->x_axis_link != $values->{x_axis_link};
    $self->x_axis_link($values->{x_axis_link});
    notice __x"Updating x_axis_grouping from {old} to {new} for graph {name}",
        old => $self->x_axis_grouping, new => $values->{x_axis_grouping}, name => $self->title
            if $options{report_only} && $self->x_axis_grouping ne $values->{x_axis_grouping};
    $self->x_axis_grouping($values->{x_axis_grouping});
    notice __x"Updating group_by from {old} to {new} for graph {name}",
        old => $self->group_by, new => $values->{group_by}, name => $self->title
            if $options{report_only} && $self->group_by != $values->{group_by};
    $self->group_by($values->{group_by});
    notice __x"Updating stackseries from {old} to {new} for graph {name}",
        old => $self->stackseries, new => $values->{stackseries}, name => $self->title
            if $options{report_only} && $self->stackseries != $values->{stackseries};
    $self->stackseries($values->{stackseries});
    notice __x"Updating trend from {old} to {new} for graph {name}",
        old => $self->trend, new => $values->{trend}, name => $self->title
            if $options{report_only} && ($self->trend||0) != ($values->{trend}||0);
    $self->trend($values->{trend});
    my $from = $values->{from} && DateTime::Format::ISO8601->parse_datetime($values->{from});
    notice __x"Updating from from {old} to {new} for graph {name}",
        old => $self->from, new => $from, name => $self->title
            if $options{report_only} && ($self->from || '') ne ($from || '');
    $self->from($from);
    my $to = $values->{to} && DateTime::Format::ISO8601->parse_datetime($values->{to});
    notice __x"Updating to from {old} to {new} for graph {name}",
        old => $self->to, new => $to, name => $self->title
            if $options{report_only} && ($self->to || '') ne ($to || '');
    $self->to($to);
    notice __x"Updating x_axis_range from {old} to {new} for graph {name}",
        old => $self->x_axis_range, new => $values->{x_axis_range}, name => $self->title
            if $options{report_only} && ($self->x_axis_range || '') ne ($values->{x_axis_range} || '');
    $self->x_axis_range($values->{x_axis_range});
    notice __x"Updating is_shared from {old} to {new} for graph {name}",
        old => $self->is_shared, new => $values->{is_shared}, name => $self->title
            if $options{report_only} && $self->is_shared != $values->{is_shared};
    $self->is_shared($values->{is_shared});
    notice __x"Updating user_id from {old} to {new} for graph {name}",
        old => $self->user_id, new => $values->{user_id}, name => $self->title
            if $options{report_only} && ($self->user_id || 0) != ($values->{user_id} || 0);
    $self->user_id($values->{user_id});
    notice __x"Updating group_id from {old} to {new} for graph {name}",
        old => $self->group_id, new => $values->{group_id}, name => $self->title
            if $options{report_only} && ($self->group_id || 0) != ($values->{group_id} || 0);
    $self->group_id($values->{group_id});
    notice __x"Updating as_percent from {old} to {new} for graph {name}",
        old => $self->as_percent, new => $values->{as_percent}, name => $self->title
            if $options{report_only} && $self->as_percent != $values->{as_percent};
    $self->as_percent($values->{as_percent});
    notice __x"Updating type from {old} to {new} for graph {name}",
        old => $self->type, new => $values->{type}, name => $self->title
            if $options{report_only} && $self->type ne $values->{type};
    $self->type($values->{type});
    notice __x"Updating metric_group_id from {old} to {new} for graph {name}",
        old => $self->metric_group_id, new => $values->{metric_group_id}, name => $self->title
            if $options{report_only} && $self->metric_group_id != $values->{metric_group_id};
    $self->metric_group_id($values->{metric_group_id});
}

sub export_hash
{   my $self = shift;
    +{
        title           => $self->title,
        description     => $self->description,
        y_axis          => $self->y_axis,
        y_axis_stack    => $self->y_axis_stack,
        y_axis_label    => $self->y_axis_label,
        x_axis          => $self->x_axis,
        x_axis_link     => $self->x_axis_link,
        x_axis_grouping => $self->x_axis_grouping,
        group_by        => $self->group_by,
        stackseries     => $self->stackseries,
        trend           => $self->trend,
        from            => $self->from && $self->from->datetime,
        to              => $self->to && $self->to->datetime,
        x_axis_range    => $self->x_axis_range,
        is_shared       => $self->is_shared,
        user_id         => $self->user_id,
        group_id        => $self->group_id,
        as_percent      => $self->as_percent,
        type            => $self->type,
        metric_group_id => $self->metric_group_id,
    };
}

1;
