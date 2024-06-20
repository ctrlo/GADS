
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

package GADS::Groups;

use GADS::Group;
use Log::Report 'linkspace';
use Moo;

has schema => (
    is       => 'rw',
    required => 1,
);

has all => (is => 'lazy',);

sub _build_all
{   my $self = shift;

    my @all_rs = $self->schema->resultset('Group')->search(
        {},
        {
            order_by => 'me.name',
        },
    )->all;
    my @groups;
    foreach my $grs (@all_rs)
    {
        my $group = GADS::Group->new(
            id     => $grs->id,
            name   => $grs->name,
            schema => $self->schema,
        );
        push @groups, $group;
    }
    \@groups;
}

sub group
{   my ($self, $id) = @_;
    my ($group) = grep { $_->id == $id } @{ $self->all };
    $group;
}

sub purge
{   my $self = shift;
    foreach my $group (@{ $self->all })
    {
        $group->delete;
    }
}

1;
