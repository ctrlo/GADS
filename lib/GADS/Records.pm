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

package GADS::Records;

use DateTime;
use DateTime::Format::Strptime qw( );
use DBIx::Class::ResultClass::HashRefInflator;
use GADS::Record;
use GADS::View;
use HTML::Entities;
use JSON qw(decode_json encode_json);
use Log::Report;
use POSIX qw(ceil);
use Scalar::Util qw(looks_like_number);
use Text::CSV::Encoded;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

with 'GADS::RecordsJoin';

# Preferably this is passed in to prevent extra
# DB reads, but loads it if it isn't
has layout => (
    is       => 'rw',
    required => 1,
);

has user => (
    is       => 'ro',
    required => 1,
);

has pages => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_pages
{   my $self = shift;
    $self->rows ? ceil($self->count / $self->rows) : 1;
}

has view => (
    is => 'rw',
);

# Whether to limit any results to only those
# in a specific view
has limit_to_view => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_limit_to_view
{   my $self = shift;
    my $limit_to_view = $self->user && $self->user->{limit_to_view} or return;
    GADS::View->new(
        user        => undef, # In case user does not have access
        id          => $limit_to_view,
        schema      => $self->schema,
        layout      => $self->layout,
        instance_id => $self->layout->instance_id,
    );
}

has from => (
    is => 'rw',
);

has to => (
    is => 'rw',
);

# Whether to force recalculation of cached fields
has force_update => (
    is => 'rw',
);

has remembered_only => (
    is => 'rw',
);

# Array ref with column IDs
has columns => (
    is => 'rw',
);

# Array ref with any additional column IDs requested
has columns_extra => (
    is => 'rw',
);

# Value containing the actual columns retrieved.
# In "normal order" as per layout.
has columns_retrieved_no => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

# Value containing the actual columns retrieved.
# In "dependent order", needed for calcvals
has columns_retrieved_do => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

has rows => (
    is => 'rw',
);

has count => (
    is      => 'rwp',
    isa     => Int,
    lazy    => 1,
    builder => 1,
    clearer => 1,
);

has has_children => (
    is      => 'lazy',
    isa     => Bool,
    clearer => 1,
);

has page => (
    is => 'rw',
);

has include_approval => (
    is      => 'rw',
    default => 0,
);

# Whether to fill in missing values of children from parent.
# XXX Is interpolate the correct word??!
has interpolate_children => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

# Limit to specific current IDs
has current_ids => (
    is  => 'rw',
    isa => Maybe[ArrayRef],
);

# Produce the overall search condition array
sub search_query
{   my ($self, %options) = @_;
    my @search     = $self->_query_params(%options);
    my $root_table = $options{root_table} || 'current';
    my $current    = $root_table eq 'current' ? 'me' : 'current';
    my $record     = $root_table eq 'record'  ? 'me' : 'record';
    unless ($self->include_approval)
    {
        # There is a chance that there will be no approval records. In that case,
        # the search will be a lot quicker without adding the approval search
        # condition (due to indexes not spanning across tables). So, do a quick
        # check first, and only add the condition if needed
        my ($approval_exists) = $root_table eq 'current' && $self->schema->resultset('Current')->search({
            instance_id        => $self->layout->instance_id,
            "$record.approval" => 1,
        },{
            join => 'record',
            rows => 1,
        })->all;
        push @search, (
            { "$record.approval"  => 0 },
        ) if $approval_exists;
    }
    push @search, { "$current.id"          => $self->current_ids} if $self->current_ids;
    push @search, { "$current.instance_id" => $self->layout->instance_id };
    [@search];
}

has plus_select => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has order_by => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has order_by_count => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

sub order_by_inc
{   my $self = shift;
    $self->order_by_count($self->order_by_count + 1);
}

has sort => (
    is     => 'rw',
    isa    => Maybe[ArrayRef],
    coerce => sub {
        return unless $_[0];
        # Allow single sorts, or several in an array
        ref $_[0] eq 'ARRAY' ? $_[0] : [ $_[0] ],
    },
);

has schema => (
    is       => 'rw',
    required => 1,
);

has default_sort => (
    is => 'rw',
);

has results => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _search_construct;

sub _default_sort
{   my ($self, $col_id, $type) = @_;

    if ($col_id)
    {
        my $column = $self->layout->column($col_id);
        { $type => $column };
    }
    else {
        { -asc => 'id' };
    }
}

