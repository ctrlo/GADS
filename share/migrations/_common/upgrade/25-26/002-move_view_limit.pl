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

    # Find all users with a view limit
    foreach my $user ($schema->resultset('User')->search({ limit_to_view => { '!=' => undef } })->all)
    {
        $schema->resultset('ViewLimit')->create({
            user_id => $user->id,
            view_id => $user->limit_to_view->id,
        });
        $user->update({
            limit_to_view => undef,
        });
    }
};
