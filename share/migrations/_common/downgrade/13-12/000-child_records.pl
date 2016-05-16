use strict;
use warnings;
use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    foreach my $type (qw/Curval Date Daterange Enum File Intgr Person String/)
    {
        # Existing records are unique values
        $schema->resultset($type)->search({
            'current.parent_id' => { '!=' => undef },
            child_unique        => 0,
        },{
            join => { record => 'current' },
        })->delete;
    }
};
