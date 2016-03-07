use strict;
use warnings;
use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;

    # Retrieve all users that have a lastrecord defined
    foreach my $user (
        $schema->resultset('User')->search(
            { lastrecord => { '!=' => undef } }
        )->all
    )
    {
        # Move lastrecord from user table to dedicated table,
        # with relevant instance ID
        my $lastrecord = $user->lastrecord;
        $schema->resultset('UserLastrecord')->create({
            instance_id => $lastrecord->current->instance->id,
            record_id   => $lastrecord->id,
            user_id     => $user->id,
        });
        $user->update({
            lastrecord => undef,
        });
    }
};
