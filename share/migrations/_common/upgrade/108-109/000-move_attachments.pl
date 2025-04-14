use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
use FindBin;
use Log::Report;

use feature 'say';

use lib "$FindBin::Bin/../lib";

use File::Basename qw(basename);
use Config::Any ();

my $config_fn = basename $0 . './config.yml';

my $config = Config::Any->load_files({
    files=> [ $config_fn ],
    use_ext => 1,
});

my $conf = $config->[0]{'config.yml'} or die "No config found";

migrate {
    my $schema = shift->schema;

    GADS::Config->instance(config=>$conf);

    $schema->storage->connect_info(
        [ sub { $schema->storage->dbh }, { quote_names => 1 } ] );

    foreach my $file ($schema->resultset('Fileval')->all) {
        my $target = GADS::Schema::Result::Fileval::file_to_id($file);
        say "Moving file:" . $file->name;
        $target->dir->mkpath;
        $target->spew(iomode => '>:raw', $file->content); 
   }
};
