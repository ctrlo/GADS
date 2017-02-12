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

    # Create default site if it doesn't exist
    if (!$schema->resultset('Site')->count)
    {
        my $site = $schema->resultset('Site')->create({
            created => DateTime->now,
        });
        $schema->resultset('Audit')->update({ site_id => $site->id });
        $schema->resultset('Group')->update({ site_id => $site->id });
        $schema->resultset('Import')->update({ site_id => $site->id });
        $schema->resultset('Instance')->update({ site_id => $site->id });
        $schema->resultset('Organisation')->update({ site_id => $site->id });
        $schema->resultset('Title')->update({ site_id => $site->id });
        $schema->resultset('User')->update({ site_id => $site->id });
    }

    foreach my $site ($schema->resultset('Site')->all)
    {
        # See if we can find an instance with anything in
        my ($instance) = $schema->resultset('Instance')->search({
            email_welcome_text => { '!=' => undef },
            email_welcome_text => { '!=' => '' },
        })->all;
        $instance = $schema->resultset('Instance')->next
            if !$instance;

	# Move site settings from instance to site
        $site->update({
	    email_welcome_text         => $instance->email_welcome_text,
	    email_welcome_subject      => $instance->email_welcome_subject,
	    email_delete_text          => $instance->email_delete_text,
	    email_delete_subject       => $instance->email_delete_subject,
	    email_reject_text          => $instance->email_reject_text,
	    email_reject_subject       => $instance->email_reject_subject,
	    register_text              => $instance->register_text,
	    homepage_text              => $instance->homepage_text,
	    homepage_text2             => $instance->homepage_text2,
	    register_title_help        => $instance->register_title_help,
	    register_freetext1_help    => $instance->register_telephone_help,
	    register_email_help        => $instance->register_email_help,
	    register_organisation_help => $instance->register_organisation_help,
	    register_notes_help        => $instance->register_notes_help,
            register_freetext1_name    => 'Telephone', # Make freetext1 called telephone
            register_organisation_name => 'Organisation',
        });
        # No longer needed
        $instance->update({
	    email_welcome_text         => undef,
	    email_welcome_subject      => undef,
	    email_delete_text          => undef,
	    email_delete_subject       => undef,
	    email_reject_text          => undef,
	    email_reject_subject       => undef,
	    register_text              => undef,
	    homepage_text              => undef,
	    homepage_text2             => undef,
	    register_title_help        => undef,
	    register_telephone_help    => undef,
	    register_email_help        => undef,
	    register_organisation_help => undef,
	    register_notes_help        => undef,
        });
    }

    # Deprecate telephone into freetext1
    foreach my $user ($schema->resultset('User')->all)
    {
        $user->update({
            freetext1 => $user->telephone,
        });
        $user->update({
            telephone => undef,
        });
    }
};
