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

use GADS::Config;
use GADS::Layout;
use Log::Report;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'ro',
    required => 1,
);

has user => (
    is       => 'ro',
    required => 1,
);

has all => (
    is => 'lazy',
);

has all_of_user => (
    is => 'lazy',
);

sub _build_all
{   my $self = shift;
    [grep { $_->user_can_anything } @{$self->_layouts}];
}

has _layouts => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build__layouts
{   my $self = shift;
    my @layouts;

    # Get all permissions to save them being built in each instance
    my $rs = $self->schema->resultset('InstanceGroup')->search({
        user_id => $self->user->{id},
    },{
        select => [
            {
                max => 'instance_id',
            },
            {
                max => 'permission',
            },
        ],
        as       => [qw/instance_id permission/],
        group_by => [qw/permission instance_id/],
        join     => {
            group => 'user_groups',
        },
    });
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

    my $perms_table;
    $perms_table->{$_->{instance_id}}->{$_->{permission}} = 1
        foreach ($rs->all);

    $rs = $self->schema->resultset('LayoutGroup')->search({
        user_id => $self->user->{id},
    },{
        select => [
            {
                max => 'layout.instance_id',
            },
            {
                max => 'me.layout_id',
            },
            {
                max => 'me.permission',
            },
        ],
        as       => [qw/instance_id layout_id permission/],
        group_by => [qw/me.permission me.layout_id/],
        join     => [
            'layout',
            {
                group => 'user_groups',
            },
        ],
    });
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

    my $perms_columns;
    $perms_columns->{$_->{instance_id}}->{$_->{layout_id}}->{$_->{permission}} = 1
        foreach ($rs->all);

    foreach my $instance ($self->schema->resultset('Instance')->all)
    {
        my $p_table   = {
            $self->user->{id} => $perms_table->{$instance->id} || {},
        };
        my $p_columns = {
            $self->user->{id} => $perms_columns->{$instance->id} || {},
        };
        my %params = (
            user                      => $self->user,
            schema                    => $self->schema,
            config                    => GADS::Config->instance,
            instance_id               => $instance->id,
            _user_permissions_table   => $p_table,
            _user_permissions_columns => $p_columns,
        );
        $params{cols_db} = $layouts[0]->cols_db if @layouts;
        push @layouts, GADS::Layout->new(%params);
    }
    \@layouts;
}

has _layouts_index => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build__layouts_index
{   my $self = shift;
    my %layouts = map { $_->instance_id => $_ } @{$self->_layouts};
    \%layouts;
}

sub layout
{   my ($self, $instance_id) = @_;
    $self->_layouts_index->{$instance_id}
        or panic "Layout for instance ID $instance_id not found";
}

sub is_valid
{   my ($self, $id) = @_;
    grep { $_->instance_id == $id } @{$self->all}
        or return;
    $id; # Return ID to make testing easier
}

1;

