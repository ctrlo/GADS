#!/bin/bash

set -e

apt-get update
apt-get install -y curl gpg
curl -o- https://debian.ctrlo.com/repos/apt/debian/whatever.gpg.key | gpg --dearmor -o /usr/share/keyrings/ctrlo-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/ctrlo-keyring.gpg] https://debian.ctrlo.com/repos/apt/debian/ trixie main' | tee /etc/apt/sources.list.d/ctrlo.list

apt-get update
# Install Dancer2
apt-get install -y libapache2-mod-fastcgi libapache2-mod-perl2 libauth-yubikey-webclient-perl libauthen-oath-perl libconfig-inifiles-perl \
                   libconvert-base32-perl libcpanel-json-xs-perl libcrypt-saltedhash-perl libcrypt-urandom-perl libdancer2-perl \
                   libdancer2-plugin-auth-extensible-provider-dbic-perl libdancer2-plugin-dbic-perl libdancer2-session-dbic-perl \
                   libdata-dump-streamer-perl libdata-visitor-perl libdatetime-format-mysql-perl libdbd-mysql-perl libdbix-class-helpers-perl \
                   libdbix-class-migration-perl libdbix-class-perl libfcgi-perl libfile-copy-recursive-perl libimager-qrcode-perl libimager-perl \
                   libio-all-perl liblog-report-lexicon-perl liblog-report-perl liblog-report-template-perl libdancer2-plugin-logreport-perl \
                   libmail-box-perl libmail-transport-perl libmath-random-isaac-xs-perl libmoox-singleton-perl libpod-parser-perl \
                   libregexp-common-perl libstring-camelcase-perl libtemplate-perl libtext-autoformat-perl libtext-csv-perl libyaml-libyaml-perl
# Install GADS
apt-get install -y libdatetime-format-cldr-perl libtree-dagnode-perl libalgorithm-dependency-perl libdatetime-set-perl libdata-compare-perl \
                   libdatetime-event-random-perl libtext-csv-encoded-perl libhtml-fromtext-perl libhtml-scrubber-perl libdbd-pg-perl postgresql \
                   postgresql-contrib libdatetime-format-pg-perl libset-infinite-perl libtie-cache-perl libmath-round-perl \
                   libmoox-types-mooselike-datetime-perl libdatetime-format-datemanip-perl libinline-lua-perl lua5.2 libctrlo-crypt-xkcdpassword-perl \
                   libfile-slurp-perl libfile-mimeinfo-perl liblist-compare-perl libnet-oauth2-authorizationserver-perl libfontconfig1 \
                   libctrlo-pdf-perl libpdf-builder-perl fonts-liberation libdate-holidays-gb-perl libcgi-deurl-xs-perl libfile-bom-perl \
                   libdatetime-format-iso8601-perl liblog-log4perl-perl libwww-mechanize-chrome-perl chromium libfile-libmagic-perl \
                   libnet-saml2-perl liburl-encode-perl libtext-markdown-perl
# test dependencies
apt-get install -y libtest-mocktime-perl libtest-tempdir-tiny-perl libdbd-sqlite3-perl libdatetime-format-sqlite-perl libtest-compile-perl
