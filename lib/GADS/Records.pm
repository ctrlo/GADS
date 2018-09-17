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
use GADS::Config;
use GADS::Graph::Data;
use GADS::Record;
use GADS::Timeline;
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
    my $count = $self->search_limit_reached || $self->count;
    $self->rows ? ceil($count / $self->rows) : 1;
}

has search => (
    is  => 'rw',
    isa => Maybe[Str],
);

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
                push @search, $self->_search_construct($decoded, $self->layout, %options);
            }
        }
    }
    [ '-or' => \@search ];
}

has from => (
    is     => 'rw',
    coerce => sub {
        my $value = shift
            or return;
        $value->truncate(to => 'day');
        return $value;
    },
);

has to => (
    is     => 'rw',
    coerce => sub {
        my $value = shift
            or return;
        return $value if $value->hms('') eq '000000';
        $value->truncate(to => 'day')->add(days => 1);
        return $value;
    },
);

sub limit_qty
{   my $self = shift;
    return unless ($self->from xor $self->to);
    return 'from' if $self->from;
    return 'to' if $self->to;
}

has exclusive => (
    is => 'rw',
);

sub exclusive_of_from {
    my $ex = $_[0]->exclusive || '';
    $ex eq 'from';
}

sub exclusive_of_to {
    my $ex = $_[0]->exclusive || '';
    $ex eq 'to';
}

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

# Whether to retrieve all columns for this set of records. Needed when going to
# be writing to the records, to ensure that calc fields are retrieved to
# subsequently write to
has retrieve_all_columns => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
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

has max_results => (
    is => 'rw',
);

has rows => (
    is => 'rw',
);

has count => (
    is      => 'lazy',
    isa     => Int,
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

# Internal parameter to set the exact current IDs that will be retrieved,
# without running any search queries. Used when downloading chunked data, when
# all the current IDs have already been retrieved
has _set_current_ids => (
    is  => 'rw',
    isa => Maybe[ArrayRef],
);

# A parameter that can be used externally to restrict to a set of current IDs.
# This will also have the search parameters applied, which could include
# limited views for the user (unlike the above internal parameter)
has limit_current_ids => (
    is  => 'rw',
    isa => Maybe[ArrayRef],
);

# Current ID results, or limit to specific current IDs
has current_ids => (
    is        => 'lazy',
    isa       => Maybe[ArrayRef], # If undef will be ignored
    clearer   => 1,
    predicate => 1,
);

sub _build_current_ids
{   my $self = shift;
    local $GADS::Schema::Result::Record::REWIND = $self->rewind_formatted
        if $self->rewind;
    $self->_set_current_ids || [$self->_current_ids_rs->all];
}

# Produce the overall search condition array
sub search_query
{   my ($self, %options) = @_;
    # Only used by common_search(). Will pull wrong query_params
    # if left in %options
    my $linked        = delete $options{linked};
    my @search        = $self->_query_params(%options);
    my $root_table    = $options{root_table} || 'current';
    my $current       = $root_table eq 'current' ? 'me' : 'current';
    my $record_single = $self->record_name(%options);
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
            { "$record_single.approval" => 0 },
        ) if $approval_exists;
    }
    # Current IDs from quick search if used
    push @search, { "$current.id"          => $self->_search_all_fields->{cids} } if $self->search;
    push @search, { "$current.id"          => $self->limit_current_ids } if $self->limit_current_ids; # $self->has_current_ids && $self->current_ids;
    push @search, { "$current.instance_id" => $self->layout->instance_id };
    push @search, $self->common_search(%options, linked => $linked);
    push @search, {
        "$record_single.created" => { '<' => $self->rewind_formatted },
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
    is        => 'lazy',
    isa       => ArrayRef,
    clearer   => 1,
    predicate => 1,
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
                    $self->_search_construct($decoded, $self->layout, ignore_perms => 1, user => $user),
                };
                $search = { %$search, %$_ }
                    foreach $self->common_search;
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

has _search_all_fields => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

