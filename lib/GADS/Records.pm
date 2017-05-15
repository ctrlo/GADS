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

use Data::Dumper qw/Dumper/;
use DateTime;
use DateTime::Format::Strptime qw( );
use DBIx::Class::Helper::ResultSet::Util qw(correlate);
use DBIx::Class::ResultClass::HashRefInflator;
use GADS::Record;
use GADS::View;
use HTML::Entities;
use Log::Report 'linkspace';
use POSIX qw(ceil);
use Scalar::Util qw(looks_like_number);
use Text::CSV::Encoded;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;

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
has view_limits => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_view_limits
{   my $self = shift;
    $self->user or return [];
    my @view_limits = $self->schema->resultset('ViewLimit')->search({
        'me.user_id' => $self->user->{id},
    },{
        prefetch => 'view',
    })->all;
    my @views;
    foreach my $view_limit (@view_limits)
    {
        push @views, GADS::View->new(
            user        => undef, # In case user does not have access
            id          => $view_limit->view_id,
            schema      => $self->schema,
            layout      => $self->layout,
            instance_id => $self->layout->instance_id,
        ) if $view_limit->view->instance_id == $self->layout->instance_id;
    }
    \@views;
}

sub view_limits_search
{   my ($self, %options) = @_;
    my @search;
    foreach my $view (@{$self->view_limits})
    {
        if (my $filter = $view->filter)
        {
            my $decoded = $filter->as_hash;
            if (keys %$decoded)
            {
                # Get the user search criteria
                push @search, @{$self->_search_construct($decoded, $self->layout)};
            }
        }
    }
    [ '-or' => \@search ];
}

has from => (
    is => 'rw',
);

has to => (
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

# Whether to take results from some previous point in time
has rewind => (
    is  => 'ro',
    isa => Maybe[DateAndTime],
);

sub rewind_formatted
{   my $self = shift;
    $self->rewind or return;
    $self->schema->storage->datetime_parser->format_datetime($self->rewind);
}

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
    # Only used by record_later_search(). Will pull wrong query_params
    # if left in %options
    my $linked     = delete $options{linked};
    my @search     = $self->_query_params(%options);
    my $root_table = $options{root_table} || 'current';
    my $current    = $root_table eq 'current' ? 'me' : 'current';
    unless ($self->include_approval)
    {
        # There is a chance that there will be no approval records. In that case,
        # the search will be a lot quicker without adding the approval search
        # condition (due to indexes not spanning across tables). So, do a quick
        # check first, and only add the condition if needed
        my ($approval_exists) = $root_table eq 'current' && $self->schema->resultset('Current')->search({
            instance_id        => $self->layout->instance_id,
            "records.approval" => 1,
        },{
            join => 'records',
            rows => 1,
        })->all;
        push @search, (
            { "record_single.approval"  => 0 },
        ) if $approval_exists;
    }
    push @search, { "$current.id"          => $self->current_ids} if $self->current_ids;
    push @search, { "$current.instance_id" => $self->layout->instance_id };
    push @search, $self->record_later_search(%options, linked => $linked);
    push @search, {
        'record_single.created' => { '<' => $self->rewind_formatted },
    } if $self->rewind;
    [@search];
}

has _plus_select => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

sub clear_sorts
{   my $self = shift;
    $self->_clear_sorts;
    $self->clear_sort_first;
}

# Internal list of all sorts for this resultset. Generated from any of the means
# of setting a sort, or returns default if required
has _sorts => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

# User-specified sort override
has sort => (
    is     => 'rw',
    isa    => Maybe[ArrayRef],
    coerce => sub {
        return unless $_[0];
        # Allow single sorts, or several in an array
        ref $_[0] eq 'ARRAY' ? $_[0] : [ $_[0] ],
    },
);

# The first sort of the calculated list of sorts
has sort_first => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_sort_first
{   my $self = shift;
    @{$self->_sorts}[0];
}

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

