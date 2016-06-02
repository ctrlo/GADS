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
use GADS::Schema;
use JSON qw(decode_json);
use Log::Report;
use MIME::Base64;
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
        $self->schema or return;
        my ($view) = $self->schema->resultset('View')->search({
            'me.id'          => $self->id,
            'me.instance_id' => $self->instance_id,
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
    isa     => sub {
        decode_json($_[0]); # Will die on error
    },
    lazy    => 1,
    builder => sub { ($_[0]->_view && $_[0]->_view->filter) || '{}' },
    trigger => sub {
        my ($self, $value) = @_;
        $self->filter_changed(1)
            if $self->_view && $self->_view->filter ne $value;
    },
);

sub filter_base64
{   my $self = shift;
    encode_base64($self->filter);
}

has filter_changed => (
    is => 'rw',
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
        $self->_view or return;
        my @view_layouts = map {$_->layout_id} $self->_view->view_layouts;
        \@view_layouts,
    },
);

# All the filters in a flat structure
has filters => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _build_filters
{   my $self = shift;
    my $decoded = decode_json($self->filter);
    my $cols_in_filter = {};
    _filter_tables($decoded, $cols_in_filter);
    [values %$cols_in_filter];
}

# Whether the view has a variable "CURUSER" condition
has has_curuser => (
    is      => 'lazy',
    isa     => Bool,
    clearer => 1,
);

sub _build_has_curuser
{   my $self = shift;
    grep {
        $self->layout->column($_->{field})->type eq 'person'
        && $_->{value} eq '[CURUSER]'
    } @{$self->filters};
}

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
    if (!$self->has_id || !$self->user)
    {
        # New view or no user defined, therefore writable
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

# Recursively find all tables in a nested filter
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
        $tables->{$filter->{id}} = {
            field    => $filter->{id},
            value    => $filter->{value},
            operator => $filter->{operator},
        };
    }
}

sub write
{   my $self = shift;

    my $vu;
    if (!$self->user) # Used during tests - no user
    {
        $vu->{global} = 1;
    }
    elsif ($self->global || $self->user->{permission}->{layout})
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

    $vu->{name}        = $self->name or error __"Please enter a name for the view";
    $vu->{filter}      = $self->filter;
    $vu->{instance_id} = $self->instance_id;
    my $decoded = decode_json($self->filter);

    $self->clear_filters;
    $self->clear_has_curuser;

    # Get all the columns in the filter. Check whether the user has
    # access to them.
    my $cols_in_filter = {};
    _filter_tables $decoded, $cols_in_filter;
    foreach my $col_id (keys %$cols_in_filter)
    {
        my $strp = DateTime::Format::Strptime->new(
            pattern   => '%F',
        );
        my $col   = $self->layout->column($col_id);
        my $fil   = $cols_in_filter->{$col_id};
        my $val   = $fil->{value};
        my $op    = $fil->{operator};
        my $rtype = $col->return_type;
        if ($rtype eq 'daterange' && ($op eq 'equal' || $op eq 'not_equal'))
        {   # expect exact daterange format, "yyyy-mm-dd to yyyy-mm-dd"
            my ($from, $to) = split ' to ', $val;
            error __x qq(Invalid daterange format "{value}" for operator "$op". Value must be a
                full date range ("yyyy-mm-dd to yyyy-mm-dd").), value => $val
                if !$strp->parse_datetime($from) || !$strp->parse_datetime($to);
        }
        elsif (
            ($rtype eq 'date' || $rtype eq 'daterange')
            && ($op ne 'is_empty' && $op ne 'is_not_empty')
        )
        {   # expect standard date format for other daterange operators
            error __x qq(Invalid date format "{value}"), value => $val
                if ( $val !~ /^[-0-9]+$/ # parse_datetime allows junk after proper date
                    || !$strp->parse_datetime($val)
                ) && $val ne 'CURDATE';
        }

        error __x "No value can be entered for empty and not empty operators"
            if ($op eq 'is_empty' || $op eq 'is_not_empty') && $val;
        error __x"Invalid field ID {id} in filter", id => $col_id
            unless $col->user_can('read');
    }

    if ($self->id)
    {
        $self->writable
            or error __x"You do not have access to modify view {id}", id => $self->id;
        $self->_view->update($vu);

        # Update any alert caches for new filter
        if ($self->filter_changed && $self->has_alerts)
        {
            my $alert = GADS::Alert->new(
                user      => $self->user,
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

    # Then update any sorts
    # $self->sorts($values);

    # Then update the filter table, which we use to query what fields are
    # applied to a view's filters when doing alerts.
    # We don't sanitise the columns the user has visible at this point -
    # there is not much point, as they could be removed later anyway. We
    # do this during the processing of the alerts and filters elsewhere.
    my @existing = $self->schema->resultset('Filter')->search({ view_id => $self->id })->all;
    foreach my $table (keys %$cols_in_filter)
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
    $search = { view_id => $self->id };
    $search->{layout_id} = { '!=' => [ '-and', keys %$cols_in_filter ] } if keys %$cols_in_filter;
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
    my @allsorts;
    foreach my $layout_id (@fields)
    {
        my $type = shift @types;
        error __x"Invalid type {type}", type => $type
            unless grep { $_->{name} eq $type } @{sort_types()};
        # Check column is valid and user has access
        error __x"Invalid field ID {id} in sort", id => $layout_id
            if $layout_id && !$self->layout->column($layout_id)->user_can('read');
        my $sort = {
            view_id   => $self->id,
            layout_id => ($layout_id || undef), # ID will be empty string
            type      => $type,
        };
        my $s = $schema->resultset('Sort')->create($sort);
        push @allsorts, $s->id;
    }
    $self->_clear_view;
    $self->sorts($self->_get_sorts);
}

1;

