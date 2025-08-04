use strict;
use warnings;

use DateTime;
use DBIx::Class::Migration::RunScript;
use FindBin;
use Log::Report;

use feature 'say';

use lib "$FindBin::Bin/../lib";

use Config::Any ();

my $config_fn = "$FindBin::Bin/.." . ($ENV{DANCER_CONFDIR} ? "/" . $ENV{DANCER_CONFDIR} : "") . "/config.yml";

my $config = Config::Any->load_files({
    files=> [ $config_fn ],
    use_ext => 1,
});

my $conf = $config->[0]{$config_fn} or die "No config found";

migrate {
    my $schema = shift->schema;

    GADS::Config->instance(config=>$conf);

    my $guard = $schema->txn_scope_guard;

    $schema->storage->connect_info(
        [ sub { $schema->storage->dbh }, { quote_names => 1 } ] );

    foreach my $file ($schema->resultset('Fileval')->all) {
        my $target = GADS::Schema::Result::Fileval::file_to_id($file);
        say "Moving file:" . $file->name;
        $file->update({
            content => scalar $target->slurp(iomode => '<:raw'),
        });
        unlink $target->cleanup;
    }

    $guard->commit;
};
