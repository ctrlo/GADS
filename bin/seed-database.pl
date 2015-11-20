#!/usr/bin/perl

=pod
GADS - Globally Accessible Data Store
Copyright (C) 2015 Ctrl O Ltd

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

use strict;
use warnings;
use 5.10.0;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Getopt::Long;
use Dancer2;
use Dancer2::Plugin::DBIC;

my ($initial_username, $instance_name);
my $namespace = $ENV{CDB_NAMESPACE};
GetOptions (
    'initial_username=s' => \$initial_username,
    'instance_name=s'    => \$instance_name,
) or exit;

unless ($instance_name)
{
    say "Please enter the name of the first datasheet";
    chomp ($instance_name = <STDIN>);
}

unless ($initial_username)
{
    say "Please enter the email address of the first user";
    chomp ($initial_username = <STDIN>);
}

my ($dbic) = values %{config->{plugins}->{DBIC}};
my $migration_cmd = qq(dbic-migration -Ilib --schema_class='GADS::Schema' --username=$dbic->{user} --password=$dbic->{pass} --dsn='$dbic->{dsn}' --dbic_connect_attrs quote_names=1);
say "Installing schema...";
qx($migration_cmd install);
say "Inserting permissions fixtures...";
qx($migration_cmd populate --fixture_set permissions);

say qq(Creating initial username "$initial_username"...);
my $user = rset('User')->create({
    username => $initial_username,
    email    => $initial_username,
});

say "Adding all permissions to initial username...";
foreach my $perm (rset('Permission')->all)
{
    rset('UserPermission')->create({
        user_id       => $user->id,
        permission_id => $perm->id,
    });
}

say "Creating initial datasheet...";
rset('Instance')->create({
    name => 'GADS',
});

