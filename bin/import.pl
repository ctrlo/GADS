#!/usr/bin/perl

=pod
GADS - Globally Accessible Data Store
Copyright (C) 2017 Ctrl O Ltd

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

use Dancer2;
use Dancer2::Plugin::DBIC;
use File::Slurp;
use GADS::Layout;
use GADS::Column::Calc;
use GADS::Column::Curval;
use GADS::Column::Date;
use GADS::Column::Daterange;
use GADS::Column::Enum;
use GADS::Column::File;
use GADS::Column::Intgr;
use GADS::Column::Person;
use GADS::Column::Rag;
use GADS::Column::String;
use GADS::Column::Tree;
use GADS::Config;
use GADS::Instance;
use GADS::Instances;
use GADS::Graph;
use GADS::Graphs;
use GADS::Groups;
use GADS::MetricGroups;
use GADS::Schema;
use Getopt::Long qw(:config pass_through);
use JSON qw();
use Log::Report syntax => 'LONG';
use String::CamelCase qw(camelize);

my ($site_id, $purge);

GetOptions (
    'site-id=s' => \$site_id,
    'purge'     => \$purge,
) or exit;

$site_id or report ERROR =>  "Please provide site ID with --site-id";

-d '_export'
    or report ERROR => "Export directory does not exist";

GADS::Config->instance(
    config => config,
);

schema->site_id($site_id);

my $encoder = JSON->new;

if ($purge)
{
    foreach my $instance (@{GADS::Instances->new(schema => schema)->all})
    {
        $instance->purge;
    }

    GADS::Groups->new(schema => schema)->purge;
}

schema->resultset('Group')->count
    and report ERROR => "Groups already exists. Use --purge to remove everything from this site before import";

-d '_export/groups'
    or report ERROR => "Groups directory does not exist";

my $group_mapping; # ID mapping
foreach my $group (dir('_export/groups'))
{
    my $new = GADS::Group->new(
        name   => $group->{name},
        schema => schema,
    );
    $new->write;
    $group_mapping->{$group->{id}} = $new->id;
}

opendir my $root, '_export' or report FAULT => "Cannot open directory _export";
foreach my $ins (readdir $root)
{
    next unless $ins =~ /^instance/;

    my $instance_info = load_json("_export/$ins/instance");
    my $instance = GADS::Instance->new(
        name   => $instance_info->{name},
        schema => schema,
    );
    $instance->write;

    my $layout = GADS::Layout->new(
	user        => undef,
	schema      => schema,
	config      => GADS::Config->instance,
	instance_id => $instance->id,
    );

    foreach my $col (dir("_export/$ins/layout"))
    {
        if ($col->{type} eq 'enum')
        {
            delete $_->{id}
                foreach @{$col->{enumvals}};
        }
        my $class = "GADS::Column::".camelize($col->{type});
        my $column = $class->new(
            type   => $col->{type},
            schema => schema,
            user   => undef,
            layout => $layout,
        );
        $column->import_hash($col);
        $column->write;
        foreach my $old_id (keys %{$col->{permissions}})
        {
            my $new_id = $group_mapping->{$old_id};
            $column->set_permissions($new_id, $col->{permissions}->{$old_id});
        }
    }

    foreach my $mg (dir("$ins/metrics"))
    {
        my $metric_group = GADS::MetricGroup->new(
            name   => $mg->{name},
            schema => schema,
        );
        $metric_group->write;
        foreach my $metric (@{$mg->{metrics}})
        {
            GADS::Metric->new(
                target                => $metric->{target},
                metric_group_id       => $metric_group->id,
                x_axis_value          => $metric->{x_axis_value},
                y_axis_grouping_value => $metric->{y_axis_grouping_value},
            )->write;
        }

    }

    foreach my $g (dir("$ins/graphs"))
    {
        # Convert to new column IDs
        $g->{x_axis} = $group_mapping->{$g->{x_axis}};
        $g->{y_axis} = $group_mapping->{$g->{y_axis}};
        $g->{group_by} = $group_mapping->{$g->{group_by}};
        my $graph = GADS::Graph->new(
            layout => $layout,
            schema => schema,
        );
        $graph->import_hash($g);
        $graph->write;
    }
}

sub dir
{   my $name = shift;
    opendir my $dir, $name or report FAULT => "Cannot open directory $name";
    map { load_json("$name/$_") } grep { $_ ne '.' && $_ ne '..' } sort readdir $dir;
}

sub load_json
{   my $file = shift;
    my $json = read_file($file, binmode => ':utf8');
    $encoder->decode($json);
}

