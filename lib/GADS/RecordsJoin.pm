=pod
GADS - Globally Accessible Data Store
Copyright (C) 2016 Ctrl O Ltd

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

package GADS::RecordsJoin;

use Data::Compare;
use Data::Dumper;
use Log::Report 'linkspace';
use Moo::Role;
use MooX::Types::MooseLike::Base qw(ArrayRef);

my $debug = 0;

has _jp_store => (
    is      => 'rwp',
    isa     => ArrayRef,
    default => sub { [] },
);

sub _all_joins
{   my ($self, %options) = @_;
    return $self->_all_joins_recurse($self->_jpfetch(%options));
}

sub _all_joins_recurse
{   my ($self, @joins) = @_;
    my @return;
    foreach my $j (@joins)
    {
        push @return, $j;
        push @return, $self->_all_joins_children($j->{children})
            if $j->{children};
    }
    @return;
}

sub _all_joins_children
{   my ($self, $children) = @_;
    my @return;
    foreach (@$children)
    {
        push @return, $self->_all_joins_children($_->{children})
            if $_->{children};
        push @return, $_
    }
    @return;
}

sub _compare_parents
{   my ($parent1, $parent2) = @_;
    return 1 if !$parent1 && !$parent2;
    return 0 if $parent1 xor $parent2;
    $parent1->id == $parent2->id;
}

sub _add_children
{   my ($self, $join, $column, %options) = @_;
    $join->{children} ||= [];
    my %existing = map { $_->{column}->id => 1 } @{$join->{children}};
    foreach my $c (@{$column->curval_fields_retrieve})
    {
        next if $c->internal;
        # prefetch and linked match the parent.
        # search and sort are left blank, but may be updated with an
        # additional direct call with just the child and that option.
        my $child = {
            prefetch => 1,
            curval   => $c->is_curcommon,
            column   => $c,
            parent   => $column,
        };
        push @{$join->{children}}, $child
            if !$existing{$c->id};
    }
}

sub _add_jp
{   my ($self, $column, %options) = @_;

    # Catch a bug whereby fields could be made to be linked to fields within
    # the same table. This results in data not being retrieved properly.
    panic __x"Link parent of field ID {id} is from same table as field itself", id => $column->id
        if $column->link_parent && $column->link_parent->instance_id == $column->instance_id;

    trace __x"Checking or adding {field} to the store", field => $column->field
        if $debug;

    my $prefetch = ($column->fetch_with_record || ($options{include_multivalue} && $options{include_multivalue} == $column->id)) && $options{prefetch};

    # Check whether join is already in store, if so update
    trace __x"Check to see if it's already in the store"
        if $debug;
    foreach my $j ($self->_all_joins_recurse(@{$self->_jp_store}))
    {
        trace __x"Checking join {field}", field => $j->{column}->field
            if $debug;
        if ($column->id == $j->{column}->id)
        {
            trace __x"Possibly found, checking to see if parents match"
                if $debug;
            if ( _compare_parents($options{parent}, $j->{parent}) )
            {
                $j->{prefetch} ||= $prefetch;
                $j->{search}   ||= $options{search};
                $j->{linked}   ||= $options{linked};
                $j->{sort}     ||= $options{sort};
                $j->{group}    ||= $options{group};
                $j->{drcol}    ||= $options{drcol};
                if ($column->is_curcommon && $prefetch)
                {
                    $self->_add_children($j, $column, %options);
                }
                trace __x"Found existing, returning"
                    if $debug;
                return;
            }
            trace __x"Parents didn't match"
                if $debug;
        }
    }

    trace __x"Not found, going on to add"
        if $debug;

    my $join_add = {
        # Never prefetch multivalue columns, which can result in huge numbers of rows being retrieved.
        prefetch   => $prefetch,        # Whether values should be retrieved
        search     => $options{search}, # Whether it's used in a WHERE clause
        linked     => $options{linked}, # Whether it's a linked table
        sort       => $options{sort},   # Whether it's used in an order_by clause
        group      => $options{group},  # Whether it's used in a group_by clause
        drcol      => $options{drcol},  # Whether it's used as a daterange column on a graph x-axis
        column     => $column,
        parent     => $options{parent},
    };

    # If it's a curval field then we need to account for any joins that are
    # part of the curval
    if ($column->is_curcommon)
    {
        $self->_add_children($join_add, $column, %options)
            if $prefetch;
    }

    # Otherwise add it
    if (my $parent = $options{parent})
    {
        # Find parent and add to that
        foreach my $c (@{$self->_jp_store})
        {
            if ($c->{column}->id == $parent->id)
            {
                my %existing = map { $_->{column}->id => $_ } @{$c->{children}};
                if (my $exists = $existing{$join_add->{column}->id})
                {
                    $exists->{search} ||= $options{search};
                    $exists->{sort}   ||= $options{sort};
                    $exists->{group}  ||= $options{group};
                    $exists->{drcol}  ||= $options{drcol};
                }
                else {
                    push @{$c->{children}}, $join_add
                }
            }
        }
    }
    else {
        push @{$self->_jp_store}, $join_add;
    }
}

