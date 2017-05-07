use strict;
use warnings;

use DateTime;
use DBIx::Class::Migration::RunScript;
use JSON qw(encode_json);
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    foreach my $user ($schema->resultset('User')->all)
    {
        my $session_settings = {};
        if (my $view = $user->lastview)
        {
            $session_settings = {
                view => {
                    $view->instance_id => $view->id,
                },
            };
        }
        $user->update({
            lastview         => undef,
            session_settings => encode_json($session_settings),
        });
    }
};
