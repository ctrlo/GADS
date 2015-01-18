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

use Log::Report;
use Moo;

has user => (
    is       => 'rw',
    required => 1,
);

has schema => (
    is       => 'rw',
    required => 1,
);

has user_views => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_user_views },
);

# Only required a full view is retrieved
has layout => (
    is => 'rw',
);

sub _user_views
{   my $self = shift;
    my @views = $self->schema->resultset('View')->search({
        -or => [
            user_id => $self->user->{id},
            global  => 1,
        ]
    },{
            order_by => ['global', 'name'],
    })->all;
    \@views;
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
    my $view    = try { GADS::View->new(
        user   => $self->user,
        id     => $view_id,
        schema => $self->schema,
        layout => $self->layout,
    ); };
    $view;
}

1;