sub _build__search_all_fields
{   my $self = shift;

    my $search = $self->search
        or return {};

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

        my $joins       = $field->{type} eq 'current_id' # Include joins for limited views
                        ? {
                              'record_single' => [
                                  'record_later',
                                  $self->jpfetch(search => 1),
                              ]
                          }
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
            ? { 'me.id' => $search_local }
            : $field->{index_field} # string with additional index field
            ? ( { $field->{index_field} => $search_index }, { $s => $search_local } )
            : { $s => $search_local };
        if ($field->{type} eq 'current_id')
        {
            push @search, { 'me.instance_id' => $self->layout->instance_id };
        }
        else {
            push @search, { 'layout.id' => \@columns_can_view };
            push @search, $self->common_search(search => 1);
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

    # Limit to maximum of 500 results, otherwise the stack limit is exceeded
    my @cids = keys %found;
    my $count = @cids;
    my $limit;
    if ($count > 500)
    {
        @cids  = @cids[0 .. 499];
        $limit = 500;
    }

    +{
        cids          => \@cids,
        count         => $count,
        limit_reached => $limit,
    };
}

has search_limit_reached => (
    is  => 'lazy',
    isa => Maybe[Int],
);

sub _build_search_limit_reached
{   my $self = shift;
    $self->_search_all_fields->{limit_reached};
}

has is_group => (
    is  => 'lazy',
    isa => Bool,
);

sub _build_is_group
{   shift->isa('GADS::RecordsGroup');
}

# Produce a standard set of results without grouping
sub _current_ids_rs
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
            [$self->linked_hash(search => 1, sort => 1)],
            {
                'record_single' => [ # The (assumed) single record for the required version of current
                    'record_later',  # The record after the single record (undef when single is latest)
                    $self->jpfetch(search => 1, sort => 1, linked => 0),
                ],
            },
        ],
        '+select' => $self->_plus_select, # Used for additional sort columns
        order_by  => $self->order_by(search => 1, with_min => 'group'),
        distinct  => 1, # Otherwise multiple records returned for multivalue fields
    };
    my $page = $self->page;
    $page = $self->pages
        if $page && $page > 1 && $page > $self->pages; # Building page count is expensive, avoid if not needed

    $select->{rows} = $self->rows if $self->rows;
    $select->{page} = $page if $page;

    # Get the current IDs
    # Only take the latest record_single (no later ones)
    $self->schema->resultset('Current')->search(
        [-and => $search_query], $select
    )->get_column('me.id');
}

# Produce a search query that filters by all the required current IDs. This
# needs to include the list of current IDs itself, plus a filter to ensure only
# the required version of a record is retrieved. Assumes that REWIND has
# already been set by the calling function.
sub _cid_search_query
{   my $self = shift;
    my $search = { map { %$_ } $self->common_search(prefetch => 1, sort => 1, linked => 1) };

    # If this is a group query then we will not be limiting by number of
    # records (but will be reducing number of results by group), and therefore
    # it's best to pass the current IDs required as a SQL query (otherwise we
    # could be passing in 1000s of ID values). If we're doing the opposite,
    # then we would be creating some very big queries with the sub-query, and
    # therefore performance (Pg at least) has been shown to be better if we run
    # the ID subquery first and only pass the IDs in to the main query
    if ($self->is_group)
    {
        $search->{'me.id'} = { -in => $self->_current_ids_rs->as_query };
    }
    else {
        $search->{'me.id'} = $self->current_ids;
    }

    my $record_single = $self->record_name(linked => 0);
    $search->{"$record_single.created"} = { '<' => $self->rewind_formatted }
        if $self->rewind;
    $search;
}

