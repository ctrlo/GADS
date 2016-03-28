use strict;
use warnings;
use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    # Create new index column based on existing values
    # This won't be as fast as native SQL, but that doesn't
    # matter and this is database agnostic
    foreach my $row (
        $schema->resultset('String')->all
    )
    {
        if (my $value = lc $row->value)
        {
            $value = substr $value, 0, 128;
            $row->update({
                value_index => $value,
            });
        }
    }
};
