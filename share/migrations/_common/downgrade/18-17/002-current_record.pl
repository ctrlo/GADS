use strict;
use warnings;
use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    foreach my $current ($schema->resultset('Current')->all)
    {
        # Existing records are unique values
        my $record = $schema->resultset('Record')->search({
            current_id => $current->id,
            approval   => 0,
        },{
            order_by => { -desc => [qw/created id/] },
            rows     => 1,
        })->next;
        $current->update({ record_id => $record->id });
    }
};
