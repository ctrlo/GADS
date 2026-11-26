use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

our %prereq_pm = (
    'Algorithm::Dependency::Ordered'                    => 0,
    'Auth::Yubikey_WebClient'                           => 0,
    'Authen::Oath'                                      => 0,
    'CGI::Deurl::XS'                                    => 0,
    'Convert::Base32'                                   => 0,
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
    'Imager::QRCode'                                    => 0,
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
    'Test::TempDir::Tiny' => 0,
    'DBD::SQLite'         => 0,
    'Test::Tempdir::Tiny' => 0,
);

our %aliases = (
    'Algorithm::Dependency::Ordered'                  => 'Algorithm::Dependency',
    'Auth::Yubikey_WebClient'                         => 'Auth::Yubikey::WebClient',
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

package MY;

sub get_prereq {
    my $first = 1;
    my @keys = sort keys %prereq_pm;
    open my $fh, '>>Makefile.deps';
    print $fh "deb_control_deps: deb_control_init\n";
    for my $module (@keys) {
        next if $module eq 'Starman'; # Skip and add later as this isn't a Perl module and we want it to be the last entry in the list
        my $localModule = defined $aliases{$module} ? $aliases{$module} : $module;
        next if $localModule eq ''; # Skip this module as it is already covered by another module
        $localModule =~ s/::/-/g;
        $localModule =~ tr/A-Z/a-z/;
        $localModule = "lib$localModule-perl";
        print $fh $first ?
            # Is this the first entry? if so, just append to the result
            "\t\$(NOECHO) \$(ECHO) 'depends: $localModule (>= $prereq_pm{$module}),' >> \$(CTRLFILE)" :
            "\n\t\$(NOECHO) \$(ECHO) ' $localModule (>= $prereq_pm{$module}),' >> \$(CTRLFILE)";
        $first = 0;
    }
    print $fh "\n\t\$(NOECHO) \$(ECHO) ' starman (>= 0)' >> \$(CTRLFILE)";
    print $fh "\n";
    close $fh;
}

sub get_deps {
    my @all_deps = (sort keys %prereq_pm, sort keys %test_pm);
    open my $fh, '>Makefile.deps';
    print $fh 'DEPS := ' . join(' ', @all_deps) . "\n";
    print $fh "\n";
    print $fh "installdeps:\n";
    print $fh "\t\$(NOECHO) cpan \$(DEPS)\n";
    print $fh "\n";
    close $fh;
}

# Add to the makefile (at the end)
sub postamble {
    # In theory the get_deps sub should clobber the Makefile.deps, but I want to be sure
    unlink 'Makefile.deps' if -e 'Makefile.deps';
    get_deps();
    get_prereq();
    return "include Makefile.extra\n";
}
