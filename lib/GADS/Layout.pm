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

package GADS::Layout;

use GADS::Schema;
use GADS::View;
use Log::Report;
use String::CamelCase qw(camelize);

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);

sub all
{   my ($class, $new) = @_;
    if ($new)
    {
        my $count = 0;
        foreach my $v (@{$new->{id}})
        {
            my $field;
            $field->{name} = $new->{name}[$count];
            $field->{type} = $new->{type}[$count];
            $field->{permission} = $new->{permission}[$count];
            rset('Layout')->find($v)->update($field);
            $count++;
        }
    }
    my @layout = rset('Layout')->search({},{ order_by => 'position' })->all;
    \@layout;
}

sub _delete_unused_nodes
{
    my ($layout_id, $dbids) = @_;

    my @top = rset('Enumval')->search({
        layout_id => $layout_id,
        parent    => undef
    })->all;

    sub _flat
    {
        my ($start, $flat, $level) = @_;
        push @$flat, { id => $start->id, level => $level, deleted => $start->deleted, parent => $start->parent ? $start->parent->id : undef };
        # See if it has any children
        my @children = rset('Enumval')->search({ parent => $start->id })->all;
        foreach my $child (@children)
        {
            _flat($child, $flat, $level + 1);
        }
    };

    # Now collect all the nodes in a flat structure. We can only delete
    # from the children up, otherwise there are relationship constraints.
    # We actually only delete nodes that aren't referenced anywhere, in
    # order to keep data integrity for old records
    my @flat;
    foreach (@top)
    {
        _flat $_, \@flat, 0;
    }
    @flat = sort { $b->{level} <=> $a->{level} } @flat;

    # Do the actual deletion if they don't exist
    foreach my $node (@flat)
    {
        next if $node->{deleted}; # Already deleted
        if (grep {$node->{id} == $_} @$dbids)
        {
            # Current node still exists, but its parent doesn't
            # Move current node to the top by undefing the parent
            if ($node->{parent} && not grep {$node->{parent} == $_} @$dbids)
            {
                rset('Enumval')->find($node->{id})->update({ parent => undef });
            }
        }
        else
        {
            my $count = rset('Enum')->search({ layout_id => $layout_id, value => $node->{id} })->count; # In use somewhere
            my $haschild = grep {$_->{parent} && $node->{id} == $_->{parent}} @flat;                   # Has (deleted) children
            if ($count || $haschild)
            {
                rset('Enumval')->find($node->{id})->update({ deleted => 1 });
            }
            else {
                rset('Enumval')->find($node->{id})->delete;
            }
        }
    }
}

sub _collate;

sub tree
{   my ($class, $layout_id, $args) = @_;

    sub update
    {
        my ($layout_id, $t, $dbids) = @_;

        my $parent = $t->{parent} || '#';
        $parent = undef if $parent eq '#'; # Hash is top of tree (no parent)

        my $dbt;
        if ($t->{id} =~ /^[0-9]+$/)
        {
            # existing entry
            ($dbt) = rset('Enumval')->search({
                layout_id => $layout_id,
                id        => $t->{id},
            })->all;
        }
        if ($dbt)
        {
            $dbt->update({
                parent => $parent,
                value  => $t->{text},
            });
        }
        else {
            # new entry
            $dbt = rset('Enumval')->create({
                layout_id => $layout_id,
                parent    => $parent,
                value     => $t->{text},
            });
        }

        push @$dbids, $dbt->id;

        foreach my $child (@{$t->{children}})
        {
            $child->{parent} = $dbt->id;
            update($layout_id, $child, $dbids);
        }
    };

    # Update tree if new value provided
    if (my $tree = $args->{tree})
    {
        my $dbids = []; # Array of all database IDs. We'll delete any no longer existant after update

        # Do any updates
        foreach my $t (@$tree)
        {
            update $layout_id, $t, $dbids;
        }

        _delete_unused_nodes($layout_id, $dbids);
    }

    my $selected;
    if (my $value = $args->{value})
    {
        # Specify which record's value to initially select
        $selected = $value;
    }

    sub _collate
    {
        my ($start, $selected, $all) = @_;

        # See if it has any children
        my @children = grep
        {
            my $p = $_->get_column('parent');
            $p && $p == $start->id;
        }
        @$all;

        my @cc;
        foreach my $child (@children)
        {
            push @cc, _collate($child, $selected, $all);
        }
        my $sbool = $selected && $selected == $start->id ? 1 : 0;
        my $item = {
            id       => $start->id,
            text     => $start->value,
            state => {selected => \$sbool},
        };
        $item->{children} = \@cc if @cc;
        return $item;
    };

    return [] unless $layout_id;

    my @all = rset('Enumval')->search({
        layout_id => $layout_id,
        deleted   => 0
    },{
        order_by  => 'value'
    })->all;

    my @top = grep { not defined $_->get_column('parent') } @all;
    my @tree;
    foreach (@top)
    {
        push @tree, _collate($_, $selected, \@all);
    }
    \@tree;
}

