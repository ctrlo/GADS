use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    # Rename all purge permissions to delete_noneed_approval
    $schema->resultset('InstanceGroup')->search({
        permission => 'purge',
    })->update({
        permission => 'delete_noneed_approval',
    });

    # Revert previously changed group names
    $schema->resultset('Group')->search({
        name => 'Purge deleted records',
    })->update({
        name => 'Delete records approval not needed',
    });
};
