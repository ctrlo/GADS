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

package GADS::Column::Tree;

use JSON qw(decode_json encode_json);
use Log::Report 'linkspace';
use String::CamelCase qw(camelize);
use Tree::DAG_Node;

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

sub DESTROY
{   my $self = shift;
    $self->_root->delete_tree if $self->_has_tree;
}

sub value_field_as_index
{   return 'id';
}

has '+has_filter_typeahead' => (
    default => 1,
);

has '+fixedvals' => (
    default => 1,
);

has '+can_multivalue' => (
    default => 1,
);

sub _build_sprefix { 'value' };

sub _build_retrieve_fields
{   my $self = shift;
    [qw/id value/];
}

has end_node_only => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    default => 0,
);

# The root node, which all other nodes are referenced from.
# Gets value from _tree once it's built
has _root => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_tree->{root} },
);

# A hash of all the tree nodes. Also gets value from
# _tree once it's built. Contains only DAG_Node nodes
has _nodes => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_tree->{nodes} },
    clearer => 1,
);

# An array of all the enumvals. Also gets value from
# _tree once it's built. Contains the enumvals with
# their actual values in, but no tree relationship info
has enumvals => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _build_enumvals
{   my $self = shift;
    my $enumrs = $self->schema->resultset('Enumval')->search({
        layout_id => $self->id,
    },{
        order_by => 'me.value',
    });
    $enumrs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @enumvals = $enumrs->all;
    \@enumvals;
}

has _enumvals_index => (
    is      => 'rwp',
    isa     => HashRef,
    lazy    => 1,
    builder => 1,
    clearer => 1,
);

sub _build__enumvals_index
{   my $self = shift;
    my %enumvals = map {$_->{id} => $_} @{$self->enumvals};
    \%enumvals;
}

sub tjoin
{   my $self = shift;
    +{$self->field => 'value'};
}

# The whole tree, constructed here so that it only
# needs to be done once
has _tree => (
    is        => 'rw',
    lazy      => 1,
    clearer   => 1,
    builder   => 1,
    predicate => 1,
);

# The original values hash
has original => (
    is => 'rw',
);

after build_values => sub {
    my ($self, $original) = @_;
    $self->original($original);
    $self->end_node_only($original->{end_node_only});
};

sub _build_table
{   my $self = shift;
    'Enum';
}

sub write_special
{   my ($self, %options) = @_;
    my $rset = $options{rset};
    $rset->update({
        end_node_only => $self->end_node_only,
    });
    return ();
};

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Enum')->search({ layout_id => $id })->delete;
    $schema->resultset('Enumval')->search({ layout_id => $id })->update({parent => undef});
    $schema->resultset('Enumval')->search({ layout_id => $id })->delete;
}

after 'delete' => sub {
    my $self = shift;
    $self->clear;
};

sub clear
{   my $self = shift;
    $self->_clear_nodes;
    $self->clear_enumvals;
    $self->_clear_enumvals_index;
    $self->_root->delete_tree if $self->_has_tree;
    $self->_clear_tree;
}

sub validate
{   my ($self, $value, %options) = @_;
    return 1 if !$value;

    if (!$self->node($value))
    {
        return 0 unless $options{fatal};
        error __x"'{int}' is not a valid tree node ID for '{col}'",
            int => $value, col => $self->name;
    }
    if ($self->node($value)->{node}->{attributes}->{deleted})
    {
        return 0 unless $options{fatal};
        error __x"Node '{int}' has been deleted and can therefore not be used"
            , int => $value;
    }
    1;
}

sub validate_search {1} # Anything is valid as a search value

# Get a single node value
sub node
{   my ($self, $id) = @_;

    $id or return;
    $self->_nodes->{$id} or return;

    {
        node  => $self->_nodes->{$id},
        value => $self->_enumvals_index->{$id}->{value},
    }
}

sub _build__tree
{   my $self = shift;

    my $enumvals;
    my $tree = {};
    my @order;
    my @enumvals = @{$self->enumvals};
    foreach my $enumval (@enumvals)
    {
        # If a node is deleted then still add to the tree, in case it is still
        # in use and needed for things like code evaluation. However, don't add
        # it in the tree with a parent, just have it "loose"
        my $parent = !$enumval->{deleted} && $enumval->{parent}; # && $enum->parent->id;
        my $node = Tree::DAG_Node->new();
        $node->name($enumval->{id});
        $tree->{$enumval->{id}} = {
            node       => $node,
            parent     => $parent,
            attributes => {
                deleted => $enumval->{deleted},
            },
        };
        # Keep order in a list
        push @order, $enumval->{id};
        # Store the entire value for retrieval later
        $enumvals->{$enumval->{id}} = $enumval;
    }

    my $root = Tree::DAG_Node->new();
    $root->name("Root");

    foreach my $n (@order)
    {
        my $node = $tree->{$n};
        if (my $parent = $node->{parent})
        {
            $tree->{$parent}->{node}->add_daughter($node->{node});
        }
        else {
            $root->add_daughter($node->{node});
        }
    }

    {
        nodes    => $tree,
        root     => $root,
        enumvals => $enumvals,
    }
}

