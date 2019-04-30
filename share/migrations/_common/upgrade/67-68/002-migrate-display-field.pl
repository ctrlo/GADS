use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    # Rename all delete_noneed_approval permissions to purge
    foreach my $layout ($schema->resultset('Layout')->search({
        display_field => { '!=' => undef },
    })->all)
    {
        my $operator = $layout->display_matchtype eq 'exact_negative'
            ? 'not_equal'
            : $layout->display_matchtype eq 'contains_negative'
            ? 'not_contains'
            : $layout->display_matchtype eq 'exact'
            ? 'equal'
            : $layout->display_matchtype eq 'contains'
            ? 'contains'
            : 'equal'; # default

        $schema->resultset('DisplayField')->create({
            layout_id        => $layout->id,
            display_field_id => $layout->display_field->id,
            regex            => $layout->display_regex,
            operator         => $operator,
        });

        $layout->update({
            display_field     => undef,
            display_regex     => undef,
            display_matchtype => undef,
        });
    }
};
