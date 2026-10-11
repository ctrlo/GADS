use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    foreach my $widget ($schema->resultset('Widget')->all)
    {
        if ($widget->type eq 'timeline')
        {
            $widget->update({
                tl_options => $widget->options,
            });
        }
        elsif ($widget->type eq 'globe')
        {
            $widget->update({
                globe_options => $widget->options,
            });
        }
    }

    # Record dashboards not relevant after downgrade, and if remaining will
    # cause problems displaying the original table dashboards
    $schema->resultset('Widget')->search({
        'dashboard.type' => 'record',
    },{
        join => 'dashboard',
    })->delete;
    $schema->resultset('Dashboard')->search({ type => 'record' })->delete;
};
