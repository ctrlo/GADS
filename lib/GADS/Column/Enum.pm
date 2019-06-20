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

package GADS::Column::Enum;

use Log::Report 'linkspace';

use Moo;
use MooX::Types::MooseLike::Base qw/ArrayRef HashRef/;

extends 'GADS::Column';

has enumvals => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $sort = $self->ordering && $self->ordering eq 'asc'
            ? 'me.value'
            : $self->ordering && $self->ordering eq 'desc'
            ? { -desc => 'me.value' }
            : ['me.position', 'me.id'];
        my $enumrs = $self->schema->resultset('Enumval')->search({
            layout_id => $self->id,
            deleted   => 0,
        }, {
            order_by => $sort
        });
        $enumrs->result_class('DBIx::Class::ResultClass::HashRefInflator');
        my @enumvals = $enumrs->all;
        \@enumvals;
    },
    trigger => sub {
        my $self = shift;
        $self->_clear_enumvals_index;
    },
    coerce => sub {
        # Deal with submitted values straight from a HTML form. These will be
        # *all* submitted parameters, so we need to pull out only the relevant
        # ones.  We submit like this and not using a single array parameter to
        # ensure we keep the IDs intact.
        my $values = shift;
        ref $values eq 'ARRAY' and return $values; # From DB, already correct
        my @enumvals;
        my @enumvals_in = @{$values->{enumvals}};
        my @enumval_ids = @{$values->{enumval_ids}};
        foreach my $v (@enumvals_in)
        {
            my $id = shift @enumval_ids;
            if (!$id) # New one
            {
                push @enumvals, {
                    value => $v, # New, no ID
                };
            }
            else {
                push @enumvals, {
                    id    => $id,
                    value => $v,
                };
            }
        }

        \@enumvals;
    },
);

sub id_as_string
{   my ($self, $id) = @_;
    $id or return undef;
    $self->enumval($id)->{value};
}

# Indexed list of enumvals
has _enumvals_index => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        my %enumvals = map {$_->{id} => $_} @{$self->enumvals};
        \%enumvals;
    },
);

has ordering => (
    is  => 'rw',
    isa => sub {
        !defined $_[0] || $_[0] eq "desc" || $_[0] eq "asc"
            or error "Invalid enum order value: {ordering}", ordering => $_[0];
    }
);

sub value_field_as_index
{   return 'id';
}

has '+can_multivalue' => (
    default => 1,
);

has '+has_filter_typeahead' => (
    default => 1,
);

has '+fixedvals' => (
    default => 1,
);

sub _build_sprefix { 'value' };

after build_values => sub {
    my ($self, $original) = @_;
    $self->ordering($original->{ordering});
};

sub _build_retrieve_fields
{   my $self = shift;
    [qw/id value deleted/];
}

sub write_special
{   my ($self, %options) = @_;

    my $id           = $options{id};
    my $rset         = $options{rset};
    my $enum_mapping = $options{enum_mapping};

    my $position;
    foreach my $en (@{$self->enumvals})
    {
        my $value = $en->{value};
        error __x"{value} is not a valid value for an item of a drop-down list",
            value => ($value ? qq('$value') : 'A blank value')
            unless $value =~ /^[ \S]+$/;
        $position++;
        if ($en->{id})
        {
            my $enumval = $options{create_missing_id}
                ? $self->schema->resultset('Enumval')->find_or_create({ id => $en->{id}, layout_id => $id })
                : $self->schema->resultset('Enumval')->find($en->{id});
            $enumval or error __x"Bad ID {id} for multiple select update", id => $en->{id};
            $enumval->update({ value => $en->{value}, position => $en->{position} || $position });
        }
        else {
            my $new = $self->schema->resultset('Enumval')->create({
                value     => $en->{value},
                layout_id => $id,
                position  => $en->{position} || $position,
            });
            $en->{id} = $new->id;
        }
        $enum_mapping->{$en->{source_id}} = $en->{id}
            if $enum_mapping;
    }

    # Then delete any that no longer exist
    $self->_delete_unused_nodes;
    $rset->update({
        ordering => $self->ordering,
    });

    return ();
};

sub tjoin
{   my $self = shift;
    +{$self->field => 'value'};
}

sub previous_values_prefix
{   my $self = shift;
    'value';
}

sub previous_values_join
{   my $self = shift;
    'value';
}

