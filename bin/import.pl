#!/usr/bin/perl -CS

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
use Path::Tiny;
use GADS::DB;
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
use Path::Tiny;

my ($site_id, $purge, $add, $report_only, $merge, $update_cached);

GetOptions (
    'site-id=s'     => \$site_id,
    'purge'         => \$purge,
    'add'           => \$add,
    'report-only'   => \$report_only,
    'merge'         => \$merge,
    'update-cached' => \$update_cached,
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

if ($purge && !$report_only)
{
    foreach my $instance (@{GADS::Instances->new(schema => schema, user => undef, user_permission_override => 1)->all})
    {
        $instance->purge;
    }

    GADS::Groups->new(schema => schema)->purge;
}

schema->resultset('Group')->count && !$add && !$report_only
    and report ERROR => "Groups already exists. Use --purge to remove everything from this site before import or --add to add config";

-d '_export/groups'
    or report ERROR => "Groups directory does not exist";

my $group_mapping; # ID mapping
my $groups = GADS::Groups->new(schema => schema);
foreach my $g(dir('_export/groups'))
{
    my ($group) = grep { $_->name eq $g->{name} } @{$groups->all};

    if ($group)
    {
        report NOTICE => __x"Existing: Group {name} already exists", name => $g->{name}
            if $report_only;
    }
    else {
        report NOTICE => __x"Creation: New group {name} to be created", name => $g->{name};
        $group = GADS::Group->new(
            name   => $g->{name},
            schema => schema,
        );
        $group->write;
    }

    $group_mapping->{$g->{id}} = $group->id;
}

opendir my $root, '_export' or report FAULT => "Cannot open directory _export";

my $column_mapping;
my $layouts;
my @all_columns;

foreach my $ins (readdir $root)
{
    next unless $ins =~ /^instance/;

    my $instance_info = load_json("_export/$ins/instance");

    my $existing = rset('Instance')->search({
        name => $instance_info->{name},
    });

    my $instance;
    if (my $count = $existing->count)
    {
        report ERROR => __x"More than one existing instance name {name}",
            name => $instance_info->{name} if $count > 1;
        $instance = $existing->next;
        report NOTICE => __x"Existing: Instance {name} already exists", name => $instance_info->{name}
            if $report_only;
        report ERROR => __x"Instance {name} already exists", name => $instance_info->{name}
            unless $merge;
    }
    else {
        report NOTICE => __x"Creation: Instance name {name} created", name => $instance_info->{name};
        $instance = rset('Instance')->create({
            name   => $instance_info->{name},
        });

    }

    my $topic_mapping; # topic ID mapping
    if (-d "_export/$ins/topics")
    {
        foreach my $topic (dir("_export/$ins/topics"))
        {
            my $top;
            my $topic_hash = {
                name                  => $topic->{name},
                initial_state         => $topic->{initial_state},
                click_to_edit         => $topic->{click_to_edit},
                prevent_edit_topic_id => $topic->{prevent_edit_topic_id},
                description           => $topic->{description},
                instance_id           => $instance->id,
            };
            if ($report_only || $merge)
            {
                $top = rset('Topic')->search({
                    name        => $topic->{name},
                    instance_id => $instance->id,
                });
                report ERROR => __x"More than one topic named {name} already exists", name => $topic->{name}
                    if $top->count > 1;
                report NOTICE => __x"Existing: Topic {name} already exists, will update", name => $topic->{name}
                    if $top->count && $report_only;
                report NOTICE => __x"Creation: Topic {name} to be created", name => $topic->{name}
                    if $top->count && $report_only;
                if ($top = $top->next)
                {
                    $top->update($topic_hash);
                }
            }
            $top = schema->resultset('Topic')->create($topic_hash) if !$top;

            $topic_mapping->{$topic->{id}} = $top->id;
        }
    }

    my $layout = GADS::Layout->new(
       user                     => undef,
       user_permission_override => 1,
       schema                   => schema,
       config                   => GADS::Config->instance,
       instance_id              => $instance->id,
    );
    $layout->create_internal_columns;

    $layout->create_internal_columns;

    my %existing_columns = map { $_->id => $_ } $layout->all(exclude_internal => 1);

    # The layout in a column is a weakref, so it will have been destroyed by
    # the time we try and use it later in the script. Therefore, keep a
    # reference to it.
    $layouts->{$layout->instance_id} = $layout; 

    my $highest_update; # The column with the highest ID that's been updated
    my @created;
    foreach my $col (dir("_export/$ins/layout"))
    {
        my $updated;
        my $column = $layout->column_by_name($col->{name});
        if ($column)
        {
            report NOTICE => __x"Update: Column {name} already exists, will update", name => $col->{name}
                if $report_only;
            report ERROR => __x"Column {name} already exists", name => $col->{name}
                unless $merge;
            report ERROR => __x"Existing column type does not match import for column name {name} in table {table}",
                name => $col->{name}, table => $layout->name
                    if $col->{type} ne $column->type;
            $highest_update = $col->{id} if !$highest_update || $col->{id} > $highest_update;
            $updated = 1;
        }

        if (!$column)
        {
            report NOTICE => __x"Creation: Column {name} to be created", name => $col->{name};
            push @created, $col;
        }

        my $class = "GADS::Column::".camelize($col->{type});
        $column ||= $class->new(
            type   => $col->{type},
            schema => schema,
            user   => undef,
            layout => $layout,
        );
        $column->import_hash($col, report_only => $report_only);
        $column->topic_id($topic_mapping->{$col->{topic_id}}) if $col->{topic_id};
        # Don't add to the DBIx schema yet, as we may not have all the
        # information needed (e.g. related field IDs)
        $column->write(override => 1, no_db_add => 1, no_cache_update => 1, update_dependents => 0);
        $column->import_after_write($col, report_only => $updated && $report_only);

        my $perms_to_set = {};
        foreach my $old_id (keys %{$col->{permissions}})
        {
            my $new_id = $group_mapping->{$old_id};
            $perms_to_set->{$new_id} = $col->{permissions}->{$old_id};
        }
        $column->set_permissions($perms_to_set, report_only => $report_only);

        $column_mapping->{$col->{id}} = $column->id;

        push @all_columns, {
            column  => $column,
            values  => $col,
            updated => $updated,
        };

        delete $existing_columns{$column->id};
    }

    # Check for fields that look like new columns (with a different name) but
    # have an ID older than existing columns. These are probably fields that
    # have had their name changed
    foreach my $create (@created)
    {
        report NOTICE => __x"Suspected name updated: column {name} was created but its "
            ."ID is less than those already existing. Could it be an updated name?", name => $create->{name}
            if $highest_update && $create->{id} < $highest_update;
    }

    if ($merge)
    {
        foreach my $col (values %existing_columns)
        {
            report NOTICE => __x"Deletion: Column {name} no longer exist", name => $col->name;
            $col->delete
                unless $report_only;
        }
    }

    foreach my $mg (dir("_export/$ins/metrics"))
    {
        report ERROR => "Not yet any report-only support for metric groups"
            if $report_only;
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

    $layout->clear;

    foreach my $g (dir("_export/$ins/graphs"))
    {
        # Convert to new column IDs
        $g->{x_axis} = $column_mapping->{$g->{x_axis}};
        $g->{y_axis} = $column_mapping->{$g->{y_axis}};
        $g->{group_by} = $column_mapping->{$g->{group_by}}
            if $g->{group_by};

        my $graph;
        if ($merge || $report_only)
        {
            my $graph_rs = rset('Graph')->search({
                title => $g->{title},
            });
            report ERROR => "More than one existing graph titled {title}", title => $g->{title}
                if $graph_rs->count > 1;
            if ($graph_rs->count)
            {
                $graph = GADS::Graph->new(
                    id     => $graph_rs->next->id,
                    layout => $layout,
                    schema => schema,
                );
            }
            else {
                report NOTICE => "Graph to be created: {graph}", graph => $g->{title};
            }
        }
        $graph ||= GADS::Graph->new(
            layout => $layout,
            schema => schema,
        );
        $graph->import_hash($g, report_only => $report_only);
        $graph->write unless $report_only;
    }
}

$_->clear foreach values %$layouts;
foreach (@all_columns)
{
    my $col = $_->{column};
    report NOTICE => __x"Final update of column {name}", name => $col->name;
    $col->import_after_all($_->{values}, mapping => $column_mapping, report_only => $report_only && $_->{updated});
    # Now add to the DBIx schema
    $col->write(no_cache_update => 1, add_db => 1, update_dependents => 1, report_only => $report_only);
}

if (!$report_only && $update_cached)
{
    GADS::DB->setup(schema);
    $_->{column}->can('update_cached') && $_->{column}->update_cached(no_alerts => 1)
        foreach @all_columns;
}

exit if $report_only;
$guard->commit;

sub dir
{   my $name = shift;
    opendir my $dir, $name or report FAULT => "Cannot open directory $name";
    map { load_json("$name/$_") } grep { $_ ne '.' && $_ ne '..' } sort readdir $dir;
}

sub load_json
{   my $file = shift;
    my $json = path($file)->slurp_utf8;
    $encoder->decode($json);
}
