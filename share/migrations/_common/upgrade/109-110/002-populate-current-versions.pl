use strict;
use warnings;

use feature 'say';

use DBIx::Class::Migration::RunScript;
use Log::Report;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    my $rec_class = $schema->class('Record');
    $rec_class->might_have(
        record_later => 'Record',
        sub {
            my $args = shift;
            return {
                "$args->{foreign_alias}.current_id"  => { -ident => "$args->{self_alias}.current_id" },
                -or => [
                    {
                        "$args->{foreign_alias}.created" => { '>' => \"$args->{self_alias}.created" },
                    },
                    {
                        "$args->{foreign_alias}.created" => { '=' => \"$args->{self_alias}.created" },
                        "$args->{foreign_alias}.id"      => { '>' => \"$args->{self_alias}.id" },
                    },
                ],
                "$args->{foreign_alias}.approval"    => 0,
            };
        }
    );

    $schema->unregister_source('Record');
    $schema->register_class(Record => $rec_class);

    my $rs = $schema->resultset('Current')->search({
        'records.approval'        => 0,
        'record_later.current_id' => undef,
    },{
        page     => 1,
        rows     => 100,
        order_by => 'me.id',
        prefetch => {
            records => 'record_later',
        },
    });

    my $pager     = $rs->pager;
    my $page      = $pager->current_page;
    my $last_page = $pager->last_page;
    while ($page)
    {
        $rs = $rs->search( {}, { page => $page } );
        say "Writing record versions $page of $last_page";
        $pager->current_page($page);
        foreach my $current ($rs->all)
        {
            my @records = $current->records; # Should only be one for latest version
            @records == 1
                or error __x"Unexpected number of records for {count} for {current_id}",
                    count => scalar @records, current_id => $current->id;
            my $latest = $records[0]->id;
            $current->update({
                current_version_id => $latest,
            });
        }
        $page = $pager->next_page;
    }
};
