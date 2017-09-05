use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                => 'GADS',
    AUTHOR              => q{Ctrl O <info@ctrlo.com>},
    VERSION_FROM        => 'lib/GADS.pm',
    ABSTRACT            => 'Web based data store, designed to replace spreadsheets used to store lists of data',
    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Algorithm::Dependency::Ordered'            => 0,
        'Dancer2'                                   => 0.201,
        'Dancer2::Plugin::Auth::Extensible'         => 0.601,
        'Dancer2::Plugin::Auth::Extensible::Provider::DBIC' => 0.623,
        'Dancer2::Plugin::DBIC'                     => 0.0013,
        'Dancer2::Plugin::LogReport'                => 1.10,
        'Data::Compare'                             => 0,
        'DateTime'                                  => 0,
        'DateTime::Event::Random'                   => 0,
        'DateTime::Format::Strptime'                => 0,
        'DateTime::Format::CLDR'                    => 0,
        'DateTime::Format::DateManip'               => 0,
        'DateTime::Format::SQLite'                  => 0,
        'DateTime::Span'                            => 0,
        'DBIx::Class::Helper::ResultSet::DateMethods1' => 0,
        'DBIx::Class::Migration'                    => 0,
        'DBIx::Class::ResultClass::HashRefInflator' => 0,
        'HTML::FromText'                            => 0,
        'List::Compare'                             => 0,
        'Log::Report'                               => 1.16,
        'Mail::Message'                             => 0,
        'Math::Round'                               => 0,
        'MooX::Singleton'                           => 0,
        'MooX::Types::MooseLike::DateTime'          => 0,
        'namespace::clean'                          => 0,
        'Session::Token'                            => 0,
        'String::CamelCase'                         => 0,
        'Test::MockTime'                            => 0,
        'Test::More'                                => 0,
        'Text::Autoformat'                          => 0,
        'Text::CSV::Encoded'                        => 0,
        'Tie::Cache'                                => 0,
        'Tree::DAG_Node'                            => 0,
        'WWW::Mechanize::PhantomJS'                 => 0,
        'YAML'                                      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GADS-*' },
);
