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
use Log::Report;
use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);

has _jp_store => (
    is      => 'rwp',
    isa     => ArrayRef,
    default => sub { [] },
);

sub _add_jp
{   my ($self, $column, %options) = @_;

    panic "Attempt to generate join for internal column"
        if $column->internal;

    my $jp_store = $self->_jp_store;
    my $key;
    my $toadd = $column->join;
    ($key) = keys %$toadd if ref $toadd eq 'HASH';

    # Check whether join is already in store, if so update
    foreach my $j (@$jp_store)
    {
        if (
            ($key && ref $j->{join} eq 'HASH' && Compare($toadd, $j->{join}))
            || $toadd eq $j->{join}
        )
        {
            $j->{prefetch} ||= !$column->multivalue && $options{prefetch};
            $j->{search}   ||= $options{search};
            $j->{linked}   ||= $options{linked};
            $j->{sort}     ||= $options{sort};
            return;
        }
    }

    # Otherwise add it
    push @$jp_store, {
        join       => $toadd,
        # Never prefetch multivalue columns, which can result in huge numbers of rows being retrieved.
        prefetch   => !$column->multivalue && $options{prefetch},   # Whether values should be retrieved
        search     => $options{search},     # Whether it's used in a WHERE clause
        linked     => $options{linked},     # Whether it's a linked table
        sort       => $options{sort},       # Whether it's used in an order_by clause
        curval     => $column->type eq 'curval' ? 1 : 0,
    };
}

sub add_prefetch
{   my $self = shift;
    $self->_add_jp(@_, prefetch => 1);
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

sub record_later_search
{   my ($self, %options) = @_;
    my $count = 1; # Always at least one
    $count++ if $options{linked};
    foreach (@{$self->_jp_store})
    {
        if ($_->{curval})
        {
            if ($options{search} && $_->{search})
            {
                $count++;
            }
            elsif ($options{sort} && $_->{sort})
            {
                $count++;
            }
            elsif ($options{prefetch} && $_->{prefetch})
            {
                $count++;
            }
        }
    }
    my $search;
    for (1..$count)
    {
        my $id = $_ == 1 ? '' : "_$_";
        $search->{"record_later$id.current_id"} = undef;
    }
    $search;
}

sub _jpfetch
{   my ($self, %options) = @_;
    my @return;
    foreach (@{$self->_jp_store})
    {
        next if !$options{linked} && $_->{linked};
        next if $options{linked} && !$_->{linked};
        next if exists $options{prefetch} && !$options{prefetch} && $_->{prefetch};
        if ($options{search} && $_->{search}) {
            push @return, $_;
            next;
        }
        if ($options{sort} && $_->{sort}) {
            push @return, $_;
            next;
        }
        if ($options{prefetch} && $_->{prefetch}) {
            push @return, $_;
            next;
        }
    }
    @return;
}

sub jpfetch
{   my $self = shift;
    map { $_->{join} } $self->_jpfetch(@_);
}

sub table_name
{   my ($self, $column, %options) = @_;
    if ($column->internal)
    {
        return 'me' if $column->name eq 'ID';
        return 'record_single' if $column->sprefix eq 'record';
        return $column->sprefix;
    }
    my $jn = $self->_join_number($column, %options);
    my $index = $jn > 1 ? "_$jn" : '';
    $column->sprefix . $index;
}

sub _join_number
{   my ($self, $column, %options) = @_;

    my $join = $column->join;

    # Find the correct join number, by iterating through all the current
    # joins, and jumping at the matching join with the count number.
    # Joins in the form "field{n} => value" will be counted as the same,
    # but only returned with an exact match.
    # If this is for a sort, then we need to adjust the options depending on
    # whether the sort is a column also included in a prefetch. If it's not,
    # then it will be first in the DBIC query, and therefore the number should
    # not include other prefetch joins.
    if ($options{sort} && $options{prefetch})
    {
        my ($jp) = grep { Compare $_->{join}, $join } @{$self->_jp_store};
        $options{prefetch} = $jp->{prefetch};
    }
    my @store = $self->_jpfetch(%options);
    my $stash = {};
    foreach my $j (@store)
    {
        my $n = _find($join, $j->{join}, $stash);
        return $n if $n;
    }

    # This shouldn't happen. If we get here then we're trying to get a
    # join number for a table that hasn't been added.
    my $cid = $column->id;
    panic "Unable to get join number: column $cid hasn't been added";
}

sub _find
{   my ($needle, $join, $stash) = @_;
    if (ref $join eq 'HASH')
    {
        my ($key, $value) = %$join;
        $stash->{$key}++;
        if (Compare $needle, $join)
        {
            # Multiple join, as in the case of enumvals
            # (field{n} => value)
            $stash->{$value}++;
            return $stash->{$value};
        }
        my $n = _find($needle, $value, $stash);
        return $n if $n;
    }
    elsif (ref $join eq 'ARRAY')
    {
        foreach (@$join)
        {
            my $n = _find($needle, $_, $stash);
            return $n if $n;
        }
    }
    else {
        $stash->{$join}++;
        if ($needle eq $join)
        {
            # Single table join
            return $stash->{$needle};
        }
    }
}

# Get the next join by the name of "value"
sub value_next_join
{   my ($self, %options) = @_;
    my $count = 1;
    foreach my $j ($self->_jpfetch(%options))
    {
        if (ref $j->{join})
        {
            my ($val) = values %{$j->{join}};
            $count++ if $val eq 'value';
        }
    }
    my $id = $count == 1 ? '' : "_$count";
    "value$id";
}

# Return a fully-qualified value field for a table
sub fqvalue
{   my ($self, $column, %options) = @_;
    my $tn = $self->table_name($column, %options);
    "$tn." . $column->value_field;
}

1;

