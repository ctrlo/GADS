
=pod
GADS - Globally Accessible Data Store
Copyright (C) 2015 Ctrl O Ltd

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

package GADS::MetricGroup;

use Data::Compare qw/Compare/;
use GADS::Metric;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

has schema => (
    is       => 'ro',
    required => 1,
);

has instance_id => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has id => (is => 'rwp',);

has metrics => (is => 'lazy',);

has _rset => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $id   = $self->id;
        $id or return;
        $id =~ /^[0-9]+$/
            or error __x "Invalid ID format {id}", id => $id;
        my $mg = $self->schema->resultset('MetricGroup')->find({
            id => $id,

            # instance_id isn't strictly needed as id is the primary key
            instance_id => $self->instance_id,
        });
        $mg or error __x "Metric Group ID {id} not found", id => $id;
        $mg;
    },
);

has name => (
    is      => 'rw',
    isa     => Maybe [Str],
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->id or return;
        $self->_rset->name;
    },
);

sub _build_metrics
{   my $self = shift;

    my @metrics;

    my @all = $self->schema->resultset('Metric')->search(
        {
            metric_group => $self->id,
            instance_id  => $self->instance_id,    # Safety check
        },
        {
            join     => 'metric_group',
            order_by => [qw/x_axis_value y_axis_grouping_value/],
        },
    );
    foreach my $metric (@all)
    {
        push @metrics,
            GADS::Metric->new(
                id                    => $metric->id,
                x_axis_value          => $metric->x_axis_value,
                target                => $metric->target,
                y_axis_grouping_value => $metric->y_axis_grouping_value,
            );
    }

    \@metrics;
}

sub write
{   my $self = shift;

    my $name = $self->name
        or error __ "Please enter a name for the metric";

    if ($self->id)
    {
        $self->_rset->update({
            name => $name,
        });
    }
    else
    {
        my $rset = $self->schema->resultset('MetricGroup')->create({
            name        => $name,
            instance_id => $self->instance_id,
        });
        $self->_set_id($rset->id);
    }
}

sub delete
{   my $self = shift;

    # See if it's being used in a graph first
    my @graphs = $self->schema->resultset('Graph')->search({
        metric_group => $self->id,
    })->all;
    if (@graphs)
    {
        my @names = map { $_->title } @graphs;
        my $names = join ', ', @names;
        error __x
"The metric is being used in the following graphs: {names}. Please remove it first.",
            names => $names;
    }

    $self->schema->resultset('Metric')->search({
        metric_group => $self->id,
    })->delete;

    $self->_rset->delete;
}

# Delete a single metric within a group
sub delete_metric
{   my ($self, $metric_id) = @_;

    $self->schema->resultset('Metric')->search({
        id           => $metric_id,
        metric_group => $self->id,
    })->delete;
}

sub export_hash
{   my $self = shift;
    my $json = {
        id      => $self->id,
        name    => $self->name,
        metrics => [],
    };
    foreach my $metric (@{ $self->metrics })
    {
        push @{ $json->{metrics} },
            {
                id                    => $metric->id,
                x_axis_value          => $metric->x_axis_value,
                target                => $metric->target,
                y_axis_grouping_value => $metric->y_axis_grouping_value,
            };
    }
    $json;
}

sub import_hash
{   my ($self, $values) = @_;

    my @existing = map {
        +{
            x_axis_value          => $_->x_axis_value,
            target                => $_->target,
            y_axis_grouping_value => $_->y_axis_grouping_value,
        }
    } @{ $self->metrics };

    delete $_->{id} foreach @{ $values->{metrics} };

    my $same = Compare \@existing, $values->{metrics};

    if ($same)
    {
        trace __x "Metrics identical for {name}", name => $self->name;
        return;
    }

    notice __x "Metrics are different for {name}. Will delete and recreate.",
        name => $self->name;

    $self->delete_metric($_->id) foreach @{ $self->metrics };

    foreach my $metric (@{ $values->{metrics} })
    {
        GADS::Metric->new(
            target                => $metric->{target},
            metric_group_id       => $self->id,
            x_axis_value          => $metric->{x_axis_value},
            y_axis_grouping_value => $metric->{y_axis_grouping_value},
            schema                => $self->schema,
        )->write;
    }

}

1;

