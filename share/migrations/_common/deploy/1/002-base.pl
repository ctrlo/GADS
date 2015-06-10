use strict;
use warnings;
use DBIx::Class::Migration::RunScript;
 
migrate {
 
    my $permission_rs = shift->schema->resultset('Permission');

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
        },
    ]);
 
};

