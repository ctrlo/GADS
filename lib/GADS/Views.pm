
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

package GADS::Views;

use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/ArrayRef HashRef Int Maybe Bool/;

# Whether the logged-in user has the layout permission
has user_has_layout => (is => 'lazy',);

sub _build_user_has_layout
{   my $self = shift;
    $self->layout->user_can("layout");
}

# Whether to show another user's views
has other_user_id => (
    is  => 'ro',
    isa => Maybe [Int],
);

has user_permission_override => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has schema => (
    is       => 'rw',
    required => 1,
);

has instance_id => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has user_views => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_user_views },
);

has user_views_all => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_user_views_all
{   my $all = shift->user_views;
    [ @{ $all->{shared} }, @{ $all->{personal} }, @{ $all->{admin} } ];
}

has global => (
    is  => 'lazy',
    isa => ArrayRef,
);

has admin => (
    is  => 'lazy',
    isa => ArrayRef,
);

has all => (
    is  => 'lazy',
    isa => ArrayRef,
);

# Only required a full view is retrieved
has layout => (is => 'rw',);

sub _user_views
{   my $self = shift;

 # Allow user ID to be overridden, but only if the logged-in user has permission
    my $user_id = ($self->user_has_layout && $self->other_user_id)
        || ($self->layout->user && $self->layout->user->id);
    my $search = [
        'me.user_id' => $user_id,
        {
            global => 1,
            -or    => [
                'me.group_id'         => undef,
                'user_groups.user_id' => $user_id,
            ],
        },
    ];
    push @$search, (is_admin => 1) if $self->user_has_layout;
    my @views = $self->schema->resultset('View')->search(
        {
            -or         => $search,
            instance_id => $self->instance_id,
        },
        {
            join => {
                group => 'user_groups',
            },
            order_by => [ 'me.global', 'me.is_admin', 'me.name' ],
            collapse => 1,
        },
    )->all;
    my $return = {
        admin    => [],
        shared   => [],
        personal => [],
    };
    foreach my $view (@views)
    {
        if ($view->global)
        {
            push @{ $return->{shared} }, $view;
        }
        elsif ($view->is_admin)
        {
            push @{ $return->{admin} }, $view;
        }
        else
        {
            push @{ $return->{personal} }, $view;
        }
    }
    $return;
}

has views_limit_extra => (is => 'lazy',);

sub _build_views_limit_extra
{   my $self = shift;
    return [] if !$self->layout->user_can('view_limit_extra');
    my @views = $self->schema->resultset('View')->search(
        {
            is_limit_extra => 1,
            instance_id    => $self->instance_id,
        },
        {
            order_by => 'me.name',
        },
    );
    \@views;
}

sub _build_global
{   my $self  = shift;
    my @views = $self->schema->resultset('View')->search({
        global      => 1,
        instance_id => $self->instance_id,
    })->all;
    my @global = map { $self->view($_->id) } @views;
    \@global;
}

sub _build_admin
{   my $self  = shift;
    my @views = $self->schema->resultset('View')->search({
        is_admin    => 1,
        instance_id => $self->instance_id,
    })->all;
    my @admin = map { $self->view($_->id) } @views;
    \@admin;
}

sub _build_all
{   my $self  = shift;
    my @views = $self->schema->resultset('View')->search({
        instance_id => $self->instance_id,
    })->all;
    my @all = map { $self->view($_->id) } @views;
    \@all;
}

# Default user view
sub default
{   my $self         = shift;
    my @user_views   = @{ $self->user_views_all } or return;
    my $default_view = shift @user_views          or return;
    my $view_id      = $default_view->id          or return;
    $self->view($view_id);
}

sub view
{   my ($self, $view_id) = @_;
    my $layout = $self->layout
        or die "layout needs to be defined to retrieve view";

    # Try to create a view using the ID. Don't bork if it fails
    my $view = GADS::View->new(
        id                       => $view_id,
        instance_id              => $self->instance_id,
        schema                   => $self->schema,
        layout                   => $self->layout,
        user_permission_override => $self->user_permission_override,
    );
    $view->exists ? $view : undef;
}

sub purge
{   my $self = shift;
    foreach my $view (@{ $self->all })
    {
# Remove any view limits, which would otherwise cause the view to not be deleted
        $self->schema->resultset('ViewLimit')->search({ view_id => $view->id })
            ->delete;
        $view->delete;
    }
}

1;

