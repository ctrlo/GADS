#!/usr/bin/env perl
#
# This script migrates the database.  Call this after every upgrade.

use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";

use YAML           qw(LoadFile);
use File::Basename qw(basename);
use Config::Any    ();

use Data::Dumper;
$Data::Dumper::Indent = 1;
my $config_fn = basename $0 . '/config.yml';
my $lib       = "$FindBin::Bin/../lib";

my $config = Config::Any->load_files({
    files   => [ $config_fn ],
    use_ext => 1,
});

my $db_settings = $config->[0]{'config.yml'}{plugins}{DBIC}{default}
    or die "configuration file structure changed.";

$ENV{DBIC_MIGRATION_USERNAME} = $db_settings->{user};
$ENV{DBIC_MIGRATION_PASSWORD} = $db_settings->{password};
my $dsn = $db_settings->{dsn};

system 'dbic-migration', "-I$lib",
    "--schema_class='GADS::Schema'",
    "--dsn='$dsn'",
    "--dbic_connect_attrs",
    "quote_names=1",
    "upgrade";
