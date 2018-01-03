use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    # Rename all delete_noneed_approval permissions to purge
    $schema->resultset('InstanceGroup')->search({
        permission => 'delete_noneed_approval',
    })->update({
        permission => 'purge',
    });

    # Change previously automatically-generated group names
    $schema->resultset('Group')->search({
        name => 'Delete records approval not needed',
    })->update({
        name => 'Purge deleted records',
    });
};