sub add_prefetch
{   my $self = shift;
    $self->_add_jp(@_, prefetch => 1);
}

sub add_group
{   my $self = shift;
    $self->_add_jp(@_, group => 1);
}

sub add_drcol
{   my $self = shift;
    $self->_add_jp(@_, drcol => 1);
}

sub add_join
{   my $self = shift;
    $self->_add_jp(@_);
}

sub add_linked_prefetch
{   my $self = shift;
    $self->_add_jp(@_, prefetch => 1, linked => 1);
}

sub add_linked_join
{   my $self = shift;
    $self->_add_jp(@_, linked => 1);
}

sub has_linked
{   my ($self, %options) = @_;
    # Check all joins, regardless of options, as we still need to add a linked
    # join even if the linked fields are all multivalue (and won't be retrieved
    # as part of the standard query). The linked join is needed to retrieve the
    # linked record IDs.
    return !!grep $_->{linked}, @{$self->_jp_store};
}

sub has_created_time
{   my ($self, %options) = @_;
    !! grep $_->{column}->name_short && $_->{column}->name_short eq '_created', $self->_jpfetch(%options);
}

sub has_created_user
{   my ($self, %options) = @_;
    !! grep $_->{column}->name_short && $_->{column}->name_short eq '_created_user', $self->_jpfetch(%options);
}

sub _root_is_record
{   my (%options) = @_;
    $options{root_table} && $options{root_table} eq 'record';
}

sub _count_version_joins
{   my ($self, %options) = @_;

    my $count = _root_is_record(%options) ? 0 : 1; # Always at least one if joining onto current

    my $include_linked = $options{linked} && $self->has_linked(%options);

    # Do 2 loops round, first for non-linked, second for linked, adding one to
    # the count in the middle for the linked record itself
    foreach my $li (0..!!$include_linked) # Only do second loop if linked requested
    {
        $count++ if !$li && $include_linked;
        # Include a record_later search for each time we join a curval with its
        # full join structure. Don't add when only a curval value on its own is
        # being used.
        my %curvals_included;
        foreach ($self->_all_joins(%options, linked => undef))
        {
            next if ($li xor $_->{linked}); # Only take same as linked loop
            # Include a curval field itself, or one of its children (only the child
            # might be searched upon)
            my $is_curcommon = $_->{column}->is_curcommon;
            if ($is_curcommon || $_->{parent})
            {
                my $curcommon_id = $is_curcommon ? $_->{column}->id : $_->{parent}->id;
                if (
                    ($options{search} && $_->{search} && $_->{parent} && !$is_curcommon) # Search in child of curval
                    || ($options{sort} && $_->{sort}) # sort is all children
                    || ($options{group} && $_->{group} && $_->{parent} && !$is_curcommon)
                    || ($options{drcol} && $_->{drcol})
                    # prefetch is all children, but not when the curval has no fields
                    || ($options{prefetch} && $_->{prefetch} && !$_->{parent} && @{$_->{children}})
                )
                {
                    unless ($curvals_included{$curcommon_id})
                    {
                        $count++;
                        $curvals_included{$curcommon_id} = 1;
                    }
                }
            }
        }
    }
    $count;
}

sub record_later_search
{   my ($self, %options) = @_;

    # Do not add record_later search if using previous_values (in which case
    # all versions selected) or current_version_only (direct version join).
    return () if $self->previous_values || $options{current_version_only};

    return ({
        "record_earlier.id" => undef,
    }) if $self->record_earlier;

    my $count = $self->_count_version_joins(%options);

    my @search;
    for (1..$count)
    {
        my $id = $_ == 1 ? '' : "_$_";
        my $alt = $options{alt} ? "_alternative" : "";
        push @search, {
            "record_later$alt$id.current_id" => undef,
        };
    }
    @search;
}

