FROM perl

RUN mkdir -p /gads
WORKDIR /gads
EXPOSE 8080

RUN apt update && apt install -y liblua5.3-dev ssmtp mailutils wait-for-it

COPY Makefile.PL /gads
RUN cpanm --notest $(perl -wE 'our %prereq_pm; require "/gads/Makefile.PL"; print join " ", sort keys %prereq_pm')

RUN sed -i 's/mailhub=mail/mailhub=mailhog:1025/' /etc/ssmtp/ssmtp.conf

CMD wait-for-it db:5432 -- dbic-migration upgrade -Ilib --schema_class='GADS::Schema' --dsn='dbi:Pg:database=postgres;host=db' && perl bin/app.pl
