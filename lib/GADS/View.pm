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

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use Ouch;
use String::CamelCase qw(camelize);
use GADS::Util         qw(:all);
schema->storage->debug(1);

use GADS::Schema;

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

sub view
{   my ($self, $view_id, $user, $update) = @_;
    $view_id || $update or return;

    if ($update)
    {
        $user or ouch 'usermissing', "User ID needs to be supplied for view when updating";

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

        # Finally update the filter
        rset('View')->find($view_id)->update({
            filter => $update->{filter},
        });
    }

    rset('View')->find($view_id);
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
        or ouch 'noperms', "You do not have permission to delete $id";
    rset('Sort')->search({ view_id => $view->id })->delete
        or ouch 'dbfail', "There was a database error when deleting the view's sort values";
    rset('ViewLayout')->search({ view_id => $view->id })->delete
        or ouch 'dbfail', "There was a database error when deleting the view's layouts";
    rset('Filter')->search({ view_id => $view->id })->delete
        or ouch 'dbfail', "There was a database error when deleting the view's filters";
    $view->delete
        or ouch 'dbfail', "There was a database error when deleting the view";
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
                next if $acol->type eq 'rag' || $acol->type eq 'calc';
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
            $c->{vtype} = "date" if $c->{return_format} eq "date";
        }

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
                next if $acol->type eq 'rag' || $acol->type eq 'calc';
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
            }) or ouch 'dbfail', "Database error when inserting new view";
            $view_id = $new->id;
            $ident->{view_id} = $view_id;
        }
        else {
            $view_id = $ident->{view_id}; # or ouch 'badparam', "Please supply a view ID";
        }
        my $view = _get_view($view_id, $ident->{user}->{id}); # Borks on an error
        !$view->global || $ident->{user}->{permission}->{layout}
            or ouch 'noperms', "You do not have access to modify view $view_id";

        # Will be a scalar if only one value submitted. If so,
        # convert to array
        my @colviews = !$update->{column}
                     ? ()
                     : ref $update->{column} eq 'ARRAY'
                     ? @{$update->{column}}
                     : ( $update->{column} );

        foreach my $c (rset('Layout')->all)
        {
            my $item = { view_id => $view_id, layout_id => $c->id };
            if (grep {$c->id == $_} @colviews)
            {
                # Column should be in view
                rset('ViewLayout')->create($item)
                    unless rset('ViewLayout')->search($item)->count;
            }
            else {
                rset('ViewLayout')->search($item)->delete;
            }
        }
        my $vu;
        if ($ident->{user}->{permission}->{layout})
        {
            $vu->{global} = $update->{global} ? 1 : 0;
        }
        $update->{viewname} or ouch 'badvalue', "Please enter a name for the view";
        $vu->{name} = $update->{viewname};
        $view->update($vu);
    }

    # Whether we have only been asked for file columns
    my $search = $ident->{files} ? { type => 'file' } : {};

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
        my $c = _column $col, \@allcols;
        push @return, $c;
    }
    return \@return;
}

# Return true if an enum value exists and is not deleted
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
        rset('Enumval')->search({
            id        => $value,
            layout_id => $column->{id},
            deleted   => 0,
        })->count ? 1 : 0;
    }
}

sub _get_view
{
    my ($view_id, $user_id) = @_;

    my $view = rset('View')->find($view_id);
    $view
        or ouch 'notfound', "Requested view $view_id not found";
    $view->global
        and return $view; # Anyone has access to this
    return $view unless $user_id;
    $view->user->id != $user_id
        and ouch 'noperms', "You do not have access to the requested view $view_id";
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
            ouch 'badparam', "Invalid type $type"
                unless grep { $_->{name} eq $type } @{sort_types()};
            my $sort = {
                view_id   => $view_id,
                layout_id => $update->{"sortfield$id$new"},
                type      => $type,
            };
            if ($new)
            {
                # New filter
                my $s = rset('Sort')->create($sort)
                    or ouch 'dbfail', "Database error when inserting new sort";
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
                $s->delete
                    or ouch 'dbfail', "Database error when deleting view ".$s->id;
            }
        }
    }

    my @sorts;
    my $sort_r = rset('Sort')->search({
        view_id => $view_id
    },{
        prefetch => {
            'layout' => 'enumvals'
        } 
    });

    foreach my $sort ($sort_r->all)
    {
        my $s;
        $s->{id}     = $sort->id;
        $s->{type  } = $sort->type;
        $s->{column} = _column $sort->layout;
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

