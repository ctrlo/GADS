#!/usr/bin/env perl
use Dancer2;
use FindBin '$RealBin';
# Need Log::Report loaded to be able to use report() function
use Log::Report 'linkspace', syntax => 'LONG';
# Also need to load Dancer2 plugin, to ensure logging configuration is loaded now
use Dancer2::Plugin::LogReport 'linkspace';
use Plack::Builder;
use Plack::Handler::FCGI;

# For some reason Apache SetEnv directives dont propagate
# correctly to the dispatchers, so forcing PSGI and env here
# is safer.
set apphandler => 'PSGI';
set environment => 'production';

# Set the warning signal handler before loading GADS (via app.psgi) to
# redirect any warnings to Log::Report during compilation, as well as
# while the application runs. Include the message class no_session for these
# warnings to prevent them being displayed to the user (adding no_session
# ensures that they are not sent to the session message stash)
$SIG{__WARN__} = sub { report WARNING => shift, _class => 'no_session' };

my $psgi = path($RealBin, '..', 'bin', 'app.psgi');
my $app = do($psgi);
die "Unable to read startup script: $@" if $@;

my $server = Plack::Handler::FCGI->new(nproc => 5, detach => 1);

$server->run($app);
