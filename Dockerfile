FROM perl:5.30.0-stretch

RUN mkdir -p /gads/bin
WORKDIR /gads
EXPOSE 8080

RUN apt update && apt install -y liblua5.3-dev ssmtp mailutils wait-for-it chromium nano

COPY Makefile.PL /gads
COPY bin/output_cpanfile /gads/bin
RUN cd /gads && perl bin/output_cpanfile > cpanfile && cpanm --notest /gads

RUN sed -i 's/mailhub=mail/mailhub=mailhog:1025/' /etc/ssmtp/ssmtp.conf

CMD wait-for-it db:5432 -- dbic-migration upgrade -Ilib --schema_class='GADS::Schema' --dsn='dbi:Pg:database=postgres;host=db' && starman --port 3000 bin/app.psgi
