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

use Log::Report 'linkspace';
use Moo;

# Not required so that dategroup can be called separately
has schema => (
    is       => 'rw',
);

has user => (
    is => 'rw',
);

has layout => (
    is => 'rw',
);

has all => (
    is      => 'rw',
    builder => '_all',
    lazy    => 1,
);

sub _all
{   my $self = shift;

    my @graphs; my @user_graphs;
    if (my $user = $self->user)
    {
        # XXX When the DBIC rel options show up, this can all be
        # simplified with a custom join condition. For now, do
        # two separate queries

        # Get which graphs the user has first
        my $user_id = ref $self->user eq 'HASH' ? $self->user->{id} : $self->user->id;
        @user_graphs = $self->schema->resultset('Graph')->search({
            'user_graphs.user_id' => $user_id,
            instance_id           => $self->layout->instance_id,
        },{
            join => 'user_graphs',
        })->all;
    }

    # Now get all graphs, and use the previous query to see
    # if the user has this graph
    my $all_rs = $self->schema->resultset('Graph')->search(
    {
        instance_id => $self->layout->instance_id,
    },{
        order_by => 'me.title',
    });
    $all_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @all_graphs = $all_rs->all;
    foreach my $grs (@all_graphs)
    {
        my $selected = grep { $_->id == $grs->{id} } @user_graphs;
        my $graph = GADS::Graph->new(schema => $self->schema, layout => $self->layout);
        $graph->set_values($grs);
        $graph->selected($selected ? 1 : 0);
        push @graphs, $graph;
    }

    \@graphs;
}

sub purge
{   my $self = shift;
    foreach my $graph (@{$self->all})
    {
        $graph->delete;
    }
}

sub dategroup
{
    {
        day   => '%d %B %Y',
        month => '%B %Y',
        year  => '%Y',
    };
};

sub types
{ qw(bar line donut scatter pie) }

1;