sub record_single_rewind
{   my ($self, %options) = @_;
    my $rewind = $options{rewind}
        or return ();

    my $count = $self->_count_version_joins(%options);

    # Special case for "record" being the root table that is being selected
    # from, and this being the first call to record_single_rewind(). In this
    # case and at this point the count will be zero thus returning no join,
    # even though one is needed for a rewind search (to ensure that a request
    # for a specific version returns nothing if the rewind time is earlier than
    # that version). For later calls in the same query, the count stands as
    # normal and the record_name will be its normal "record" value rather than
    # "me".
    $count = 1 if _root_is_record(%options) && $count == 0;

    my $record_single = $self->record_name(%options, linked => 0);
    my @search;
    for (1..$count)
    {
        my $id = $_ == 1 ? '' : "_$_";
        my $alt = $options{alt} ? "_alternative" : "";
        push @search, (
            "$record_single$alt$id.created" => {
                '<=' => $self->dt_parser->format_datetime($rewind),
            }
        );
    }
    @search;
}

sub _jpfetch
{   my ($self, %options) = @_;
    my @joins;

    my @jpstore;
    # Normally we want joins to be added and then prefetches, as they are
    # numbered in that order by DBIx::Class. However, sometimes prefetches will
    # be used as joins (during graph creation) in which case we want to retain
    # the order
    if ($options{retain_join_order})
    {
        @jpstore = @{$self->_jp_store};
    }
    else {
        @jpstore = grep { !$_->{prefetch} } @{$self->_jp_store};
        push @jpstore, grep { $_->{prefetch} } @{$self->_jp_store};
    }

    my @jpstore2 = grep { $_->{linked} } @jpstore;
    push @jpstore2, grep { !$_->{linked} } @jpstore;

    foreach (@jpstore2)
    {
        next if exists $options{prefetch} && !$options{prefetch} && $_->{prefetch} && !$options{group} && !$options{drcol};
        push @joins, $self->_jpfetch_add(options => \%options, join => $_,);
    }
    my @return;
    if ($options{limit} && @joins)
    {
        my $offset = ($options{page} - 1) * $options{limit};
        return if @joins < $offset;
        my $end = $options{limit}-1+$offset ;
        $end = @joins-1 if $end > @joins-1;
        push @return, grep { $_->{search} } @joins[0..$offset-1] if $options{search};
        push @return, grep { $_->{sort} } @joins[0..$offset-1] if $options{sort};
        push @return, @joins[$offset..$end];
        push @return, grep { $_->{search} } @joins[$end+1..@joins-1] if $options{search};
        push @return, grep { $_->{sort} } @joins[$end+1..@joins-1] if $options{sort};
    }
    else {
        @return = @joins;
    }
    my @return2;
    foreach (@return)
    {
        if (defined $options{linked})
        {
            next if !$options{linked} && $_->{linked};
            next if $options{linked} && !$_->{linked};
        }
        push @return2, $_;
    }
    return @return2;
}

sub _jpfetch_add
{   my ($self, %params) = @_;
    my $options = $params{options};
    my $join    = $params{join};
    my $return  = $params{return};
    my $parent  = $params{parent};

    my $current_version_only = $options->{current_version_only};

    if (
        ($options->{search} && $join->{search})
        || ($options->{sort} && $join->{sort})
        || ($options->{group} && $join->{group})
        || ($options->{drcol} && $join->{drcol})
        || (
            # Include only aggregate columns if requested. This is used when a
            # records object has been built, but then only the aggregate columns
            # within that are required for an aggregate query
            $options->{prefetch} && $join->{prefetch}
                && (!$options->{aggregate} || $join->{column}->aggregate)
        )
        || ($options->{extra_column} && $join->{column}->id == $options->{extra_column}->id)
    )
    {
        my $column = $join->{column};
        if ($column->is_curcommon)
        {
            my @children;
            foreach my $child (@{$join->{children}})
            {
                push @children, $self->_jpfetch_add(options => $options, join => $child, parent => $column);
            }
            my $simple = {%$join};
            $simple->{join} = $column->sprefix;
            # Remove multivalues to prevent huge amount of rows being fetched.
            # These will be fetched later as individual columns.
            # Keep any for a sort - these still need to be used when fetching rows.
            @children = grep { $_->{search} || $_->{sort} || $_->{column}->fetch_with_record || $options->{include_multivalue} || $_->{group} || $_->{drcol} } @children
                if $options->{prefetch};
            my $options = {
                join_current_version => $current_version_only,
            };
            return {
                %$join,
                parent    => $parent,
                column    => $column,
                join      => $column->make_join($options, map $_->{join}, @children),
                children  => \@children,
            };
        }
        else {
            return { %$join, join => $join->{column}->tjoin(join_current_version => $current_version_only) };
        }
    }
    else {
        return ();
    }
}