# Shortcut to generate the required joining hash for a DBIC search
sub linked_hash
{   my ($self, %options) = @_;
    my @tables = $self->jpfetch(%options, linked => 1);
    if (@tables)
    {
        {
            linked => {
                record => \@tables,
            },
        };
    }
    else {
        {
            linked => 'record',
        }
    }
}

# A function to see if any views have a particular record within
sub search_views
{   my ($self, $current_ids, @views) = @_;

    return unless @views && @$current_ids;

    # Need to specify no columns to be retrieved, otherwise as soon as
    # $self->joins is called, prefetch will have all the columns in
    $self->columns([]);

    my @foundin;
    foreach my $view (@views)
    {
        # Treat each view with CURUSER as a separate view for each user
        # that has it set as an alert
        my @user_ids = $view->has_curuser
           ? $self->schema->resultset('Alert')->search({
            view_id => $view->id
        })->get_column('user_id')->all : (undef);

        foreach my $user_id (@user_ids)
        {
            my $filter  = $view->filter || '{}';
            my $view_id = $view->id;
            trace qq(About to decode filter for view ID $view_id);
            my $decoded = decode_json($filter);
            if (keys %$decoded)
            {
                my $search = {
                    'me.instance_id' => $self->layout->instance_id,
                    @{$self->_search_construct($decoded, $self->layout, ignore_perms => 1, user_id => $user_id)},
                };
                my $i = 0; my @ids;
                while ($i < @$current_ids)
                {
                    # See comment above about searching for all current_ids
                    unless (@$current_ids == $self->count)
                    {
                        my $max = $i + 499;
                        $max = @$current_ids-1 if $max >= @$current_ids;
                        $search->{'me.id'} = [@{$current_ids}[$i..$max]];
                    }
                    push @ids, $self->schema->resultset('Current')->search($search,{
                        join => {'record' => [$self->jpfetch(search => 1)]},
                    })->get_column('id')->all;
                    last unless $search->{'me.id'};
                    $i += 500;
                }
                foreach my $id (@ids)
                {
                    push @foundin, {
                        view    => $view,
                        id      => $id,
                        user_id => $user_id,
                    };
                }
            }
            else {
                # No filter, definitely in view
                push @foundin, {
                    view    => $view,
                    user_id => $user_id,
                    id      => $_,
                } foreach @$current_ids;
            }
        }
    }
    @foundin;
}

