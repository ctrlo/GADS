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

my ($site_id, $purge, $add);

GetOptions (
    'site-id=s' => \$site_id,
    'purge'     => \$purge,
    'add'       => \$add,
) or exit;

$site_id or report ERROR =>  "Please provide site ID with --site-id";

-d '_export'
    or report ERROR => "Export directory does not exist";

GADS::Config->instance(
    config => config,
);

schema->site_id($site_id);

my $encoder = JSON->new;

my $guard = schema->txn_scope_guard;

if ($purge)
{
    foreach my $instance (@{GADS::Instances->new(schema => schema)->all})
    {
        $instance->purge;
    }

    GADS::Groups->new(schema => schema)->purge;
}

schema->resultset('Group')->count && !$add
    and report ERROR => "Groups already exists. Use --purge to remove everything from this site before import or --add to add config";

-d '_export/groups'
    or report ERROR => "Groups directory does not exist";

my $group_mapping; # ID mapping
my $groups = GADS::Groups->new(schema => schema);
foreach my $group (dir('_export/groups'))
{
    my ($new) = grep { $_->name eq $group->{name} } @{$groups->all};

    if (!$new)
    {
        $new = GADS::Group->new(
            name   => $group->{name},
            schema => schema,
        );
        $new->write;
    }

    $group_mapping->{$group->{id}} = $new->id;
}

opendir my $root, '_export' or report FAULT => "Cannot open directory _export";

my $column_mapping;
my $layouts;
my @all_columns;

foreach my $ins (readdir $root)
{
    next unless $ins =~ /^instance/;

    my $instance_info = load_json("_export/$ins/instance");

    report NOTICE => "Creating instance name $instance_info->{name}";

    my $instance = rset('Instance')->create({
        name   => $instance_info->{name},
    });

    my $topic_mapping; # topic ID mapping
    if (-d "_export/$ins/topics")
    {
        foreach my $topic (dir("_export/$ins/topics"))
        {
            my $new = schema->resultset('Topic')->create({
                name          => $topic->{name},
                initial_state => $topic->{initial_state},
                click_to_edit => $topic->{click_to_edit},
            });

            $topic_mapping->{$topic->{id}} = $new->id;
        }
    }

    my $layout = GADS::Layout->new(
       user                     => undef,
       user_permission_override => 1,
       schema                   => schema,
       config                   => GADS::Config->instance,
       instance_id              => $instance->id,
    );

    # The layout in a column is a weakref, so it will have been destroyed by
    # the time we try and use it later in the script. Therefore, keep a
    # reference to it.
    $layouts->{$layout->instance_id} = $layout; 

    foreach my $col (dir("_export/$ins/layout"))
    {
        report NOTICE => "Creating field $col->{name}";

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
        $column->topic_id($topic_mapping->{$col->{topic_id}}) if $col->{topic_id};
        # Don't add to the DBIx schema yet, as we may not have all the
        # information needed (e.g. related field IDs)
        $column->write(override => 1, no_db_add => 1, no_cache_update => 1, update_dependents => 0);
        $column->import_after_write($col);

        my $perms_to_set = {};
        foreach my $old_id (keys %{$col->{permissions}})
        {
            my $new_id = $group_mapping->{$old_id};
            $perms_to_set->{$new_id} = $col->{permissions}->{$old_id};
        }
        $column->set_permissions($perms_to_set);

        $column_mapping->{$col->{id}} = $column->id;

        push @all_columns, {
            column => $column,
            values => $col,
        };
    }

    foreach my $mg (dir("_export/$ins/metrics"))
    {
        my $metric_group = GADS::MetricGroup->new(
            name        => $mg->{name},
            instance_id => $layout->instance_id,
            schema      => schema,
        );
        $metric_group->write;
        foreach my $metric (@{$mg->{metrics}})
        {
            GADS::Metric->new(
                target                => $metric->{target},
                metric_group_id       => $metric_group->id,
                x_axis_value          => $metric->{x_axis_value},
                y_axis_grouping_value => $metric->{y_axis_grouping_value},
                schema                => schema,
            )->write;
        }

    }

    foreach my $g (dir("_export/$ins/graphs"))
    {
        # Convert to new column IDs
        $g->{x_axis} = $column_mapping->{$g->{x_axis}};
        $g->{y_axis} = $column_mapping->{$g->{y_axis}};
        $g->{group_by} = $column_mapping->{$g->{group_by}}
            if $g->{group_by};
        my $graph = GADS::Graph->new(
            layout => $layout,
            schema => schema,
        );
        $graph->import_hash($g);
        $graph->write;
    }
}

foreach (@all_columns)
{
    my $col = $_->{column};
    $col->import_after_all($_->{values}, $column_mapping);
    # Now add to the DBIx schema
    $col->write(no_cache_update => 1, add_db => 1, update_dependents => 1);
}

$_->{column}->can('update_cached') && $_->{column}->update_cached(no_alerts => 1)
    foreach @all_columns;


$guard->commit;

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