# See comments on alternative join in GADS::DB
sub _to_alt
{   my $join = shift;
    panic "Missing join" if !$join;
    return $join."_alternative" if !ref $join;
    return [ map _to_alt($_), @$join ]
        if ref $join eq 'ARRAY';
    my @keys = keys %$join;
    panic "Unexpected number of keys for join ".Dumper $join if @keys > 1;
    my $j1 = $keys[0];
    my $j2 = $join->{$j1};
    #my ($j1, $j2) = each %$join;
    return { _to_alt($j1) => _to_alt($j2) };
}

sub jpfetch
{   my ($self, %options) = @_;
    my @cols = $self->_jpfetch(%options);
    @cols = grep $_->{column}->multivalue == $options{multivalue} || $_->{group}, @cols
        if defined $options{multivalue};
    my @joins = grep $_, map { $_->{join} } @cols;
    @joins = map { _to_alt($_) } @joins
        if $options{alt};
    return @joins;
}

sub columns_fetch
{   my ($self, %options) = @_;
    my @prefetch;
    foreach my $jp ($self->_jpfetch(prefetch => 1, %options))
    {
        next unless $jp->{prefetch};
        my $column = $jp->{column};
        my $table = $self->table_name($column, prefetch => 1, %options);
        my $fields = $column->retrieve_fields or next;
        my @values = (@$fields, 'id');
        push @prefetch, {$column->field.".$_" => "$table.$_"} foreach @values; # unless $column->is_curcommon;
        push @prefetch, $column->field.'.child_unique'
            if $column->userinput;
        if ($jp->{children} && @{$jp->{children}})
        {
            my $rec_single_name = $self->record_name(%options, prefetch => 1, column => $column);
            push @prefetch, { $column->field.".record_id" => "$rec_single_name.id" };
            foreach my $child (@{$jp->{children}})
            {
                my $column2 = $child->{column};
                my %opt = %options;
                # delete $opt{search};
                my $table = $self->table_name($column2, prefetch => 1, %opt, parent => $column);
                my $fields2 = $column2->retrieve_fields or next;
                my @values = (@$fields2, 'id');
                push @prefetch, {$column->field.".".$column2->field.".$_" => "$table.$_"} foreach @values;
            }
        }
    }

    return @prefetch;
}

sub _record_name_by_count
{   my ($self, $count, %options) = @_;
    my $c_offset = $count == 1 ? '' : "_$count";
    return "current_version$c_offset"
        if $options{current_version_only};
    return "record_single$c_offset";
}

sub record_name
{   my ($self, %options) = @_;
    my @store = $self->_jpfetch(%options);
    my $count;
    # If the query is being performed on the Record table, then the record name
    # will start with that. Otherwise, it will start with record_single as the
    # record will be joined to the Current table.
    if ($options{root_table} && $options{root_table} eq 'record')
    {
        return 'me' if !$options{column};
        $count = 0;
    }
    elsif ($self->has_linked(%options)) {
        $count = 1;
    }
    else {
        $count = 0;
    }

    # Linked is always first. Drop straight back if that's what's wanted
    return $self->_record_name_by_count($count, %options)
        if $options{linked};

    # Now add on for any curval columns in the linked section
    foreach my $c (@store)
    {
        next unless $c->{column}->is_curcommon && $c->{linked};
        next if !@{$c->{children}}; # No record_singles unless fields selected from curval
        $count++;
        return $self->_record_name_by_count($count, %options)
            if $options{column} && $options{column}->id == $c->{column}->id;
    }

    # Now the query of the main record
    $count++
        unless _root_is_record(%options);

    # And now add on any curval columns in the normal section

    # The column options allows a record_single to be generated for a curval
    # field. In this case, we have to work out how many previous record_single
    # there have been up to and including the column required
    if (my $col = $options{column})
    {
        foreach my $c (@store)
        {
            next unless $c->{column}->is_curcommon && !$c->{linked};
            next if !@{$c->{children}}; # No record_singles unless fields selected from curval
            $count++;
            last if $c->{column}->id == $col->id;
        }
    }

    my $c_offset = $count == 1 ? '' : "_$count";
    return $self->_record_name_by_count($count, %options);
}

