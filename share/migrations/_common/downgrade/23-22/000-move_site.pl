use strict;
use warnings;

use DateTime;
use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    foreach my $site ($schema->resultset('Site')->all)
    {
        # Get first instance to fill in info from site
        my $instance = $schema->resultset('Instance')->search({
            site_id => $site->id,
        },{
            order_by => { -asc => 'me.id' },
        })->next;

	# Move site settings from instance to site
        $instance->update({
	    email_welcome_text         => $site->email_welcome_text,
	    email_welcome_subject      => $site->email_welcome_subject,
	    email_delete_text          => $site->email_delete_text,
	    email_delete_subject       => $site->email_delete_subject,
	    email_reject_text          => $site->email_reject_text,
	    email_reject_subject       => $site->email_reject_subject,
	    register_text              => $site->register_text,
	    homepage_text              => $site->homepage_text,
	    homepage_text2             => $site->homepage_text2,
	    register_title_help        => $site->register_title_help,
	    register_telephone_help    => $site->register_freetext1_help,
	    register_email_help        => $site->register_email_help,
	    register_organisation_help => $site->register_organisation_help,
	    register_notes_help        => $site->register_notes_help,
        });
    }

    foreach my $user ($schema->resultset('User')->all)
    {
        $user->update({
            telephone => $user->freetext1,
        });
    }

    # Delete site if only one
    if ($schema->resultset('Site')->count == 1)
    {
        $schema->resultset('Audit')->update({ site_id => undef });
        $schema->resultset('Group')->update({ site_id => undef });
        $schema->resultset('Import')->update({ site_id => undef });
        $schema->resultset('Instance')->update({ site_id => undef });
        $schema->resultset('Organisation')->update({ site_id => undef });
        $schema->resultset('Title')->update({ site_id => undef });
        $schema->resultset('User')->update({ site_id => undef });
        $schema->resultset('Site')->delete;
    }
};
