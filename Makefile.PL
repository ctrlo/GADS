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
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer2'     => 0.11,
        'Algorithm::Dependency::Ordered'            => 0,
        'Dancer2::Plugin::Auth::Extensible'         => 0,
        'Dancer2::Plugin::DBIC'                     => 0,
        'Data::Compare'                             => 0,
        'DateTime'                                  => 0,
        'DateTime::Format::Strptime'                => 0,
        'DateTime::Span'                            => 0,
        'DBIx::Class::ResultClass::HashRefInflator' => 0,
        'HTML::FromText'                            => 0,
        'Log::Report'                               => 0,
        'Mail::Message'                             => 0,
        'namespace::clean'                          => 0,
        'Session::Token'                            => 0,
        'String::CamelCase'                         => 0,
        'Text::Autoformat'                          => 0,
        'Text::CSV::Encoded'                        => 0,
        'Tree::DAG_Node'                            => 0,
        'WWW::Mechanize::PhantomJS'                 => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GADS-*' },
);