=pod
Return a fully-qualified value field for a table.

%options signifies what will be counted when getting the join numbers. For
example, if tables that are joined for both searches and prefetches should be
included, then use

  ->table_name($col, search => 1, prefetch => 1)

=cut
sub table_name
{   my ($self, $column, %options) = @_;
    if ($column->internal)
    {
        return _root_is_record(%options) ? 'current' : ($options{alias} || 'me') if $column->table eq 'Current';
        if ($column->sprefix eq 'record')
        {
            return $self->record_name(%options);
        }
        my $tn = $column->sprefix;
        $tn .= "_alternative" if $options{alt};
        return $tn;
    }
    my $jn = $self->_join_number($column, %options);
    my $index = $jn > 1 ? "_$jn" : '';
    my $tn = $column->sprefix;
    $tn .= "_alternative" if $options{alt};
    $tn . $index;
}

sub _join_number
{   my ($self, $column, %options) = @_;

    $self->_dump_jp_store; # Only does anything when logging level high enough

    # Find the correct join number, by iterating through all the current
    # joins, and jumping at the matching join with the count number.
    # Joins in the form "field{n} => value" will be counted as the same,
    # but only returned with an exact match.

    my @store = $self->_jpfetch(%options, linked => undef);
    my $stash = {};

    if ($options{find_value})
    {
        trace "Looking in the store for all joins for find_value"
            if $debug;
    }
    else {
        trace __x"Looking in the store for join number for column {id}", id => $column->id
            if $debug;
    }

    foreach my $j (@store)
    {
        trace "Checking join ".$j->{column}->id
            if $debug;
        my $n = _find($column, $j, $stash, %options);
        trace __x"return from find request is: {n}", n => $n
            if $debug;
        return $n if $n;
        if ($j->{children})
        {
            trace "This join has other joins, checking..."
                if $debug;
            foreach my $j2 (@{$j->{children}})
            {
                if ($j2->{children})
                {
                    trace "This join has other joins, checking..."
                        if $debug;
                    foreach my $j3 (@{$j2->{children}}) # Replace with recursive function?
                    {
                        trace "Looking at join ".$j3->{column}->id
                            if $debug;
                        $n = _find($column, $j3, $stash, %options);
                        trace __x"return from find request is: {n}", n => $n
                            if $debug;
                        return $n if $n;
                    }
                }
                trace "Looking at join ".$j2->{column}->id
                    if $debug;
                $n = _find($column, $j2, $stash, %options);
                trace __x"return from find request is: {n}", n => $n
                    if $debug;
                return $n if $n;
            }
        }
    }

    return $stash->{value} if $options{find_value};

    # This shouldn't happen. If we get here then we're trying to get a
    # join number for a table that hasn't been added.
    my $cid = $column->id;
    $options{parent} = $options{parent}->id if $options{parent}; # Prevent dumping of whole object
    $options{extra_column} = $options{extra_column}->id if $options{extra_column};
    panic "Unable to get join number: column $cid hasn't been added for options ".Dumper(\%options);
}

