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

use GADS::Graphs;
use Log::Report;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'rw',
    required => 1,
);

has layout => (
    is => 'rw',
);

# Internal DBIC object of graph
has _graph => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->id or return;
        my ($graph) = $self->schema->resultset('Graph')->search({
            'me.id' => $self->id
        },{
            prefetch => [qw/x_axis y_axis group_by/],
        })->all;
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
        $self->x_axis_grouping($original->{x_axis_grouping});
        $self->y_axis($original->{y_axis});
        $self->y_axis_stack($original->{y_axis_stack});
        $self->description($original->{description});
        $self->stackseries($original->{stackseries});
        $self->type($original->{type});
        $self->group_by($original->{group_by});
        $self->title($original->{title});
        $self->y_axis_label($original->{y_axis_label});
    },
);

has id => (
    is  => 'rwp',
    isa => Int,
);

has title => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->title },
);

has description => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->description },
);

has x_axis => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    coerce  => sub { $_[0] || undef }, # Empty string from form
    builder => sub { $_[0]->_graph && $_[0]->_graph->x_axis && $_[0]->_graph->x_axis->id },
);

# X-axis is undef for graph showing all columns in view
has x_axis_name => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->x_axis ? $_[0]->layout->column($_[0]->x_axis)->name : "" },
);

has x_axis_grouping => (
    is      => 'rw',
    isa     => sub {
        return unless $_[0];
        grep { $_[0] eq $_ } keys %{GADS::Graphs->new->dategroup}
            or error __x"{xas} is an invalid value for X-axis grouping", xas => $_[0];
    },
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->x_axis_grouping },
);

has type => (
    is      => 'rw',
    isa     => sub {
        return unless $_[0];
        grep { $_[0] eq $_ } GADS::Graphs->types
            or error __x"Invalid graph type {type}", type => $_[0];
    },
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->type },
);

has group_by => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->group_by && $_[0]->_graph->group_by->id },
    coerce  => sub { $_[0] || undef },
);

has stackseries => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub { $_[0]->_graph && $_[0]->_graph->stackseries },
);

has y_axis => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->y_axis->id },
);

has y_axis_label => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->y_axis_label },
);

has y_axis_stack => (
    is      => 'rw',
    isa     => sub {
        return unless $_[0];
        error __x"{yas} is an invalid value for Y-axis", yas => $_[0]
            unless $_[0] eq 'count' || $_[0] eq 'sum';
    },
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->y_axis_stack },
);

has showlegend => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    builder => sub {
        my $graph = $_[0]->_graph or return;
        # Legend is shown for secondary groupings. No point otherwise.
        $graph->group_by || $graph->type eq "pie" || $graph->type eq "donut" ? 1 : 0;
    },
);

# XXX This could potentially be a metric ID from another instance. This
# doesn't really matter, but would be tidier if it was fixed.
has metric_group_id => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    coerce  => sub { $_[0] || undef }, # blank string from form
    builder => sub { $_[0]->_graph && $_[0]->_graph->get_column('metric_group') },
);

# Whether a user has the graph selected. Used by GADS::Graphs
has selected => (
    is  => 'rw',
    isa => Bool,
);

sub delete
{   my $self = shift;

    my $schema = $self->schema;
    my $graph = $schema->resultset('Graph')->find($self->id);
    $schema->resultset('UserGraph')->search({ graph_id => $self->id })->delete;
    $schema->resultset('Graph')->search({ id => $self->id })->delete;
}

# Write (updated) values to the database
sub write
{   my $self = shift;

    my $newgraph;
    $newgraph->{title}           = $self->title or error __"Please enter a title";
    $newgraph->{description}     = $self->description;
    $newgraph->{y_axis}          = $self->y_axis or error __"Please select a Y-axis";
    $newgraph->{y_axis_stack}    = $self->y_axis_stack or error __"A valid is required for Y-xis stacking";
    $newgraph->{y_axis_label}    = $self->y_axis_label;
    $newgraph->{x_axis}          = $self->x_axis;
    $newgraph->{x_axis_grouping} = $self->x_axis_grouping;
    $newgraph->{group_by}        = $self->group_by;
    $newgraph->{metric_group}    = $self->metric_group_id;
    $newgraph->{stackseries}     = $self->stackseries;
    $newgraph->{type}            = $self->type;
    $newgraph->{instance_id}     = $self->layout->instance_id;

    error __"A field returning a numberic value must be used for the Y-axis when calculating the sum of values"
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
{   my ($self, $values) = @_;
    $self->title($values->{title});
    $self->description($values->{description});
    $self->y_axis($values->{y_axis});
    $self->y_axis_stack($values->{y_axis_stack});
    $self->y_axis_label($values->{y_axis_label});
    $self->x_axis($values->{x_axis});
    $self->x_axis_grouping($values->{x_axis_grouping});
    $self->group_by($values->{group_by});
    $self->stackseries($values->{stackseries});
    $self->type($values->{type});
    $self->metric_group($values->{metric_group_id});
}

sub export
{   my $self = shift;
    +{
        title           => $self->title,
        description     => $self->description,
        y_axis          => $self->y_axis,
        y_axis_stack    => $self->y_axis_stack,
        y_axis_label    => $self->y_axis_label,
        x_axis          => $self->x_axis,
        x_axis_grouping => $self->x_axis_grouping,
        group_by        => $self->group_by,
        stackseries     => $self->stackseries,
        type            => $self->type,
        metric_group    => $self->metric_group_id,
    };
}

1;


