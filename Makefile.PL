use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

our %prereq_pm = (
    'Algorithm::Dependency::Ordered'                    => 0,
    'CGI::Deurl::XS'                                    => 0,
    'Crypt::OpenSSL::Verify'                            => 0,
    'Crypt::OpenSSL::Random'                            => 0,
    'Crypt::URandom'                                    => 0,
    'CtrlO::Crypt::XkcdPassword'                        => 0,
    'CtrlO::PDF'                                        => '0.06',
    'Dancer2'                                           => '0.300001',
    'Dancer2::Plugin::Auth::Extensible'                 => '0.601',
    'Dancer2::Plugin::Auth::Extensible::Provider::DBIC' => '0.623',
    'Dancer2::Plugin::DBIC'                             => '0.0013',
    'Dancer2::Plugin::LogReport'                        => '1.10',
    'Data::Compare'                                     => 0,
    'Date::Holidays::GB'                                => 0,
    'DateTime'                                          => 0,
    'DateTime::Event::Random'                           => 0,
    'DateTime::Format::CLDR'                            => 0,
    'DateTime::Format::DateManip'                       => 0,
    'DateTime::Format::ISO8601'                         => 0,
    'DateTime::Format::SQLite'                          => 0,
    'DateTime::Format::Strptime'                        => 0,
    'DateTime::Format::XSD'                             => 0,
    'DateTime::Hires'                                   => 0,
    'DateTime::Span'                                    => 0,
    'DBD::Pg'                                           => 0,
    'DBIx::Class::Helper::ResultSet::DateMethods1'      => 0,
    'DBIx::Class::Migration'                            => 0,
    'DBIx::Class::ResultClass::HashRefInflator'         => 0,
    'File::BOM'                                         => 0,
    'File::LibMagic'                                    => 0,
    'File::Slurper'                                     => 0,
    'HTML::FromText'                                    => 0,
    'HTML::Scrubber'                                    => 0,
    'Inline::Lua'                                       => '0.16',
    'List::Compare'                                     => 0,
    'List::MoreUtils'                                   => 0,
    'List::Util'                                        => '1.45',
    'Log::Log4perl'                                     => 0,
    'Log::Report'                                       => '1.28',
    'Mail::Message'                                     => 0,
    'Mail::Transport::Sendmail'                         => 0,
    'Math::Random::ISAAC::XS'                           => 0,
    'Math::Round'                                       => 0,
    'MooseX::Types::URI'                                => 0,
    'MooseX::Types::DateTime'                           => 0,
    'MooseX::Types::Common'                             => 0,
    'MooX::Singleton'                                   => 0,
    'MooX::Types::MooseLike::DateTime'                  => 0,
    'namespace::clean'                                  => 0,
    'Net::OAuth2::AuthorizationServer::PasswordGrant'   => 0,
    'Net::SAML2'                                        => 0,
    'Plack'                                             => '1.0047',
    'PDF::Table'                                        => '1.006',
    'Session::Token'                                    => 0,
    'Starman'                                           => 0,
    'String::CamelCase'                                 => 0,
    'Test::MockTime'                                    => 0,
    'Test::More'                                        => '1.302112',
    'Text::Autoformat'                                  => 0,
    'Text::CSV::Encoded'                                => 0,
    'Text::Markdown'                                    => 0,
    'Tie::Cache'                                        => 0,
    'Tree::DAG_Node'                                    => 0,
    'URI::Encode'                                       => 0,
    'URL::Encode'                                       => 0,
    'URN::Oasis::SAML2'                                 => 0,
    'WWW::Form::UrlEncoded::XS'                         => 0,
    'WWW::Mechanize::Chrome'                            => 0,
    'XML::Enc'                                          => 0,
    'XML::Generator'                                    => 0,
    'XML::Sig'                                          => 0,
    'YAML'                                              => 0,
);

our %test_pm = (
    'Test::TempDir::Tiny' => 0
);

our %aliases = (
    'Algorithm::Dependency::Ordered'                  => 'Algorithm::Dependency',
    'DBIx::Class::Helper::ResultSet::DateMethods1'    => 'DBIx::Class::Helpers',
    'DBIx::Class::Migration'                          => 'DBIx::Class',
    'DBIx::Class::ResultClass::HashRefInflator'       => '', # Covered above - leave empty to avoid duplicate entries in the control file
    'Mail::Transport::Sendmail'                       => 'Mail::Transport',
    'Net::OAuth2::AuthorizationServer::PasswordGrant' => 'Net::OAuth2::AuthorizationServer',
    'Tree::DAG_Node'                                  => 'Tree::DAGNode',
    'DateTime::Span'                                  => 'DateTime::Set',
    'List::Util'                                      => 'Scalar::List::Utils',
    'Test::More'                                      => 'Test::Simple',
);

