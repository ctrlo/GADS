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
use MooX::Types::MooseLike::Base qw(:all);

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
    foreach my $c (@{$column->curval_fields_retrieve(all_fields => $options{all_fields})})
    {
        next if $c->is_curcommon;
        # prefetch and linked match the parent.
        # search and sort are left blank, but may be updated with an
        # additional direct call with just the child and that option.
        my $child = {
            join       => $c->tjoin(all_fields => $options{all_fields}),
            prefetch   => 1,
            curval     => $c->is_curcommon,
            column     => $c,
            parent     => $column,
        };
        $self->_add_children($child, $c, %options)
            if $c->is_curcommon;
        push @{$join->{children}}, $child
            if !$existing{$c->id};
    }
}

sub _add_jp
{   my ($self, $column, %options) = @_;

    panic "Attempt to generate join for internal column"
        if $column->internal;

    my $key;
    my $toadd = $column->tjoin(all_fields => $options{all_fields});
    ($key) = keys %$toadd if ref $toadd eq 'HASH';

    trace __x"Checking or adding {field} to the store", field => $column->field;

    my $prefetch = (!$column->multivalue || $options{include_multivalue}) && $options{prefetch};

    # Check whether join is already in store, if so update
    trace __x"Check to see if it's already in the store";
    foreach my $j ($self->_all_joins_recurse(@{$self->_jp_store}))
    {
        trace __x"Checking join {field}", field => $j->{column}->field;
        if (
            ($key && ref $j->{join} eq 'HASH' && Compare($toadd, $j->{join}))
            || $toadd eq $j->{join}
        )
        {
            trace __x"Possibly found, checking to see if parents match";
            if ( _compare_parents($options{parent}, $j->{parent}) )
            {
                $j->{prefetch} ||= $prefetch;
                $j->{search}   ||= $options{search};
                $j->{linked}   ||= $options{linked};
                $j->{sort}     ||= $options{sort};
                $j->{group}    ||= $options{group};
                $self->_add_children($j, $column, %options)
                    if ($column->is_curcommon && $prefetch);
                trace __x"Found existing, returning";
                return;
            }
            trace __x"Parents didn't match";
        }
    }

    trace __x"Not found, going on to add";

    my $join_add = {
        join       => $toadd,
        # Never prefetch multivalue columns, which can result in huge numbers of rows being retrieved.
        prefetch   => $prefetch,        # Whether values should be retrieved
        search     => $options{search}, # Whether it's used in a WHERE clause
        linked     => $options{linked}, # Whether it's a linked table
        sort       => $options{sort},   # Whether it's used in an order_by clause
        group      => $options{group},  # Whether it's used in a group_by clause
        column     => $column,
        parent     => $options{parent},
    };

    # If it's a curval field then we need to account for any joins that are
    # part of the curval
    $self->_add_children($join_add, $column, %options)
        if ($column->is_curcommon && $prefetch);

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

# General additional search parameters that need to be added for correct
# results
sub common_search
{   my ($self, %options) = @_;
    my @search;
    my $count = $options{no_current} ? 0 : 1; # Always at least one if joining onto current

    # Do 2 loops round, first for non-linked, second for linked, adding one to
    # the count in the middle for the linked record itself
    foreach my $li (0..!!$options{linked}) # Only do second loop if linked requested
    {
        $count++ if !$li && $options{linked};
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

    for (1..$count)
    {
        my $id = $_ == 1 ? '' : "_$_";
        push @search, {
            "record_later$id.current_id" => undef,
        };
    }
    @search;
}

sub _jpfetch
{   my ($self, %options) = @_;
    my $joins = [];

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
        next if exists $options{prefetch} && !$options{prefetch} && $_->{prefetch} && !$options{group};
        $self->_jpfetch_add(options => \%options, join => $_, return => $joins);
    }
    my @return;
    if ($options{limit} && @$joins)
    {
        my @joins = @$joins;
        my $offset = ($options{page} - 1) * $options{limit};
        return if @joins < $offset;
        my $end = $options{limit}-1+$offset ;
        $end = @joins-1 if $end > @joins-1;
        push @return, grep { $_->{search} } @joins[0..$offset-1] if $options{search};
        push @return, @joins[$offset..$end];
        push @return, grep { $_->{search} } @joins[$end+1..@joins-1] if $options{search};
    }
    else {
        @return = @$joins;
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
    if (
        ($options->{search} && $_->{search})
        || ($options->{sort} && $_->{sort})
        || ($options->{group} && $_->{group})
        || ($options->{prefetch} && $_->{prefetch})
        || ($options->{extra_column} && $_->{column}->id == $options->{extra_column}->id)
    )
    {
        if ($join->{column}->is_curcommon)
        {
            my $children = [];
            foreach my $child (@{$join->{children}})
            {
                $self->_jpfetch_add(options => $options, join => $child, return => $children, parent => $join->{column});
            }
            my $simple = {%$join};
            $simple->{join} = $join->{column}->sprefix;
            # Remove multivalues to prevent huge amount of rows being fetched.
            # These will be fetched later as individual columns.
            # Keep any for a sort - these still need to be used when fetching rows.
            my @children = @$children;
            @children = grep { $_->{sort} || !$_->{column}->multivalue || $options->{include_multivalue} || $_->{group} } @$children
                if $options->{prefetch};
            push @$return, {
                parent    => $parent,
                column    => $join->{column},
                join      => $join->{column}->make_join(map {$_->{join}} @children),
                search    => $join->{search},
                sort      => $join->{sort},
                group     => $join->{group},
                prefetch  => $join->{prefetch},
                linked    => $join->{linked},
                all_joins => [$simple, @children],
                children  => \@children,
            };
        }
        else {
            push @$return, $join;
        }
    }
}

sub jpfetch
{   my $self = shift;
    map { $_->{join} } $self->_jpfetch(@_);
}

sub columns_fetch
{   my ($self, %options) = @_;
    my @prefetch;
    foreach my $jp ($self->_jpfetch(prefetch => 1, %options))
    {
        my $column = $jp->{column};
        my $table = $self->table_name($column, prefetch => 1, %options);
        my @values = @{$column->retrieve_fields};
        push @prefetch, {$column->field.".$_" => "$table.$_"} foreach @values; # unless $column->is_curcommon;
        push @prefetch, $column->field.'.child_unique'
            if $column->userinput;
        if ($jp->{children})
        {
            foreach my $child (@{$jp->{children}})
            {
                my $column2 = $child->{column};
                my %opt = %options;
                # delete $opt{search};
                my $table = $self->table_name($column2, prefetch => 1, %opt, parent => $column);
                my @values = @{$column2->retrieve_fields};
                push @prefetch, {$column->field.".".$column2->field.".$_" => "$table.$_"} foreach @values;
            }
        }
    }

    return @prefetch;
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
        return 'me' if !$options{linked};
        $count = 0;
    }
    else {
        $count = 1;
    }
    if (!$options{linked})
    {
        $count++;
        $count += grep { $_->{column}->type eq 'autocur' && $_->{linked} } @store;
    }
    my $c_offset = $count == 1 ? '' : "_$count";
    return "record_single$c_offset";
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
        return 'me' if $column->name eq 'ID';
        if ($column->sprefix eq 'record')
        {
            return $self->record_name(%options);
        }
        return $column->sprefix;
    }
    my $jn = $self->_join_number($column, %options);
    my $index = $jn > 1 ? "_$jn" : '';
    $column->sprefix . $index;
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
        trace "Looking in the store for all joins for find_value";
    }
    else {
        trace __x"Looking in the store for join number for column {id}", id => $column->id;
    }

    foreach my $j (@store)
    {
        trace "Checking join ".$j->{column}->id;
        my $n;
        if ($j->{all_joins})
        {
            trace "This join has other joins, checking...";
            foreach my $j2 (@{$j->{all_joins}})
            {
                if ($j2->{all_joins})
                {
                    trace "This join has other joins, checking...";
                    foreach my $j3 (@{$j2->{all_joins}}) # Replace with recursive function?
                    {
                        trace "Looking at join ".$j3->{column}->id;
                        $n = _find($column, $j3, $stash, %options);
                        trace __x"return from find request is: {n}", n => $n;
                        return $n if $n;
                    }
                }
                trace "Looking at join ".$j2->{column}->id;
                $n = _find($column, $j2, $stash, %options);
                trace __x"return from find request is: {n}", n => $n;
                return $n if $n;
            }
        }
        else {
            $n = _find($column, $j, $stash, %options);
            trace __x"return from find request is: {n}", n => $n;
        }
        return $n if $n;
    }

    return $stash->{value} if $options{find_value};

    # This shouldn't happen. If we get here then we're trying to get a
    # join number for a table that hasn't been added.
    my $cid = $column->id;
    $options{parent} = $options{parent}->id if $options{parent}; # Prevent dumping of whole object
    panic "Unable to get join number: column $cid hasn't been added for options ".Dumper(\%options);
}

