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

use Algorithm::Dependency::Ordered;
use Algorithm::Dependency::Source::HoA;
use Dancer2;
use Dancer2::Plugin::DBIC;
use GADS::Config;
use GADS::Layout;
use GADS::Views;
use Getopt::Long;
use String::CamelCase qw(camelize);
use YAML::XS          qw/LoadFile DumpFile/;

GADS::Config->instance(config => config,);

my ($instance_id, $site_id, $load_file, $dump_file, $global_views);
GetOptions(
    'instance-id=s' => \$instance_id,
    'site-id=s'     => \$site_id,
    'load-file=s'   => \$load_file,
    'dump-file=s'   => \$dump_file,
    'global-views'  => \$global_views,
) or exit;

$instance_id             or die "Need --instance-id";
$site_id                 or die "Need --site-id";
$load_file || $dump_file or die "Need either --load-file or --dump-file";

schema->site_id($site_id);

my $layout = GADS::Layout->new(
    user_permission_override => 1,
    user                     => undef,
    instance_id              => $instance_id,
    config                   => config,
    schema                   => schema,
);

my $views = GADS::Views->new(
    user        => undef,
    schema      => schema,
    layout      => $layout,
    instance_id => $instance_id,
);

sub write_props
{   my ($field, $new) = @_;
    $field->name($new->{name});
    $field->name_short($new->{name_short});
    $field->type($new->{type});
    $field->optional($new->{optional});
    $field->remember($new->{remember});
    $field->isunique($new->{isunique});
    $field->textbox($new->{textbox})
        if $field->can('textbox');
    $field->typeahead($new->{typeahead})
        if $field->can('typeahead');
    $field->force_regex($new->{force_regex} || '')
        if $field->can('force_regex');
    $field->position($new->{position});
    $field->ordering($new->{ordering});
    $field->end_node_only($new->{end_node_only})
        if $field->can('end_node_only');
    $field->multivalue($new->{multivalue});
    $field->description($new->{description});
    $field->helptext($new->{helptext});
    $field->display_field($new->{display_field});
    $field->display_regex($new->{display_regex});
    $field->link_parent_id($new->{link_parent_id});
    $field->filter->as_json($new->{filter});
    $field->_set_options($new->{options});
    $field->enumvals($new->{enumvals})
        if $field->type eq 'enum';

    if ($field->type eq 'curval')
    {
        $field->curval_field_ids($new->{curval_field_ids});
        my ($random) = @{ $field->curval_field_ids };
        $field->refers_to_instance(
            $layout->column($random)->layout->instance_id);
    }
    $field->write(no_cache_update => 1, create_missing_id => 1)
        ;    # Create any new enums, with existing IDs
}

if ($load_file)
{
    my $guard = schema->txn_scope_guard;

    my $array = LoadFile $load_file;

    if ($global_views)
    {
        foreach my $import (@$array)
        {
            schema->resultset('View')->search({
                id          => $import->{id},
                instance_id => { '!=' => $instance_id },
            })->count
                and die
                "View ID $import->{id} already exists but for wrong instance";
            schema->resultset('View')->find_or_create({
                id          => $import->{id},
                instance_id => $instance_id,
            });
            my $view = GADS::View->new(
                id          => $import->{id},
                user        => undef,
                schema      => schema,
                layout      => $layout,
                instance_id => $instance_id,
            );
            $view->columns($import->{columns});
            $view->global($import->{is_admin});
            $view->is_admin($import->{is_admin});
            $view->name($import->{name});
            $view->filter->as_json($import->{filter});
            $view->write;
            my (@sort_fields, @sort_types);

            foreach my $sort (@{ $import->{sorts} })
            {
                push @sort_fields, $sort->{layout_id};
                push @sort_types,  $sort->{type};
            }
            $view->set_sorts(\@sort_fields, \@sort_types);
        }
    }
    else
    {
        my %loaded;
        $loaded{ $_->{id} } = $_ foreach @$array;

        # Find new ones
        my %missing = %loaded;
        delete $missing{ $_->id } foreach $layout->all;

        # Create first in case they are referenced
        if (%missing)
        {
            my %deps = map {
                       $_->{id} => $_->{display_field}
                    && $missing{ $_->{display_field} }
                    ? [ $_->{display_field} ]
                    : []
            } values %missing;

            my $source = Algorithm::Dependency::Source::HoA->new(\%deps);
            my $dep    = Algorithm::Dependency::Ordered->new(source => $source)
                or die 'Failed to set up dependency algorithm';
            my @order   = @{ $dep->schedule_all };
            my @missing = map { $missing{$_} } @order;

            foreach my $new (@missing)
            {
                say STDERR "Creating missing field $new->{id} ($new->{name})";
                my $class = "GADS::Column::" . camelize $new->{type};
                my $field = $class->new(
                    id     => $new->{id},
                    schema => schema,
                    user   => undef,
                    layout => $layout,
                );
                write_props($field, $new);
            }
        }

        foreach my $field ($layout->all)
        {
            if (my $new = $loaded{ $field->id })
            {
                write_props($field, $new);
            }
            else
            {
                say STDERR "Field "
                    . $field->name . " (ID "
                    . $field->id
                    . ") not in updated layout - needs manual deletion";
            }
        }

        # Refresh new layout and load any calc fields (done last as short names
        # might not otherwise exist)
        $layout->clear;
        foreach my $field ($layout->all)
        {
            next if $field->userinput;
            $field->code($loaded{ $field->id }->{code})
                if $loaded{ $field->id };
            $field->write(no_cache_update => 1);
        }
    }

    $guard->commit;
}
else
{

    my @out;

    if ($global_views)
    {
        foreach my $view (@{ $views->all })
        {
            next unless $view->global || $view->is_admin;
            push @out,
                {
                    id       => $view->id,
                    name     => $view->name,
                    global   => $view->global,
                    is_admin => $view->is_admin,
                    filter   => $view->filter->as_json,
                    columns  => $view->columns,
                    sorts    => $view->sorts,
                };
        }
    }
    else
    {
        foreach my $field ($layout->all)
        {
            my $hash = {
                id         => $field->id,
                name       => $field->name,
                name_short => $field->name_short,
                type       => $field->type,
                optional   => $field->optional,
                remember   => $field->remember,
                isunique   => $field->isunique,
                textbox    => $field->can('textbox')   ? $field->textbox : 0,
                typeahead  => $field->can('typeahead') ? $field->typeahead
                : 0,
                force_regex => $field->can('force_regex')
                ? $field->force_regex
                : '',
                position      => $field->position,
                ordering      => $field->ordering,
                end_node_only => $field->can('end_node_only')
                ? $field->end_node_only
                : 0,
                multivalue     => $field->multivalue,
                description    => $field->description,
                helptext       => $field->helptext,
                display_field  => $field->display_field,
                display_regex  => $field->display_regex,
                link_parent_id => $field->link_parent_id,
                filter         => $field->filter->as_json,
                options        => $field->options,
            };
            $hash->{enumvals} = $field->enumvals if $field->type eq 'enum';
            $hash->{code}     = $field->code     if !$field->userinput;
            $hash->{curval_field_ids} = $field->curval_field_ids
                if $field->type eq 'curval';
            push @out, $hash;
        }
    }

    DumpFile $dump_file, [@out];
}

