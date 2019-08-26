package GADS::Schema::ResultSet::Dashboard;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use Log::Report 'linkspace';

sub dashboard
{   my ($self, %params) = @_;

    my $user   = $params{user};
    my $layout = $params{layout};

    my $dashboard_rs = $self->search({
        'me.instance_id' => $layout->instance_id,
        'me.user_id'     => undef,
    },{
        prefetch => 'widgets',
    });

    if ($dashboard_rs->count)
    {
        my $dashboard = $dashboard_rs->next;
        $_->layout($layout) foreach $dashboard->widgets;
        return $dashboard;
    }

    my $schema = $self->result_source->schema;
    my $guard = $schema->txn_scope_guard;

    # First time this has been called. Create default dashboard using legacy
    # homepage text if it exists
    my $dashboard = $self->create({
        instance_id => $layout->instance_id,
    });

    # Can't use create_related as before_create hook does not get called
    if ($layout->homepage_text2) # Assume 2 columns of homepage
    {
        $dashboard->create_related('widgets', {
            type    => 'notice',
            h       => 6,
            w       => 6,
            x       => 6,
            y       => 0,
            content => $layout->homepage_text2,
        });
    }
    $dashboard->create_related('widgets', {
        type    => 'notice',
        h       => 6,
        w       => $layout->homepage_text2 ? 6 : 12,
        x       => 0,
        y       => 0,
        content => $layout->homepage_text,
    });

    $guard->commit;

    return $dashboard; 
}

1;
