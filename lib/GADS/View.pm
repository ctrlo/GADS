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

package GADS::View;

use GADS::Schema;
use JSON qw(decode_json encode_json);
use Log::Report;
use String::CamelCase qw(camelize);

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

has id => (
    is        => 'rw',
    predicate => 1,
);

has user => (
    is       => 'rw',
    required => 1,
);

has schema => (
    is       => 'rw',
    required => 1,
);

has layout => (
    is       => 'rw',
    required => 1,
);

# Internal DBIC object of view
has _view => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my ($view) = $self->schema->resultset('View')->search({
            'me.id' => $self->id
        },{
            prefetch => ['sorts', 'alerts'],
        })->all;
        $view;
    },
);

# All the following have to be lazily built, otherwise it's
# possible that the schema object to the database will not
# have been processed yet
has global => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    builder => sub { $_[0]->_view && $_[0]->_view->global },
);

has name => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_view && $_[0]->_view->name },
);

has filter => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_view && $_[0]->_view->filter },
);

has sorts => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_view && $_[0]->_get_sorts || [] },
);

has alert => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_view or return;
        my ($alert) = grep { $self->user->{id} == $_->user_id } $self->_view->alerts;
        $alert;
    }
);

has columns => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_view or return;
        my @view_layouts = map {$_->layout_id} $self->_view->view_layouts;
        \@view_layouts,
    },
);

has owner => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_view && $_[0]->_view->user_id },
);

has writable => (
    is => 'rw',
);

# Validate what access the user has
sub BUILD
{   my $self = shift;
    if (!$self->has_id)
    {
        # New view, therefore writable
        $self->writable(1);
    }
    elsif ($self->global)
    {
        $self->writable(1) if $self->user->{permission}->{layout};
    }
    elsif ($self->owner && $self->owner == $self->user->{id})
    {
        $self->writable(1);
    }
    else {
        error __x"User {user} does not have access to view {view}",
            user => $self->user->{id}, view => $self->id;
    }
}

sub _filter_tables
{   my ($filter, $tables) = @_;

    if (my $rules = $filter->{rules})
    {
        # Filter has other nested filters
        foreach my $rule (@$rules)
        {
            _filter_tables($rule, $tables);
        }
    }
    elsif (my $id = $filter->{id}) {
        $tables->{$filter->{id}} = 1;
    }
}

sub write
{   my $self = shift;

    my $vu;
    if ($self->user->{permission}->{layout})
    {
        if ($self->global)
        {
            $vu->{global}  = 1;
            $vu->{user_id} = undef;
        }
        else {
            $vu->{global}  = 0;
            $vu->{user_id} = $self->user->{id};
        }
    }
    else {
        $vu->{user_id} = $self->user->{id};
    }

    $vu->{name} = $self->name or error __"Please enter a name for the view";
    $vu->{filter} = $self->filter;

    if ($self->id)
    {
        $self->writable
            or error __x"You do not have access to modify view {id}", id => $self->id;
        $self->_view->update($vu)
    }
    else {
        $self->id($self->schema->resultset('View')->create($vu)->id);
    }

    my $schema = $self->schema;
    my @colviews = @{$self->columns};

    foreach my $c ($self->layout->all)
    {
        my $item = { view_id => $self->id, layout_id => $c->id };
        if (grep {$c->id == $_} @colviews)
        {
            # Column should be in view
            unless($schema->resultset('ViewLayout')->search($item)->count)
            {
                $schema->resultset('ViewLayout')->create($item);
                # Update alert cache with new column
                my @alerts = $schema->resultset('View')->search({
                    'me.id' => $self->id
                },{
                    columns  => [
                        { 'me.id'  => \"MAX(me.id)" },
                        { 'alert_caches.id'  => \"MAX(alert_caches.id)" },
                        { 'alert_caches.current_id'  => \"MAX(alert_caches.current_id)" },
                    ],
                    join     => 'alert_caches',
                    group_by => 'current_id',
                })->all;
                my @pop;
                foreach my $alert (@alerts)
                {
                    push @pop, map { {
                        layout_id  => $c->id,
                        view_id    => $self->id,
                        current_id => $_->current_id,
                    } } $alert->alert_caches;
                }
                $schema->resultset('AlertCache')->populate(\@pop) if @pop;
            }
        }
        else {
            $schema->resultset('ViewLayout')->search($item)->delete;
            # Also delete alert cache for this column
            $schema->resultset('AlertCache')->search({
                view_id   => $self->id,
                layout_id => $c->id
            })->delete;
        }
    }

    # Then update any sorts
    # $self->sorts($values);

    # Then update the filter table, which we use to query what fields are
    # applied to a view's filters when doing alerts
    my @existing = $self->schema->resultset('Filter')->search({ view_id => $self->id })->all;
    my $decoded = decode_json($self->filter);
    my $tables = {};
    _filter_tables $decoded, $tables;
    foreach my $table (keys $tables)
    {
        unless (grep { $_->layout_id == $table } @existing)
        {
            $self->schema->resultset('Filter')->create({
                view_id   => $self->id,
                layout_id => $table,
            });
        }
    }
    # Delete those no longer there
    my $search = { view_id => $self->id };
    $search->{layout_id} = { '!=' => [ '-and', keys %$tables ] } if keys %$tables;
    $self->schema->resultset('Filter')->search($search)->delete;
}

