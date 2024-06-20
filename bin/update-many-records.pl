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

# Example script for bulk updating records. Edit as required.

use FindBin;
use lib "$FindBin::Bin/../lib";

use GADS::DB;
use GADS::Instances;
use GADS::Layout;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport mode => 'NORMAL';

GADS::DB->setup(schema);
GADS::Config->instance(config => config,);

my $user_id =    # XXX
    my $user = schema->resultset('User')->find($user_id);

my $layout = GADS::Layout->new(
    user        => $user,
    schema      => schema,
    instance_id =>           # XXX,
);
my $views = GADS::Views->new(
    user        => $user,
    schema      => schema,
    layout      => $layout,
    instance_id =>            # XXX,
);
my $view    = $views->view(1);      # XXX
my $records = GADS::Records->new(
    user   => $user,
    view   => $view,
    layout => $layout,
    schema => schema,
);

my $guard = schema->txn_scope_guard;

foreach my $record (@{ $records->results })
{
    my $latest = schema->resultset('Date')->search(
        {
            current_id => $record->current_id,
            value      => { '!=' => undef },
            layout_id  =>                        # XXX,
        },
        {
            join => 'record',
        },
    )->get_column('id')->max;
    my $val = schema->resultset('Date')->find($latest)->value;
    schema->resultset('Date')->search(
        {
            'record.current_id' => $record->current_id,
            'me.id'             => { '>' => $latest },
            layout_id           =>                        # XXX,
        },
        {
            join => 'record',
        },
    )->update({
            value => $val,
    });
}

$guard->commit;
