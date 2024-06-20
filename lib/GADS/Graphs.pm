
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

package GADS::Graphs;

use GADS::Graph;
use Log::Report 'linkspace';
use Scalar::Util qw/blessed/;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

has schema => (
    is       => 'ro',
    required => 1,
);

has current_user => (is => 'rw',);

has layout => (is => 'rw',);

has all => (
    is      => 'rw',
    builder => '_all',
    lazy    => 1,
);

sub _all
{   my $self = shift;

    my @graphs;
    my @user_graphs;

    # First create a hash of all the graphs the user has selected
    my %user_selected =
        map { $_->id => 1 } $self->schema->resultset('Graph')->search(
            {
                'user_graphs.user_id' => $self->current_user->id,
                instance_id           => $self->layout->instance_id,
            },
            {
                join => 'user_graphs',
            },
    )->all;

    # Now get all graphs, and use the previous hash to see
    # if the user has this graph selected
    my $all_rs = $self->schema->resultset('Graph')->search(
        {
            instance_id => $self->layout->instance_id,
            -or         => [
                {
                    'me.is_shared' => 1,
                    'me.group_id'  => undef,
                },
                {
                    'me.is_shared'        => 1,
                    'user_groups.user_id' => $self->current_user->id,
                },
                {
                    'me.user_id' => $self->current_user->id,
                },
            ],
        },
        {
            join => {
                group => 'user_groups',
            },
            collapse => 1,
            order_by => 'me.title',
        },
    );
    $all_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @all_graphs = $all_rs->all;
    foreach my $grs (@all_graphs)
    {
        my $graph = GADS::Graph->new(
            schema       => $self->schema,
            layout       => $self->layout,
            current_user => $self->current_user,
            selected     => $user_selected{ $grs->{id} },
            set_values   => $grs,
        );
        push @graphs, $graph;
    }

    \@graphs;
}

has all_shared => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_all_shared
{   my $self = shift;
    [ grep $_->is_shared, @{ $self->all } ];
}

has all_personal => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_all_personal
{   my $self = shift;
    [ grep !$_->is_shared, @{ $self->all } ];
}

has all_all_users => (is => 'lazy',);

sub _build_all_all_users
{   my $self = shift;

    my $all_rs = $self->schema->resultset('Graph')->search({
        instance_id => $self->layout->instance_id,
    });
    $all_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @all_graphs = $all_rs->all;
    my @graphs;
    foreach my $grs (@all_graphs)
    {
        my $graph = GADS::Graph->new(
            schema     => $self->schema,
            layout     => $self->layout,
            set_values => $grs,
        );
        push @graphs, $graph;
    }

    \@graphs;
}

sub purge
{   my $self = shift;
    foreach my $graph (@{ $self->all_all_users })
    {
        $graph->delete;
    }
}

sub types { qw(bar line donut scatter pie) }

1;