sub _build_results
{   my $self = shift;
    local $GADS::Schema::Result::Record::REWIND = $self->rewind_formatted
        if $self->rewind;

    my $search_query = $self->search_query(search => 1, sort => 1, linked => 1); # Need to call first to build joins

    my @prefetches = $self->jpfetch(prefetch => 1, linked => 0);
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
    my @linked_prefetch = $self->linked_hash(prefetch => 1);

    my $select = {
        prefetch => [
            [@linked_prefetch],
            $rec1,
        ],
        join     => [
            [$self->linked_hash(sort => 1)],
            $rec2,
        ],
        '+select' => $self->_plus_select, # Used for additional sort columns
        '+columns' => {
            record_created => $self->schema->resultset('Current')
              ->correlate('records')
              ->get_column('created')
              ->min_rs->as_query,
        },
        order_by  => $self->order_by(prefetch => 1, with_min => 'each'),
    };

    my $result = $self->schema->resultset('Current')->search($self->_cid_search_query, $select);

    $result->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my $column_flags = {
        map {
            $_->id => $_->flags
        } grep {
            %{$_->flags}
        } @{$self->columns_retrieved_no}
    };

    my @all; my @record_ids;
    my @retrieved = $result->all;
    foreach my $rec (@retrieved)
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
            record_created       => $rec->{record_created},
        );
        push @record_ids, $rec->{record_single}->{id};
        push @record_ids, $rec->{linked}->{record_single}->{id}
            if $rec->{linked}->{record_single};
    }

    # Fetch and add multi-values
    $self->fetch_multivalues(
        record_ids => \@record_ids,
        retrieved  => \@retrieved,
        records    => \@all,
    );

    \@all;
}

sub fetch_multivalues
{   my ($self, %params) = @_;

    my $record_ids    = $params{record_ids};
    my $retrieved     = $params{retrieved};
    my $records       = $params{records};
    my %curval_fields;

    my %multi; # Stash of all the multivalues to fetch and insert
    my $cols_done = {};
    foreach my $column (@{$self->columns_retrieved_no})
    {
        my @cols = ($column);
        push @cols, $column->link_parent if $column->link_parent;
        if ($column->type eq 'curval')
        {
            push @cols, @{$column->curval_fields_multivalue};
            # Flag any curval multivalue fields as also requiring fetching
            $curval_fields{$_->field} = $column->field
                foreach @{$column->curval_fields_multivalue};
        }
        foreach my $col (@cols)
        {
            next unless $col->multivalue;
            next if $cols_done->{$col->id};
            my @rids; # Used for the record IDs of the curval field values (different to main record IDs)
            if (my $field = $curval_fields{$col->field})
            {
                foreach my $rec (@$retrieved)
                {
#                    next if !$rec->{record_single};
                    foreach (@{$rec->{record_single}->{$field}})
                    {
                        push @rids, $_->{value}->{record_single}->{id}
                            if $_->{value};
                    }
                }
            }
            # Fetch the multivalues for either the main record IDs or the
            # records within the curval values. Then pass all back to the
            # calling function
            foreach my $val ($col->fetch_multivalues((@rids && \@rids) || $record_ids))
            {
                my $field = "field$val->{layout_id}";
                $multi{$val->{record_id}}->{$field} ||= [];
                push @{$multi{$val->{record_id}}->{$field}}, $val;
                $cols_done->{$val->{layout_id}} = 1;
            }
        }
    }

    foreach my $row (@$records)
    {
        my $record    = $row->record;
        my $record_id = $record->{id};
        # %multi is set with each record ID and then its multi-value
        # fields within it. Sub-fields that are multivalue within curval fields
        # are also fetched, but stored with the ID of the record of the
        # curval value rather than the record from this retrieval.
        # First normal values:
        foreach my $field (keys %{$multi{$record_id}})
        {
            $record->{$field} = $multi{$record_id}->{$field};
        }
        # Then the curval sub-fields
        foreach my $curval_subfield (keys %curval_fields)
        {
            my $curval_field = $curval_fields{$curval_subfield};
            foreach my $subrecord (@{$record->{$curval_field}}) # Foreach whole curval value
            {
                my $sub_record2 = $subrecord->{value}->{record_single}
                    or next; # blank curval value, no need to populate subfields
                $sub_record2->{$curval_subfield} = $multi{$sub_record2->{id}}->{$curval_subfield};
            }
        }
        if ($row->linked_record_raw)
        {
            my $record_linked = $row->linked_record_raw;
            my $record_id_linked = $record_linked->{id};
            $record_linked->{$_} = $multi{$record_id_linked}->{$_} foreach keys %{$multi{$record_id_linked}};
        }
    };
}

# Store for all the current IDs when retrieving rows in chunks. Storing them
# all now ensures consistency when retrieving all rows, as otherwise as rows
# are edited different chunks will be retrieved
has _all_cids_store => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _build__all_cids_store
{   my $self = shift;
    $self->current_ids;
}

