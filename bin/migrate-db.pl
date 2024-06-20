#!/usr/bin/env perl
#
# Use this script to manage database migrations.
#
# For an upgrade, simply run bin/migrate-db.pl --upgrade
#

use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2;
my $config = config;

use DBIx::Class::Migration;
use Dancer2::Plugin::LogReport 'linkspace', mode => 'NORMAL';
use Getopt::Long;

my ($prepare, $install, $upgrade, $downgrade, $status, $fixtures);

GetOptions(
    'prepare'    => \$prepare,
    'install'    => \$install,
    'upgrade'    => \$upgrade,
    'downgrade'  => \$downgrade,
    'status'     => \$status,
    'fixtures=s' => \$fixtures,
) or exit;

$prepare || $install || $upgrade || $downgrade || $status || $fixtures
    or error
    "Please specify --prepare, --install, --status, --fixtures or --upgrade";

my $db_settings = $config->{plugins}{DBIC}{default}
    or panic "configuration file structure changed.";

my @app_connect = (
    $db_settings->{dsn},
    $db_settings->{user},
    $db_settings->{password},
    {
        quote_names => 1,
        RaiseError  => 1,
    },
);

my $migration = DBIx::Class::Migration->new(
    schema_class => 'GADS::Schema',
    schema_args  => \@app_connect,
    target_dir   => "$FindBin::Bin/../share",
    dbic_dh_args => {
        force_overwrite     => 1,
        quote_identifiers   => 1,
        databases           => [ 'MySQL', 'PostgreSQL' ],
        sql_translator_args => {
            producer_args => {
                mysql_version => 5.7,
            },
        },
    },
);

if    ($prepare)   { $migration->prepare }
elsif ($install)   { $migration->install }
elsif ($upgrade)   { $migration->upgrade }
elsif ($downgrade) { $migration->downgrade }
elsif ($status)    { $migration->status }
elsif ($fixtures)
{
    my $rootdir = "$FindBin::Bin/..";
    my @dirs    = grep { -d } glob "$rootdir/share/fixtures/*";
    my $version = 0;
    foreach (@dirs)
    {
        s!^.*/([0-9]+)$!$1!
            or next;
        $version = $_ if $_ > $version;
    }
    my $fixtures_root = "$rootdir/share/fixtures/$version";
    my $dbfixtures    = DBIx::Class::Fixtures->new({
        config_dir => "$fixtures_root/conf",
    });
    if ($fixtures eq 'export')
    {
        $dbfixtures->dump({
            config    => 'permissions.json',
            directory => "$fixtures_root/permissions",
            schema    => $migration->schema,
        });
    }
    elsif ($fixtures eq 'import')
    {
        $dbfixtures->populate({
            directory          => "$fixtures_root/permissions",
            schema             => $migration->schema,
            no_deploy          => 1,
            use_find_or_create => 1,
            update_existing    => 1,
        });
    }
    else
    {
        error "Invalid fixtures action $fixtures";
    }
}
