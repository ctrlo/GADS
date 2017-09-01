=pod
GADS
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

package GADS::Instances;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'ro',
    required => 1,
);

has all => (
    is => 'lazy',
);

# Only return instances that this user has any access to
has user => (
    is => 'ro',
);

sub _build_all
{   my $self = shift;
    # See what tables this user has access to. Perform 2 separate queries,
    # otherwise the combined number of rows to search through is huge for all
    # the different user/group/layout combinations making the query very slow.
    #
    # First the user's groups, unless it's a layout admin
    my $search = {};
    if ($self->user && !$self->user->{permission}->{layout})
    {
        my @groups = $self->schema->resultset('Group')->search({
            'user_groups.user_id' => $self->user->{id}
        },{
            join => 'user_groups',
        })->get_column('me.id')->all;
        $search = {'layout_groups.group_id' => [@groups]};
    }
    # Then the instances
    my @instances = $self->schema->resultset('Instance')->search($search,{
        join     => {
            layouts => 'layout_groups',
        },
        collapse => 1,
        order_by => ['me.name'],
    })->all;
    \@instances;
}

sub is_valid
{   my ($self, $id) = @_;
    grep { $_->id == $id } @{$self->all}
        or return;
    $id; # Return ID to make testing easier
}

1;