sub search_all_fields
{   my ($self, $search) = @_;

    $search or return;

    my %results;

    my $search_index = lc(substr($search, 0, 128));
    if ($search =~ s/\*/%/g )
    {
        $search = { like => $search };
        $search_index =~ s/\*/%/g;
        $search_index = { like => $search_index };
    }

    # XXX These really need to be pulled from the various Column classes
    my @fields = (
        { type => 'string', plural => 'strings', index_field => 'value_index' },
        { type => 'int'   , plural => 'intgrs' },
        { type => 'date'  , plural => 'dates' },
        { type => 'string', plural => 'dateranges' },
        { type => 'string', plural => 'ragvals' },
        { type => 'string', plural => 'calcvals', value_field => 'value_text' },
        { type => 'number', plural => 'calcvals', value_field => 'value_numeric' },
        { type => 'int'   , plural => 'calcvals', value_field => 'value_int' },
        { type => 'date'  , plural => 'calcvals', value_field => 'value_date' },
        { type => 'string', plural => 'enums', sub => 1 },
        { type => 'string', plural => 'people', sub => 1 },
        { type => 'file'  , plural => 'files', sub => 1, value_field => 'name' },
        { type => 'current_id', plural => '' }, # Empty string to avoid uninit warnings
    );

    my @columns_can_view;
    foreach my $col ($self->layout->all(user_can_read => 1))
    {
        push @columns_can_view, $col->id;
        push @columns_can_view, @{$col->curval_field_ids}
            if ($col->type eq 'curval'); # Curval type needs all its columns from other layout
    }

    # Applies to all types of fields being searched
    my @basic_search;
    # Only search limited view if configured for user
    if (my $view = $self->limit_to_view)
    {
        if (my $filter = $view->filter)
        {
            my $decoded = decode_json($filter);
            if (keys %$decoded)
            {
                push @basic_search, @{$self->_search_construct($decoded, $self->layout)};
            }
        }
    }

    my %found;
    foreach my $field (@fields)
    {
        next if ($field->{type} eq 'number')
            && !looks_like_number $search;
        next if ($field->{type} eq 'int' || $field->{type} eq 'current_id')
            && $search !~ /^-?\d+$/;
        next if $field->{type} eq 'date' && !GADS::Column::Date->validate($search);

        # These aren't really needed for current_id, but no harm
        my $plural      = $field->{plural};
        my $value_field = $field->{value_field} || 'value';
        my $s           = $field->{sub} ? "value.$value_field" : "$plural.$value_field";
        my $joins       = $field->{type} eq 'current_id'
                        ? undef
                        : $field->{sub}
                        ? {
                              'record' => [
                                  $self->jpfetch(search => 1),
                                  {
                                      $plural => ['value', 'layout']
                                  },
                              ]
                          } 
                        : {
                              'record' => [
                                  $self->jpfetch(search => 1),
                                  {
                                      $plural => 'layout'
                                  },
                              ]
                          };

        my @search = @basic_search;
        push @search,
            $field->{type} eq 'current_id'
            ? { id => $search }
            : $field->{index_field} # string with additional index field
            ? ( { $field->{index_field} => $search_index }, { $s => $search } )
            : { $s => $search };
        if ($field->{type} eq 'current_id')
        {
            push @search, { 'me.instance_id' => $self->layout->instance_id };
        }
        else {
            push @search, { 'layout.id' => \@columns_can_view }
        }
        my @currents = $self->schema->resultset('Current')->search({ -and => \@search},{
            join => $joins,
        })->all;

        foreach my $current (@currents)
        {
            if ($current->instance_id != $self->layout->instance_id)
            {
                # instance ID different from current, therefore must be curval field result
                my @search = @basic_search;
                push @search, "curvals.value" => $current->id;
                my $found = $self->schema->resultset('Current')->search({ -and => \@search},{
                    join => {
                        record => [
                            'curvals',
                            $self->jpfetch(search => 1),
                        ]
                    },
                });
                $found{$_} = 1
                    foreach $found->get_column('id')->all;
            }
            else {
                $found{$current->id} = 1;
            }
        }
    }

    my @ids = keys %found;
    $self->current_ids(\@ids);
}

# Produce a standard set of results without grouping
sub _build_results
{   my $self = shift;

    # XXX Okay, this is a bit weird - we join current to record to current.
    # This is because we return records at the end, and it allows current
    # to be used when the record is used. Is there a better way?
    my $search_query    = $self->search_query(search => 1, sort => 1); # Need to call first to build joins
    my @prefetches      = $self->jpfetch(prefetch => 1);
    my @linked_prefetch = $self->linked_hash(prefetch => 1);

    # Run 2 queries. First to get the current IDs of the matching records, then
    # the second to get the actual data for the records. Although this means
    # 2 separate DB queries, it prevents queries with large SELECT and WHERE
    # clauses, which can be very slow (with Pg at least).
    my $select = {
        join     => [
            {
                'record' => [$self->jpfetch(search => 1, sort => 1)],
            },
            [$self->linked_hash(search => 1, sort => 1)],
        ],
        '+select' => $self->plus_select, # Used for additional sort columns
        order_by  => $self->order_by,
    };
    my $page = $self->page;
    $page = $self->pages
        if $page && $page > 1 && $page > $self->pages; # Building page count is expensive, avoid if not needed

    $select->{rows} = $self->rows if $self->rows;
    $select->{page} = $page if $page;

    # Get the current IDs
    my @cids = $self->schema->resultset('Current')->search(
        [-and => $search_query], $select
    )->get_column('me.id')->all;

    # Now redo the query with those IDs
    my $rec1 = @prefetches ? { record => [@prefetches] } : 'record';
    # Add joins for sorts, but only if they're not already a prefetch (otherwise ordering can be messed up)
    my @j = $self->jpfetch(sort => 1, prefetch => 0);
    my $rec2 = @j ? { record => [@j] } : 'record';

    $select = {
        prefetch => [
            $rec1,
            [@linked_prefetch],
        ],
        join     => [
            $rec2,
            [$self->linked_hash(sort => 1)],
        ],
        '+select' => $self->plus_select, # Used for additional sort columns
        order_by  => $self->order_by,
    };

    my $result = $self->schema->resultset('Current')->search(
        { 'me.id' => \@cids }, $select
    );

    $result->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @all;
    foreach my $rec ($result->all)
    {
        my @children = map { $_->{id} } @{$rec->{currents}};
        push @all, GADS::Record->new(
            schema               => $self->schema,
            record               => $rec->{record},
            linked_record        => $rec->{linked}->{record},
            child_records        => \@children,
            parent_id            => $rec->{parent_id},
            linked_id            => $rec->{linked_id},
            user                 => $self->user,
            layout               => $self->layout,
            force_update         => $self->force_update,
            columns_retrieved_no => $self->columns_retrieved_no,
            columns_retrieved_do => $self->columns_retrieved_do,
        );
    }

    \@all;
}

