use strict;
use warnings;
use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    # Storage of child records change in this schema
    foreach my $child (
        $schema->resultset('Current')->search({
            parent_id => { '!=' => undef },
        })->all
    )
    {
        foreach my $child_record (
            $schema->resultset('Record')->search({
                current_id => $child->id,
            })->all
        )
        {
            foreach my $type (qw/Curval Date Daterange Enum File Intgr Person String/)
            {
                # Existing records are unique values
                $schema->resultset($type)->search({
                    record_id => $child_record->id,
                })->update({ child_unique => 1 });

                # Inherited were missing under old schema. Add them.
                my $parentval_rs = $schema->resultset($type)->search({
                        record_id => $child->parent->record_id,
                });
                $parentval_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
                foreach my $parentval ($parentval_rs->all)
                {
                    next if $schema->resultset($type)->search({
                        record_id => $child_record->id,
                        layout_id => $parentval->{layout_id},
                    })->count;
                    $parentval->{record_id} = $child_record->id;
                    delete $parentval->{id};
                    $schema->resultset($type)->create($parentval);
                }
            }
        }
    }
};
