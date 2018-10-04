use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

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

    my @group_names = values %permissions;

    # Create permissions that would have been deleted
    foreach my $permission (keys %permissions)
    {
        $permissions{$permission} = $schema->resultset('Permission')->create({
            name        => $permission,
            description => $permissions{$permission},
        });
    }

    my $superadmin_rs = $schema->resultset('Permission')->search({name => 'superadmin'});
    
    foreach my $site ($schema->resultset('Site')->all)
    {
        my $ig_rs = $schema->resultset('InstanceGroup')->search({
            site_id => $site->id,
        },{
            join => 'instance',
        });
        foreach my $table_perm ($ig_rs->all)
        {
            # For each group entry, add the permissions into the users of that group
            foreach my $user_group ($table_perm->group->user_groups)
            {
                next unless $permissions{$table_perm->permission}; # New permission not applicable
                $schema->resultset('UserPermission')->find_or_create({
                    user_id       => $user_group->user->id,
                    permission_id => $permissions{$table_perm->permission}->id,
                });
            }
        }
        $ig_rs->delete;

        # Delete groups that were created during upgrade, but only if there is
        # only exactly one (could be others created by the user)
        foreach my $name (@group_names)
        {
            my $rs = $schema->resultset('Group')->search({
                name    => $name,
                site_id => $site->id,
            });
            if ($rs->count == 1)
            {
                $_->user_groups->delete foreach $rs->all;
                $rs->delete unless $rs->next->layout_groups;
            }
        }
    }

    # Delete super-admin permission
    $_->user_permissions->delete foreach $superadmin_rs->all;
    $superadmin_rs->delete;
};