has _next_single_id => (
    is      => 'rwp',
    isa     => Maybe[Int],
    default => 0,
);

# This could be called thousands of times (e.g. download), so fetch
# the rows in chunks
sub single
{   my $self = shift;
    my $chunk = 100; # Size of chunks to retrieve each time
    $self->rows($chunk) unless $self->rows;
    $self->page(1) unless $self->page;
    my $next_id = $self->_next_single_id;
    if ($next_id >= $chunk)
    {
        return if $self->page == $self->pages;
        $next_id = $next_id - $chunk;
        $self->clear_results;
        $self->page($self->page + 1);
    }
    my $row = $self->results->[$next_id];
    $self->_set__next_single_id($next_id + 1);
    $row;
}

sub _build_count
{   my $self = shift;

    my $search_query = $self->search_query(search => 1);
    my @joins        = $self->jpfetch(search => 1);
    my @linked       = $self->linked_hash(search => 1, linked => 1);
    my $select = {
        join     => [
            {
                'record' => [@joins],
            },
            [@linked],
        ],
    };

    $self->schema->resultset('Current')->search(
        [-and => $search_query], $select
    )->count;
}

sub _build_has_children
{   my $self = shift;

    my @search_query = @{$self->search_query(search => 1)};
    my $linked = $self->linked_hash(search => 1);
    my $select = {
        join     => [
            {
                'record' => [$self->jpfetch(search => 1)],
            },
            $linked,
        ],
        rows => 1,
    };

    push @search_query, { 'me.parent_id' => { '!=' => undef }};
    my @child = $self->schema->resultset('Current')->search(
        [-and => [@search_query]], $select
    )->all;
    @child ? 1 : 0;
}

sub _build_columns_retrieved_do
{   my $self = shift;
    my $layout = $self->layout;
    # First, add all the columns in the view as a prefetch. During
    # this stage, we keep track of what we've added, so that we
    # can act accordingly during the filters
    my @columns;
    if ($self->columns)
    {
        my @col_ids = grep {defined $_} @{$self->columns}; # Remove undef column IDs
        my %col_ids;
        @col_ids{@col_ids} = undef;
        @columns = grep { exists $col_ids{$_->id} } $layout->all(order_dependencies => 1);
    }
    elsif (my $view = $self->view)
    {
        @columns = $layout->view(
            $view->id,
            order_dependencies => 1,
            user_can_read      => 1,
            columns_extra      => $self->columns_extra,
        );
    }
    else {
        @columns = $layout->all(
            remembered_only    => $self->remembered_only,
            order_dependencies => 1,
        );
    }
    \@columns;
}

sub _build_columns_retrieved_no
{   my $self = shift;
    my %columns_retrieved = map { $_->id => undef } @{$self->columns_retrieved_do};
    my @columns_retrieved_no = grep { exists $columns_retrieved{$_->id} } $self->layout->all;
    \@columns_retrieved_no;
}

sub clear
{   my $self = shift;
    $self->clear_pages;
    $self->clear_limit_to_view;
    $self->clear_columns_retrieved_no;
    $self->clear_columns_retrieved_do;
    $self->clear_count;
    $self->clear_results;
    $self->_set__next_single_id(0);
}