sub json
{   my ($self, @selected) = @_;

    my %selected = map { $_ => 1 } @selected;

    my $stash = {
        tree => {
            text => "root"
        },
    };
    my $root = $self->_root;
    return [] unless $root->depth_under; # No nodes
    $root->walk_down
    ({
        callback => sub
        {
                my($node, $options) = @_;
                my $depth = $options->{_depth};
                if ($depth == 0)
                {
                    # Starting out at root
                    $options->{stash}->{last_node}->{$depth} = $stash->{tree};
                }
                elsif (!$self->_enumvals_index->{$node->name}->{deleted}) # Ignore deleted nodes
                {
                    my $parent = $options->{stash}->{last_node}->{$depth-1};
                    my $text = $self->_enumvals_index->{$node->name}->{value};
                    $parent->{children} = [] unless $parent->{children};
                    my $leaf = {
                        text => $text,
                        id   => $node->name,
                    };
                    $leaf->{state} = {selected => \1} if $selected{$node->name};
                    push @{$parent->{children}}, $leaf;
                    $options->{stash}->{last_node}->{$depth} = $parent->{children}->[-1];
                }
                return 1; # Keep walking.
        },
        _depth => 0,
        stash  => $stash,
    });
    $stash->{tree}->{children};
}

sub _delete_unused_nodes
{   my ($self, %options) = @_;

    # Get all ones currently in database. This will be different to
    # the ones currently in _enumvals_index
    my $node_rs = $self->schema->resultset('Enumval')->search({
        layout_id => $self->id,
    });
    $node_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @all_nodes = $node_rs->all;

    my @top = grep { !$_->{parent} } @all_nodes;

    sub _flat
    {
        my ($self, $start, $flat, $level, @all_nodes) = @_;
        push @$flat, {
            id      => $start->{id},
            level   => $level,
            deleted => $start->{deleted},
            parent  => $start->{parent},
        };
        # See if it has any children
        my @children = grep { $_->{parent} && $_->{parent} == $start->{id} } @all_nodes;
        foreach my $child (@children)
        {
            _flat($self, $child, $flat, $level + 1, @all_nodes);
        }
    };

    # Now collect all the nodes in a flat structure. We can only delete
    # from the children up, otherwise there are relationship constraints.
    # We actually only delete nodes that aren't referenced anywhere, in
    # order to keep data integrity for old records
    my $flat = [];
    foreach (@top)
    {
        _flat $self, $_, $flat, 0, @all_nodes;
    }
    my @flat = sort { $b->{level} <=> $a->{level} } @$flat;

    # Do the actual deletion if they don't exist
    foreach my $node (@flat)
    {
        next if $node->{deleted}; # Already deleted
        if ($self->_enumvals_index->{$node->{id}})
        {
            # Node in use somewhere
            if ($node->{parent}
                && (!$self->_enumvals_index->{$node->{parent}} || $self->_enumvals_index->{$node->{parent}}->{deleted})
            )
            {
                # Current node still exists, but its parent doesn't
                # Move current node to the top by undefing the parent
                $self->schema->resultset('Enumval')->find($node->{id})->update({
                    parent => undef
                });
            }
        }
        else
        {
            my $count = $self->schema->resultset('Enum')->search({
                layout_id => $self->id,
                value     => $node->{id}
            })->count; # In use somewhere
            my $haschild = grep {$_->{parent} && $node->{id} == $_->{parent}} @flat; # Has (deleted) children
            if ($count || $haschild)
            {
                $self->schema->resultset('Enumval')->find($node->{id})->update({
                    deleted => 1
                });
            }
            else {
                $self->schema->resultset('Enumval')->find($node->{id})->delete;
            }
        }
    }
}

sub random
{   my $self = shift;
    my %hash = %{$self->_enumvals_index};
    my $value;
    while (!$value)
    {
        my $node = $hash{(keys %hash)[rand keys %hash]};
        $value = $node->{value} unless $node->{deleted};
    }
    $value;
}

sub update
{   my ($self, $tree) = @_;

    # Create a new hash ref with our new tree structure in. We'll copy
    # the new nodes into it as we go, and then compare it to the old
    # one after to know which ones to delete from the database
    my $new_tree = {};

    # Do any updates
    foreach my $t (@$tree)
    {
        $self->_update($t, $new_tree);
    }

    $self->_set__enumvals_index($new_tree);
    $self->_delete_unused_nodes;
    $self->clear;
}

