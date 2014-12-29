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

package GADS::View;

use GADS::Schema;
use GADS::Util        qw(:all);
use JSON qw(decode_json encode_json);
use Log::Report;
use String::CamelCase qw(camelize);

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);

schema->storage->debug(1); # Last module to load so sets for all

sub main($$)
{   my ($class, $user_id) = @_;
    my $view = rset('View')->search(
        {
            user => $user_id
        },
        {
            order_by => { -desc => 'main' },
            rows     => 1
        }
    );
    my ($v) = $view->all;
    $v = rset('View')->create({ user => $user_id, main => 1 })
        unless $v;
    $v->id;
}

sub _filter_tables
{   my ($filter, $tables) = @_;

    if (my $rules = $filter->{rules})
    {
        # Filter has other nested filters
        foreach my $rule (@$rules)
        {
            _filter_tables($rule, $tables);
        }
    }
    elsif (my $id = $filter->{id}) {
        $tables->{$filter->{id}} = 1;
    }
}

sub view
{   my ($self, $view_id, $user, $update) = @_;
    $view_id || $update or return;

    if ($update)
    {
        $user or error __"User ID needs to be supplied for view when updating";

        # First update selected columns
        my $params = {
            view_id => $view_id, # ID returned here in case of new view
            user    => $user,
        };

        $self->columns($params, $update);
        $view_id = $params->{view_id};

        # Pass the view ID back in case it was new
        $update->{view_id} = $view_id;

        # Then update any sorts
        $self->sorts($params->{view_id}, $update);

        # Finally update the filter.
        # First the text based filter, which is the one
        # actually used:
        rset('View')->find($view_id)->update({
            filter => $update->{filter},
        });
        # Then the filter table, which we use to query what fields are
        # applied to a view's filters when doing alerts
        my @existing = rset('Filter')->search({ view_id => $view_id })->all;
        my $decoded = decode_json($update->{filter});
        my $tables = {};
        _filter_tables $decoded, $tables;
        foreach my $table (keys $tables)
        {
            unless (grep { $_->layout_id == $table } @existing)
            {
                rset('Filter')->create({
                    view_id   => $view_id,
                    layout_id => $table,
                });
            }
        }
        # Delete those no longer there
        my $search = { view_id => $view_id };
        $search->{layout_id} = { '!=' => [ '-and', keys %$tables ] } if keys %$tables;
        rset('Filter')->search($search)->delete;
    }

    my $view = _get_view($view_id, $user->{id}); # Borks on invalid user for view
    my ($alert) = grep { $user->{id} && $user->{id} == $_->user_id } $view->alerts;
    my $sorts = $self->sorts($view->id);
    {
        id      => $view->id,
        user_id => $view->user_id,
        name    => $view->name,
        global  => $view->global,
        filter  => $view->filter,
        sorts   => $sorts,
        alert   => $alert,
    }
}

sub all
{   my ($class, $user_id) = @_;
    my @views = rset('View')->search({
        -or => [
            user_id => $user_id,
            global  => 1,
        ]
    },{
            order_by => ['global', 'name'],
    })->all;
    \@views;
}

sub delete
{   my ($class, $id, $user) = @_;

    my $view = _get_view($id, $user->{id}); # Borks on an error
    !$view->global || $user->{permission}->{layout}
        or error __x"You do not have permission to delete {id}", id => $id;
    rset('Sort')->search({ view_id => $view->id })->delete;
    rset('ViewLayout')->search({ view_id => $view->id })->delete;
    rset('Filter')->search({ view_id => $view->id })->delete;
    rset('AlertCache')->search({ view_id => $view->id })->delete;
    rset('Alert')->search({ view_id => $view->id })->delete;
    $view->delete;
}

# Any suffixes that may be valid when creating calc values
sub _suffix
{
    return '(\.from|\.to)' if shift eq 'daterange';
    return '';
}

sub _column_id
{
    {
        field   => 'current_id',
        type    => 'id',
        name    => 'id',
        suffix  => '',
        numeric => 1,
    };
}