# Construct various parameters used for the query. These are all
# related, so it makes sense to construct them together.
sub _query_params
{   my ($self, %options) = @_;

    $self->order_by([]);
    $self->order_by_count(0);
    my $layout = $self->layout;

    my @search_date;                    # The search criteria to narrow-down by date range
    foreach my $c (@{$self->columns_retrieved_do})
    {
        if ($c->type eq "date" || $c->type eq "daterange")
        {
            # Apply any date filters if required
            my @f;
            if (my $to = $self->to)
            {
                my $f = {
                    id       => $c->id,
                    operator => 'less_or_equal',
                    value    => $to->ymd,
                };
                push @f, $f;
            }
            if (my $from = $self->from)
            {
                my $f = {
                    id       => $c->id,
                    operator => 'greater_or_equal',
                    value    => $from->ymd,
                };
                push @f, $f;
            }
            push @search_date, {
                condition => "AND",
                rules     => \@f,
            } if @f;
        }
        # We're viewing this, so prefetch all the values
        $self->add_prefetch($c);
        $self->add_linked_prefetch($c->link_parent) if $c->link_parent;
    }

    my @limit;  # The overall limit, for example reduction by date range or approval field
    my @search; # The user search
    # The following code needs to be run twice, to make sure that join numbers
    # are worked out correctly. Otherwise, a search criteria might not take
    # into account a subsuquent sort, and vice-versa.
    for (1..2)
    {
        # Add any date ranges to the search from above
        if (@search_date)
        {
            # _search_construct returns an array ref, so dereference it first
            my @res = @{($self->_search_construct({condition => 'OR', rules => \@search_date}, $layout))};
            push @limit, @res if @res;
        }

        my $user_sort = $self->sort; # Sort overriding view's sort

        # Now add all the filters as joins (we don't need to prefetch this data). However,
        # the filter might also be a column in the view from before, in which case add
        # it to, or use, the prefetch. We use the tracking variables from above.
        if (my $view = $self->view)
        {
            # Apply view filter, but not if specific current IDs set (as when quick search is used)
            if ($view->filter && !$self->current_ids)
            {
                my $decoded = decode_json($view->filter);
                if (keys %$decoded)
                {
                    # Get the user search criteria
                    @search = @{$self->_search_construct($decoded, $layout, %options)};
                }
            }
            unless ($user_sort)
            {
                foreach my $sort (@{$view->sorts})
                {
                    if (my $col_id = $sort->{layout_id})
                    {
                        my $column  = $layout->column($col_id);
                        my $type    = $sort->{type} eq 'desc' ? '-desc' : '-asc';
                        $self->add_sort($column, $type);
                    }
                    else {
                        # No column defined means sort by ID
                        my $type = $sort->{type} eq 'desc' ? '-desc' : '-asc';
                        push @{$self->order_by}, { $type => 'me.id' };
                    }
                    # Add the first sort column to the object for retrieval later
                    $self->sort({
                        id   => $sort->{layout_id},
                        type => $sort->{type},
                    }) unless $self->sort;
                }
            }
        }
        if (my $view = $self->limit_to_view)
        {
            if (my $filter = $view->filter)
            {
                my $decoded = decode_json($filter);
                if (keys %$decoded)
                {
                    # Get the user search criteria
                    push @search, @{$self->_search_construct($decoded, $layout, %options)};
                }
            }
        }
        # Configure specific user selected sort, if applicable. This needs to be done
        # after the filters have been added, otherwise the filters could add additonal
        # joins which will put the value_x columns out of kilter. A user selected
        # column will always be in a prefetch, so it's not possible for the reverse
        # to happen
        if ($user_sort)
        {
            my @sorts;
            foreach my $s (@$user_sort)
            {
                my $type = $s->{type} && $s->{type} eq 'desc' ? '-desc' : '-asc';
                if (!$s->{id})
                {
                    push @{$self->order_by}, { $type => 'me.id' };
                }
                elsif (my $column = $layout->column($s->{id}))
                {
                    $self->add_sort($column, $type);
                }
            }
        }
        # Default sort
        unless (@{$self->order_by})
        {
            my $default_sort = $self->default_sort;
            my $type         = $default_sort->{type} && $default_sort->{type} eq 'desc' ? 'desc' : 'asc';
            if (my $col_id = $default_sort->{id})
            {
                my $col     = $self->layout->column($col_id);
                $self->add_sort($col, "-$type");
                $self->sort({
                    id   => $col_id,
                    type => $type,
                });
            }
            else {
                push @{$self->order_by}, { "-$type" => 'me.id' };
                $self->sort({
                    type => $type,
                });
            }
        }
    }

    (@limit, @search);
}

