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

#
# Script to update filtered value snapshot field based on all historical data
#

use FindBin;
use lib "$FindBin::Bin/../lib";

use GADS::DB;
use GADS::Instances;
use GADS::Layout;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport mode => 'NORMAL';
use Tie::Cache;

GADS::DB->setup(schema);

# Setup singleton classes with required parameters for if/when
# they are called in classes later.
GADS::Config->instance(config => config,);

tie %{ schema->storage->dbh->{CachedKids} }, 'Tie::Cache', 100;

foreach my $site (schema->resultset('Site')->all)
{
    schema->site_id($site->id);
    my $instances = GADS::Instances->new(
        schema                   => schema,
        user                     => undef,
        user_permission_override => 1,
    );

    foreach my $layout (@{ $instances->all })
    {

        my @filval = grep $_->type eq 'filval', $layout->all;
        next if !@filval;
        say STDERR "doing table " . $layout->name;

        my $records = GADS::Records->new(
            user   => undef,
            layout => $layout,
            schema => schema,

#columns              => $cols,
#curcommon_all_fields => 1, # Code might contain curcommon fields not in normal display
            include_children => 1,    # Update all child records regardless
        );

        while (my $record = $records->single)
        {
            say STDERR "Doing " . $record->current_id;
            my $guard  = schema->txn_scope_guard;
            my $rewind = schema->storage->datetime_parser->format_datetime(
                $record->created);
            foreach my $filval (@filval)
            {
                schema->resultset('Curval')->search({
                    record_id => $record->record_id,
                    layout_id => $filval->id,
                })->delete;
                next
                    if schema->resultset('Curval')->search({
                        record_id => $record->record_id,
                        layout_id => $filval->id,
                    })->count;
                $layout->record($record);
                local $GADS::Schema::Result::Record::REWIND = $rewind;
                my $datum = $record->fields->{ $filval->id };
                $filval->related_field->clear;
                my $vals = $filval->related_field->filtered_values;
                schema->resultset('Curval')->create({
                    record_id => $record->record_id,
                    layout_id => $filval->id,
                    value     => $_->{id},
                })
                    foreach @$vals;
            }
            $guard->commit;
        }
    }
}
