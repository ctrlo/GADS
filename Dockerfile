FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN ["mkdir","/app"]
WORKDIR "/app"
COPY ./ /app
ENV POSTGRES_HOST=postgres
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_DB=postgres
RUN ["apt-get","update"]
RUN ["apt-get","install","cpanminus","liblua5.3-dev","gcc","g++","libdatetime-format-sqlite-perl","libtest-most-perl","libdatetime-set-perl","libdbix-class-schema-loader-perl","libmagic-dev","postgresql-client","libpng-dev","libssl-dev","libpq-dev","libjson-perl","libsession-token-perl","libnet-oauth2-authorizationserver-perl","libtext-csv-encoded-perl","libcrypt-urandom-perl","libhtml-scrubber-perl","libtext-markdown-perl","libwww-form-urlencoded-xs-perl","libstring-camelcase-perl","libmail-transport-perl","liblog-log4perl-perl","libplack-perl","libdbd-pg-perl","libmail-message-perl","libmath-random-isaac-xs-perl","libdbix-class-helpers-perl","libtree-dagnode-perl","libmath-round-perl","libdatetime-format-dateparse-perl","libwww-mechanize-perl","libdatetime-format-iso8601-perl","libmoox-types-mooselike-perl","libmoox-singleton-perl","libpdf-table-perl","libdancer2-perl","liblist-compare-perl","liburl-encode-perl","libtie-cache-perl","libhtml-fromtext-perl","libdata-compare-perl","libfile-bom-perl","libalgorithm-dependency-perl","libdancer-plugin-auth-extensible-perl","libfile-libmagic-perl","-y"]
RUN ["perl","bin/output_cpanfile",">","cpanfile"]
RUN ["cpanm","--installdeps","--cpanfile","cpanfile","--sudo","--notest","."]
RUN ["sed","-i","'s/localhost/'$(hostname)'/g'","./config.yml"]
RUN ["chmod","+x","./bin/app-docker.pl"]
ENTRYPOINT [ "./bin/app-docker.pl" ]
