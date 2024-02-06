FROM perl:5.34
RUN ["mkdir","/app"]
COPY ./ /app
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive
ENV POSTGRES_HOST = "localhost"
ENV POSTGRES_USER = "postgres"
ENV POSTGRES_PASSWORD = "postgres"
ENV POSTGRES_DB = "postgres"
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
RUN ["apt-get","install","-y","libalgorithm-dependency-perl","libdancer-plugin-auth-extensible-perl","libfile-libmagic-perl"]
RUN ["cpan","-T","CPAN","YAML","Algorithm::Dependency::Ordered","CGI::Deurl::XS","Crypt::URandom","CtrlO::Crypt::XkcdPassword","CtrlO::PDF"]
RUN ["cpan","-T","DBD::Pg","DBIx::Class::Helper::ResultSet::DateMethods1","DBIx::Class::Migration","DBIx::Class::ResultClass::HashRefInflator"]
RUN ["cpan","-T","Dancer2","Dancer2::Plugin::Auth::Extensible","Dancer2::Plugin::Auth::Extensible::Provider::DBIC","Dancer2::Plugin::DBIC"]
RUN ["cpan","-T","Dancer2::Plugin::LogReport","Data::Compare","Date::Holidays::GB","DateTime","DateTime::Event::Random","DateTime::Format::CLDR"]
RUN ["cpan","-T","DateTime::Format::DateManip","DateTime::Format::ISO8601","DateTime::Format::SQLite","DateTime::Format::Strptime"]
RUN ["cpan","-T","DateTime::Span","File::BOM","File::LibMagic","HTML::FromText","HTML::Scrubber","Inline::Lua","List::Compare","List::MoreUtils"]
RUN ["cpan","-T","Log::Log4perl","Log::Report","Mail::Message","Mail::Transport::Sendmail","Math::Random::ISAAC::XS","Math::Round","MooX::Singleton"]
RUN ["cpan","-T","MooX::Types::MooseLike::DateTime","Net::OAuth2::AuthorizationServer::PasswordGrant","Net::SAML2","PDF::Table","Plack"]
RUN ["cpan","-T","Session::Token","Starman","String::CamelCase","Test::MockTime","Test::More","Text::Autoformat","Text::CSV::Encoded"]
RUN ["cpan","-T","Text::Markdown","Tie::Cache","Tree::DAG_Node","URL::Encode","WWW::Form::UrlEncoded::XS","WWW::Mechanize::Chrome","namespace::clean"]
RUN ["cpan","-T","."]
RUN ["chmod","+x","./bin/docker-app.pl"]
RUN ["chmod","+x","./bin/setupdb.sh"]
ENTRYPOINT [ "./bin/docker-app.pl" ]