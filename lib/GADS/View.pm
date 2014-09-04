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
{   my ($class, $view_id) = @_;
    $view_id or return;
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

sub _column
{
    my $col = shift;
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
    }
    else {
        $c->{type}    = $col->type;
        $c->{sprefix} = $field;
        $c->{join}    = $field;
    }

    $c->{table} = $c->{type} eq 'tree' ? 'Enum' : camelize $c->{type};

    if ($col->type eq 'calc')
    {
        my ($calc) = $col->calcs;
        if ($calc) # Calculations defined?
        {
            my $allcols = shift;
            my @calccols;
            foreach my $acol (@$allcols)
            {
                next if $acol->type eq 'rag' || $acol->type eq 'calc';
                my $name = $acol->name; my $suffix = _suffix $acol->type;
                next unless $calc->calc =~ /\Q[$name\E$suffix\Q]/i;
                my $c = _column($acol);
                push @calccols, $c;
            }

            $c->{calc} = {
                id      => $calc->id,
                calc    => $calc->calc,
                columns => \@calccols,
            };
        }

        $c->{userinput} = 0;
    }
    elsif ($col->type eq 'rag')
    {
        my ($rag) = $col->rags;
        if ($rag) # RAG defined?
        {
            my $allcols = shift;
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

    my @cached = qw(rag calc person daterange);
    $c->{hascache}   = grep( /$col->type/, @cached ),
    $c->{id}         = $col->id,
    $c->{name}       = $col->name,
    $c->{remember}   = $col->remember,
    $c->{ordering}   = $col->ordering,
    $c->{permission} = $col->permission,
    $c->{readonly}   = $col->permission == READONLY ? 1 : 0;
    $c->{approve}    = $col->permission == APPROVE ? 1 : 0;
    $c->{open}       = $col->permission == OPEN ? 1 : 0;
    $c->{optional}   = $col->optional,
    $c->{field}      = $field,

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
        if ($ident->{user}->{permission}->{admin})
        {
            $vu->{global} = $update->{global} ? 1 : 0;
        }
        $update->{viewname} or ouch 'badvalue', "Please enter a name for the view";
        $vu->{name} = $update->{viewname};
        $view->update($vu);
    }

    # Whether we have only been asked for file columns
    my $search = $ident->{files} ? { type => 'file' } : {};

    my @allcols = rset('Layout')->search($search,{
        order_by => ['me.position', 'enumvals.id'],
        prefetch => ['enumvals', 'calcs', 'rags' ],
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
                prefetch => 'layout',
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

sub filter_types
{
    [
        { code => 'gt'      , text => 'Greater than' },
        { code => 'lt'      , text => 'Less than'    },
        { code => 'equal'   , text => 'Equals'       },
        { code => 'contains', text => 'Contains'     },
    ]
}

sub filters
{
    my ($class, $view_id, $update) = @_;

    if ($update)
    {
        # Collect all the filters. These can be in a variety of formats. New
        # ones will be a scalar for a single one or an arrayref for multiples.
        # Existing ones will have a unique field ID. This is maintained to retain
        # the data associated with that entry.
        my @allfilters;
        foreach my $v (keys %$update)
        {
            next unless $v =~ /^filfield(\d+)(new)?/; # For each filter group
            my $id = $1;
            my $new = $2 ? 'new' : '';
            my $op = $update->{"filoperator$id"};
            ouch 'badparam', "Invalid operator $op"
                unless grep { $_->{code} eq $op } @{filter_types()};
            my $filter = {
                view_id   => $view_id,
                layout_id => $update->{"filfield$id$new"},
                value     => $update->{"filvalue$id"},
                operator  => $op,
            };
            if ($new)
            {
                # New filter
                my $f = rset('Filter')->create($filter)
                    or ouch 'dbfail', "Database error when inserting new filter";
                push @allfilters, $f->id;
            }
            else {
                # Search on view as well to ensure ID belongs to view
                my ($f) = rset('Filter')->search({ view_id => $view_id, id => $id })->all;
                if ($f)
                {
                    $f->update($filter);
                    push @allfilters, $id;
                }
            }
        }
        # Then delete any that no longer exist
        foreach my $f (rset('Filter')->search({ view_id => $view_id }))
        {
            unless (grep {$_ == $f->id} @allfilters)
            {
                # Don't actually delete, so that old records can still reference the value
                # Set deleted flag instead
                $f->delete
                    or ouch 'dbfail', "Database error when deleting view ".$f->id;
            }
        }
    }

    my @filters;
    my $filter_r = rset('Filter')->search({
        view_id => $view_id
    },{
        prefetch => {
            'layout' => 'enumvals'
        } 
    });

    foreach my $fil ($filter_r->all)
    {
        my $f;
        $f->{id}       = $fil->id;
        $f->{operator} = $fil->operator;
        $f->{value}    = $fil->value;
        $f->{column}   = _column $fil->layout;
        push @filters, $f;
    }

    \@filters;
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