sub _column
{
    my $col = shift;
    my $allcols = shift;
    my $c;
    
    my $field = "field".$col->id;

    if ($col->type eq 'enum' || $col->type eq 'tree' || $col->type eq 'person')
    {
        $c->{type} = $col->type;
        $c->{sprefix} = 'value';
        $c->{join}    = {$field => 'value'};
        if ($c->{type} eq 'enum')
        {
            my @enums = $col->enumvals;
            $c->{enumvals} = \@enums;
        }
        $c->{fixedvals} = 1;
    }
    else {
        $c->{type}      = $col->type;
        $c->{sprefix}   = $field;
        $c->{join}      = $field;
        $c->{fixedvals} = 0;
    }

    $c->{table} = $c->{type} eq 'tree' ? 'Enum' : camelize $c->{type};
    $c->{vtype} = ""; # Initialise default

    if ($col->type eq 'calc')
    {
        my ($calc) = $col->calcs;
        if ($calc) # Calculations defined?
        {
            my @calccols;
            foreach my $acol (@$allcols)
            {
                my $name = $acol->name; my $suffix = _suffix $acol->type;
                next unless $calc->calc =~ /\Q[$name\E$suffix\Q]/i;
                my $c = _column($acol);
                push @calccols, $c;
            }
            # Also check for special ID column
            push @calccols, _column_id
                if $calc->calc =~ /\Q[id]/i;

            $c->{calc} = {
                id      => $calc->id,
                calc    => $calc->calc,
                columns => \@calccols,
            };
            $c->{return_format} = $calc->return_format;
            $c->{vtype} = "date" if $c->{return_format} && $c->{return_format} eq "date";
        }

        $c->{table}     = "Calcval";
        $c->{userinput} = 0;
    }
    elsif ($col->type eq 'rag')
    {
        my ($rag) = $col->rags;
        if ($rag) # RAG defined?
        {
            my @ragcols;
            foreach my $acol (@$allcols)
            {
                my $name = $acol->name; my $suffix = _suffix $acol->type;
                my $regex = qr/\Q[$name\E$suffix\Q]/i;
                next unless $rag->green =~ $regex || $rag->amber =~ $regex || $rag->red =~ $regex;
                my $c = _column($acol);
                push @ragcols, $c;
            }
            # Also check for special ID column
            push @ragcols, _column_id
                if $rag->green =~ /\Q[id]/i || $rag->amber =~ /\Q[id]/i || $rag->red =~ /\Q[id]/i;

            $c->{rag} = {
                id      => $rag->id,
                green   => $rag->green,
                amber   => $rag->amber,
                red     => $rag->red,
                columns => \@ragcols,
            };
        }

        $c->{table}     = "Ragval";
        $c->{userinput} = 0;
    }
    elsif ($col->type eq 'file')
    {
        $c->{userinput} = 1;
        my ($file_option) = $col->file_options;
        if ($file_option)
        {
            $c->{file_option} = {
                filesize => $file_option->filesize,
            };
        }
    }
    else {
        $c->{userinput} = 1;
    }

    $c->{suffix}  = _suffix $col->type;
    if ($col->type eq 'daterange' || $col->type eq 'date' || $col->type eq 'intgr')
    {
        $c->{numeric} = 1;
    }
    else {
        $c->{numeric} = 0;
    }

    # See what columns depend on this one
    my @depends = grep {$_->display_field && $_->display_field->id == $col->id} @$allcols;
    my @depended_by = map { { id => $_->id, regex => $_->display_regex } } @depends;

    # Virtual type. Will definitely be date for date ;-)
    $c->{vtype} = 'date' if $c->{type} eq 'date';

    my @cached = qw(rag calc person daterange);
    $c->{hascache}      = grep( /^$c->{type}$/, @cached ),
    $c->{id}            = $col->id,
    $c->{name}          = $col->name,
    $c->{remember}      = $col->remember,
    $c->{ordering}      = $col->ordering,
    $c->{permission}    = $col->permission,
    $c->{readonly}      = $col->permission == READONLY ? 1 : 0;
    $c->{approve}       = $col->permission == APPROVE ? 1 : 0;
    $c->{open}          = $col->permission == OPEN ? 1 : 0;
    $c->{optional}      = $col->optional,
    $c->{hidden}        = $col->hidden,
    $c->{description}   = $col->description,
    $c->{display_field} = $col->display_field,
    $c->{display_regex} = $col->display_regex,
    $c->{depended_by}   = \@depended_by;
    $c->{helptext}      = $col->helptext,
    $c->{end_node_only} = $col->end_node_only,
    $c->{field}         = $field,

    $c;
}

