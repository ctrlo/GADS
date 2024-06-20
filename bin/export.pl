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
use GADS::Config;
use GADS::Instances;
use GADS::Graphs;
use GADS::Layout;
use GADS::MetricGroups;
use GADS::Schema;
use Getopt::Long;
use JSON qw();
use Log::Report syntax => 'LONG';

my ($site_id, @instance_ids, $include_data);

GetOptions(
    'site-id=s'     => \$site_id,
    'instance-id=s' => \@instance_ids,
    'include-data'  => \$include_data,
) or exit;

$site_id or report ERROR => "Please provide site ID with --site-id";

mkdir '_export'
    or report FAULT => "Unable to create export directory";

GADS::Config->instance(config => config,);

schema->site_id($site_id);
local $GADS::Schema::IGNORE_PERMISSIONS = 1;

my $instances_object = GADS::Instances->new(schema => schema, user => undef);

my @instances =
    @instance_ids
    ? (map { $instances_object->layout($_) } @instance_ids)
    : @{ $instances_object->all };

my $encoder = JSON->new->pretty;

mkdir '_export/groups'
    or report FAULT => "Unable to create groups directory";

my @groups = schema->resultset('Group')->search(
    [
        'layout.instance_id'          => [ map $_->instance_id, @instances ],
        'instance_groups.instance_id' =>
            [ map $_->instance_id, @instances ],
    ],
    {
        join => [
            {
                layout_groups => 'layout',
            },
            'instance_groups',
        ],
        collapse => 1,
    },
)->all;

foreach my $group (@groups)
{
    my $json = $encoder->encode({
        id   => $group->id,
        name => $group->name,
    });
    my $file = "_export/groups/" . $group->id;
    open(my $fh, ">:encoding(UTF-8)", $file)
        or report FAULT => "Error opening $file for write";
    print $fh $json;
}

if ($include_data)
{
    mkdir "_export/users"
        or report FAULT => "Unable to create users directory";
    my @users;
    if (@instance_ids)
    {
        @users = schema->resultset('User')->search(
            [
                'current.instance_id' =>
                    [ map $_->instance_id, @instances ],
                'current_deletedbies.instance_id' =>
                    [ map $_->instance_id, @instances ],
            ],
            {
                collapse => 1,
                join     => [
                    {
                        record_createdbies => 'current',
                    },
                    'current_deletedbies',
                ],
            },
        );
    }
    else
    {
        @users = schema->resultset('User')->all,;
    }
    dump_all("_export/users/", @users);
}

foreach my $layout (@instances)
{
    my $instance_id = $layout->instance_id;
    my $ins_dir     = "_export/instance$instance_id";
    mkdir $ins_dir
        or report FAULT => "Unable to create instance directory";
    my $json = $encoder->encode($layout->export);
    my $file = "$ins_dir/instance";
    open(my $fh, ">:encoding(UTF-8)", $file)
        or report FAULT => "Error opening $file for write";
    print $fh $json;

    mkdir "$ins_dir/topics"
        or report FAULT => "Unable to create topics directory";
    foreach my $topic (
        schema->resultset('Topic')->search({ instance_id => $instance_id })
        ->all)
    {
        my $json = $encoder->encode({
            id            => $topic->id,
            name          => $topic->name,
            description   => $topic->description,
            initial_state => $topic->initial_state,
            click_to_edit => $topic->click_to_edit,
            instance_id   => $topic->instance_id,
        });
        my $file = "$ins_dir/topics/" . $topic->id;
        open(my $fh, ">:encoding(UTF-8)", $file)
            or report FAULT => "Error opening $file for write";
        print $fh $json;
    }

    mkdir "$ins_dir/layout"
        or report FAULT => "Unable to create layout directory";

    dump_all("$ins_dir/layout/", $layout->all(order_dependencies => 1));

    mkdir "$ins_dir/metrics"
        or report FAULT => "Unable to create metrics directory";
    dump_all(
        "$ins_dir/metrics/",
        @{ GADS::MetricGroups->new(
                schema      => schema,
                instance_id => $instance_id
            )->all
        }
    );

    mkdir "$ins_dir/graphs"
        or report FAULT => "Unable to create graphs directory";
    my @graphs = @{ GADS::Graphs->new(schema => schema, layout => $layout)
            ->all_all_users };
    @graphs = grep !$_->user_id, @graphs
        if !$include_data;    # Users not included without include_data flag
    dump_all("$ins_dir/graphs/", @graphs);

    mkdir "$ins_dir/views"
        or report FAULT => "Unable to create views directory";
    my $views = GADS::Views->new(
        schema                   => schema,
        layout                   => $layout,
        instance_id              => $layout->instance_id,
        user_permission_override => 1
    );
    my @views = @{ $views->global };
    push @views, @{ $views->admin };
    dump_all("$ins_dir/views/", @views);

    if ($include_data)
    {
        mkdir "$ins_dir/records"
            or report FAULT => "Unable to create records directory";
        dump_all(
            "$ins_dir/records/",
            schema->resultset('Current')->search({
                instance_id  => $instance_id,
                draftuser_id => undef,
            })->all,
        );
    }
}

sub dump_all
{   my $path = shift;
    my $count;
    foreach (@_)
    {
        my $json = $encoder->encode($_->export_hash);
        my $file = sprintf("%s%05d_%s", $path, ++$count, $_->id);
        open(my $fh, ">:encoding(UTF-8)", $file)
            or report FAULT => "Error opening $file for write";
        print $fh $json;
    }
}
