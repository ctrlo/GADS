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
use DBIx::Class::Migration;

my ($initial_username, $instance_name, $host);
my $namespace = $ENV{CDB_NAMESPACE};
GetOptions (
    'initial_username=s' => \$initial_username,
    'instance_name=s'    => \$instance_name,
    'site=s'             => \$host,
) or exit;

my ($dbic) = values %{config->{plugins}->{DBIC}}
    or die "Please create config.yml before running this script";

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

unless ($host)
{
    say "Please enter the hostname that will be used to access this site";
    chomp ($host = <STDIN>);
}

my $migration = DBIx::Class::Migration->new(
    schema_class => 'GADS::Schema',
    schema_args  => [{
        user         => $dbic->{user},
        password     => $dbic->{password},
        dsn          => $dbic->{dsn},
        quote_names  => 1,
    }],
);

say "Installing schema and fixtures if needed...";
$migration->install_if_needed(default_fixture_sets => ['permissions']);

# It's possible that permissions may not have been populated.  DBIC Migration
# doesn't error if the fixtures above don't exist, and whenever a new version
# of the schema is created, the fixtures need to be copied across, which needs
# to be done manually. So, at least do a check now:
rset('Permission')->count
    or die "No permissions populated. Do the fixtures exist?";

say qq(Creating site "$host"...);
my $site = rset('Site')->create({
    host                       => $host,
    register_organisation_name => 'Organisation',
});

say qq(Creating initial username "$initial_username"...);
my $user = rset('User')->create({
    username => $initial_username,
    email    => $initial_username,
    site_id  => $site->id,
});

say "Adding all permissions to initial username...";
foreach my $perm (rset('Permission')->all)
{
    rset('UserPermission')->create({
        user_id       => $user->id,
        permission_id => $perm->id,
    });
}

if($ENV{TEST}) {

    say 'Creating basic user "basic@example.com" with no permissions...';
    my $user = rset('User')->create({
        username => 'basic@example.com',
        email    => 'basic@exmaple.com',
        site_id  => $site->id,
    });

    say "Creating group for basic user";
    my $group = rset('Group')->create({
        name   => 'basic',
        site_id => $site->id,
    });

    say "Adding basic user to basic group";
    $user->search_related('user_groups')->create({
        group_id => $group->id,
    });
}

say "Creating initial datasheet...";
rset('Instance')->create({
    name    => $instance_name,
    site_id => $site->id,
});

