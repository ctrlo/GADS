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
use MooX::Types::MooseLike::Base qw/ArrayRef HashRef Int/;

has user => (
    is       => 'rw',
    required => 1,
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

has global => (
    is  => 'lazy',
    isa => ArrayRef,
);

has all => (
    is  => 'lazy',
    isa => ArrayRef,
);

# Only required a full view is retrieved
has layout => (
    is => 'rw',
);

sub _user_views
{   my $self = shift;
    my @search = (
        user_id => $self->user ? $self->user->{id} : undef,
        global  => 1,
    );
    push @search, (is_admin => 1) if !$self->user || $self->user->{permission}->{layout};
    my @views = $self->schema->resultset('View')->search({
        -or         => [@search],
        instance_id => $self->instance_id,
    },{
            order_by => ['global', 'is_admin', 'name'],
    })->all;
    \@views;
}

sub _build_global
{   my $self = shift;
    my @views = $self->schema->resultset('View')->search({
        global      => 1,
        instance_id => $self->instance_id,
    })->all;
    my @global = map { $self->view($_->id) } @views;
    \@global;
}

sub _build_all
{   my $self = shift;
    my @views = $self->schema->resultset('View')->search({
        instance_id => $self->instance_id,
    })->all;
    my @all = map { $self->view($_->id) } @views;
    \@all;
}

# Default user view
sub default
{   my $self = shift;
    my @user_views   = @{$self->user_views} or return;
    my $default_view = shift @user_views or return;
    my $view_id      = $default_view->id or return;
    $self->view($view_id);
}

sub view
{   my ($self, $view_id) =  @_;
    my $layout = $self->layout or die "layout needs to be defined to retrieve view";
    # Try to create a view using the ID. Don't bork if it fails
    my $view = GADS::View->new(
        user        => $self->user,
        id          => $view_id,
        instance_id => $self->instance_id,
        schema      => $self->schema,
        layout      => $self->layout,
    );
    $view->exists ? $view : undef;
}

sub purge
{   my $self = shift;
    foreach my $view (@{$self->all})
    {
        $view->delete;
    }
}

1;