sub _update
{   my ($self, $t, $new_tree) = @_;

    my $parent = $t->{parent} || '#';
    $parent = undef if $parent eq '#'; # Hash is top of tree (no parent)

    my $dbt;
    if ($t->{id} && $t->{id} =~ /^[0-9]+$/)
    {
        # existing entry
        $dbt = $self->_enumvals_index->{$t->{id}};
    }
    if ($dbt)
    {
        if ($dbt->{value} ne $t->{text})
        {
            $self->schema->resultset('Enumval')->find($t->{id})->update({
                parent => $parent,
                value  => $t->{text},
            });
        }
        $new_tree->{$dbt->{id}} = $dbt;
    }
    else {
        # new entry
        $dbt = {
            layout_id => $self->id,
            parent    => $parent,
            value     => $t->{text},
        };
        my $id = $self->schema->resultset('Enumval')->create($dbt)->id;
        $dbt->{id} = $id;
        # Add to existing cache.
        $new_tree->{$id} = $dbt;
    }

    foreach my $child (@{$t->{children}})
    {
        $child->{parent} = $dbt->{id};
        $self->_update($child, $new_tree);
    }
};

sub resultset_for_values
{   my $self = shift;
    if ($self->end_node_only)
    {
        $self->schema->resultset('Enumval')->search({
            'me.layout_id' => $self->id,
            'me.deleted'   => 0,
            'enumvals.id'  => undef,
        },{
            join => 'enumvals',
        });
    }
    else {
        $self->schema->resultset('Enumval')->search({
            layout_id => $self->id,
            deleted   => 0,
        });
    }
}

sub _import_branch
{   my ($self, $old_in, $new_in, $report) = @_;
    my @old = sort { $a->{text} cmp $b->{text} } @$old_in;
    my @new = sort { $a->{text} cmp $b->{text} } @$new_in;
    my @to_write;
    while (@old)
    {
        my $old = shift @old;
        my $new = shift @new;
        # If it's the same, easy, onto the next one
        if ($old->{text} eq $new->{text})
        {
            notice __x"No change for tree value {value}", value => $old->{text}
                if $report;
            $new->{id} = $old->{id};
            push @to_write, $new;
        }
        # Different. Is the next one the same?
        elsif ($old[0] && $new[0] && $old[0]->{text} eq $new[0]->{text})
        {
            # Yes, assume the previous is a value change
            notice __x"Changing tree value {old} to {new}", old => $old->{text}, new => $new->{text}
                if $report;
            $new->{id} = $old->{id};
            push @to_write, $new;
        }
        # Is the next new one the same as the current old one?
        elsif ($new[0] && $old->{text} eq $new[0]->{text})
        {
            # Yes, assume new value
            notice __x"Adding tree value {new}", new => $new->{text}
                if $report;
            delete $new->{id};
            push @to_write, $new;
            # Add old one back onto stack for processing next loop
            unshift @old, $old;
        }
        else {
            # Different, don't know what to do, require manual intervention
            if ($report)
            {
                notice __x"Error: don't know how to handle tree updates, manual intervention required."
                    ." (failed at old {old} new {new})", old => $old->{text}, new => $new->{text};
                return;
            }
            else {
                error __x"Error: don't know how to handle tree updates, manual intervention required";
            }
        }
        if ($new->{children} && @{$new->{children}})
        {
            $new->{children} = [$self->_import_branch($old->{children}, $new->{children}, $report)];
        }
    }
    # Add any remaining new ones
    delete $_->{id} foreach @new;
    push @to_write, @new;
    return @to_write;
}

sub import_after_write
{   my ($self, $values, %options) = @_;
    my $report = $options{report_only};
    my @new = @{$values->{tree}};

    my @to_write;
    # Same as enumval: We have no unqiue identifier with which to match, so we
    # have to compare the new and the old lists to try and work out what's
    # changed. Simple changes are handled automatically, more complicated ones
    # will require manual intervention
    if (my @old = @{$self->json})
    {
        @to_write = $self->_import_branch(\@old, \@new, $report);
    }
    else {
        delete $_->{id} foreach @new;
        @to_write = @new;
    }

    $self->update(\@to_write);
}

before import_hash => sub {
    my ($self, $values, %options) = @_;
    my $report = $options{report_only} && $self->id;
    notice __x"Update: end_node_only from {old} to {new}", old => $self->end_node_only, new => $values->{end_node_only}
        if $report && $self->end_node_only != $values->{end_node_only};
    $self->end_node_only($values->{end_node_only});
};

around export_hash => sub {
    my $orig = shift;
    my ($self, $values) = @_;
    my $hash = $orig->(@_);
    $hash->{end_node_only} = $self->end_node_only;
    $hash->{tree}          = $self->json; # Not actually JSON
    return $hash;
};

1;

