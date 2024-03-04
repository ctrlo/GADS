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

use GADS::Config;
use GADS::Layout;
use GADS::Group;
use GADS::Column::String;
use GADS::Column::Intgr;
use GADS::Column::Enum;
use GADS::Column::Tree;

# Seed singleton
GADS::Config->instance(
    config => config,
);

my ($initial_username, $instance_name, $host);
my $namespace = $ENV{CDB_NAMESPACE};
GetOptions (
    'initial_username=s' => \$initial_username,
    'instance_name=s'    => \$instance_name,
    'site=s'             => \$host,
) or exit;

my ($dbic) = values %{config->{plugins}->{DBIC}}
    or die "Please create config.yml before running this script";

unless ($initial_username)
{
    say "Please enter the email address of the first user";
    chomp ($initial_username = <STDIN>);
}

unless ($instance_name)
{
    say "Please enter the name of the first datasheet";
    chomp ($instance_name = <STDIN>);
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

say "Creating initial datasheet...";
rset('Instance')->create({
    name    => $instance_name,
    site_id => $site->id,
});

my $group  = GADS::Group->new(schema => schema);
$group->name('Read/write');
$group->write;

rset('UserGroup')->create({
    user_id  => $user->id,
    group_id => $group->id,
});

my $perms = {$group->id => [qw/read write_existing write_existing_no_approval write_new write_new_no_approval/]};

my $activities = _create_table("Activities", $site, string => 20, tree => 5, enum => 20, intgr => 20);

for my $i (1..10)
{
    my $curval_layout = _create_table("Curval$i", $site, string => 3, tree => 0, enum => 3, intgr => 1);

    my $curval = GADS::Column::Curval->new(
        optional   => 1,
        schema     => schema,
        user       => $user,
        layout     => $activities,
    );
    $curval->refers_to_instance_id($curval_layout->instance_id);
    my @curval_field_ids = schema->resultset('Layout')->search({
        internal    => 0,
        instance_id => $curval_layout->instance_id,
    })->get_column('id')->all;
    $curval->curval_field_ids(\@curval_field_ids);
    $curval->type('curval');
    $curval->name("curval$i");
    $curval->delete_not_used(1);
    $curval->show_add(1);
    $curval->value_selector('noshow');
    $curval->set_permissions($perms);
    $curval->write;
}

sub _create_table
{   my ($name, $site, %counts) = @_;

    say "Creating table";

    my $activities = rset('Instance')->create({
        name => "$name",
        site_id => $site->id,
    });

    my $layout = GADS::Layout->new(
        user        => $user,
        schema      => schema,
        config      => config,
        instance_id => $activities->id,
    );
    $layout->create_internal_columns;

    say "Creating string fields";

    for my $i (1..$counts{string})
    {
        my $string = GADS::Column::String->new(
            optional => 1,
            schema   => schema,
            user     => $user,
            layout   => $layout,
        );
        $string->type('string');
        $string->name("string$i");
        $string->set_permissions($perms);
        $string->write;
    }

    say "Creating tree fields";

    for my $i (1..$counts{tree})
    {
        my $tree = GADS::Column::Tree->new(
            optional => 1,
            schema   => schema,
            user     => $user,
            layout   => $layout,
        );
        $tree->type('tree');
        $tree->name("tree$i");
        $tree->set_permissions($perms);
        $tree->write;

        my @nodes;
        for my $j (1..200)
        {
            push @nodes, {
                text => "Node $i $j",
                children => [],
            };
        }
        $tree->update(\@nodes);
    }

    say "Creating enum fields";

    for my $i (1..$counts{enum})
    {
        my $enum = GADS::Column::Enum->new(
            optional => 1,
            schema   => schema,
            user     => $user,
            layout   => $layout,
        );
        $enum->type('enum');
        $enum->name("enum$i");
        $enum->set_permissions($perms);
        my @enumvals;
        for my $j (1..100)
        {
            push @enumvals, {
                value => "foo$j",
            };
        }
        $enum->enumvals(\@enumvals);
        $enum->write;
    }

    say "Creating integer fields";

    for my $i (1..$counts{intgr})
    {
        my $intgr = GADS::Column::Intgr->new(
            optional => 1,
            schema   => schema,
            user     => $user,
            layout   => $layout,
        );
        $intgr->type('intgr');
        $intgr->name("integer$i");
        $intgr->set_permissions($perms);
        $intgr->write;
    }

    return $layout;
}
