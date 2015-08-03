#!/usr/bin/perl -CS

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

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use GADS::DB;
use GADS::Layout;
use GADS::Views;
use YAML;

GADS::DB->setup(schema);

my $layout = GADS::Layout->new(user => undef, schema => schema, config => config);

my @columns;
foreach my $column ($layout->all)
{
    say STDERR "Exporting ".$column->name;
    my $col = {
        id            => $column->id,
        name          => $column->name,
        type          => $column->type,
        return_type   => $column->return_type,
        optional      => $column->optional,
        remember      => $column->remember,
        position      => $column->position,
        ordering      => $column->ordering,
        description   => $column->description,
        helptext      => $column->helptext,
        display_field => $column->display_field,
        display_regex => $column->display_regex,
    };
    if ($column->type eq "tree")
    {
        $col->{end_node_only} = $column->end_node_only,
        $col->{json}          = $column->json,
    }
    elsif ($column->type eq "calc")
    {
        $col->{calc} = $column->calc;
    }
    elsif ($column->type eq "enum")
    {
        $col->{enumvals} = $column->enumvals;
        $col->{ordering} = $column->ordering;
    }
    elsif ($column->type eq "file")
    {
        $col->{filesize} = $column->filesize;
    }
    elsif ($column->type eq "rag")
    {
        $col->{green} = $column->green;
        $col->{amber} = $column->amber;
        $col->{red} = $column->red;
    }
    push @columns, $col;
}

my $views  = GADS::Views->new(user => undef, schema => schema, layout => $layout);

my @views;
foreach my $v (@{$views->global})
{
    say STDERR "Exporting view ".$v->name;
    my @sort_fields;
    my @sort_types;
    foreach my $s (@{$v->sorts})
    {
        push @sort_fields, $s->{layout_id};
        push @sort_types, $s->{type};
    }
    my $view = {
        name          => $v->name,
        filter        => $v->filter,
        columns       => $v->columns,
        sorts         => {
            fields => \@sort_fields,
            types  => \@sort_types,
        },
    };
    push @views, $view;
}

print Dump {
    columns => \@columns,
    views   => \@views,
};

