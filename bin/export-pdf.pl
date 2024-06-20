#!/usr/bin/perl

=pod
GADS - Globally Accessible Data Store
Copyright (C) 2019 Ctrl O Ltd

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

my ($site_id, @instance_ids, $output);

GetOptions(
    'site-id=s'     => \$site_id,
    'instance-id=s' => \@instance_ids,
    'output=s'      => \$output,
) or exit;

$site_id or report ERROR => "Please provide site ID with --site-id";
$output  or report ERROR => "Please provide output file name with --output";

GADS::Config->instance(config => config,);

schema->site_id($site_id);

my $pdf = CtrlO::PDF->new(footer => "Linkspace configuration",);

my $instances_object = GADS::Instances->new(
    schema                   => schema,
    user                     => undef,
    user_permission_override => 1
);

my @instances =
    @instance_ids
    ? (map { $instances_object->layout($_) } @instance_ids)
    : @{ $instances_object->all };

foreach my $layout (@instances)
{
    my $instance_id = $layout->instance_id;

    $pdf->add_page;
    $pdf->heading('Linkspace configuration for table "' . $layout->name . '"');

    foreach my $field ($layout->all(exclude_internal => 1))
    {
        my $id = $field->id;
        $pdf->heading($field->name . " (ID $id)", size => 12);

        my $data = [];

        my %types = (
            enum      => 'Drop-down',
            tree      => 'Tree',
            intgr     => 'Integer',
            string    => 'Free text',
            date      => 'Date',
            daterange => 'Date range',
            autocur   => 'Automatic value of records that refer to this',
            curval    => 'Record from other table',
            file      => 'Document',
            person    => 'User on the system',
            calc      => 'Automatically calculated',
            rag       => 'RAG',
            filval    => 'Automatic capture of filtered values',
        );
        my $type = $types{ $field->type } or die "Unknown type " . $field->type;
        push @$data, [ 'Type', $type ];
        push @$data, [ 'Short name', $field->name_short ]
            if $field->name_short;
        push @$data, [ 'Topic', $field->topic->name ]
            if $field->topic;
        push @$data, [ 'Mandatory',          $field->optional ? 'No'  : 'Yes' ];
        push @$data, [ 'Unique values only', $field->isunique ? 'Yes' : 'No' ];
        push @$data, [ 'Description',        $field->description || '<blank>' ];
        push @$data, [ 'User help text',     $field->helptext    || '<blank>' ];
        push @$data,
            [ 'Allow multiple values', $field->multivalue ? 'Yes' : 'No' ];
        push @$data, [ 'Permissions', $field->group_summary ];

        if (my $df = $field->display_fields_summary)
        {
            push @$data, $df;
        }
        else
        {
            push @$data,
                [ 'Display conditions', 'This field is always displayed' ];
        }

        push @$data, $field->additional_pdf_export;

        my $hdr_props = {
            repeat    => 1,
            justify   => 'center',
            font_size => 8,
        };

        $pdf->table(data => $data,);

        $pdf->_down(15);
    }

}

$pdf->pdf->saveas($output);
