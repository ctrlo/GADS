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

use GADS::Alert;
use GADS::Filter;
use GADS::Schema;
use Log::Report 'linkspace';
use MIME::Base64;
use String::CamelCase qw(camelize);

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

has id => (
    is        => 'rw',
    clearer   => 1,
    predicate => 1,
);

# Whether the logged-in user has the layout permission
has user_has_layout => (
    is => 'lazy',
);

sub _build_user_has_layout
{   my $self = shift;
    $self->layout->user_can("layout");
}

# Whether to write the view as another user
has other_user_id => (
    is  => 'rw',
    isa => Maybe[Int],
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

has layout => (
    is       => 'rw',
    required => 1,
);

# Internal DBIC object of view
has _view => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        my ($view) = $self->schema->resultset('View')->search({
            'me.id'          => $self->id,
            'me.instance_id' => $self->instance_id,
        },{
            prefetch => ['sorts', 'alerts'],
            order_by => 'sorts.id', # Ensure sorts are retrieve in correct order to apply
        })->all;
        if (!$view)
        {
            $self->clear_id;
            return;
        }
        # Check whether user has read access to view
        return $view if $self->user_permission_override;
        my $user_id = $self->layout->user && $self->layout->user->id;
        my $no_access = $self->has_id && $self->layout->user && !$view->global && !$view->is_admin && !$view->is_limit_extra
            && !$self->layout->user_can("layout") && $view->user_id != $user_id;
        $no_access ||= $view->global && $view->group_id
            && !$self->schema->resultset('User')->find($user_id)->has_group->{$view->group_id};
        if ($no_access)
        {
            error __x"User {user} does not have access to view {view}",
                user => $self->layout->user->id, view => $self->id;
        }
        $view;
    },
);

sub exists
{   my $self = shift;
    $self->_view && $self->_view->id ? 1 : 0;
}

# All the following have to be lazily built, otherwise it's
# possible that the schema object to the database will not
# have been processed yet
has global => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    builder => sub { $_[0]->_view && $_[0]->_view->global || 0 },
);

has is_admin => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    builder => sub { $_[0]->_view && $_[0]->_view->is_admin || 0 },
);

has group_id => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    coerce  => sub { $_[0] || undef },
    builder => sub { $_[0]->_view && $_[0]->_view->group_id },
);

has name => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_view && $_[0]->_view->name },
);

has filter => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    coerce  => sub {
        my $value = shift;
        if (ref $value ne 'GADS::Filter')
        {
            if (ref $value eq 'HASH')
            {
                $value = GADS::Filter->new(
                    as_hash => $value,
                );
            }
            else {
                $value = GADS::Filter->new(
                    as_json => $value,
                );
            }
        }
        $value;
    },
    builder => sub {
        my $self = shift;
        my $filter = $self->_view # Don't trigger changed() in Filter
            ? GADS::Filter->new(layout => $self->layout, as_json => $self->_view->filter)
            : GADS::Filter->new(layout => $self->layout);
    },
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
        my ($alert) = grep { $self->layout->user->id == $_->user_id } $self->_view->alerts;
        $alert;
    }
);

has all_alerts => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_all_alerts
{   my $self = shift;
    [ $self->_view->alerts ];
}

has has_alerts => (
    is  => 'lazy',
    isa => Bool,
);

sub _build_has_alerts
{   my $self = shift;
    $self->_view or return;
    $self->_view->alerts->count ? 1 : 0;
}

has columns => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_view or return [];
        my @view_layouts = map {$_->layout_id} $self->_view->view_layouts;
        \@view_layouts,
    },
);

# Whether the view has a variable "CURUSER" condition
has has_curuser => (
    is      => 'lazy',
    isa     => Bool,
    clearer => 1,
);

sub _build_has_curuser
{   my $self = shift;
    grep {
        ($self->layout->column($_->{id})->type eq 'person'
            && $_->{value} && $_->{value} eq '[CURUSER]')
        || ($self->layout->column($_->{id})->return_type eq 'string'
            && $_->{value} && $_->{value} eq '[CURUSER]')
    } @{$self->filter->filters};
}

has owner => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_view && $_[0]->_view->user_id },
);

has writable => (
    is      => 'lazy',
    isa     => Bool,
    clearer => 1,
);

sub _build_writable
{   my $self = shift;
    if (!$self->layout->user)
    {
        # Special case - no user means writable (for tests)
        return 1;
    }
    elsif ($self->is_admin)
    {
        return 1 if $self->layout->user_can("layout");
    }
    elsif ($self->global)
    {
        return 1 if !$self->group_id && $self->layout->user_can("layout");
        return 1 if $self->group_id && $self->layout->user_can("view_group");
    }
    elsif (!$self->has_id)
    {
        # New view, not global
        return 1 if $self->layout->user_can("view_create");
    }
    elsif ($self->owner && $self->owner == $self->layout->user->id)
    {
        return 1 if $self->layout->user_can("view_create");
    }
    elsif ($self->layout->user_can("layout"))
    {
        return 1;
    }
    return 0;
}

