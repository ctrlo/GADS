use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    # Find all users with a view limit
    $schema->resultset('Layout')->search({
        type => [ 'date', 'daterange' ],
    })->update({
        options => '{"show_datepicker":"1"}',
    });
};
