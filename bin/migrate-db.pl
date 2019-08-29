#!/usr/bin/env perl
#
# This script migrates the database.  Call this after every upgrade.

use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2;
my $config = config;

my $db_settings = $config->{plugins}{DBIC}{default}
    or die "configuration file structure changed.";

$ENV{DBIC_MIGRATION_USERNAME} = $db_settings->{user};
$ENV{DBIC_MIGRATION_PASSWORD} = $db_settings->{password};
my $dsn = $db_settings->{dsn};

my $lib       = "$FindBin::Bin/../lib";

system 'dbic-migration', "-I$lib",
    "--schema_class='GADS::Schema'",
    "--dsn='$dsn'",
    "--dbic_connect_attrs",
    "quote_names=1",
    "upgrade"
	and die "Migration failed";
