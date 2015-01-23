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
        my ($graph) = $self->schema->resultset('Graph')->search({
            'me.id' => $self->id
        },{
            prefetch => [qw/x_axis y_axis group_by/],
        })->all;
        $graph;
    },
);

has set_values => (
    is => 'rw',
    trigger => sub {
        my ($self, $original) = @_;
        $self->id($original->{id});
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
    is  => 'rw',
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

has addgraphusers => (
    is      => 'rw',
    isa     => Bool,
);

has x_axis => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub { $_[0]->_graph && $_[0]->_graph->x_axis->id },
);

has x_axis_name => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->layout->column($_[0]->x_axis)->name },
);

has x_axis_grouping => (
    is      => 'rw',
    isa     => sub {
        return unless $_[0];
        grep { $_[0] eq $_ } keys GADS::Graphs->new->dategroup
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
    lazy    => 1,
    builder => sub {
        my $graph = $_[0]->_graph or return;
        # Legend is shown for secondary groupings. No point otherwise.
        $graph->group_by || $graph->type eq "pie" || $graph->type eq "donut" ? 'true' : 'false';
    },
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
    $newgraph->{x_axis}          = $self->x_axis or error __"Please select a field for X-axis";
    $newgraph->{x_axis_grouping} = $self->x_axis_grouping;
    $newgraph->{group_by}        = $self->group_by;
    $newgraph->{stackseries}     = $self->stackseries;
    $newgraph->{type}            = $self->type;

    if (my $graph = $self->_graph)
    {
        $graph->update($newgraph);
    }
    else {
        $self->_graph($self->schema->resultset('Graph')->create($newgraph));
    }

    # Add to all users default graphs if needed
    if ($self->addgraphusers)
    {
        my @existing = $self->schema->resultset('UserGraph')->search({
            graph_id => $self->id,
        })->all;
        foreach my $user (@{GADS::User->all})
        {
            unless (grep { $_->user_id == $user->id } @existing)
            {
                $self->schema->resultset('UserGraph')->create({
                    graph_id => $self->id,
                    user_id  => $user->id,
                });
            }
        }
    }
}

1;


