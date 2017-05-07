use strict;
use warnings;

use DateTime;
use DBIx::Class::Migration::RunScript;
use JSON qw(decode_json);

migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    foreach my $user ($schema->resultset('User')->all)
    {
        my $session_settings = decode_json $user->session_settings;
        if (my $view = $session_settings->{view})
        {
            my ($view_id) = values %$view; # Take random one if more than one
            $user->update({
                lastview => $view_id,
            });
        }
    }
};