return 1 if caller();

WriteMakefile(
    NAME                => 'GADS',
    AUTHOR              => q{Ctrl O <info@ctrlo.com>},
    VERSION_FROM        => 'lib/GADS.pm',
    ABSTRACT            => 'Web based data store, designed to replace spreadsheets used to store lists of data',
    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM           => \%prereq_pm,
    TEST_REQUIRES       => \%test_pm,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GADS-* GADS_*' },
);

sub get_prereq {
    my $first = 1;
    my $result = "\t\@echo 'Depends: ";
    my @keys = sort keys %prereq_pm;
    for my $module (@keys) {
        next if $module eq 'Starman'; # Skip and add later as this isn't a Perl module and we want it to be the last entry in the list
        my $localModule = defined $aliases{$module} ? $aliases{$module} : $module;
        $localModule =~ s/::/-/g;
        $localModule =~ tr/A-Z/a-z/;
        $localModule = "lib$localModule-perl";
        next if $localModule eq ''; # Skip this module as it is already covered by another module
        $result .= $first ? 
            # Is this the first entry? if so, just append to the result
            "$localModule (>= $prereq_pm{$module}),' >> GADS-\$(VERSION)/DEBIAN/control" : 
            "\n\t\@echo ' $localModule (>= $prereq_pm{$module}),' >> GADS-\$(VERSION)/DEBIAN/control";
        $first = 0;
    }
    $result .= "\n\t\@echo ' starman (>= 0)' >> GADS-\$(VERSION)/DEBIAN/control";
    return $result;
}

# Add to the makefile (at the end)
sub MY::postamble {
    # Makefile is verbatim, you cannot indent the below string to make it "easier to read"
    # Don't forget - Makefile doesn't like space indentation, use tabs all the way here!
    my $result = <<'END_MAKEFILE';

check_yarn:
	@echo "Checking for yarn"
	@yarn --version || (echo "yarn is not installed. Please install it from https://yarnpkg.com/getting-started/install" && exit 1)

yarn: check_yarn
	@echo "Installing node modules"
	@yarn --frozen-lockfile
	@npx update-browserslist-db@latest

yarn_build: yarn
	@echo "Building Bundles"
	@NODE_ENV=production yarn webpack
	@git checkout ./public/js/fengari-web.js

build_web: yarn_build

deb_mkdirs:
	@echo "Creating Directories"
	@mkdir -p GADS-$(VERSION)/srv/GADS
	@mkdir -p GADS-$(VERSION)/DEBIAN

deb_copy: deb_mkdirs
	@echo "Copying files"
	@cp -r bin environments lib public share views config.yml-example GADS-$(VERSION)/srv/GADS

deb_control: deb_copy
	@rm -f GADS-$(VERSION)/DEBIAN/control
	@echo "Creating package manifest"
	@echo "Package: GADS" > GADS-$(VERSION)/DEBIAN/control
	@echo "Version: $(VERSION)" >> GADS-$(VERSION)/DEBIAN/control
	@echo "Section: database" >> GADS-$(VERSION)/DEBIAN/control
	@echo "Priority: optional" >> GADS-$(VERSION)/DEBIAN/control
	@echo "Architecture: amd64" >> GADS-$(VERSION)/DEBIAN/control
%prereq%
	@echo 'Recommends: postgresql (>= 0)' >> GADS-$(VERSION)/DEBIAN/control
	@echo "Maintainer: CtrlO Ltd <info@ctrlo.com>" >> GADS-$(VERSION)/DEBIAN/control
	@echo "Description: Globally Accessible Data Store (GADS) is a web application for storing and sharing data across an organisation." >> GADS-$(VERSION)/DEBIAN/control
	@echo " It provides a simple interface for creating and managing data, as well as powerful features for sharing and collaborating on data with others." >> GADS-$(VERSION)/DEBIAN/control
	@echo " GADS is built using the Dancer2 web framework and is designed to be easy to use and extendable." >> GADS-$(VERSION)/DEBIAN/control
	@echo "Vcs-Git: https://github.com/ctrlo/GADS.git" >> GADS-$(VERSION)/DEBIAN/control

deb_package: deb_control
	@echo "Creating package for GADS-$(VERSION)"
	@cd GADS-$(VERSION)
	@dpkg-deb --build ./GADS-$(VERSION) ./GADS_$(VERSION).deb

deb_clean: deb_package
	@echo "Cleaning up..."
	@rm -rf GADS-$(VERSION)

deb_build: build_web deb_clean
END_MAKEFILE

    # Get the pre-requisites as defined in this file as a string for building the package
    my $prereq = get_prereq();
    # Replace the string '%prereq%' in the build script with the dependencies here
    $result =~ s/%prereq%/$prereq/g;
    return $result;
}
