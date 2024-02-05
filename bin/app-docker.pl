#!/usr/bin/env perl

use FindBin;
use Dancer2;
use lib "$FindBin::Bin/../lib";

use GADS;

my $postgres_host = $ENV{POSTGRES_HOST} || 'localhost';
my $postgres_user = $ENV{POSTGRES_USER} || 'postgres';
my $postgres_pass = $ENV{POSTGRES_PASSWORD} || 'postgres';
my $postgres_db = $ENV{POSTGRES_DB} || 'gads';
my $hostname = `hostname`;

my $file = "$FindBin::Bin/../config_local.yml";

if(-e $file) {
    unlink $file;
}

open(CONFIG_LOCAL, ">$file") or die("Unable to open file $file for writing\n");

print CONFIG_LOCAL "gads:\n";
print CONFIG_LOCAL "  url: http://$hostname/"
print CONFIG_LOCAL "plugins:\n";
print CONFIG_LOCAL "  DBIC:\n";
print CONFIG_LOCAL "    default:\n";
print CONFIG_LOCAL "      dsn: dbi:Pg:dbname=$postgres_db;host=$postgres_host\n";
print CONFIG_LOCAL "      user: $postgres_user\n";
print CONFIG_LOCAL "      password: $postgres_pass\n";

close(CONFIG_LOCAL);

GADS->dance;
