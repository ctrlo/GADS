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
use Getopt::Long qw(:config pass_through);
use JSON qw();
use Log::Report syntax => 'LONG';

my ($site_id, @instance_ids);

GetOptions (
    'site-id=s'              => \$site_id,
    'instance-id=s'              => \@instance_ids,
#    'ignore-incomplete-dateranges' => \$ignore_incomplete_dateranges,
#    'dry-run'                      => \$dry_run,
#    'ignore-string-zeros'          => \$ignore_string_zeros,
#    'force=s'                      => \$force,
#    'invalid-csv=s'                => \$invalid_csv,
#    'invalid-report=s'             => \@invalid_report,
#    'instance-id=s'                => \$instance_id,
#    'update-unique=s'              => \$update_unique,
#    'skip-existing-unique=s'       => \$skip_existing_unique,
#    'update-only'                  => \$update_only, # Do not write new version record
#    'blank-invalid-enum'           => \$blank_invalid_enum,
#    'no-change-unless-blank=s'     => \$no_change_unless_blank, # =bork or =blank_new
#    'report-changes'               => \$report_changes,
#    'append=s'                     => \@append,
) or exit;

$site_id or report ERROR =>  "Please provide site ID with --site-id";

mkdir '_export'
    or report FAULT => "Unable to create export directory";

GADS::Config->instance(
    config => config,
);

schema->site_id($site_id);

my $instances_object = GADS::Instances->new(schema => schema, user => undef, user_permission_override => 1);

my @instances = @instance_ids
    ? (map { $instances_object->layout($_) } @instance_ids)
    : @{$instances_object->all};

my $encoder = JSON->new->pretty;

mkdir '_export/groups'
    or report FAULT => "Unable to create groups directory";

foreach my $group (schema->resultset('Group')->all)
{
    my $json = $encoder->encode({
        id   => $group->id,
        name => $group->name,
    });
    my $file = "_export/groups/".$group->id;
    open(my $fh, ">:encoding(UTF-8)", $file)
        or report FAULT => "Error opening $file for write";
    print $fh $json;
}

foreach my $layout (@instances)
{
    my $instance_id = $layout->instance_id;
    my $ins_dir = "_export/instance$instance_id";
    mkdir $ins_dir
        or report FAULT => "Unable to create instance directory";
    my $json = $encoder->encode($layout->export);
    my $file = "$ins_dir/instance";
    open(my $fh, ">:encoding(UTF-8)", $file)
        or report FAULT => "Error opening $file for write";
    print $fh $json;

    mkdir "$ins_dir/topics"
        or report FAULT => "Unable to create topics directory";
    foreach my $topic (schema->resultset('Topic')->search({ instance_id => $instance_id })->all)
    {
        my $json = $encoder->encode({
            id            => $topic->id,
            name          => $topic->name,
            initial_state => $topic->initial_state,
            click_to_edit => $topic->click_to_edit,
            instance_id   => $topic->instance_id,
        });
        my $file = "$ins_dir/topics/".$topic->id;
        open(my $fh, ">:encoding(UTF-8)", $file)
            or report FAULT => "Error opening $file for write";
        print $fh $json;
    }

    mkdir "$ins_dir/layout"
        or report FAULT => "Unable to create layout directory";

    dump_all("$ins_dir/layout/", $layout->all(order_dependencies => 1));

    mkdir "$ins_dir/metrics"
        or report FAULT => "Unable to create metrics directory";
    dump_all("$ins_dir/metrics/", @{GADS::MetricGroups->new(schema => schema, instance_id => $instance_id)->all});

    mkdir "$ins_dir/graphs"
        or report FAULT => "Unable to create graphs directory";
    dump_all("$ins_dir/graphs/", @{GADS::Graphs->new(schema => schema, layout => $layout)->all});
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
