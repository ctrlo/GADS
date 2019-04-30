use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    foreach my $display_field ($schema->resultset('DisplayField')->all)
    {
        my $operator = $display_field->operator eq 'not_equal'
            ? 'exact_negative'
            : $display_field->operator eq 'not_contains'
            ? 'contains_negative'
            : $display_field->operator eq 'equal'
            ? 'exact'
            : $display_field->operator eq 'contains'
            ? 'contains'
            : die("Unknown matchtype: ".$display_field->operator);
        my $layout = $schema->resultset('Layout')->find($display_field->layout_id);
        $layout->update({
            display_field     => $display_field->display_field_id,
            display_regex     => $display_field->regex,
            display_matchtype => $operator,
        });
    }
};
