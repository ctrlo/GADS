use strict;
use warnings;
use DateTime;
use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;

    foreach my $calc ($schema->resultset('Calc')->all)
    {
        my $return_format = $calc->return_format;
        if ($return_format eq 'integer')
        {
            # Some calc fields are defined integer, whereas they
            # should be numeric. This adjusts so that data isn't lost
            if ($schema->resultset('Calcval')->search({
                layout_id => $calc->layout_id,
                value     => {
                    -like => "%.%", # Decimal point in value?
                },
            })->count)
            {
                $return_format = 'numeric';
                $schema->resultset('Calc')->search({
                    layout_id => $calc->layout_id,
                })->update({
                    return_format => 'numeric',
                });
            }
        }

        my $newcol = $return_format eq 'numeric'
            ? 'value_numeric'
            : $return_format eq 'integer'
            ? 'value_int'
            : $return_format eq 'date'
            ? 'value_date'
            : 'value_text';

        foreach my $row ($schema->resultset('Calcval')->search({ layout_id => $calc->layout_id }))
        {
            my $newval = $row->value || undef;
            $newval = DateTime->from_epoch(epoch => $newval)
                if $return_format eq 'date' && $newval;
            $row->update({
                value   => undef,
                $newcol => $newval,
            });
        }
    }
};