# The find_value option will not match any joins, but will instead allow the
# number of joins called "value" to be counted. Each iteration updates the
# stash, which can be retrieved at the end (used by value_next_join)
sub _find
{   my ($needle, $jp, $stash, %options) = @_;

    trace "Checking against join ".$jp->{column}->id
        if $debug;

    my $is_cc = $jp->{column}->type eq 'curval' || $jp->{column}->type eq 'filval';
    my $join = $jp->{column}->is_curcommon
        ? $jp->{column}->sprefix
        #: $is_cc
        #? { $jp->{column}->sprefix => 'value' }
        : $jp->{column}->tjoin(join_current_version => $options{current_version_only});
    if (ref $join eq 'HASH')
    {
        my ($key, $value) = %$join;
        trace __x"This join is a hash with key:{key} and value: {value}", key => $key, value => Dumper($value)
            if $debug;
        trace __x"We are looking for value being equal to {needle}", needle => $needle->sprefix
            if $needle && $debug;
        if (
            ($options{find_value} && $value eq 'value')
            || $needle->sprefix eq $value)
        {
            trace "Incrementing key and value counters"
                if $debug;
            $stash->{$key}++;
            $stash->{$value}++;
            if ($jp->{parent} && !$stash->{parents_included}->{$jp->{parent}->id})
            {
                if ($jp->{parent}->type eq 'curval' || $jp->{parent}->type eq 'filval')
                {
                    # A curval join has an extra "value" join whereas an
                    # autocur does not
                    trace "Incrementing value count to account for parent"
                        if $debug;
                    $stash->{value}++;
                }
                $stash->{parents_included}->{$jp->{parent}->id} = 1;
            }
            if (!$options{find_value}
                && $needle->field eq $key && _compare_parents($options{parent}, $jp->{parent}))
            {
                trace "We have a match, returning"
                    if $debug;
                return $stash->{$value};
            }
        }
    }
    elsif (ref $join eq 'ARRAY')
    {
        trace "This join is an array"
            if $debug;
        foreach (@$join)
        {
            my $n = _find($needle, $_, $stash);
            trace "Return from find is $n"
                if $debug;
            return $n if $n;
        }
    }
    else {
        trace "This join is a standard join"
            if $debug;
        $stash->{$join}++
            if $join;
        if ($jp->{parent} && !$stash->{parents_included}->{$jp->{parent}->id})
        {
            $stash->{value}++ if $jp->{parent}->value_field eq 'value';
            $stash->{parents_included}->{$jp->{parent}->id} = 1;
        }
        if (!$options{find_value} && $join && $needle->sprefix eq $join)
        {
            # Single table join
            if (_compare_parents($options{parent}, $jp->{parent})
                # Account for autocur joins, in which case only match when
                # it's the one we need
                && ($needle->sprefix ne 'current' || $needle->id == $jp->{column}->id))
            {
                trace "We have a match"
                    if $debug;
                return $stash->{$needle->sprefix};
            }
        }
    }
    trace "No match"
        if $debug;
    return undef;
}

# Get the next join by the name of "value"
sub value_next_join
{   my ($self, %options) = @_;
    my $count = $self->_join_number(undef, %options, find_value => 1);
    $count++; # Add one for the next join, prevent uninit errors
    my $id = $count == 1 ? '' : "_$count";
    "value$id";
}

# Return a fully-qualified value field for a table
sub fqvalue
{   my ($self, $column, %options) = @_;
    my $as_index = delete $options{as_index};
    my $tn = $self->table_name($column, %options);
    my $value_field = $as_index ? $column->value_field_as_index : $column->value_field;
    "$tn." . $value_field;
}

has aggregate_fields => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub { [] },
);