sub validate
{   my ($self, $value, %options) = @_;
    return 1 if !$value;
    if (!defined $self->enumval($value)) # unchanged deleted value
    {
        return 0 unless $options{fatal};
        error __x"'{int}' is not a valid enum ID for '{col}'",
            int => $value, col => $self->name;
    }
    1;
}

# Any value is valid for a search, as it can include begins_with etc
sub validate_search {1};

sub cleanup
{   my ($class, $schema, $id) = @_;
    # Rely on tree cleanup instead. If we have our own here, then
    # it may error for tree types if the rows reference parents.
};

sub enumval
{   my ($self, $id) = @_;
    return unless $id;
    $self->_enumvals_index->{$id};
}

sub random
{   my $self = shift;
    my %hash = %{$self->_enumvals_index};
    return unless %hash;
    $hash{(keys %hash)[rand keys %hash]}->{value};
}

sub _enumvals_from_form
{   my $self = shift;

}
   
sub _delete_unused_nodes
{   my $self = shift;

    my @all = $self->schema->resultset('Enumval')->search({
        layout_id => $self->id,
    })->all;

    foreach my $node (@all)
    {
        next if $node->deleted; # Already deleted
        unless (grep {$node->id == $_->{id}} @{$self->enumvals})
        {
            my $count = $self->schema->resultset('Enum')->search({
                layout_id => $self->id,
                value     => $node->id
            })->count; # In use somewhere
            if ($count)
            {
                $node->update({ deleted => 1 });
            }
            else {
                $node->delete;
            }
        }
    }
}

sub resultset_for_values
{   my $self = shift;
    return $self->schema->resultset('Enumval')->search({
        layout_id => $self->id,
        deleted   => 0,
    });
}

before import_hash => sub {
    my ($self, $values, %options) = @_;
    my $report = $options{report_only} && $self->id;
    my @new = @{$values->{enumvals}};
    my @to_write;
    # We have no unqiue identifier with which to match, so we have to compare
    # the new and the old lists to try and work out what's changed. Simple
    # changes are handled automatically, more complicated ones will require
    # manual intervention
    if (my @old = @{$self->enumvals})
    {
        @old = sort { $a->{id} <=> $b->{id} } @old;
        @new = sort { $a->{id} <=> $b->{id} } @new;
        while (@old)
        {
            my $old = shift @old;
            my $new = shift @new;
            # If it's the same, easy, onto the next one
            if ($old->{value} eq $new->{value})
            {
                trace __x"No change for enum value {value}", value => $old->{value}
                    if $report;
                $new->{source_id} = $new->{id};
                $new->{id} = $old->{id};
                push @to_write, $new;
                next;
            }
            # Different. Is the next one the same?
            if ($old[0] && $new[0] && $old[0]->{value} eq $new[0]->{value})
            {
                # Yes, assume the previous is a value change
                notice __x"Changing enum value {old} to {new}", old => $old->{value}, new => $new->{value}
                    if $report;
                $new->{source_id} = $new->{id};
                $new->{id} = $old->{id};
                push @to_write, $new;
            }
            elsif ($options{force})
            {
                notice __x"Unknown enumval update {value}, forcing as requested", value => $new->{value};
                $new->{source_id} = delete $new->{id};
                push @to_write, $new;
            }
            else {
                # Different, don't know what to do, require manual intervention
                if ($report)
                {
                    notice __x"Error: don't know how to handle enumval updates for {name}, manual intervention required",
                        name => $self->name;
                    return;
                }
                else {
                    error __x"Error: don't know how to handle enumval updates for {name}, manual intervention required",
                        name => $self->name;
                }
            }
        }
        # Add any remaining new ones
        $_->{source_id} = delete $_->{id} foreach @new;
        push @to_write, @new;
    }
    else {
        $_->{source_id} = delete $_->{id} foreach @new;
        @to_write = @new;
    }
    $self->enumvals(\@to_write);
    $self->ordering($values->{ordering});
};

around export_hash => sub {
    my $orig = shift;
    my ($self, $values) = @_;
    my $hash = $orig->(@_);
    $hash->{enumvals} = $self->enumvals;
    $hash->{ordering} = $self->ordering;
    return $hash;
};

sub import_value
{   my ($self, $value) = @_;

    $self->schema->resultset('Enum')->create({
        record_id    => $value->{record_id},
        layout_id    => $self->id,
        child_unique => $value->{child_unique},
        value        => $value->{value},
    });
}

1;

