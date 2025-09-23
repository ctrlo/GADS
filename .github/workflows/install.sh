#!/bin/bash

apt-get update
apt-get install -y curl gpg
curl -o- https://debian.ctrlo.com/repos/apt/debian/whatever.gpg.key | gpg --dearmor -o /usr/share/keyrings/ctrlo-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/ctrlo-keyring.gpg] https://debian.ctrlo.com/repos/apt/debian/ bookworm main' | tee /etc/apt/sources.list.d/ctrlo.list
apt-get update
apt-get install -y libapache2-mod-fastcgi libapache2-mod-perl2 libconfig-inifiles-perl libcrypt-saltedhash-perl libcrypt-urandom-perl libdancer2-perl
apt-get install -y libdancer2-plugin-auth-extensible-provider-dbic-perl libdancer2-plugin-dbic-perl libdancer2-session-dbic-perl
apt-get install -y libdata-dump-streamer-perl libdata-visitor-perl libdatetime-format-mysql-perl libdbd-mysql-perl libdbix-class-migration-perl
apt-get install -y libdbix-class-perl libfcgi-perl libfile-copy-recursive-perl libio-all-perl liblog-report-lexicon-perl liblog-report-perl
apt-get install -y libmail-box-perl libmail-transport-perl libmath-random-isaac-xs-perl libmoox-singleton-perl libpod-parser-perl libregexp-common-perl
apt-get install -y libstring-camelcase-perl libtemplate-perl libtext-autoformat-perl libtext-csv-perl libyaml-libyaml-perl libdatetime-format-cldr-perl
apt-get install -y libtree-dagnode-perl libalgorithm-dependency-perl libdatetime-set-perl libdata-compare-perl libdatetime-event-random-perl
apt-get install -y libtext-csv-encoded-perl libhtml-fromtext-perl libhtml-scrubber-perl libdbd-pg-perl postgresql postgresql-contrib
apt-get install -y libdatetime-format-pg-perl libset-infinite-perl libtie-cache-perl libdbix-class-helpers-perl libmath-round-perl
apt-get install -y libmoox-types-mooselike-datetime-perl libdatetime-format-datemanip-perl libinline-lua-perl lua5.2 libctrlo-crypt-xkcdpassword-perl
apt-get install -y libfile-slurp-perl libfile-mimeinfo-perl liblist-compare-perl libnet-oauth2-authorizationserver-perl libfontconfig1
apt-get install -y libctrlo-pdf-perl libpdf-builder-perl fonts-liberation libdate-holidays-gb-perl libcgi-deurl-xs-perl libfile-bom-perl
apt-get install -y libdatetime-format-iso8601-perl liblog-log4perl-perl libwww-mechanize-chrome-perl chromium libfile-libmagic-perl libnet-saml2-perl
apt-get install -y liburl-encode-perl libtext-markdown-perl