sub delete
{   my ($class, $id) = @_;
    my $item = rset('Layout')->find($id)
        or error __x"Unable to find item with ID {id}", id => $id;

    # First see if any views are conditional on this field
    if (my @deps = rset('Layout')->search({ display_field => $item->id })->all)
    {
        my @depsn = map { $_->name } @deps;
        my $dep   = join ', ', @depsn;
        error __x"The following fields are conditional on this field: {dep}.
            Please remove these conditions before deletion.", dep => $dep;
    }

    my @graphs = rset('Graph')->search(
        [
            { x_axis => $item->id   },
            { y_axis => $item->id   },
            { group_by => $item->id },
        ]
    )->all;
    if (@graphs)
    {
        my $g = join(q{, }, map{$_->title} @graphs);
        error __x"The following graphs references this field: {graph}. Please update them before deletion."
            , graph => $g;
    }
    rset('ViewLayout')->search({ layout_id => $item->id })->delete;
    rset('Filter')->search({ layout_id => $item->id })->delete;
    rset('Person')->search({ layout_id => $item->id })->delete;
    rset('Enum')->search({ layout_id => $item->id })->delete;
    rset('Calc')->search({ layout_id => $item->id })->delete;
    rset('Rag')->search({ layout_id => $item->id })->delete;
    rset('AlertCache')->search({ layout_id => $item->id })->delete;
    my $type = $item->type;
    if ($type eq 'tree')
    {
        _delete_unused_nodes($item->id, []);
        $type = 'enum';
    }
    elsif($type eq 'enum')
    {
        rset('Enumval')->search({ layout_id => $item->id })->delete;
    }
    elsif($type eq 'calc')
    {
        rset('Calcval')->search({ layout_id => $item->id })->delete;
    }
    elsif($type eq 'rag')
    {
        rset('Ragval')->search({ layout_id => $item->id })->delete;
    }
    my $table = camelize $type;
    rset($table)->search({ layout_id => $item->id })->delete;
    $item->delete;
}

sub position
{   my ($class, $params) = @_;
    foreach my $o (keys %$params)
    {
        next unless $o =~ /position([0-9]+)/;
        rset('Layout')->find($1)->update({ position => $params->{$o} });
    }
}

