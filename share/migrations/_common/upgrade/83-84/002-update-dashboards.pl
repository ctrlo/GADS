use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
use Log::Report;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    # If there is more than one site ID then the site dashboard will belong to
    # only one of those. Comment out this error statement and then fix that.
    #error "More than one site, manual intervention required"
    #    if $schema->resultset('Site')->count > 1;

    foreach my $dashboard ($schema->resultset('Dashboard')->all)
    {
        if ($dashboard->instance_id)
        {
            $dashboard->update({
                site_id => $dashboard->instance->site_id,
            });
        }
        elsif ($dashboard->user_id)
        {
            $dashboard->update({
                site_id => $dashboard->user->site_id,
            });
        }
        else {
            $dashboard->update({
                site_id => $schema->resultset('Site')->next->id,
            });
        }
    }
};
