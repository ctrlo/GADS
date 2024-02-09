#!/bin/bash
apt-get update
apt-get install cpanminus liblua5.3-dev gcc g++ libdatetime-format-sqlite-perl libtest-most-perl libdatetime-set-perl \
                     libdbix-class-schema-loader-perl libmagic-dev postgresql-client libpng-dev libssl-dev libpq-dev \
                     libjson-perl libsession-token-perl libnet-oauth2-authorizationserver-perl libtext-csv-encoded-perl \
                     libcrypt-urandom-perl libhtml-scrubber-perl libtext-markdown-perl libwww-form-urlencoded-xs-perl \
                     libstring-camelcase-perl libmail-transport-perl liblog-log4perl-perl libplack-perl libdbd-pg-perl \
                     libmail-message-perl libmath-random-isaac-xs-perl libdbix-class-helpers-perl libtree-dagnode-perl \
                     libmath-round-perl libdatetime-format-dateparse-perl libwww-mechanize-perl libdatetime-format-iso8601-perl \
                     libmoox-types-mooselike-perl libmoox-singleton-perl libpdf-table-perl libdancer2-perl liblist-compare-perl \
                     liburl-encode-perl libtie-cache-perl libhtml-fromtext-perl libdata-compare-perl libfile-bom-perl \
                     libalgorithm-dependency-perl libdancer-plugin-auth-extensible-perl libfile-libmagic-perl
perl bin/output_cpanfile > cpanfile
cpanm --installdeps --cpanfile cpanfile --sudo --notest .
apt autoremove -y;
apt autoclean -y;
