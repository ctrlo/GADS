use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
use FindBin;

use lib "$FindBin::Bin/../lib";

use Config::Any    ();

use feature 'say';

my $config_fn = "$FindBin::Bin/../config.yml";

my $config = Config::Any->load_files(
    {
        files   => [$config_fn],
        use_ext => 1,
    }
);

my $conf = $config->[0]{$config_fn} or die "No config found";

migrate {
    my $schema = shift->schema;

    GADS::Config->instance( config => $conf );

    my $uid = getpwnam("lspace");
    my $gid = getgrnam("www-data");

    $schema->storage->connect_info( [ sub { $schema->storage->dbh }, { quote_names => 1 } ] );

    my $rs = $schema->resultset('Fileval')->search( {}, { page => 1, rows => 100, order_by => 'me.id' } );

    my $pager     = $rs->pager;
    my $page      = $pager->current_page;
    my $last_page = $pager->last_page;
    do {
        $rs = $rs->search( {}, { page => $page } );
        say "Page $page of $last_page";
        $pager->current_page($page);
        foreach my $file ( $rs->all ) {
            my $target = GADS::Schema::Result::Fileval::file_to_id($file);
            $target->dir->mkpath(0, { owner => $uid, group => $gid, mode => 600 });
            $target->spew( iomode => '>:raw', $file->content );
            # Simplest way, trying to recursively run through all files and directories would overcomplicate this IMO
            chown $uid, $gid, "$target"
              or die("Unable to change ownership of $target");
            chmod 660, "$target"
              or die("Unable to change permissions on $target");
        }
        $page = $pager->next_page;
    } while ($page);
};
