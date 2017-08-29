use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    # New super-admin permission
    my $superadmin = $schema->resultset('Permission')->create({
        name        => 'superadmin',
        description => 'Super-administrator',
    });
    my %permissions = (
        delete                 => 'Delete records',
        delete_noneed_approval => 'Delete records approval not needed',
        download               => 'Download records',
        layout                 => 'Manage fields',
        message                => 'Send messages',
        view_create            => 'Create and edit views',
        create_child           => 'Create and edit child records',
        bulk_update            => 'Bulk update records',
        link                   => 'Create and manage linked records',
    );

    # Create replica groups for old global permissions, but only ones used
    foreach my $site ($schema->resultset('Site')->all)
    {
        foreach my $permission (keys %permissions)
        {
            my @user_permissions = $schema->resultset('Permission')->search({
                'me.name'             => $permission,
                'user.site_id'        => $site->id,
                'user_permissions.id' => { '!=' => undef },
            },
            {
                prefetch => {
                    user_permissions => 'user',
                },
            })->all or next;
            my @users;
            foreach my $us (@user_permissions)
            {
                push @users, $_->user
                    foreach $us->user_permissions;
            }

            my $group = $schema->resultset('Group')->create({
                name    => $permissions{$permission},
                site_id => $site->id,
            });

            foreach my $user (@users)
            {
                $schema->resultset('UserGroup')->create({
                    user_id  => $user->id,
                    group_id => $group->id,
                });

                # Make any existing layout editors into super-admins. These users are
                # more likely to need this permission than users with the "manage user"
                # permission
                $schema->resultset('UserPermission')->create({
                    user_id       => $user->id,
                    permission_id => $superadmin->id,
                }) if $permission eq 'layout';
            }

            foreach my $instance ($schema->resultset('Instance')->search({ site_id => $site->id })->all)
            {
                $schema->resultset('InstanceGroup')->create({
                    instance_id => $instance->id,
                    group_id    => $group->id,
                    permission  => $permission,
                });
            }

            foreach my $us (@user_permissions)
            {
                $_->delete
                    foreach $us->user_permissions;
            }
        }
    }
    $schema->resultset('Permission')->search({
        name => [keys %permissions],
    })->delete;
};
