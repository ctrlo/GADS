use strict;
use warnings;

use DateTime;
use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    # Migrate all user limits to the old limit_to_view column. There may be
    # more than one, in which case only the latest will be used.
    foreach my $limit ($schema->resultset('ViewLimit')->all)
    {
        $schema->resultset('User')->find($limit->user_id)->update({
            limit_to_view => $limit->view_id,
        });
    }
};