# The find_value option will not match any joins, but will instead allow the
# number of joins called "value" to be counted. Each iteration updates the
# stash, which can be retrieved at the end (used by value_next_join)
sub _find
{   my ($needle, $jp, $stash, %options) = @_;

    trace "Checking against join ".$jp->{column}->id;

    if (ref $jp->{join} eq 'HASH')
    {
        my ($key, $value) = %{$jp->{join}};
        trace __x"This join is a hash with key:{key} and value: {value}", key => $key, value => Dumper($value);
        trace __x"We are looking for value being equal to {needle}", needle => $needle->sprefix if $needle;
        if (
            ($options{find_value} && $value eq 'value')
            || $needle->sprefix eq $value)
        {
            trace "Incrementing key and value counters";
            $stash->{$key}++;
            $stash->{$value}++;
            if ($jp->{parent} && !$stash->{parents_included}->{$jp->{parent}->id})
            {
                trace "Incrementing value count to account for parent";
                $stash->{value}++;
                $stash->{parents_included}->{$jp->{parent}->id} = 1;
            }
            if (!$options{find_value}
                && $needle->field eq $key && _compare_parents($options{parent}, $jp->{parent}))
            {
                trace "We have a match, returning";
                return $stash->{$value};
            }
        }
    }
    elsif (ref $jp->{join} eq 'ARRAY')
    {
        trace "This join is an array";
        foreach (@{$jp->{join}})
        {
            my $n = _find($needle, $_, $stash);
            trace "Return from find is $n";
            return $n if $n;
        }
    }
    else {
        trace "This join is a standard join";
        $stash->{$jp->{join}}++;
        if ($jp->{parent} && !$stash->{parents_included}->{$jp->{parent}->id})
        {
            $stash->{value}++ if $jp->{parent}->value_field eq 'value';
            $stash->{parents_included}->{$jp->{parent}->id} = 1;
        }
        if (!$options{find_value} && $needle->sprefix eq $jp->{join})
        {
            # Single table join
            if (_compare_parents($options{parent}, $jp->{parent})
                # Account for autocur joins, in which case only match when
                # it's the one we need
                && ($needle->sprefix ne 'current' || $needle->id == $jp->{column}->id))
            {
                trace "We have a match";
                return $stash->{$needle->sprefix};
            }
        }
    }
    trace "No match";
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
    my $tn = $self->table_name($column, %options);
    "$tn." . $column->value_field;
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
    parent   => $parent_id,
    children => $children
},";
    my $space = '    ' x $indent;
    $ret =~ s/^(.*)$/$space$1/mg;
    $ret;
}

sub _dump_jp_store
{   my $self = shift;
    return;
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
        curval   => $jp->{curval},
        children => $children
    },
";
    }
    trace "$dumped\n";
}

1;

