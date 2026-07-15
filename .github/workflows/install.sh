#!/bin/bash

set -e

apt-get update
apt-get install -y curl gpg
curl -o- https://debian.ctrlo.com/repos/apt/debian/whatever.gpg.key | gpg --dearmor -o /usr/share/keyrings/ctrlo-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/ctrlo-keyring.gpg] https://debian.ctrlo.com/repos/apt/debian/ trixie main' | tee /etc/apt/sources.list.d/ctrlo.list

apt-get update
# dependencies as found when trying to run the tests in a clean docker container
apt-get install -y libctrlo-crypt-xkcdpassword-perl libdatetime-perl libdancer2-plugin-logreport-perl libmoox-types-mooselike-perl \
                   libhtml-fromtext-perl libdatetime-format-cldr-perl libpath-class-perl libmoox-singleton-perl libalgorithm-dependency-perl \
                   libstring-camelcase-perl libdata-compare-perl libdbix-class-perl libctrlo-pdf-perl libsession-token-perl libhtml-scrubber-perl \
                   libtext-markdown-perl libmail-message-perl liblingua-en-inflect-perl libmail-transport-perl libdatetime-format-iso8601-perl \
                   libdbix-class-helpers-perl libfile-bom-perl libtext-csv-perl libmoox-types-mooselike-datetime-perl liblist-compare-perl \
                   libmath-round-perl libtext-csv-encoded-perl libcgi-deurl-xs-perl libtree-dagnode-perl libdatetime-format-datemanip-perl \
                   libdate-holidays-gb-perl libinline-lua-perl libfile-libmagic-perl libnet-saml2-perl liburl-encode-perl \
                   libmath-random-isaac-xs-perl libtie-cache-perl libwww-mechanize-chrome-perl libdancer2-plugin-dbic-perl \
                   libdancer2-plugin-auth-extensible-perl libdancer2-plugin-auth-extensible-provider-dbic-perl \
                   libnet-oauth2-authorizationserver-perl libdbd-pg-perl
# test dependencies
apt-get install -y libtest-mocktime-perl libtest-tempdir-tiny-perl libdbd-sqlite3-perl libdatetime-format-sqlite-perl