sub delete
{   my $self = shift;

    $self->writable
        or error __x"You do not have permission to delete {id}", id => $self->id;
    my $view = $self->_view;
    $self->schema->resultset('Sort')->search({ view_id => $view->id })->delete;
    $self->schema->resultset('ViewLayout')->search({ view_id => $view->id })->delete;
    $self->schema->resultset('Filter')->search({ view_id => $view->id })->delete;
    $self->schema->resultset('AlertCache')->search({ view_id => $view->id })->delete;
    $self->schema->resultset('Alert')->search({ view_id => $view->id })->delete;
    $view->delete;
}

sub sort_types
{
    [
        {
            name        => "asc",
            description => "Ascending"
        },
        {
            name        => "desc",
            description => "Descending"
        },
    ]
}

sub filter_types
{
    [
        { code => 'gt'      , text => 'Greater than' },
        { code => 'lt'      , text => 'Less than'    },
        { code => 'equal'   , text => 'Equals'       },
        { code => 'contains', text => 'Contains'     },
    ]
}

sub _get_sorts
{   my $self = shift;

    my @sorts;
    foreach my $sort ($self->_view->sorts->all)
    {
        my $s;
        $s->{id}        = $sort->id;
        $s->{type}      = $sort->type;
        $s->{layout_id} = $sort->layout_id;
        push @sorts, $s;
    }
    \@sorts;
}

sub set_sorts
{   my ($self, $update) = @_;

    # Collect all the sorts. These can be in a variety of formats. New
    # ones will be a scalar for a single one or an arrayref for multiples.
    # Existing ones will have a unique field ID. This is maintained to retain
    # the data associated with that entry.
    my $schema = $self->schema;
    my @allsorts;
    foreach my $v (keys %$update)
    {
        next unless $v =~ /^sortfield(\d+)(new)?/; # For each sort group
        my $id   = $1;
        my $new  = $2 ? 'new' : '';
        my $type = $update->{"sorttype$id"};
        error __x"Invalid type {type}", type => $type
            unless grep { $_->{name} eq $type } @{sort_types()};
        my $layout_id = $update->{"sortfield$id$new"} || undef;
        my $sort = {
            view_id   => $self->id,
            layout_id => $layout_id,
            type      => $type,
        };
        if ($new)
        {
            # New filter
            my $s = $schema->resultset('Sort')->create($sort);
            push @allsorts, $s->id;
        }
        else {
            # Search on view as well to ensure ID belongs to view
            my ($s) = $schema->resultset('Sort')->search({ view_id => $self->id, id => $id })->all;
            if ($s)
            {
                $s->update($sort);
                push @allsorts, $id;
            }
        }
    }
    # Then delete any that no longer exist
    foreach my $s ($schema->resultset('Sort')->search({ view_id => $self->id }))
    {
        unless (grep {$_ == $s->id} @allsorts)
        {
            $s->delete;
        }
    }
    $self->sorts($self->_get_sorts);
}

1;