sub add_aggregate
{   my ($self, $column, $operator, %options) = @_;

    # Whether this column appears in the group_by statement, therefore meaning
    # it does not require a separate sql select statement. This can possibly be
    # removed in the future by checking the fields that have been added as
    # grouped.
    my $is_grouped = delete $options{is_grouped};
    my $is_linked  = delete $options{is_linked};
    # Whether there are any group_by statements at all in the planned sql query
    my @group_cols = $options{group_cols} ? @{delete $options{group_cols}} : ();
    my $parent     = delete $options{parent};
    my $as_index   = $self->group_values_as_index;
    my $drcol      = !!$self->dr_column;

    my ($existing) = grep {
        $_->{column}->id == $column->id
        && ((!$_->{parent} && !$parent) || ($_->{parent} && $parent && $_->{parent}->id == $parent->id))
        && $_->{operator} ne $operator
    } @{$self->aggregate_fields};

    return $existing if $existing;

    my $select;
    my $as = $is_linked ? $is_linked->field : $column->field;
    $as = $as.'_count' if $operator eq 'count';
    $as = $as.'_sum' if $operator eq 'sum';
    $as = $as.'_distinct' if $operator eq 'distinct' && !$is_grouped;
    $as = $as.'_link' if $is_linked;

    # The select statement to get this column's value varies depending on
    # what we want to retrieve. If we're selecting a field with multiple
    # values, then we have to run this as a separate subquery, otherwise if
    # there are more than one multiple-value retrieval then that aggregates
    # will be counting multiple times for each set of multiple values (due
    # to the multiple joins)

    # Field is either multivalue or its parent is
    if (($column->multivalue || ($parent && $parent->multivalue)) && !$is_grouped)
    {
        # Assume curval if it's a parent - we need to search the curval
        # table for all the curvals that are part of the records retrieved.
        if ($parent)
        {
            my $f_rs = $self->schema->resultset('Curval')->search({
                'mecurval.record_id' => {
                    # Match against main query's records (use cvo_values as
                    # we are matching against the record ID of the outer
                    # select statement, not the record IDs in the record
                    # selection)
                    -ident => $self->cvo_values ? 'current_version.id' : 'record_single.id'
                },
                'mecurval.layout_id' => $parent->id,
                # If retrieving from a previous point in time then add
                # required search criteria to only retrieve single correct
                # record
                $self->cvo_values ? () : ('record_later.id' => undef),
                $self->rewind_values ? ('record_single_alternative.created' => {
                    '<=' => $self->dt_parser->format_datetime($self->rewind_values)
                }) : ()
            },
            {
                alias => 'mecurval', # Can't use default "me" as already used in main query
                join => {
                    'value' => {
                        $self->cvo_values
                        ? ('current_version_alternative' => [
                            $column->tjoin(join_current_version => 1)
                        ])
                        : ('record_single_alternative' => [
                            'record_later',
                            $column->tjoin,
                        ])
                    },
                },
            });
            if ($column->numeric && $operator eq 'sum')
            {
                $select = $f_rs->get_column((ref $column->tjoin(join_current_version => $self->cvo_values) eq 'HASH' ? 'value_2' :  $column->field).".".$column->value_field)->sum_rs->as_query;
            }
            elsif ($operator eq 'sum' || $operator eq 'max') # Default to max for sum of non-numeric columns
            {
                my $fn = (ref $column->tjoin(join_current_version => $self->cvo_values) eq 'HASH' ? 'value_2' :  $column->field).".".$column->value_field;
                $select = $f_rs->get_column($fn)->max_rs->as_query;
            }
            elsif ($operator eq 'distinct') {
                # At the moment we do not expect a distinct count to be
                # necessary for a field from within a curval. We might want
                # to add this functionality in the future, in which case it
                # will look something like the next else block
                panic __x"Unexpected count distinct for curval sub-field {name} ({id})",
                    name => $column->name, id => $column->id;
            }
            else {
                panic "Unknown operator $operator";
            }
        }
        # Otherwise a standard subquery select for that type of field
        else {
            # Also need to add the main search query, otherwise if we take
            # all the field's values for each record, then we won't be
            # filtering the non-matched ones in the case of multivalue
            # fields.
            # Need to include "group" as an option to the subquery, to
            # ensure that the grouping column is added to match to the main
            # query's group column. This does not apply if doing an overall
            # aggregate though, as there is only a need to retrieve the
            # overall results, not for each matching grouped row. If the
            # "group" option is included unnecessarily, then this can cause
            # joins of multiple-value fields which can include too many
            # results in the aggregate.
            my $has_grouped = @group_cols;
            my $searchq = $self->search_query(%options, search => 1, extra_column => $column, linked => 0, group => $has_grouped, alt => 1, alias => 'mefield', current_version_only => $self->cvo_values, rewind => $self->rewind_values);
            foreach my $group (@group_cols)
            {
                push @$searchq, {
                    $self->fqvalue($group->{column}, %options, search => 1, as_index => $as_index, linked => 0, group => 1, alt => 1, extra_column => $group->{column}, parent => $group->{parent}, drcol => $drcol, current_version_only => $self->cvo_values) => {
                        -ident => $self->fqvalue($group->{column}, %options, search => 1, parent => $group->{parent}, as_index => $as_index, linked => 0, group => 1, extra_column => $group->{column}, drcol => $drcol, current_version_only => $self->cvo_values)
                    },
                };
            }
            $select = $self->schema->resultset('Current')->search(
                [-and => $searchq ],
                {
                    alias => 'mefield',
                    join  => [
                        [$self->linked_hash(%options, search => 1, group => $has_grouped, alt => 1, extra_column => $column, current_version_only => $self->cvo_values)],
                        {
                            $self->cvo_values
                            ? ('current_version_alternative' => [
                                $self->jpfetch(%options, search => 1, linked => 0, group => $has_grouped, extra_column => $column, alt => 1, current_version_only => 1)
                            ])
                            : ('record_single_alternative' => [ # The (assumed) single record for the required version of current
                                'record_later_alternative',  # The record after the single record (undef when single is latest)
                                $self->jpfetch(%options, search => 1, linked => 0, group => $has_grouped, extra_column => $column, alt => 1, current_version_only => 0),
                            ])
                        },
                    ],
                    select => {
                        count => { distinct => $self->fqvalue($column, %options, search => 1, as_index => $as_index, linked => 0, group => 1, alt => 1, extra_column => $column, drcol => $drcol, current_version_only => $self->cvo_values) },
                        -as   => 'sub_query_as',
                    },
                },
            );
            my $col_fq = $self->fqvalue($column, %options, search => 1, as_index => $as_index, linked => 0, group => 1, alt => 1, extra_column => $column, drcol => $drcol, current_version_only => $self->cvo_values);
            if ($column->numeric && $operator eq 'sum')
            {
                $select = $select->get_column($col_fq)->sum_rs->as_query;
                $operator = 'max';
            }
            # Default to max for sum of non-numeric columns.
            # count selects max here and then count as the operator below
            elsif ($operator eq 'sum' || $operator eq 'max' || $operator eq 'count')
            {
                $select = $select->get_column($col_fq)->max_rs->as_query;
            }
            elsif ($operator eq 'distinct' || $operator eq 'count')
            {
                $select = $select->get_column('sub_query_as')->as_query;
                $operator = 'max';
            }
            else {
                panic "Unknown operator $operator";
            }
        }
    }
    # Standard single-value field - select directly, no need for a subquery
    else {
        $select = $self->fqvalue($column, %options, as_index => $as_index, prefetch => 1, group => 1, linked => 0, parent => $parent, retain_join_order => 1, drcol => $drcol, current_version_only => $self->cvo_values);
    }

    my $overall_select = $operator eq 'distinct'
        ? {
            count => { distinct => $select },
            -as   => $as,
        }
        : {
            $operator => $select,
            -as       => $as,
        };

    my $aggfield = {
        column   => $column,
        parent   => $parent,
        select   => $overall_select,
        operator => $operator,
        as       => $as,
    };

    push @{$self->aggregate_fields}, $aggfield;

    # Also add linked column if required
    $self->add_aggregate($column->link_parent, $operator, is_linked => $column, parent => $parent, group_cols => \@group_cols, is_grouped => $is_grouped)
        if $column->link_parent;

    $aggfield;
}