sub item
{   my ($self, $args) = @_;
    my $item;
    if($args->{submit})
    {
        my $newitem;
        $newitem->{optional} = $args->{optional} ? 1 : 0;
        $newitem->{hidden} = $args->{hidden} ? 1 : 0;
        $newitem->{remember} = $args->{remember} ? 1 : 0;
        ($newitem->{name} = $args->{name}) =~ /^[ \S]+$/ # Only normal spaces please
            or error __"Please enter a name for item";
        ($newitem->{type}       = $args->{type}) =~ /^(intgr|string|date|daterange|enum|tree|person|rag|calc|file)$/
            or error __x"Bad type {type} for item", type => $args->{type};
        ($newitem->{permission} = $args->{permission}) =~ /^[012]$/
            or error __x"Bad permission {permission} for item", permission => $args->{permission};
        $newitem->{description} = $args->{description};
        $newitem->{helptext}    = $args->{helptext};

        $newitem->{display_field} = ($args->{display_condition} && grep {$args->{display_field} == $_->id} @{$self->all})
                                  ? $args->{display_field}
                                  : undef;

        $newitem->{display_regex} = $args->{display_regex};

        my @enumvals;
        if ($args->{type} eq 'enum')
        {
            sub collectenum
            {
                my ($value, $index) = @_;
                error __x"'{value}' is not a valid value for the multiple select", value => $value
                    unless $value =~ /^[ \S]+$/;
                my $p = {
                    index => $index,
                    value => $value,
                };
                return $p;
            };
            # Collect all the enum values. These can be in a variety of formats. New
            # ones will be a scalar for a single one or an arrayref for multiples.
            # Existing ones will have a unique field ID. This is maintained to retain
            # the data associated with that entry.
            foreach my $v (keys %$args)
            {
                next unless $v =~ /^enumval(\d*)/;
                if (ref $args->{$v} eq 'ARRAY')
                {
                    foreach my $w (@{$args->{$v}})
                    {
                        my $e = collectenum($w, 0);
                        push @enumvals, $e if $e;
                    }
                }
                else {
                    my $e = collectenum($args->{$v}, $1);
                    push @enumvals, $e if $e;
                }
            }

            # Finally save the ordering value
            $newitem->{ordering} = $args->{ordering} eq "desc"
                                 ? "desc"
                                 : $args->{ordering} eq "asc"
                                 ? "asc"
                                 : undef;
        } elsif ($args->{type} eq "tree")
        {
            $newitem->{end_node_only} = $args->{end_node_only} ? 1 : 0;
        }
            
        if ($args->{id})
        {
            $item = rset('Layout')->find($args->{id})
                or error __x"Unable to find item with ID {id}", id => $args->{id};
            $item = $item->update($newitem);

            if ($item->type eq 'enum')
            {
                # Trees are dealt with separately using AJAX calls
                # First insert and update values
                foreach my $en (@enumvals)
                {
                    if ($en->{index})
                    {
                        my $enumval = rset('Enumval')->find($en->{index})
                            or error __x"Bad index {index} for multiple select update", index => $en->{index};
                        $enumval->update({ value => $en->{value} });
                    }
                    else {
                        my $new = rset('Enumval')->create({ value => $en->{value}, layout_id => $item->id });
                        $en->{index} = $new->id;
                    }
                }
                # Then delete any that no longer exist
                my @dbids = map {$_->{index}} @enumvals;
                _delete_unused_nodes($item->id, \@dbids);
                #foreach my $en ($item->enumvals->all)
                #{
                #    unless (grep {$_->{index} == $en->id} @enumvals)
                #    {
                #        # Don't actually delete if old records still reference the value
                #        # Set deleted flag instead
                #        if (rset('Enum')->search({ layout_id => $item->id, value => $en->id })->count)
                #        {
                #            $en->update({ deleted => 1 })
                #                or ouch 'dbfail', "Database error when deleting multiple select value $en->{value}";
                #        }
                #        else {
                #            $en->delete;
                #        }
                #    }
                #}
            }
        }
        else {
            # No ID - new item
            $item = rset('Layout')->create($newitem);
            foreach my $en (@enumvals)
            {
                rset('Enumval')->create({ value => $en->{value}, layout_id => $item->id });
            }
            if ($args->{type} eq 'tree')
            {
                # For new items of a tree, the nodes will have already been inserted
                # but with a layout_id of null. Now is the time to update them
                rset('Enumval')->search({ layout_id => undef })->update({ layout_id => $item->id });
            }
        }
        if ($args->{type} eq 'rag')
        {
            my $rag = {
                red   => $args->{red},
                amber => $args->{amber},
                green => $args->{green},
            };
            my ($ragr) = rset('Rag')->search({ layout_id => $item->id })->all;
            my $need_update;
            if ($ragr)
            {
                # First see if the calculation has changed
                $need_update =  $ragr->red ne $rag->{red}
                             || $ragr->amber ne $rag->{amber}
                             || $ragr->green ne $rag->{green};
                $ragr->update($rag);
                # Clear out cached calues. Will be auto-inserted later
            }
            else {
                $rag->{layout_id} = $item->id;
                rset('Rag')->create($rag);
                $need_update = 1;
            }
            if ($need_update)
            {
                # Get records first so that we have old values and fields needed for calc
                my $rag_col = GADS::View->columns({ id => $item->id });
                GADS::Record->update_cache($rag_col);
            }
        }
        if ($args->{type} eq 'calc')
        {
            my $calc = {
                calc          => $args->{calc},
                return_format => $args->{return_format} ? 'date' : '',
            };
            my ($calcr) = rset('Calc')->search({ layout_id => $item->id })->all;
            my $need_update;
            if ($calcr)
            {
                # First see if the calculation has changed
                $need_update = $calcr->calc ne $calc->{calc};
                $calcr->update($calc);
            }
            else {
                $calc->{layout_id} = $item->id;
                $calcr = rset('Calc')->create($calc);
                $need_update = 1;
            }
            if ($need_update)
            {
                # Get records first so that we have old values and fields needed for calc
                my $calc_col = GADS::View->columns({ id => $item->id });
                GADS::Record->update_cache($calc_col);
            }
        }
        if ($args->{type} eq 'file')
        {
            my $foption = {
                filesize => (int($args->{filesize}) || undef),
            };
            my ($file_option) = rset('FileOption')->search({ layout_id => $item->id })->all;
            if ($file_option)
            {
                $file_option->update($foption);
            }
            else {
                $foption->{layout_id} = $item->id;
                rset('FileOption')->create($foption);
            }
        }
    }
    else {
        ($item) = rset('Layout')->search({
            'me.id'  => $args->{id},
        },{
            prefetch => ['enumvals', 'calcs', 'rags' ],
            order_by => 'enumvals.id',
        })->all;
        $item or error __x"Unable to find item with ID {id}", id => $args->{id};
    }
    my $itemhash = {
        id            => $item->id,
        name          => $item->name,
        type          => $item->type,
        ordering      => $item->ordering,
        permission    => $item->permission,
        optional      => $item->optional,
        hidden        => $item->hidden,
        description   => $item->description,
        helptext      => $item->helptext,
        display_field => $item->display_field,
        display_regex => $item->display_regex,
        end_node_only => $item->end_node_only,
        remember      => $item->remember,
    };

    if ($item->type eq 'enum' || $item->type eq 'tree')
    {
            my @enumvals = $item->enumvals;
            $itemhash->{enumvals} = \@enumvals;
    }
    elsif ($item->type eq 'rag')
    {
        my ($rag) = rset('Rag')->search({ layout_id => $item->id });
        $itemhash->{rag} = $rag;
    }
    elsif ($item->type eq 'calc')
    {
        my ($calc) = rset('Calc')->search({ layout_id => $item->id });
        $itemhash->{calc} = $calc;
    }
    elsif ($item->type eq 'file')
    {
        my ($file_option) = rset('FileOption')->search({ layout_id => $item->id });
        $itemhash->{file_option} = $file_option;
    }
    $itemhash;
}

1;


