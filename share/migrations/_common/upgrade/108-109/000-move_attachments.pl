use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
use FindBin;
use Log::Report;

use lib "$FindBin::Bin/../lib";

use File::Basename qw(basename);
use Config::Any    ();

my $config_fn = basename $0 . './config.yml';

my $config = Config::Any->load_files(
    {
        files   => [$config_fn],
        use_ext => 1,
    }
);

my $conf = $config->[0]{'config.yml'} or die "No config found";

migrate {
    my $schema = shift->schema;

    GADS::Config->instance( config => $conf );

    $schema->storage->connect_info( [ sub { $schema->storage->dbh }, { quote_names => 1 } ] );

    my $rs = $schema->resultset('Fileval')->search( {}, { page => 1, rows => 100, order_by => 'me.id' } );

    my $pager     = $rs->pager;
    my $page      = $pager->current_page;
    my $last_page = $pager->last_page;
    do {
        $rs = $rs->search( {}, { page => $page } );
        notice __x "Page {page} of {last}", page => $page, last => $last_page;
        $pager->current_page($page);
        foreach my $file ( $rs->all ) {
            my $target = GADS::Schema::Result::Fileval::file_to_id($file);
            $target->dir->mkpath;
            $target->spew( iomode => '>:raw', $file->content );
        }
        $page = $pager->next_page;
    } while ($page);
};
