use strict;
use warnings;
use DBIx::Class::Migration::RunScript;
 
migrate {

    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    my $permission_rs = $schema->resultset('Permission');

    $permission_rs->populate
    ([
        {
            name        => 'delete',
            description => 'User can delete records',
            order       => 1,
        },{
            name        => 'delete_noneed_approval',
            description => 'User does not need approval when deleting records',
            order       => 2,
        },{
            name        => 'useradmin',
            description => 'User can manage other user accounts',
            order       => 3,
        },{
            name        => 'download',
            description => 'User can download data',
            order       => 4,
        },{
            name        => 'layout',
            description => 'User can administer layout, views and graph',
            order       => 5,
        },{
            name        => 'message',
            description => 'User can send messages',
            order       => 6,
        },{
            name        => 'view_create',
            description => 'User can create, modify and delete views',
            order       => 7,
        },{
            name        => 'create_related',
            description => 'User can create related records and edit fields of existing related records',
            order       => 8,
        },{
            name        => 'link',
            description => 'User can link records between data sets',
            order       => 9,
        },{
            name        => 'audit',
            description => 'User can access audit data',
            order       => 10,
        },
    ]);

    my $user = $schema->resultset('User')->create({
        username => 'info@ctrlo.com',
        email    => 'info@ctrlo.com',
    });

    my ($useradmin) = $schema->resultset('Permission')->search({
        name => 'useradmin',
    });

    $schema->resultset('UserPermission')->create({
        user_id       => $user->id,
        permission_id => $useradmin->id,
    });

    $schema->resultset('Instance')->create({
        name => 'GADS',
    });
};