sub columns
{   my ($class, $ident, $update) = @_;

    if ($update)
    {
        my $view_id;
        unless ($ident->{view_id})
        {
            my $new = rset('View')->create({
                user_id => $ident->{user}->{id}
            });
            $view_id = $new->id;
            $ident->{view_id} = $view_id;
        }
        else {
            $view_id = $ident->{view_id}; # or ouch 'badparam', "Please supply a view ID";
        }
        my $view = _get_view($view_id, $ident->{user}->{id}); # Borks on an error
        !$view->global || $ident->{user}->{permission}->{layout}
            or error __x"You do not have access to modify view {id}", id => $view_id;

        # Will be a scalar if only one value submitted. If so,
        # convert to array
        my @colviews = !$update->{column}
                     ? ()
                     : ref $update->{column} eq 'ARRAY'
                     ? @{$update->{column}}
                     : ( $update->{column} );

        foreach my $c (rset('Layout')->all)
        {
            next if !$ident->{user}->{permission}->{layout} && $c->hidden;
            my $item = { view_id => $view_id, layout_id => $c->id };
            if (grep {$c->id == $_} @colviews)
            {
                # Column should be in view
                unless(rset('ViewLayout')->search($item)->count)
                {
                    rset('ViewLayout')->create($item);
                    # Update alert cache with new column
                    my @alerts = rset('View')->search({
                        'me.id' => $view_id
                    },{
                        columns  => [
                            { 'me.id'  => \"MAX(me.id)" },
                            { 'alert_caches.id'  => \"MAX(alert_caches.id)" },
                            { 'alert_caches.current_id'  => \"MAX(alert_caches.current_id)" },
                        ],
                        join     => 'alert_caches',
                        group_by => 'current_id',
                    })->all;
                    my @pop;
                    foreach my $alert (@alerts)
                    {
                        push @pop, map { {
                            layout_id  => $c->id,
                            view_id    => $view_id,
                            current_id => $_->current_id
                        } } $alert->alert_caches;
                    }
                    rset('AlertCache')->populate(\@pop) if @pop;
                }
            }
            else {
                rset('ViewLayout')->search($item)->delete;
                # Also delete alert cache for this column
                rset('AlertCache')->search({
                    view_id   => $view_id,
                    layout_id => $c->id
                })->delete;
            }
        }
        my $vu;
        if ($ident->{user}->{permission}->{layout})
        {
            if ($update->{global})
            {
                $vu->{global}  = 1;
                $vu->{user_id} = undef;
            }
            else {
                $vu->{global}  = 0;
                $vu->{user_id} = $ident->{user}->{id};
            }
        }
        $update->{viewname} or error __"Please enter a name for the view";
        $vu->{name} = $update->{viewname};
        $view->update($vu);
    }

    # Whether we have only been asked for file columns
    my $search = $ident->{files} ? { 'me.type' => 'file' } : {};
    $search->{'me.remember'} = 1 if $ident->{remembered_only};

    my $pf = ['enumvals', 'calcs', 'rags', 'file_options', 'display_field' ];
    my @allcols = rset('Layout')->search($search,{
        order_by => ['me.position', 'enumvals.id'],
        prefetch => $pf,
    })->all; # Used for calc values

    my @cols;
    if (my $view_id = $ident->{view_id})
    {
        _get_view($view_id, $ident->{user}->{id}); # Borks on an error

        my @cc = rset('ViewLayout')->search(
            {
                'view_id' => $view_id,
            },{
                order_by => 'layout.position',
                prefetch => {layout => $pf},
            }
        )->all;
        foreach (@cc)
        {
            push @cols, $_->layout;
        }
    }
    elsif ($ident->{id})
    {
        my $cc = rset('Layout')->find($ident->{id});
        push @cols, $cc;
    }
    else
    {
        @cols = @allcols;
    }
    my @return;
    foreach my $col (@cols)
    {
        next if $col->hidden && $ident->{no_hidden} && !$ident->{user}->{permission}->{layout};
        my $c = _column $col, \@allcols;
        push @return, $c;
    }
    return \@return;
}

