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

package GADS::MetricGroups;

use GADS::MetricGroup;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw(Int);

has schema => (
    is       => 'ro',
    required => 1,
);

has instance_id => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has all => (
    is      => 'lazy',
);

sub _build_all
{   my $self = shift;

    my @metrics;

    my @all = $self->schema->resultset('MetricGroup')->search(
    {
        instance_id => $self->instance_id,
    },{
        order_by => 'me.name',
    });
    foreach my $metric (@all)
    {
        push @metrics, GADS::MetricGroup->new({
            id          => $metric->id,
            name        => $metric->name,
            schema      => $self->schema,
            instance_id => $self->instance_id,
        });
    }

    \@metrics;
}

sub purge
{   my $self = shift;
    foreach my $mg (@{$self->all})
    {
        $mg->delete;
    }
}

1;