sub add_sort
{   my ($self, $column, $type) = @_;

    $self->add_join($column, sort => 1);
    my $s_table = $self->table_name($column, sort => 1, search => 1);
    $self->order_by_inc;
    my $sort_name = "sort_".$self->order_by_count;
    if ($column->link_parent)
    {
        push @{$self->plus_select}, {
            concat => [
                "$s_table.".$column->value_field,
                $self->table_name_linked($column->link_parent, sort => 1, search => 1, linked => 1).".".$column->value_field,
            ],
            -as    => $sort_name,
        };
    }
    else {
        $sort_name = "$s_table.".$column->value_field;
    }
    push @{$self->order_by}, {
        $type => $sort_name,
    };
}

# $ignore_perms means to ignore any permissions on the column being
# processed. For example, if the current user is updating a record,
# we want to process columns that the user doesn't have access to
# for things like alerts, but not for their normal viewing.
sub _search_construct
{   my ($self, $filter, $layout, %options) = @_;

    my $ignore_perms = $options{ignore_perms};
    if (my $rules = $filter->{rules})
    {
        # Filter has other nested filters
        my @final;
        foreach my $rule (@$rules)
        {
            my @res = $self->_search_construct($rule, $layout, %options);
            push @final, @res if @res;
        }
        my $condition = $filter->{condition} && $filter->{condition} eq 'OR' ? '-or' : '-and';
        return @final ? [$condition => \@final] : [];
    }

    my %ops = (
        equal            => '=',
        greater          => '>',
        greater_or_equal => '>=',
        less             => '<',
        less_or_equal    => '<=',
        contains         => '-like',
        begins_with      => '-like',
        not_equal        => '!=',
        is_empty         => '=',
        is_not_empty     => '!=',
    );

    my %permission = $ignore_perms ? () : (permission => 'read');
    my $column   = $layout->column($filter->{id}, %permission)
        or return;
    my $operator = $ops{$filter->{operator}}
        or error __x"Invalid operator {filter}", filter => $filter->{operator};

    $self->add_join($column, search => 1);
    my $s_table = $self->table_name($column, %options, search => 1);

    my @conditions;
    if ($column->type eq "daterange")
    {
        # If it's a daterange, we have to be intelligent about the way the
        # search is constructed. Greater than, less than, equals all require
        # different values of the date range to be searched
        if ($operator eq "!=" || $operator eq "=") # Only used for empty / not empty
        {
            push @conditions, {
                operator => $operator,
                s_field  => "value",
            };
        }
        elsif ($operator eq ">" || $operator eq "<=")
        {
            push @conditions, {
                operator => $operator,
                s_field  => "from",
            };
        }
        elsif ($operator eq ">=" || $operator eq "<")
        {
            push @conditions, {
                operator => $operator,
                s_field  => "to",
            };
        }
        elsif ($operator eq "-like")
        {
            # Requires 2 searches ANDed together
            push @conditions, {
                operator => "<=",
                s_field  => "from",
            };
            push @conditions, {
                operator => ">=",
                s_field  => "to",
            };
            $operator = 'equal';
        }
        else {
            error __x"Invalid operator {operator} for date range", operator => $operator;
        }
    }
    else {
        push @conditions, {
            operator => $operator,
            s_field  => $column->value_field,
        };
    }

    my $vprefix = $operator eq '-like' ? '' : '';
    my $vsuffix = $operator eq '-like' ? '%' : '';

    my $value;
    if ($filter->{operator} eq 'is_empty' || $filter->{operator} eq 'is_not_empty')
    {
        my $comb = $filter->{operator} eq 'is_empty' ? '-or' : '-and';
        $value = $column->string_storage
            ? [ $comb => undef, "" ]
            : undef;
    }
    else {
        $value = $vprefix.$filter->{value}.$vsuffix;
    }

    # Sub-in current date as required. Ideally we would use the same
    # code here as the calc/rag fields, but this can be accessed by
    # any user, so should be a lot tighter.
    if ($filter->{value} && $filter->{value} =~ "CURDATE")
    {
        my $vdt = GADS::View->parse_date_filter($filter->{value});
        my $dtf = $self->schema->storage->datetime_parser;
        $value = $dtf->format_date($vdt);
    }

    $value =~ s/\_/\\\_/g if $operator eq '-like';

    return unless $column->validate($value);

    if ($column->type eq "string")
    {
        # The normal value search of a string is not indexed, due to the potential size
        # of the data. Therefore, add the second indexed value field, to speed up
        # the search.
        # $value can be an array ref from above.
        push @conditions, {
            operator => $operator,
            s_field  => "value_index",
            value    => $value && !ref($value) ? lc(substr($value, 0, 128)) : $value,
        };
    }

    if ($column->type eq "person" && $value =~ /\[CURUSER\]/)
    {
        my $curuser = $options{user_id} || ($self->user && $self->user->{id})
            or warning "FIXME: user not set for filter";
        $curuser ||= "";
        $value =~ s/\[CURUSER\]/$curuser/g;
        $conditions[0]->{s_field} = "id";
    }

    my @final = map {
        # By default SQL will not include NULL values for not equals.
        # Let's include them. We need to use the original filter operator
        # value, not the converted SQL one.
        # XXX Repeated below
        my $sq = {$_->{operator} => $_->{value} || $value};
        $sq = [ $sq, undef ] if $filter->{operator} eq 'not_equal';
        +( "$s_table.$_->{s_field}" => $sq )
    } @conditions;
    @final = ('-and' => [@final]);
    if ($column->link_parent)
    {
        my @final2 = map {
            # XXX Repeated above
            my $sq = {$_->{operator} => $_->{value} || $value};
            $sq = [ $sq, undef ] if $filter->{operator} eq 'not_equal';
            $self->add_join($column->link_parent, linked => 1, search => 1);
            +( $self->table_name($column->link_parent, %options, search => 1, linked => 1).".$_->{s_field}" => $sq );
        } @conditions;
        @final2 = ('-and' => [@final2]);
        @final = (['-or' => [@final], [@final2]]);
    }
    return @final;
}