sub write
{   my ($self, %options) = @_;

    my $fatal = $options{no_errors} ? 0 : 1;

    $self->name or error __"Please enter a name for the view";

    # XXX Database schema currently restricts length of name. Should be changed
    # to normal text field at some point
    length $self->name < 128
        or error __"View name must be less than 128 characters";

    my $global   = !$self->layout->user ? 1 : $self->global;

    $self->clear_writable; # Force rebuild based on any updated values

    my $vu = {
        name        => $self->name,
        filter      => $self->filter->as_json,
        instance_id => $self->instance_id,
        global      => $global,
        is_admin    => $self->is_admin,
        group_id    => $self->group_id,
    };

    if ($global || $self->is_admin)
    {
        $vu->{user_id} = undef;
    }
    elsif (!$self->_view || !$self->_view->user_id) { # Preserve owner if editing other user's view
        $vu->{user_id} = ($self->user_has_layout && $self->other_user_id) || $self->layout->user->id;
    }

    $self->clear_has_curuser;

    # Get all the columns in the filter. Check whether the user has
    # access to them.
    foreach my $filter (@{$self->filter->filters})
    {
        my $col   = $self->layout->column($filter->{column_id})
            or error __x"Field ID {id} does not exist", id => $filter->{column_id};
        my $val   = $filter->{value};
        my $op    = $filter->{operator};
        my $rtype = $col->return_type;
        if ($rtype eq 'daterange')
        {
            if ($op eq 'equal' || $op eq 'not_equal')
            {
                # expect exact daterange format, e.g. "yyyy-mm-dd to yyyy-mm-dd"
                $col->validate_search($val, fatal => $fatal, full_only => 1); # Will bork on failure
            }
            else {
                $col->validate_search($val, fatal => $fatal, single_only => 1); # Will bork on failure
            }
        }
        else {
            $col->validate_search($val, fatal => $fatal) # Will bork on failure
                unless $op eq 'is_empty' || $op eq 'is_not_empty'; # Would normally fail on blank value
        }

        my $has_value = $val && (ref $val ne 'ARRAY' || @$val);
        error __x "No value can be entered for empty and not empty operators"
            if ($op eq 'is_empty' || $op eq 'is_not_empty') && $has_value;
        error __x"Invalid field ID {id} in filter", id => $filter->{column_id}
            unless $col->user_can('read');
    }

    $self->writable
        or error $self->id
            ? __x("User {user_id} does not have access to modify view {id}", user_id => $self->layout->user->id, id => $self->id)
            : __x("User {user_id} does not have permission to create new views", user_id => $self->layout->user->id);

    if ($self->id)
    {
        $self->_view->update($vu);

        # Update any alert caches for new filter
        if ($self->filter->changed && $self->has_alerts)
        {
            my $alert = GADS::Alert->new(
                user      => $self->layout->user,
                layout    => $self->layout,
                schema    => $self->schema,
                view_id   => $self->id,
            );
            $alert->update_cache;
        }
    }
    else {
        my $rset = $self->schema->resultset('View')->create($vu);
        $self->_view($rset);
        $self->id($rset->id);
    }

    my $schema = $self->schema;
    my @colviews = @{$self->columns};

    foreach my $c ($self->layout->all(user_can_read => 1))
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
    }

    # Delete any no longer needed
    my $search = {view_id => $self->id};
    $search->{'-not'} = {'layout_id' => \@colviews} if @colviews;
    $self->schema->resultset('ViewLayout')->search($search)->delete;
    $self->schema->resultset('AlertCache')->search($search)->delete;

    # Then update the filter table, which we use to query what fields are
    # applied to a view's filters when doing alerts.
    # We don't sanitise the columns the user has visible at this point -
    # there is not much point, as they could be removed later anyway. We
    # do this during the processing of the alerts and filters elsewhere.
    my @existing = $self->schema->resultset('Filter')->search({ view_id => $self->id })->all;
    my @all_filters = @{$self->filter->filters};
    foreach my $filter (@all_filters)
    {
        unless (grep { $_->layout_id == $filter->{column_id} } @existing)
        {
            # Unable to add internal columns to filter table, as they don't
            # reference any columns from the layout table
            next unless $filter->{column_id} > 0;
            $self->schema->resultset('Filter')->create({
                view_id   => $self->id,
                layout_id => $filter->{column_id},
            });
        }
    }
    # Delete those no longer there
    $search = { view_id => $self->id };
    $search->{layout_id} = { '!=' => [ '-and', map { $_->{column_id} } @all_filters ] } if @all_filters;
    $self->schema->resultset('Filter')->search($search)->delete;
}