# Test to see if an enum value is valid
sub is_valid_enumval
{   my ($self, $value, $column) = @_;

    if ($column->{type} eq "person")
    {
        rset('User')->search({
            id      => $value,
            deleted => 0,
        })->count ? 1 : 0;
    }
    else {
        my ($found) = rset('Enumval')->search({
            id        => $value,
            layout_id => $column->{id},
            deleted   => 0,
        })->all;
        error __x"ID value of {value} is not valid for {col}", value => $value, col => $column->{name}
            if !$found;
        if ($column->{end_node_only})
        {
            # Check whether this is actually an end node
            error __x"Please select an end node for '{col}'", col => $column->{name}
                if (rset('Enumval')->search({
                    layout_id => $column->{id},
                    parent    => $found->id,
                })->count);
        }
    }
}

sub _get_view
{
    my ($view_id, $user_id) = @_;

    my $view = rset('View')->find($view_id);
    $view
        or error __x"Requested view {id} not found", id => $view_id;
    $view->global
        and return $view; # Anyone has access to this
    return $view unless $user_id;
    $view->user->id != $user_id
        and error __x"You do not have access to the requested view {id}", id => $view_id;
    $view;
}

sub sort_types
{
    [
        {
            name        => "asc",
            description => "Ascending"
        },
        {
            name        => "desc",
            description => "Descending"
        },
    ]
}

sub filter_types
{
    [
        { code => 'gt'      , text => 'Greater than' },
        { code => 'lt'      , text => 'Less than'    },
        { code => 'equal'   , text => 'Equals'       },
        { code => 'contains', text => 'Contains'     },
    ]
}

sub sorts
{
    my ($class, $view_id, $update) = @_;

    if ($update)
    {
        # Collect all the sorts. These can be in a variety of formats. New
        # ones will be a scalar for a single one or an arrayref for multiples.
        # Existing ones will have a unique field ID. This is maintained to retain
        # the data associated with that entry.
        my @allsorts;
        foreach my $v (keys %$update)
        {
            next unless $v =~ /^sortfield(\d+)(new)?/; # For each sort group
            my $id   = $1;
            my $new  = $2 ? 'new' : '';
            my $type = $update->{"sorttype$id"};
            error __x"Invalid type {type}", type => $type
                unless grep { $_->{name} eq $type } @{sort_types()};
            my $layout_id = $update->{"sortfield$id$new"} || undef;
            my $sort = {
                view_id   => $view_id,
                layout_id => $layout_id,
                type      => $type,
            };
            if ($new)
            {
                # New filter
                my $s = rset('Sort')->create($sort)
                    or error __"Database error when inserting new sort";
                push @allsorts, $s->id;
            }
            else {
                # Search on view as well to ensure ID belongs to view
                my ($s) = rset('Sort')->search({ view_id => $view_id, id => $id })->all;
                if ($s)
                {
                    $s->update($sort);
                    push @allsorts, $id;
                }
            }
        }
        # Then delete any that no longer exist
        foreach my $s (rset('Sort')->search({ view_id => $view_id }))
        {
            unless (grep {$_ == $s->id} @allsorts)
            {
                $s->delete;
            }
        }
    }

    my @sorts;
    my $sort_r = rset('Sort')->search({
        view_id => $view_id
    });

    foreach my $sort ($sort_r->all)
    {
        my $s;
        my $column   = $sort->layout ? _column($sort->layout) : undef;
        $s->{id}     = $sort->id;
        $s->{type}   = $sort->type;
        $s->{column} = $column;
        push @sorts, $s;
    }

    \@sorts;
}

sub fields($)
{   my $class = shift;
    my $fields;
    #$fields->{country} = \@{[rset('Country')->search->all]};
    #$fields->{region} = \@{[rset('Region')->search->all]};
    #$fields->{cat1} = \@{[rset('Cat1')->search->all]};
    #$fields->{cat2} = \@{[rset('Cat2')->search->all]};
    #$fields->{cat3} = \@{[rset('Cat3')->search->all]};
    #$fields->{idt_status} = \@{[rset('IdtStatus')->search->all]};
    #$fields->{relevance} = \@{[rset('Relevance')->search->all]};
    #$fields->{responsible} = \@{[rset('Responsible')->search->all]};
    #$fields->{section} = \@{[rset('Section')->search->all]};
    #$fields->{status} = \@{[rset('Status')->search->all]};
#    $fields->{likelihood} = \@{[rset('Likelihood')->search->all]};
    $fields;
}


1;

