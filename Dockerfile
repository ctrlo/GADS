FROM perl:5.34
RUN ["mkdir","/app"]
COPY ./ /app
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive
ENV PGPASSWORD=mysecret
ENV GADS_EMAIL=admin@localhost
ENV GADS_PASSWORD=supersecretpassword
RUN ["apt-get","update"]
RUN ["apt-get","install","-y","cpanminus","liblua5.3-dev","gcc","g++","libdatetime-format-sqlite-perl","libtest-most-perl","libdatetime-set-perl"]
RUN ["apt-get","install","-y","libdbix-class-schema-loader-perl","libmagic-dev","postgresql-client","libpng-dev","libssl-dev","libpq-dev"]
RUN ["apt-get","install","-y","libjson-perl","libsession-token-perl","libnet-oauth2-authorizationserver-perl","libtext-csv-encoded-perl"]
RUN ["apt-get","install","-y","libcrypt-urandom-perl","libhtml-scrubber-perl","libtext-markdown-perl","libwww-form-urlencoded-xs-perl"]
RUN ["apt-get","install","-y","libstring-camelcase-perl","libmail-transport-perl","liblog-log4perl-perl","libplack-perl","libdbd-pg-perl"]
RUN ["apt-get","install","-y","libmail-message-perl","libmath-random-isaac-xs-perl","libdbix-class-helpers-perl","libtree-dagnode-perl"]
RUN ["apt-get","install","-y","libmath-round-perl","libdatetime-format-dateparse-perl","libwww-mechanize-perl","libdatetime-format-iso8601-perl"]
RUN ["apt-get","install","-y","libmoox-types-mooselike-perl","libmoox-singleton-perl","libpdf-table-perl","libdancer2-perl","liblist-compare-perl"]
RUN ["apt-get","install","-y","liburl-encode-perl","libtie-cache-perl","libhtml-fromtext-perl","libdata-compare-perl","libfile-bom-perl"]
RUN ["apt-get","install","-y","libalgorithm-dependency-perl","libdancer-plugin-auth-extensible-perl","libfile-libmagic-perl","postfix"]
RUN perl ./bin/output_cpanfile > cpanfile
RUN ["cpanm","--installdeps",".","--cpanfile","cpanfile","--notest"]
ENTRYPOINT ["./bin/docker.sh",${GADS_EMAIL},${GADS_PASSWORD}]