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
use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use Dancer2::Plugin::LogReport mode => 'NORMAL';

GADS::DB->setup(schema);

my $instances = GADS::Instances->new(schema => schema);

foreach my $instance (@{$instances->all})
{
    my $layout = GADS::Layout->new(
        user        => undef,
        instance_id => $instance->id,
        schema      => schema,
        config      => config,
    );

    foreach my $column ($layout->all)
    {
        next if $column->userinput;
        $column->base_url(config->{gads}->{url});
        $column->update_cached($column->table);
    }
}

