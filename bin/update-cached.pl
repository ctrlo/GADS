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

use GADS::DB;
use GADS::Filter;
use GADS::Instances;
use GADS::Layout;
use GADS::View;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport mode => 'VERBOSE';
use Getopt::Long;
use Tie::Cache;

my ($from_record_id);

GetOptions (
    'from-record-id=s' => \$from_record_id,
) or exit;

# Close dancer2 special dispatcher, which tries to write to the session
dispatcher close => 'error_handler';

GADS::DB->setup(schema);

# Setup singleton classes with required parameters for if/when
# they are called in classes later.
GADS::Config->instance(
    config       => config,
    app_location => app->location,
);

tie %{schema->storage->dbh->{CachedKids}}, 'Tie::Cache', 100;

local $GADS::Schema::IGNORE_PERMISSIONS = 1;

foreach my $site (schema->resultset('Site')->all)
{
    schema->site_id($site->id);
    my $instances = GADS::Instances->new(
        schema                   => schema,
        user                     => undef,
        user_permission_override => 1,
    );

    foreach my $layout (@{$instances->all})
    {
        next if $layout->no_overnight_update;

        my $cols = $layout->col_ids_for_cache_update;
        next if !@$cols;

        my $view;
        # Allow the update to be performed starting from a particular
        # current_id
        if ($from_record_id)
        {
            my $filter = GADS::Filter->new(
                as_hash => {
                    rules => [
                        {
                            id       => $layout->column_id->id,
                            type     => 'integer',
                            value    => $from_record_id,
                            operator => 'greater',
                        },
                    ],
                },
            );

            $view = GADS::View->new(
                name        => 'Test view',
                filter      => $filter,
                columns     => $cols,
                instance_id => 1,
                layout      => $layout,
                schema      => schema,
                user        => undef,
            );
        }

        my $records = GADS::Records->new(
            user                 => undef,
            view                 => $from_record_id && $view,
            layout               => $layout,
            schema               => schema,
            columns              => !$from_record_id && $cols,
            curcommon_all_fields => 1, # Code might contain curcommon fields not in normal display
            include_children     => 1, # Update all child records regardless
        );

        my %changed;
        while (my $record = $records->single)
        {
            foreach my $column ($layout->all(order_dependencies => 1, has_cache => 1))
            {
                my $datum = $record->fields->{$column->id};
                $datum->re_evaluate(no_errors => 1);
                $datum->write_value;
                $changed{$column->id} ||= [];
                push @{$changed{$column->id}}, $record->current_id
                    if $datum->changed;
            }
        }

        # Send any alerts
        foreach my $col_id (keys %changed)
        {
            my $alert_send = GADS::AlertSend->new(
                layout      => $layout,
                schema      => schema,
                user        => undef,
                current_ids => $changed{$col_id},
                columns     => $col_id,
            );
            $alert_send->process;
        }
    }
}