# Shortcut to generate the required joining hash for a DBIC search
sub linked_hash
{   my ($self, %options) = @_;
    my @tables = $self->jpfetch(%options, linked => 1);
    if (@tables)
    {
        {
            linked => [
                {
                    record_single => [
                        'record_later',
                        @tables,
                    ]
                },
            ],
        };
    }
    else {
        {
            linked => { record_single => 'record_later' },
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
        my @users = $view->has_curuser
           ? $self->schema->resultset('User')->search({
            view_id => $view->id
        }, {
            join => 'alerts',
        })->all : (undef);

        foreach my $user (@users)
        {
            my $filter  = $view->filter;
            my $view_id = $view->id;
            trace qq(About to decode filter for view ID $view_id);
            my $decoded = $filter->as_hash;
            if (keys %$decoded)
            {
                my $search = {
                    'me.instance_id'          => $self->layout->instance_id,
                    @{$self->_search_construct($decoded, $self->layout, ignore_perms => 1, user => $user)},
                    %{$self->record_later_search},
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
                        join => {
                            'record_single' => [
                                $self->jpfetch(search => 1),
                                'record_later',
                            ],
                        },
                    })->get_column('id')->all;
                    last unless $search->{'me.id'};
                    $i += 500;
                }
                foreach my $id (@ids)
                {
                    push @foundin, {
                        view    => $view,
                        id      => $id,
                        user_id => $user && $user->id,
                    };
                }
            }
            else {
                # No filter, definitely in view
                push @foundin, {
                    view    => $view,
                    user_id => $user && $user->id,
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
        { type => 'string', plural => 'strings', index_field => 'strings.value_index' },
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
    push @basic_search, $self->view_limits_search;

    my $date_column = GADS::Column::Date->new(
        schema => $self->schema,
        layout => $self->layout,
    );
    my %found;
    foreach my $field (@fields)
    {
        my $search_local = $search;
        next if ($field->{type} eq 'number')
            && !looks_like_number $search_local;
        next if ($field->{type} eq 'int' || $field->{type} eq 'current_id')
            && $search_local !~ /^-?\d+$/;
        if ($field->{type} eq 'date')
        {
            next if !$date_column->validate($search_local);
            $search_local = $self->_date_for_db($date_column, $search_local);
        }

        # These aren't really needed for current_id, but no harm
        my $plural      = $field->{plural};
        my $value_field = $field->{value_field} || 'value';
        # Need to get correct "value" number for search, in case it's been incremented through view_limits
        my $s           = $field->{sub} ? $self->value_next_join(search => 1).".$value_field" : "$plural.$value_field";

        my $joins       = $field->{type} eq 'current_id'
                        ? undef
                        : $field->{sub}
                        ? {
                              'record_single' => [
                                  'record_later',
                                  $self->jpfetch(search => 1),
                                  {
                                      $plural => ['value', 'layout']
                                  },
                              ]
                          } 
                        : {
                              'record_single' => [
                                  'record_later',
                                  $self->jpfetch(search => 1),
                                  {
                                      $plural => 'layout'
                                  },
                              ]
                          };

        my @search = @basic_search;
        push @search,
            $field->{type} eq 'current_id'
            ? { id => $search_local }
            : $field->{index_field} # string with additional index field
            ? ( { $field->{index_field} => $search_index }, { $s => $search_local } )
            : { $s => $search_local };
        if ($field->{type} eq 'current_id')
        {
            push @search, { 'me.instance_id' => $self->layout->instance_id };
        }
        else {
            push @search, { 'layout.id' => \@columns_can_view };
            push @search, $self->record_later_search(search => 1);
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
                        record_single => [
                            'record_later',
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

    # Build the search query first, to ensure that all join numbers are correct
    my $search_query    = $self->search_query(search => 1, sort => 1, linked => 1); # Need to call first to build joins
    my @prefetches      = $self->jpfetch(prefetch => 1, linked => 0);
    my @linked_prefetch = $self->linked_hash(prefetch => 1);

    # Run 2 queries. First to get the current IDs of the matching records, then
    # the second to get the actual data for the records. Although this means
    # 2 separate DB queries, it prevents queries with large SELECT and WHERE
    # clauses, which can be very slow (with Pg at least).
    my $select = {
        join     => [
            {
                'record_single' => [ # The (assumed) single record for the required version of current
                    'record_later',  # The record after the single record (undef when single is latest)
                    $self->jpfetch(search => 1, sort => 1, linked => 0),
                ],
            },
            [$self->linked_hash(search => 1, sort => 1)],
        ],
        '+select' => $self->_plus_select, # Used for additional sort columns
        order_by  => $self->order_by(search => 1),
        distinct  => 1, # Otherwise multiple records returned for multivalue fields
    };
    my $page = $self->page;
    $page = $self->pages
        if $page && $page > 1 && $page > $self->pages; # Building page count is expensive, avoid if not needed

    $select->{rows} = $self->rows if $self->rows;
    $select->{page} = $page if $page;

    local $GADS::Schema::Result::Record::REWIND = $self->rewind_formatted
        if $self->rewind;
    # Get the current IDs
    # Only take the latest record_single (no later ones)
    my @cids = $self->schema->resultset('Current')->search(
        [-and => $search_query], $select
    )->get_column('me.id')->all;

    # Now redo the query with those IDs.
    @prefetches = $self->jpfetch(prefetch => 1, linked => 0);
    unshift @prefetches, (
        {
            'createdby' => 'organisation',
        },
    );

    my $rec1 = @prefetches ? { record_single => [@prefetches] } : 'record_single';
    # Add joins for sorts, but only if they're not already a prefetch (otherwise ordering can be messed up).
    # We also add the join for record_later, so that we can take only the latest required record
    my @j = $self->jpfetch(sort => 1, prefetch => 0, linked => 0);
    my $rec2 = @j ? { record_single => [@j, 'record_later'] } : { record_single => 'record_later' };

    $select = {
        prefetch => [
            $rec1,
            [@linked_prefetch],
        ],
        join     => [
            $rec2,
            [$self->linked_hash(sort => 1)],
        ],
        '+select' => $self->_plus_select, # Used for additional sort columns
        order_by  => $self->order_by(prefetch => 1),
    };

    my $search = $self->record_later_search(prefetch => 1, sort => 1, linked => 1);
    $search->{'me.id'} = \@cids;
    $search->{'record_single.created'} = { '<' => $self->rewind_formatted }
        if $self->rewind;
    my $result = $self->schema->resultset('Current')->search($search, $select);

    $result->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my $column_flags = {
        map {
            $_->id => $_->flags
        } grep {
            %{$_->flags}
        } @{$self->columns_retrieved_no}
    };

    my @all; my @record_ids;
    foreach my $rec ($result->all)
    {
        my @children = map { $_->{id} } @{$rec->{currents}};
        push @all, GADS::Record->new(
            schema               => $self->schema,
            record               => $rec->{record_single},
            linked_record_raw    => $rec->{linked}->{record_single},
            child_records        => \@children,
            parent_id            => $rec->{parent_id},
            linked_id            => $rec->{linked_id},
            user                 => $self->user,
            layout               => $self->layout,
            columns_retrieved_no => $self->columns_retrieved_no,
            columns_retrieved_do => $self->columns_retrieved_do,
            column_flags         => $column_flags,
        );
        push @record_ids, $rec->{record_single}->{id};
        push @record_ids, $rec->{linked}->{record_single}->{id}
            if $rec->{linked}->{record_single};
    }

    # Fetch and add multi-values
    my $multi = $self->fetch_multivalues([@record_ids]);
    foreach my $row (@all)
    {
        my $record    = $row->record;
        my $record_id = $record->{id};
        $record->{$_} = $multi->{$record_id}->{$_} foreach keys %{$multi->{$record_id}};
        if ($row->linked_record_raw)
        {
            my $record_linked = $row->linked_record_raw;
            my $record_id_linked = $record_linked->{id};
            $record_linked->{$_} = $multi->{$record_id_linked}->{$_} foreach keys %{$multi->{$record_id_linked}};
        }
    };

    \@all;
}

sub fetch_multivalues
{   my ($self, $record_ids) = @_;

    my $return; # Return undef if no multivalues
    my $cols_done = {};
    foreach my $column (@{$self->columns_retrieved_no})
    {
        my @cols = ($column);
        push @cols, $column->link_parent if $column->link_parent;
        foreach my $col (@cols)
        {
            next unless $col->multivalue;
            next if $cols_done->{$col->id};
            foreach my $val ($col->fetch_multivalues($record_ids))
            {
                my $field = "field$val->{layout_id}";
                $return->{$val->{record_id}}->{$field} ||= [];
                push @{$return->{$val->{record_id}}->{$field}}, $val;
                $cols_done->{$val->{layout_id}} = 1;
            }
        }
    }
    $return;
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

    my $search_query = $self->search_query(search => 1, linked => 1);
    my @joins        = $self->jpfetch(search => 1, linked => 0);
    my @linked       = $self->linked_hash(search => 1, linked => 1);
    local $GADS::Schema::Result::Record::REWIND = $self->rewind_formatted
        if $self->rewind;
    my $select = {
        join     => [
            {
                'record_single' => [
                    'record_later',
                    @joins
                ],
            },
            [@linked],
        ],
        distinct => 1, # Otherwise multiple records returned for multivalue fields
    };

    $self->schema->resultset('Current')->search(
        [-and => $search_query], $select
    )->count;
}

sub _build_has_children
{   my $self = shift;

    my @search_query = @{$self->search_query(search => 1, linked => 1)};
    my $linked = $self->linked_hash(search => 1);
    my $select = {
        join     => [
            {
                'record_single' => [
                    'record_later',
                    $self->jpfetch(search => 1),
                ],
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
        @columns = grep { $_->id; exists $col_ids{$_->id} } $layout->all(order_dependencies => 1);
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
    $self->clear_view_limits;
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
                    value    => $self->schema->storage->datetime_parser->format_date($to),
                };
                push @f, $f;
            }
            if (my $from = $self->from)
            {
                my $f = {
                    id       => $c->id,
                    operator => 'greater_or_equal',
                    value    => $self->schema->storage->datetime_parser->format_date($from),
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


        # Now add all the filters as joins (we don't need to prefetch this data). However,
        # the filter might also be a column in the view from before, in which case add
        # it to, or use, the prefetch. We use the tracking variables from above.
        if (my $view = $self->view)
        {
            # Apply view filter, but not if specific current IDs set (as when quick search is used)
            if ($view->filter && !$self->current_ids)
            {
                my $decoded = $view->filter->as_hash;
                if (keys %$decoded)
                {
                    # Get the user search criteria
                    @search = @{$self->_search_construct($decoded, $layout, %options)};
                }
            }
        }
        push @search, $self->view_limits_search(%options);
        # Finish by calling order_by. This may add joins of its own, so it
        # ensures that any are added correctly.
        $self->order_by;
    }

    (@limit, @search);
}

sub _build__sorts
{   my $self = shift;
    my @sorts;
    if (my $user_sort = $self->sort)
    {
        foreach my $s (@$user_sort)
        {
            push @sorts, {
                id   => $s->{id} || -11, # Default ID
                type => $s->{type} || 'asc',
            } if $self->layout->column($s->{id});
        }
    }
    if (!@sorts && $self->view && @{$self->view->sorts}) {
        foreach my $sort (@{$self->view->sorts})
        {
            push @sorts, {
                id   => $sort->{layout_id} || -11, # View column is undef for ID
                type => $sort->{type} || 'asc',
            };
        }
    }
    if (!@sorts && $self->default_sort)
    {
        push @sorts, {
            id   => $self->default_sort->{id} || -11,
            type => $self->default_sort->{type} || 'asc',
        } if $self->layout->column($self->default_sort->{id});
    }
    unless (@sorts) {
        push @sorts, {
            id   => -11,
            type => 'asc',
        }
    };
    \@sorts;
}

sub order_by
{   my ($self, %options) = @_;

    $self->_plus_select([]);
    my @sorts = @{$self->_sorts};

    my @order_by;
    foreach my $s (@sorts)
    {
        my $type   = "-$s->{type}";
        my $column = $self->layout->column($s->{id});
        my @cols_main = $column->sort_columns;
        my @cols_link = $column->link_parent ? $column->link_parent->sort_columns : ();
        foreach my $col_sort (@cols_main)
        {
            $self->add_join($column->sort_parent, sort => 1)
                if $column->sort_parent;
            $self->add_join($col_sort, sort => 1, parent => $column->sort_parent)
                unless $column->internal;
            my $s_table = $self->table_name($col_sort, sort => 1, %options, parent => $column->sort_parent);
            my $sort_name;
            if ($column->link_parent) # Original column, not the sub-column ($col_sort)
            {
                my $col_link = shift @cols_link;
                $self->add_join($col_link, sort => 1);
                my $main = "$s_table.".$column->value_field;
                my $link = $self->table_name($col_link, sort => 1, linked => 1, %options).".".$col_link->value_field;
                $sort_name = $self->schema->resultset('Current')->helper_concat(
                     { -ident => $main },
                     { -ident => $link },
                );
            }
            else {
                $sort_name = "$s_table.".$col_sort->value_field;
            }
            push @order_by, {
                $type => $sort_name,
            };
        }
    }

    \@order_by;
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
    my ($parent_column, $column);
    if ($filter->{id} =~ /^([0-9]+)_([0-9]+)$/)
    {
        $column        = $layout->column($2, %permission);
        $parent_column = $layout->column($1, %permission);
    }
    else {
        $column   = $layout->column($filter->{id}, %permission);
    }
    $column
        or return;
    # If testing a comparison but we have no value, then assume search empty/not empty
    # (used during filters on curval against current record values)
    $filter->{operator} = $filter->{operator} eq 'not_equal' ? 'is_not_empty' : 'is_empty'
        if $filter->{operator} !~ /(is_empty|is_not_empty)/ && !$filter->{value};
    my $operator = $ops{$filter->{operator}}
        or error __x"Invalid operator {filter}", filter => $filter->{operator};

    my @conditions;
    my $transform_date; # Whether to convert date value to database format
    if ($column->type eq "daterange")
    {
        # If it's a daterange, we have to be intelligent about the way the
        # search is constructed. Greater than, less than, equals all require
        # different values of the date range to be searched
        if ($operator eq "!=" || $operator eq "=") # Only used for empty / not empty
        {
            push @conditions, {
                type     => $filter->{operator},
                operator => $operator,
                s_field  => "value",
            };
        }
        elsif ($operator eq ">" || $operator eq "<=")
        {
            $transform_date = 1;
            push @conditions, {
                type     => $filter->{operator},
                operator => $operator,
                s_field  => "from",
            };
        }
        elsif ($operator eq ">=" || $operator eq "<")
        {
            $transform_date = 1;
            push @conditions, {
                type     => $filter->{operator},
                operator => $operator,
                s_field  => "to",
            };
        }
        elsif ($operator eq "-like")
        {
            $transform_date = 1;
            # Requires 2 searches ANDed together
            push @conditions, {
                type     => $filter->{operator},
                operator => "<=",
                s_field  => "from",
            };
            push @conditions, {
                type     => $filter->{operator},
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
            type     => $filter->{operator},
            operator => $operator,
            s_field  => $filter->{value_field} || $column->value_field,
        };
    }

    my $vprefix = $operator eq '-like' ? '' : '';
    my $vsuffix = $operator eq '-like' ? '%' : '';

    my @values;

    if ($filter->{operator} eq 'is_empty' || $filter->{operator} eq 'is_not_empty')
    {
        push @values, $column->string_storage ? (undef, "") : undef;
    }
    else {
        my @original_values = ref $filter->{value} ? @{$filter->{value}} : ($filter->{value});
        foreach (@original_values)
        {
            $_ = $vprefix.$_.$vsuffix;

            # This shouldn't normally happen, but sometimes we can end up with an
            # invalid search value, such as if the date format has changed and the
            # filters still have the old format. In this case, match nothing rather
            # than matching all or borking.
            return ( \"0 = 1" ) if !$column->validate_search($_);

            # Sub-in current date as required. Ideally we would use the same
            # code here as the calc/rag fields, but this can be accessed by
            # any user, so should be a lot tighter.
            if ($_ && $_ =~ /CURDATE/)
            {
                my $vdt = GADS::View->parse_date_filter($_);
                my $dtf = $self->schema->storage->datetime_parser;
                $_ = $dtf->format_date($vdt);
            }
            elsif ($transform_date || ($column->return_type eq 'date' && $_))
            {
                $_ = $self->_date_for_db($column, $_);
            }

            $_ =~ s/\_/\\\_/g if $operator eq '-like';

            if ($_ && $_ =~ /\[CURUSER\]/)
            {
                if ($column->type eq "person")
                {
                    my $curuser = ($options{user} && $options{user}->id) || ($self->user && $self->user->{id})
                        or warning "FIXME: user not set for person filter";
                    $curuser ||= "";
                    $_ =~ s/\[CURUSER\]/$curuser/g;
                    $conditions[0]->{s_field} = "id";
                }
                elsif ($column->return_type eq "string")
                {
                    my $curuser = ($options{user} && $options{user}->value) || ($self->user && $self->user->{value})
                        or warning "FIXME: user not set for string filter";
                    $curuser ||= "";
                    $_ =~ s/\[CURUSER\]/$curuser/g;
                }
            }
            push @values, $_;
        }
    }

    @values or return ( \"0 = 1" ); # Nothing to match, return nothing

    if ($column->type eq "string")
    {
        # The normal value search of a string is not indexed, due to the potential size
        # of the data. Therefore, add the second indexed value field, to speed up
        # the search.
        # $value can be an array ref from above.
        push @conditions, {
            type     => $filter->{operator},
            operator => $operator,
            s_field  => "value_index",
            values   => [ map { $_ && lc(substr($_, 0, 128)) } @values ],
        };
    }

    my @final = map {
        $self->_resolve($column, $_, \@values, 0, parent => $parent_column, %options);
    } @conditions;
    @final = ('-and' => [@final]);
    my $parent_column_link = $parent_column && $parent_column->link_parent;;
    if ($parent_column_link || $column->link_parent)
    {
        my $link_parent;
        if ($parent_column)
        {
            $link_parent = $column;
        }
        else {
            $link_parent = $column->link_parent;
        }
        my @final2 = map {
            $self->_resolve($link_parent, $_, \@values, 1, parent => $parent_column_link, %options);
        } @conditions;
        @final2 = ('-and' => [@final2]);
        @final = (['-or' => [@final], [@final2]]);
    }
    return @final;
}

sub _resolve
{   my ($self, $column, $condition, $default_value, $is_linked, %options) = @_;

    my $value = $condition->{values} || $default_value;

    # If the column is a multivalue, then normally a not_equal would match
    # even if we're not expecting it to (if the record's value contains
    # "foo" and "bar", then a search for "not foo" would still return the
    # "bar" and hence the whole record including "foo".  We therefore have
    # to instead negate the record IDs containing that negative match.
    if ($column->multivalue && $condition->{type} eq 'not_equal')
    {
        $value    = @$value > 1 ? [ '-or' => @$value ] : $value->[0];
        my $subjoin = $column->subjoin;
        my $table   = $subjoin || $column->field;
        +(
            'me.id' => {
                -not_in => correlate( $self->schema->resultset('Current'), "record_single" )->search_related(
                    $column->field, {
                        "$table.$_->{s_field}" => $value,
                    },
                    {
                        select => "record_later.current_id",
                        join   => $column->subjoin,
                    }
                )->as_query
            }
        );
    }
    else {
        my $combiner = $condition->{type} =~ /(is_not_empty|not_equal)/ ? '-and' : '-or';
        $value    = @$value > 1 ? [ $combiner => @$value ] : $value->[0];
        $self->add_join($options{parent}, search => 1, linked => $is_linked)
            if $options{parent};
        $self->add_join($column, search => 1, linked => $is_linked, parent => $options{parent})
            unless $column->internal;
        my $s_table = $self->table_name($column, %options, search => 1);
        my $sq = {$condition->{operator} => $value};
        $sq = [ $sq, undef ] if $condition->{type} eq 'not_equal';
        +( "$s_table.$_->{s_field}" => $sq );
    }
}

sub _date_for_db
{   my ($self, $column, $value) = @_;
    my $dt = $column->parse_date($value);
    $self->schema->storage->datetime_parser->format_date($dt);
}

sub csv
{   my $self = shift;
    my $csv  = Text::CSV::Encoded->new({ encoding  => undef });

    # Column names
    my @columns = $self->view
        ? $self->layout->view($self->view->id, user_can_read => 1)
        : $self->layout->all(user_can_read => 1);
    my @colnames = ("ID");
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
    my ($multiple_dates, $min, $max);
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
                    my $count;
                    foreach my $range (@{$d->values})
                    {
                        # It's possible that values from other columns not within
                        # the required range will have been retrieved. Don't bother
                        # adding them
                        if (
                            (!$self->to || DateTime->compare($self->to, $range->start) >= 0)
                            && (!$self->from || DateTime->compare($range->end, $self->from) >= 0)
                        ) {
                            push @dates, {
                                from      => $range->start,
                                to        => $range->end,
                                color     => $color,
                                column    => $column->id,
                                count     => ++$count,
                                daterange => 1,
                            };
                            $min = $range->start->clone if !defined $min || $range->start < $min;
                            $max = $range->end->clone if !defined $max || $range->end > $max;
                        }
                    }
                }
                else {
                    $d->value or next;
                    if (
                        (!$self->from || DateTime->compare($d->value, $self->from) >= 0)
                        && (!$self->to || DateTime->compare($self->to, $d->value) >= 0)
                    ) {
                        push @dates, {
                            from  => $d->value,
                            to    => $d->value,
                            color => $color,
                            column=> $column->id,
                            count => 1,
                        };
                        $min = $d->value->clone if !defined $min || $d->value < $min;
                        $max = $d->value->clone if !defined $max || $d->value > $max;
                    }
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
                    "id"      => "$cid+$d->{column}+$d->{count}",
                    current_id => $cid,
                    "start"   => $d->{from}->ymd,
                    "group"   => $item_group,
                    column    => $d->{column},
                    title     => $title_i,
                };
                $item->{style} = qq(background-color: $item_color)
                    if $item_color;
                # Add one day, otherwise ends at 00:00:00, looking like day is not included
                $item->{end} = $d->{to}->clone->add( days => 1 )->ymd if $d->{daterange};
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

    +{
        items  => \@result,
        groups => \@groups,
        min    => $min && $min->subtract(days => 1),
        max    => $max && $max->add(days => 2), # one day already added to show period to end of day
    };
}

sub data_calendar
{   my $self = shift;
    $self->data_time('calendar')->{items};
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