# Which internal page we are on for retrieving sets of rows. This is not the
# same as page(), which directly affects the page of the database row retrieval
has _single_page => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

has _next_single_id => (
    is      => 'rwp',
    isa     => Maybe[Int],
    default => 0,
);

# This could be called thousands of times (e.g. download), so fetch
# the rows in chunks
my $chunk = 100;
sub single
{   my $self = shift;

    my $next_id = $self->_next_single_id;

    # Check return if limiting to a set number of results
    return if $self->max_results && $self->records_retrieved_count >= $self->max_results;
    # Check if we've returned all resulsts available
    return if $self->records_retrieved_count >= @{$self->_all_cids_store};

    if (!$self->is_group) # Don't retrieve in chunks for group records
    {
        if (
            ($next_id == 0 && $self->_single_page == 0) # First run
            || $next_id >= $chunk # retrieved all of current chunk
        )
        {
            $self->_single_page($self->_single_page + 1) # increase to next page
                unless $next_id == 0; # unless first run, already on first page

            # Work out chunk to retrieve from all current IDs
            my $start     = $chunk * $self->_single_page;
            my $end       = $start + $chunk - 1;
            my $cid_fetch = [ @{$self->_all_cids_store}[$start..$end] ];

            # Set those IDs for the next chunk retrieved from the DB
            $self->_set_current_ids($cid_fetch);
            $self->clear_current_ids;
            $self->clear_results;

            $next_id = 0;
        }
    }

    my $row = $self->results->[$next_id];
    $self->_set__next_single_id($next_id + 1);
    $row;
}

# The total number of records retrieved from this entire result set, regardless
# of chunks
sub records_retrieved_count
{   my $self = shift;
    return $self->_single_page * $chunk + $self->_next_single_id;
}

