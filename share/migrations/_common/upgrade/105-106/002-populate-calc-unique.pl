use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
use Log::Report;

migrate {
    my $schema = shift->schema;

    my $guard = $schema->txn_scope_guard;

    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [ sub { $schema->storage->dbh }, { quote_names => 1 } ] );

    my $rec_class = $schema->class('Record');
    $rec_class->might_have(
        record_later => 'Record',
        sub {
            my $args = shift;

            return {
                "$args->{foreign_alias}.current_id"  => { -ident => "$args->{self_alias}.current_id" },
                "$args->{foreign_alias}.created" => { '>' => \"$args->{self_alias}.created" },
            };
        }
    );

    #GADS::Schema->unregister_source('Record');
    #GADS::Schema->register_class(Record => $rec_class);

    $schema->unregister_source('Record');
    $schema->register_class(Record => $rec_class);

    my $rs = $schema->resultset('Current')->search({
        'record_later.id' => undef,
    },{
        prefetch => {
            records => [
                'calcvals',
                'record_later',
            ],
        },
        page => 1,
        rows => 100,
        order_by => 'me.id',
    });
    my $pager     = $rs->pager;
    my $page      = $pager->current_page;
    my $last_page = $pager->last_page;
    do {
        $rs = $rs->search({},{page => $page,});
        notice __x"Page {page} of {last}", page => $page, last => $last_page;
        $pager->current_page($page);
        foreach my $current ($rs->all)
        {
            foreach my $record ($current->records->all)
            {
                foreach my $calcval ($record->calcvals)
                {
                    my $svp = $schema->storage->svp_begin("sp_uq_calc");
                    try {
                        $schema->resultset('CalcUnique')->create({
                            layout_id       => $calcval->layout_id,
                            value_text      => $calcval->value_text,
                            value_int       => $calcval->value_int,
                            value_date      => $calcval->value_date,
                            value_numeric   => $calcval->value_numeric,
                            value_date_from => $calcval->value_date_from,
                            value_date_to   => $calcval->value_date_to,
                        });
                    };
                    if ($@ =~ /duplicate/i) # Pg: duplicate key, Mysql: Dupiicate entry
                    {
                        $schema->storage->svp_rollback("sp_uq_calc");
                        $schema->storage->svp_release("sp_uq_calc");
                    }
                    elsif ($@) {
                        $@->reportAll;
                    }
                    else {
                        $schema->storage->svp_release("sp_uq_calc");
                    }
                }
            }
        }
        $page = $pager->next_page;
    } while ($page);

    $guard->commit;
};
