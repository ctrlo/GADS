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
                options    => $widget->tl_options,
                tl_options => undef,
            });
        }
        elsif ($widget->type eq 'globe')
        {
            $widget->update({
                options       => $widget->globe_options,
                globe_options => undef,
            });
        }
    }

    # Only table dashboards at point of upgrade
    $schema->resultset('Dashboard')->update({ type => 'table' });
    $schema->resultset('Instance')->update({ record_display => 'record' });
};
