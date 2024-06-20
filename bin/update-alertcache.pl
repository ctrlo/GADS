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
use GADS::Instances;
use GADS::Layout;
use GADS::Views;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport mode => 'NORMAL';

# Close dancer2 special dispatcher, which tries to write to the session
dispatcher close => 'error_handler';

GADS::DB->setup(schema);

# Setup these singleton classes with required parameters for if/when
# they are called in classes later.
GADS::Config->instance(config => config,);

GADS::Email->instance(config => config,);

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
        my $views = GADS::Views->new(
            user                     => undef,
            schema                   => schema,
            layout                   => $layout,
            instance_id              => $layout->instance_id,
            user_permission_override => 1,
        );

        foreach my $view (@{ $views->all })
        {
            if ($view->has_alerts)
            {
                my $alert = GADS::Alert->new(
                    user    => undef,
                    layout  => $layout,
                    schema  => schema,
                    view_id => $view->id,
                    view    => $view,
                );
                $alert->update_cache(all_users => 1);
            }
            else
            {
                schema->resultset('AlertCache')->search({
                    view_id => $view->id,
                })->delete;
            }
        }
    }
}
