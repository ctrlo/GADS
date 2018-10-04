use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    foreach my $instance ($schema->resultset('Instance')->all)
    {
        my $count;
        foreach my $current ($schema->resultset('Current')->search(
            { instance_id => $instance->id },
            { order_by => 'me.id' })->all
        )
        {
            $current->update({ serial => ++$count });
        }
    }
};