sub delete
{   my $self = shift;

    $self->writable
        or error __x"You do not have permission to delete {id}", id => $self->id;
    my $vl = $self->schema->resultset('ViewLimit')->search({
        view_id => $self->id,
    },{
        prefetch => 'user',
    });
    if ($vl->count)
    {
        my $users = join '; ', $vl->get_column('user.value')->all;
        error __x"This view cannot be deleted as it is used to limit user data. Remove the view from the limited views of the following users before deleting: {users}", users => $users;
    }

    my $view = $self->_view
        or return; # Doesn't exist. May be attempt to delete view not yet written
    $self->schema->resultset('Sort')->search({ view_id => $view->id })->delete;
    $self->schema->resultset('ViewLayout')->search({ view_id => $view->id })->delete;
    $self->schema->resultset('Filter')->search({ view_id => $view->id })->delete;
    $self->schema->resultset('AlertCache')->search({ view_id => $view->id })->delete;
    my @alerts = $self->schema->resultset('Alert')->search({ view_id => $view->id })->all;
    my @alert_ids = map { $_->id } @alerts;
    $self->schema->resultset('AlertSend')->search({
        alert_id => \@alert_ids,
    })->delete;
    $self->schema->resultset('Alert')->search({
        id => \@alert_ids,
    })->delete;
    $self->schema->resultset('User')->search({ lastview => $view->id })->update({
        lastview => undef,
    });
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

    return [] unless $self->_view;

    # Sort order is defined by the database sequential ID of each sort
    my @sorts;
    foreach my $sort ($self->_view->sorts->all)
    {
        # XXX Convert from legacy internal IDs. This can be removed at some
        # point.
        if ($sort->layout_id < 0)
        {
            my %map = (
                -11 => $self->layout->column_by_name_short('_id'),
                -12 => $self->layout->column_by_name_short('_version_datetime'),
                -13 => $self->layout->column_by_name_short('_version_user'),
                -14 => $self->layout->column_by_name_short('_deleted_by'),
                -15 => $self->layout->column_by_name_short('_created'),
                -16 => $self->layout->column_by_name_short('_serial'),
            );
            $sort->update({ layout_id => $map{$sort->layout_id}->id });
        }
        my $s;
        $s->{id}        = $sort->id;
        $s->{type}      = $sort->type;
        $s->{layout_id} = $sort->layout_id;
        $s->{parent_id} = $sort->parent_id;
        $s->{filter_id} = $sort->parent_id ? $sort->parent_id.'_'.$sort->layout_id : $sort->layout_id,
        push @sorts, $s;
    }
    \@sorts;
}

sub set_sorts
{   my ($self, $sortfield, $sorttype) = @_;

    my $schema = $self->schema;
    # Delete all old ones first
    $schema->resultset('Sort')->search({ view_id => $self->id })->delete;

    # Collect all the sorts. These can be in a variety of formats. New
    # ones will be a scalar for a single one or an arrayref for multiples.
    # Existing ones will have a unique field ID. This is maintained to retain
    # the data associated with that entry.
    my @fields = ref $sortfield ? @$sortfield : ($sortfield // ()); # Allow empty string for ID
    my @types  = ref $sorttype  ? @$sorttype  : ($sorttype  || ());
    my @allsorts; my $type_last;
    foreach my $filter_id (@fields)
    {
        my ($parent_id, $layout_id);
        if ($filter_id && $filter_id =~ /^([0-9]+)_([0-9]+)$/)
        {
            $parent_id = $1;
            $layout_id = $2;
        }
        else {
            $layout_id = $filter_id;
        }
        my $type = (shift @types) || $type_last;
        error __x"Invalid type {type}", type => $type
            unless grep { $_->{name} eq $type } @{sort_types()};
        # Check column is valid and user has access
        error __x"Invalid field ID {id} in sort", id => $layout_id
            if $layout_id && !$self->layout->column($layout_id)->user_can('read');
        error __x"Invalid field ID {id} in sort", id => $parent_id
            if $parent_id && !$self->layout->column($parent_id)->user_can('read');
        my $sort = {
            view_id   => $self->id,
            layout_id => ($layout_id || undef), # ID will be empty string
            parent_id => $parent_id,
            type      => $type,
        };
        # Assume that each new sort is applied with a new ID greater than the
        # previous to give correct order.
        # XXX Would be better having an "order" column in the table
        my $s = $schema->resultset('Sort')->create($sort);
        push @allsorts, $s->id;
        $type_last = $type;
    }
    $self->_clear_view;
    $self->sorts($self->_get_sorts);
}

sub parse_date_filter
{   my ($class, $value) = @_;
    $value =~ /^(\h*([0-9]+)\h*([+])\h*)?CURDATE(\h*([-+])\h*([0-9]+)\h*)?$/
        or return;
    my $now = DateTime->now;
    my ($v1, $op1, $op2, $v2) = ($2, $3, $5, $6);
    if ($op1 && $op1 eq '+' && $v1)
    { $now->add(seconds => $v1) }
#    if ($op1 eq '-' && $v1) # Doesn't work, needs coding differently
#    { $now->subtract(seconds => $v1) }
    if ($op2 && $op2 eq '+' && $v2)
    { $now->add(seconds => $v2) }
    if ($op2 && $op2 eq '-' && $v2)
    { $now->subtract(seconds => $v2) }
    $now;
}

1;

