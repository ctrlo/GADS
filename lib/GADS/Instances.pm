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
    my $search = {};
    $search = { 'user_groups.user_id' => $self->user->{id} }
        if $self->user && !$self->user->{permission}->{layout};
    my $instance_rs = $self->schema->resultset('Instance')->search($search,{
        join     => {
            layouts => {
                layout_groups => {
                    group => 'user_groups',
                },
            },
        },
        collapse => 1,
        order_by => ['me.name'],
    });
    my @all = $instance_rs->all;
    \@all;
}

sub is_valid
{   my ($self, $id) = @_;
    grep { $_->id == $id } @{$self->all}
        or return;
    $id; # Return ID to make testing easier
}

1;

