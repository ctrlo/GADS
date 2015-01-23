#!/usr/bin/perl

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
use String::CamelCase qw(camelize);
use YAML qw/LoadFile/;

my ($file) = @ARGV;
$file or die "Usage: $0 filename";

my $import = LoadFile($file);

GADS::DB->setup(schema);

my $layout = GADS::Layout->new(user => undef, schema => schema);

my @write;
foreach my $column (@$import)
{
    my $class = $column->{type};
    $class = "GADS::Column::".camelize($class);
    my $new = $class->new(schema => schema, user => undef, layout => $layout);
    
    $new->$_($column->{$_})
        foreach (qw/name type permission description helptext optional hidden remember/);
    if ($column->{display_condition})
    {
        $new->display_field($column->{display_field});
        $new->display_regex($column->{display_regex});
    }
    else {
        $new->display_field(undef);
    }
    if ($column->{type} eq "file")
    {
        $new->filesize($column->{filesize} || undef);
    }
    elsif ($column->{type} eq "rag")
    {
        $new->write_cache(0);
        $new->red  ($column->{red});
        $new->amber($column->{amber});
        $new->green($column->{green});
    }
    elsif ($column->{type} eq "enum")
    {
        $new->ordering($column->{ordering} || undef);
    }
    elsif ($column->{type} eq "calc")
    {
        $new->write_cache(0);
        $new->calc($column->{calc});
        $new->return_type($column->{return_type});
    }
    elsif ($column->{type} eq "tree")
    {
        $new->end_node_only($column->{end_node_only});
    }

    $new->write;

    if ($column->{type} eq "enum")
    {
        my $submit = {
            enumval => [],
        };
        foreach my $enum (@{$column->{enumvals}})
        {
            next if $enum->{deleted};
            push $submit->{enumval}, $enum->{value};
        }
        $new->enumvals_from_form($submit);
    }
    elsif ($column->{type} eq "tree")
    {
        $new->update($column->{json});
    }
}

