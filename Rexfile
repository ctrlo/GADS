use Rex -feature => [1.4];

use strict;
use warnings;

use feature 'say';

task 'libs', sub {
    update_package_db;
    pkg $_, ensure => "present"
      foreach
      qw/git cpanminus liblua5.3-dev gcc g++ libdatetime-format-sqlite-perl libtest-most-perl libdatetime-set-perl libdbix-class-schema-loader-perl libmagic-dev postgresql-client libpng-dev libssl-dev libpq-dev libjson-perl libsession-token-perl libnet-oauth2-authorizationserver-perl libtext-csv-encoded-perl libcrypt-urandom-perl libhtml-scrubber-perl libtext-markdown-perl libwww-form-urlencoded-xs-perl libstring-camelcase-perl libmail-transport-perl liblog-log4perl-perl libplack-perl libdbd-pg-perl libmail-message-perl libmath-random-isaac-xs-perl libdbix-class-helpers-perl libtree-dagnode-perl libmath-round-perl libdatetime-format-dateparse-perl libwww-mechanize-perl libdatetime-format-iso8601-perl libmoox-types-mooselike-perl libmoox-singleton-perl libdancer2-perl liblist-compare-perl liburl-encode-perl libtie-cache-perl libhtml-fromtext-perl libdata-compare-perl libfile-bom-perl libalgorithm-dependency-perl libdancer-plugin-auth-extensible-perl libfile-libmagic-perl postfix perl postgres/;
};

task 'cpan', sub {
    run "perl ./bin/output_cpanfile > cpanfile";
    run "cpanm --installdeps . --notest --cpanfile ./cpanfile";
};

task 'create_db', sub {
    my $password = $ENV{POSTGRES_PASSWORD};
    if(!$password) {
        say "Input the password to use for the gads user: ";
        $password = <STDIN>;
        chomp $password;
        $ENV{POSTGRES_PASSWORD} = $password;
    }
    run ("psql -U postgres -c 'CREATE USER IF NOT EXISTS gads WITH PASSWORD '$password';'");
    run ("psql -U postgres -c 'CREATE DATABASE IF NOT EXISTS gads OWNER gads;'");
    run ("psql gads -U gads -c 'CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;'");
    run ("./bin/seed-database.pl");
};

task 'create_config', sub {
    run("cp ./config.yml-example ./config.yml");
    my $password = $ENV{POSTGRES_PASSWORD};
    if(!$password) {
        say "Input the password to use for the gads user: ";
        $password = <STDIN>;
        chomp $password;
        $ENV{POSTGRES_PASSWORD} = $password;
    }
    append_or_amend_line "./config.yml", 
        line => "      user: gads",
        regexp => qr/      user: .*/,
        on_change => sub {
            say "Changed config user to gads";
        };
    append_or_amend_line "./config.yml",
        line => "      password: " . $ENV{POSTGRES_PASSWORD},
        regexp => qr/      password: .*/,
        on_change => sub {
            say "Changed config password";
        };
};

batch 'setup', 'libs', 'cpan', 'create_config', 'create_db';
