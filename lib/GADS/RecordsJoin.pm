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

    my $jp_store          = $self->_jp_store;

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
            $j->{prefetch} ||= $options{prefetch};
            $j->{search}   ||= $options{search};
            $j->{linked}   ||= $options{linked};
            $j->{sort}     ||= $options{sort};
            return;
        }
    }

    # Otherwise add it
    push @$jp_store, {
        join     => $toadd,
        prefetch => $options{prefetch}, # Whether values should be retrieved
        search   => $options{search},   # Whether it's used in a WHERE clause
        linked   => $options{linked},   # Whether it's a linked table
        sort     => $options{sort},     # Whether it's used in an order_by clause
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

sub _jpfetch
{   my ($self, %options) = @_;
    my @return;
    foreach (@{$self->_jp_store})
    {
        next if !$options{linked} && $_->{linked};
        next if $options{linked} && !$_->{linked};
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
    my $jn = $self->_join_number($column, %options);
    my $index = $jn > 1 ? "_$jn" : '';
    $column->sprefix . $index;
}

sub _join_number
{   my ($self, $column, %options) = @_;

    my %found; my $key;
    my $join = $column->join;
    ($key) = keys %$join if ref $join eq 'HASH';

    # Need prefetches then joins to get the correct key numbers for DBIC
    my @store = $self->_jpfetch(%options);
    foreach my $j (@store)
    {
        if ($key && ref $j->{join} eq 'HASH')
        {
            $found{$key}++;
            return $found{$key} if Compare $join, $j->{join};
        }
        elsif ($join eq $j->{join})
        {
            return 1;
        }
    }
    # This shouldn't happen. If we get here then we're trying to get a
    # join number for a table that hasn't been added.
    my $cid = $column->id;
    panic "Unable to get join number: column $cid hasn't been added";

}

# Return a fully-qualified value field for a table
sub fqvalue
{   my ($self, $column, %options) = @_;
    my $tn = $self->table_name($column, %options);
    "$tn." . $column->value_field;
}

1;