sub _build_count
{   my $self = shift;

    return $self->_search_all_fields->{count} if $self->search;

    my $search_query = $self->search_query(search => 1, linked => 1);
    my @joins        = $self->jpfetch(search => 1, linked => 0);
    my @linked       = $self->linked_hash(search => 1, linked => 1);
    local $GADS::Schema::Result::Record::REWIND = $self->rewind_formatted
        if $self->rewind;
    my $select = {
        join     => [
            [@linked],
            {
                'record_single' => [
                    'record_later',
                    @joins
                ],
            },
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
            $linked,
            {
                'record_single' => [
                    'record_later',
                    $self->jpfetch(search => 1),
                ],
            },
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
    elsif (!$self->retrieve_all_columns && $self->view)
    {
        @columns = $layout->view(
            $self->view->id,
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
    $self->clear_current_ids;
    $self->_clear_search_all_fields;
    $self->clear_results;
    $self->_set__next_single_id(0);
    $self->_set_current_ids(undef);
    $self->_clear_all_cids_store;
}

# Construct various parameters used for the query. These are all
# related, so it makes sense to construct them together.
sub _query_params
{   my ($self, %options) = @_;

    my $layout = $self->layout;

    my @search_date;                    # The search criteria to narrow-down by date range
    foreach my $c (@{$self->columns_retrieved_no})
    {
        if ($c->return_type =~ /date/)
        {
            my $dateformat = GADS::Config->instance->dateformat;
            # Apply any date filters if required
            my @f;
            if (my $to = $self->to)
            {
                my $f = {
                    id       => $c->id,
                    operator => $self->exclusive_of_to ? 'less' : 'less_or_equal',
                    value    => $to->format_cldr($dateformat),
                };
                push @f, $f;
            }
            if (my $from = $self->from)
            {
                my $f = {
                    id       => $c->id,
                    operator => $self->exclusive_of_from ? 'greater' : 'greater_or_equal',
                    value    => $from->format_cldr($dateformat),
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
        @search = (); # Reset from first loop
        # Add any date ranges to the search from above
        if (@search_date)
        {
            my @res = ($self->_search_construct({condition => 'OR', rules => \@search_date}, $layout));
            push @limit, @res if @res;
        }


        # Now add all the filters as joins (we don't need to prefetch this data). However,
        # the filter might also be a column in the view from before, in which case add
        # it to, or use, the prefetch. We use the tracking variables from above.
        if (my $view = $self->view)
        {
            # Apply view filter, but not if quick search has been used
            if ($view->filter && !$self->search)
            {
                my $decoded = $view->filter->as_hash;
                if (keys %$decoded)
                {
                    # Get the user search criteria
                    @search = $self->_search_construct($decoded, $layout, %options);
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

    # First, special test where we are retrieving from a date for a number of
    # records until an unknown date. In this case, order by all the date
    # fields.
    if (my $type = $self->limit_qty)
    {
        foreach my $col (@{$self->columns_retrieved_no})
        {
            next unless $col->return_type =~ /date/;
            push @sorts, {
                id   => $col->id,
                type => $type eq 'from' ? 'asc' : 'desc',
            };
        }
        return [] if !@sorts;
    }
    if (!@sorts && $self->sort)
    {
        foreach my $s (@{$self->sort})
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
                my $main = "$s_table.".$column->sort_field;
                my $link = $self->table_name($col_link, sort => 1, linked => 1, %options).".".$col_link->sort_field;
                $sort_name = $self->schema->resultset('Current')->helper_concat(
                     { -ident => $main },
                     { -ident => $link },
                );
            }
            else {
                $sort_name = "$s_table.".$col_sort->sort_field;
            }
            push @order_by, {
                $type => $sort_name,
            };
        }
    }

    # That special condition again, retrieving a number of records from a
    # certain date. We have to order by the date of any field in each record.
    if ($self->limit_qty && $options{with_min} && @order_by)
    {
        my $date = $self->schema->storage->datetime_parser->format_datetime($self->from || $self->to);
        @order_by = map {
            my ($field) = values %$_;
            my $quoted = $self->quote($field);
            if ($field =~ /from/) # Date range
            {
                (my $to = $field) =~ s/from/to/;
                my $quoted_to = $self->quote($to);
                # For a date range, take either the "from" or the "to" value,
                # whichever is just past the start date of our range
                if ($self->limit_qty eq 'from')
                {
                    \"CASE
                        WHEN ($quoted > '$date') THEN $quoted
                        WHEN ($quoted_to > '$date') THEN $quoted_to
                        ELSE NULL END";
                }
                else { # to
                    \"CASE
                        WHEN ($quoted_to < '$date') THEN $quoted_to
                        WHEN ($quoted < '$date') THEN $quoted
                        ELSE NULL END";
                }
            }
            else {
                if ($self->limit_qty eq 'from')
                {
                    \"CASE
                        WHEN ($quoted > '$date') THEN $quoted
                        ELSE NULL END";
                }
                else {
                    \"CASE
                        WHEN ($quoted < '$date') THEN $quoted
                        ELSE NULL END";
                }
            }
        } @order_by;

        if ($options{with_min} eq 'group')
        {
            # When we have a group_by, we need an additional aggregate function
            my $func = $self->limit_qty eq 'from' ? 'min' : 'max';
            @order_by = map { +{ $func => { -ident => $_ } } } @order_by;
        }
        elsif ($options{with_min} eq 'each') {
            @order_by = map { +{ -ident => $_ } } @order_by;
        }
        else {
            panic "Invalid with_min option";
        }
        if ($self->limit_qty eq 'from')
        {
            return +{ -asc => $self->schema->resultset('Current')->helper_least(@order_by) };
        }
        else {
            return +{ -desc => $self->schema->resultset('Current')->helper_greatest(@order_by) };
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
        return @final ? ($condition => \@final) : ();
    }

    my %ops = (
        equal            => '=',
        greater          => '>',
        greater_or_equal => '>=',
        less             => '<',
        less_or_equal    => '<=',
        contains         => '-like',
        begins_with      => '-like',
        not_begins_with  => '-not_like',
        not_equal        => '!=',
        is_empty         => '=',
        is_not_empty     => '!=',
    );

    my %permission = $ignore_perms ? () : (permission => 'read');
    my ($parent_column, $column);
    $filter->{id} or return; # Used to ignore filter
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

    # Empty values can sometimes arrive as empty arrays, which evaluate true
    # when they should evaluate false. Therefore convert.
    $filter->{value} = '' if ref $filter->{value} eq 'ARRAY' && !@{$filter->{value}};

    # If testing a comparison but we have no value, then assume search empty/not empty
    # (used during filters on curval against current record values)
    $filter->{operator} = $filter->{operator} eq 'not_equal' ? 'is_not_empty' : 'is_empty'
        if $filter->{operator} !~ /(is_empty|is_not_empty)/
            && (!defined $filter->{value} || $filter->{value} eq ''); # Not zeros (valid search)
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

    my $vprefix = $operator eq '-like' || $operator eq '-not_like' ? '' : '';
    my $vsuffix = $operator eq '-like' || $operator eq '-not_like' ? '%' : '';

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
        $self->_resolve($column, $_, \@values, 0, parent => $parent_column, filter => $filter, %options);
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
            $self->_resolve($link_parent, $_, \@values, 1, parent => $parent_column_link, filter => $filter, %options);
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
    my $multivalue = $options{parent} ? $options{parent}->multivalue : $column->multivalue;
    if ($multivalue && $condition->{type} eq 'not_equal')
    {
        # Create a non-negative match of all the IDs that we don't want to
        # match. Use a Records object so that all the normal requirements are
        # dealt with, and pass it the current filter reversed
        my $records = GADS::Records->new(
            schema      => $self->schema,
            user        => $self->user,
            layout      => $self->layout,
            view_limits => [], # Don't limit by view this as well, otherwise recursive loop happens
            view  => GADS::View->new(
                filter      => { %{$options{filter}}, operator => 'equal' }, # Switch
                instance_id => $self->layout->instance_id,
                layout      => $self->layout,
                schema      => $self->schema,
                user        => $self->user,
            ),
        );
        return (
            'me.id' => {
                # We want everything that is *not* those records
                -not_in => $records->_current_ids_rs->as_query,
            }
        );
    }
    else {
        my $combiner = $condition->{type} =~ /(is_not_empty|not_equal|not_begins_with)/ ? '-and' : '-or';
        $value    = @$value > 1 ? [ $combiner => @$value ] : $value->[0];
        $self->add_join($options{parent}, search => 1, linked => $is_linked)
            if $options{parent};
        $self->add_join($column, search => 1, linked => $is_linked, parent => $options{parent})
            unless $column->internal;
        my $s_table = $self->table_name($column, %options, search => 1);
        my $sq = {$condition->{operator} => $value};
        $sq = [ $sq, undef ] if $condition->{type} eq 'not_equal' || $condition->{type} eq 'not_begins_with';
        +( "$s_table.$_->{s_field}" => $sq );
    }
}

sub _date_for_db
{   my ($self, $column, $value) = @_;
    my $dt = $column->parse_date($value);
    $self->schema->storage->datetime_parser->format_date($dt);
}

has _csv => (
    is => 'lazy',
);

sub _build__csv { Text::CSV::Encoded->new({ encoding  => undef }) }

sub csv_header
{   my $self = shift;

    my @columns = @{$self->columns_retrieved_no};
    my @colnames = ("ID");
    push @colnames, "Parent" if $self->has_children;
    push @colnames, map { $_->name } @columns;
    my $csv = $self->_csv;
    $csv->combine(@colnames)
        or error __x"An error occurred producing the CSV headings: {err}", err => $csv->error_input;
    # See if a header is defined and prepend that
    my $config = GADS::Config->instance;
    my $return = $csv->string."\n";
    if (my $header = $config && $config->gads && $config->gads->{header})
    {
        $return = "$header\n$return";
    }

    return $return;
}

sub csv_line
{   my $self = shift;
    # All the data values
    my $line = $self->single
        or return;

    my @columns = @{$self->columns_retrieved_no};
    my @items = ($line->current_id);
    push @items, $line->parent_id if $self->has_children;
    push @items, map { $line->fields->{$_->id} } @columns;
    my $csv = $self->_csv;
    $csv->combine(@items)
        or error __x"An error occurred producing a line of CSV: {err} {items}",
            err => "".$csv->error_diag, items => "@items";
    return $csv->string."\n";
}

sub data_timeline
{   my ($self, %options) = @_;

    my $original_from = $self->from;
    my $original_to   = $self->to;
    my $limit_qty     = $self->from && !$self->to;

    my $timeline = GADS::Timeline->new(
        type         => 'timeline',
        records      => $self,
        label_col_id => $options{label},
        group_col_id => $options{group},
        color_col_id => $options{color},
    );

    my ($min, $max);

    # We may have retrieved values other than the ones we want, for example
    # additional date fields in records where we wanted the other one. Normally
    # we don't want these. However, we will want to add them on if there are
    # not many records in the original set
    my (@items);
    if ($limit_qty)
    {
        $self->max_results(100);
        foreach my $run (qw/after before/)
        {
            my @over;
            # Initial retrieval will be 100 records from today (center)
            my @retrieved = @{$timeline->items};
            $max = $timeline->retrieved_to if $run eq 'after';
            $min = $timeline->retrieved_from if $run eq 'before';

            foreach (@retrieved)
            {
                if (
                    ($run eq 'after' && $_->{dt} < $max)
                    || ($run eq 'before' && $_->{dt} > $min)
                )
                {
                    push @items, $_;
                } else {
                    push @over, $_;
                }
            }
            if (
                ($run eq 'after' && $self->records_retrieved_count < 100)
                || ($run eq 'before' && $self->records_retrieved_count < 50)
            )
            {
                my $r = $self->records_retrieved_count;
                # Sort is expensive, but will only be called if there weren't many
                # records to begin with
                @over = sort { DateTime->compare($a->{dt}, $b->{dt}) } @over;
                @over = reverse @over if $run eq 'before';
                while ($r < 100 && @over)
                {
                    push @items, pop @over;
                    $r++;
                }
            }

            # Now add a smaller subset of before the required time
            # my $days  = int $min->delta_days($max)->in_units('days') / 4;
            $timeline->clear;
            # Retrieve up to but not including the previous retrieval
            if ($run eq 'after')
            {
                $self->to($original_from->clone->subtract(days => 1));
                # $min = $original_from->clone->subtract(days => $days);
                $self->from(undef);
                # Don't limit by a number - take whatever is in that period
                $self->max_results(50);
            }

            # Set the times for the display range
            $min && $min->subtract(days => 1),
            $max && $max->add(days => 2), # one day already added to show period to end of day
        }
    }
    else {
        my @retrieved = @{$timeline->items};
        if ($self->exclusive_of_to)
        {
            @items = grep {
                $_->{single} || $_->{end} < $original_to->epoch * 1000;
            } @retrieved;
        }
        elsif ($self->exclusive_of_from)
        {
            @items = grep {
                $_->{single} || $_->{start} > $original_from->epoch * 1000;
            } @retrieved;
        }
        else {
            @items = @retrieved;
        }
        @items = grep {
            !$_->{single} || ($_->{dt} >= $original_from && $_->{dt} <= $original_to)
        } @items;

        # Set the times for the display range
        $min = $self->from;
        $max = $self->to;
    }

    # Remove dt (DateTime) value, otherwise JSON encoding borks
    delete $_->{dt}
        foreach @items;

    my @groups = map {
        {
            id        => $timeline->groups->{$_},
            content   => encode_entities($_),
            order     => $_,
            style     => 'font-weight: bold',
        }
    } keys %{$timeline->groups};

    $self->from($original_from);
    $self->to($original_to);

    +{
        items  => \@items,
        groups => \@groups,
        colors => $timeline->colors,
        min    => $min,
        max    => $max,
    };
}

sub data_calendar
{   my ($self, %options) = @_;
    my $timeline = GADS::Timeline->new(
        type    => 'calendar',
        records => $self,
        from    => $options{from},
        to      => $options{to},
    );

    return $timeline->items;
}

sub quote
{   my ($self, $name) = @_;
    my $dbh = $self->schema->storage->dbh;
    return $dbh->quote_identifier($name) if $name !~ /\./;
    panic "Unexpected identifier $name" if $name =~ /\./ > 1;
    my ($table, $field) = split /\./, $name;
    return $dbh->quote_identifier($table).".".$dbh->quote_identifier($field);
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

