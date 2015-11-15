use strict;
use warnings;
use DateTime;
use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;

    my $dtf = $schema->storage->datetime_parser;
    foreach my $calc ($schema->resultset('Calc')->all)
    {
        # If it's numeric type (which will no longer exist) then
        # throw it into a string format
        my $return_format = $calc->return_format;
        $schema->resultset('Calc')->search({
            layout_id => $calc->layout_id,
        })->update({
            return_format => 'string',
        }) if $return_format eq 'numeric';

        my $oldcol = $return_format eq 'numeric'
            ? 'value_numeric'
            : $return_format eq 'integer'
            ? 'value_int'
            : $return_format eq 'date'
            ? 'value_date'
            : 'value_text';

        foreach my $row ($schema->resultset('Calcval')->search({ layout_id => $calc->layout_id }))
        {
            my $newval = $row->$oldcol || '';
            $newval =~ s/\.?0+//
                if $return_format eq 'numeric';
            $newval = $dtf->parse_date($newval)->epoch
                if $return_format eq 'date' && $newval;
            $row->update({
                value   => $newval,
            });
        }
    }
};
