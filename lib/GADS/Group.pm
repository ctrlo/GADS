
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

package GADS::Group;

use GADS::Type::Permissions;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'rw',
    required => 1,
);

has id => (
    is  => 'rwp',
    isa => Int,
);

has name => (
    is  => 'rw',
    isa => Str,
);

has default_read => (
    is  => 'rw',
    isa => Bool,
);

has default_write_new => (
    is  => 'rw',
    isa => Bool,
);

has default_write_existing => (
    is  => 'rw',
    isa => Bool,
);

has default_approve_new => (
    is  => 'rw',
    isa => Bool,
);

has default_approve_existing => (
    is  => 'rw',
    isa => Bool,
);

has default_write_new_no_approval => (
    is  => 'rw',
    isa => Bool,
);

has default_write_existing_no_approval => (
    is  => 'rw',
    isa => Bool,
);

has columns => (
    is  => 'lazy',
    isa => HashRef,
);

# Internal DBIC object of group
has _rset => (
    is      => 'rwp',
    lazy    => 1,
    builder => 1,
);

sub _build__rset
{   my $self = shift;
    my $rset;
    if ($self->id)
    {
        $rset = $self->schema->resultset('Group')->find($self->id);
    }
    else
    {
        $rset = $self->schema->resultset('Group')->create({ name => undef });
        $self->_set_id($rset->id);
    }
    $rset;
}

sub _build_columns
{   my $self  = shift;
    my @perms = $self->schema->resultset('LayoutGroup')->search({
        group_id => $self->id,
    })->all;
    my %columns;
    foreach my $perm (@perms)
    {
        $columns{ $perm->layout_id } ||= [];
        push @{ $columns{ $perm->layout_id } },
            GADS::Type::Permission->new(short => $perm->permission,);
    }
    \%columns;
}

# Populate from the database by role ID
sub from_id
{   my ($self, $id) = @_;

    $id or return;

    my $group = $self->schema->resultset('Group')->find($id)
        or return;

    $self->_set__rset($group);
    $self->name($group->name);
    foreach my $perm (GADS::Type::Permissions->all)
    {
        my $name = "default_" . $perm->short;
        $self->$name($group->$name);
    }
    $self->_set_id($id);
}

sub delete
{   my $self = shift;

    my $schema = $self->schema;
    $self->schema->resultset('LayoutGroup')->search({ group_id => $self->id })
        ->delete;
    $self->schema->resultset('InstanceGroup')
        ->search({ group_id => $self->id })->delete;
    $self->schema->resultset('UserGroup')->search({ group_id => $self->id })
        ->delete;
    $self->_rset->delete;
}

# Write (updated) values to the database
sub write
{   my $self = shift;
    my $newgroup;
    $newgroup->{name} = $self->name or error __ "Please enter a name";
    foreach my $perm (GADS::Type::Permissions->all)
    {
        my $name = "default_" . $perm->short;
        $newgroup->{$name} = $self->$name;
    }
    $self->_rset->update($newgroup);
}

1;