sub csv
{   my $self = shift;
    my $csv  = Text::CSV::Encoded->new({ encoding  => undef });

    # Column names
    my @columns = $self->view
        ? $self->layout->view($self->view->id, user_can_read => 1)
        : $self->layout->all(user_can_read => 1);
    my @colnames = ("Serial");
    push @colnames, "Parent" if $self->has_children;
    push @colnames, map { $_->name } @columns;
    $csv->combine(@colnames)
        or error __x"An error occurred producing the CSV headings: {err}", err => $csv->error_input;
    my $csvout = $csv->string."\n";

    # All the data values
    while (my $line = $self->single)
    {
        my @items = ($line->current_id);
        push @items, $line->parent_id if $self->has_children;
        push @items, map { $line->fields->{$_->id} } @columns;
        $csv->combine(@items)
            or error __x"An error occurred producing a line of CSV: {err} {items}",
                err => "".$csv->error_diag, items => "@items";
        $csvout .= $csv->string."\n";
    }
    $csvout;
}

# Base function for calendar and timeline
sub data_time
{   my ($self, $type, %options) = @_;

    my @colors = qw/event-important event-success event-warning event-info event-inverse event-special/;
    my @result;
    my %datecolors;
    my %timeline_groups;
    my $group_count;

    # Need a Graph::Data instance to get relevant colors
    my $graph = GADS::Graph::Data->new(
        schema  => $self->schema,
        records => undef,
    );

    # All the data values
    my $multiple_dates;
    while (my $record  = $self->single)
    {
        my @dates; my @titles;
        my $had_date_col; # Used to detect multiple date columns in this view
        foreach my $column (@{$self->columns_retrieved_no})
        {
            # Get item value
            my $d = $record->fields->{$column->id}
                or next;

            # Only show unique items of children, otherwise will be a lot of
            # repeated entries
            next if $record->parent_id && !$d->child_unique;

            if ($column->return_type eq "daterange" || $column->return_type eq "date")
            {
                $multiple_dates = 1 if $had_date_col;
                $had_date_col = 1;
                next unless $column->user_can('read');

                # Create colour if need be
                $datecolors{$column->id} = shift @colors unless $datecolors{$column->id};

                # Set colour
                my $color = $datecolors{$column->id};

                # Push value onto stack
                if ($column->type eq "daterange")
                {
                    $d->from_dt && $d->to_dt or next;
                    # It's possible that values from other columns not within
                    # the required range will have been retrieved. Don't bother
                    # adding them
                    push @dates, {
                        from  => $d->from_dt,
                        to    => $d->to_dt,
                        color => $color,
                        column=> $column->id,
                    } if (!$self->to || DateTime->compare($self->to, $d->from_dt) >= 0)
                      && (!$self->from || DateTime->compare($d->to_dt, $self->from) >= 0);
                }
                else {
                    $d->value or next;
                    push @dates, {
                        from  => $d->value,
                        to    => $d->value,
                        color => $color,
                        column=> $column->id,
                    } if (!$self->from || DateTime->compare($d->value, $self->from) >= 0)
                      && (!$self->to || DateTime->compare($self->to, $d->value) >= 0);
                }
            }
            else {
                next if $column->type eq "rag";
                # Check if the user has selected only one label
                next if $options{label} && $options{label} != $column->id;
                # Not a date value, push onto title
                # Don't want full HTML, which includes hyperlinks etc
                push @titles, $d->as_string if $d->as_string;
            }
        }
        if (my $label = $options{label})
        {
            @titles = ($record->fields->{$label}->as_string)
                # Value for this record may not exist or be blank
                if $record->fields->{$label} && $record->fields->{$label}->as_string;
        }
        my $item_color; my $color_key = '';
        if (my $color = $options{color})
        {
            if ($record->fields->{$color})
            {
                $color_key = $record->fields->{$color}->as_string;
                $item_color = $graph->get_color($color_key);
            }
        }
        my $item_group;
        if (my $group = $options{group})
        {
            if ($record->fields->{$group})
            {
                my $val = $record->fields->{$group}->as_string;
                unless ($item_group = $timeline_groups{$val})
                {
                    $item_group = ++$group_count;
                    $timeline_groups{$val} = $item_group;
                }
            }
        }

        # Create title label
        my $title = join ' - ', @titles;
        my $title_abr = length $title > 50 ? substr($title, 0, 45).'...' : $title;

        foreach my $d (@dates)
        {
            next unless $d->{from} && $d->{to};
            my @add;
            push @add, $self->layout->column($d->{column})->name if $multiple_dates;
            push @add, $color_key if $options{color};
            my $add = join ', ', @add;
            my $title_i = $add ? "$title ($add)" : $title;
            my $title_i_abr = $add ? "$title_abr ($add)" : $title_abr;
            if ($type eq 'calendar')
            {
                my $item = {
                    "url"   => "/record/" . $record->current_id,
                    "class" => $d->{color},
                    "title" => $title_i_abr,
                    "id"    => $record->current_id,
                    "start" => $d->{from}->epoch*1000,
                    "end"   => $d->{to}->epoch*1000,
                };
                push @result, $item;
            }
            else {
                my $cid = $record->current_id;
                $title_i = encode_entities $title_i;
                $title_i_abr = encode_entities $title_i_abr;
                # If this is an item for a single day, then abbreviate the title,
                # otherwise it can appear as a very long item on the timeline.
                # If it's multiple day, the timeline plugin will automatically shorten it.
                my $t = $d->{from}->epoch == $d->{to}->epoch ? $title_i_abr : $title_i;
                my $item = {
                    "content" => qq(<a title="$title_i" href="/record/$cid" style="color:inherit;">$t</a>),
                    "id"      => "$cid+$d->{column}",
                    current_id => $cid,
                    "start"   => $d->{from}->ymd,
                    "group"   => $item_group,
                    column    => $d->{column},
                    title     => $title_i,
                };
                $item->{style} = qq(background-color: $item_color)
                    if $item_color;
                $item->{end} = $d->{to}->ymd
                    if $d->{from}->epoch != $d->{to}->epoch;
                push @result, $item;
            }
        }
    }

    my @groups = map {
        {
            id      => $timeline_groups{$_},
            content => encode_entities $_,
        }
    } keys %timeline_groups;

    wantarray ? (\@result, \@groups) : \@result;
}

sub data_calendar
{   my $self = shift;
    $self->data_time('calendar');
}

sub data_timeline
{   my $self = shift;
    $self->data_time('timeline', @_);
}

sub _min_date { shift->_min_max_date('min', @_) };
sub _max_date { shift->_min_max_date('max', @_) };

sub _min_max_date
{   my ($self, $action, $date1, $date2) = @_;
    my $dt_parser = $self->schema->storage->datetime_parser;
    my $d1 = $dt_parser->parse_date($date1);
    my $d2 = $dt_parser->parse_date($date2);
    return $d1 if !$d2;
    return $d2 if !$d1;
    if ($action eq 'min') {
        return $d1 if $d1->epoch < $d2->epoch;
    } else {
        return $d1 if $d1->epoch > $d2->epoch;
    }
    return $d2;
}

1;