sub _dump_child
{   my ($self, $dd, $child, $indent) = @_;
    no warnings 'uninitialized';
    $dd->Values([$child->{join}]);
    my $children;
        if (ref $child->{children})
        {
            $children .= $self->_dump_child($dd, $_, $indent + 1)
                foreach @{$child->{children}};
        }
    my $join = ref $child->{join} ? $dd->Dump : $child->{join};
    chomp $join;
    my $parent_id = $child->{parent}->id;
my $ret = "
child is ".$child->{column}->id." (".$child->{column}->name.") => {
    join     => $join,
    prefetch => $child->{prefetch},
    curval   => $child->{curval},
    search   => $child->{search},
    sort     => $child->{sort},
    group    => $child->{group},
    drcol    => $child->{drcol},
    parent   => $parent_id,
    children => $children
},";
    my $space = '    ' x $indent;
    $ret =~ s/^(.*)$/$space$1/mg;
    $ret;
}

sub _dump_jp_store
{   my $self = shift;
    $debug or return;
    my $dumped = "Going to dump the jp store:\n";
    my $dd = Data::Dumper->new([]);
    $dd->Indent(0);
    no warnings 'uninitialized';
    foreach my $jp (@{$self->_jp_store})
    {
        my $children;
        if (ref $jp->{children})
        {
            $children .= $self->_dump_child($dd, $_, 3)
                foreach @{$jp->{children}};
        }
        $dd->Values([$jp->{join}]);
        my $join = ref $jp->{join} ? $dd->Dump : $jp->{join};
        chomp $join;
        $dumped .= "    join for ".$jp->{column}->id." (".$jp->{column}->name.") => {
        join     => $join,
        prefetch => $jp->{prefetch},
        search   => $jp->{search},
        linked   => $jp->{linked},
        sort     => $jp->{sort},
        group    => $jp->{group},
        drcol    => $jp->{drcol},
        curval   => $jp->{curval},
        children => $children
    },
";
    }
    trace "$dumped\n";
}

1;

