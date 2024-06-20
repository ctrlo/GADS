package GADS::Helper::Changed;

# This package is based on DBIx::Class::ResultSource::View as a way to return a
# custom SQL query as the source for another query. This returns a query with a
# window function, to work out which records have changed values in a
# particular timeframe

use strict;
use warnings;

use DBIx::Class::ResultSet;

use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ResultSource/);
__PACKAGE__->mk_group_accessors('simple' => qw(is_virtual view_definition));

our $CHANGED_PARAMS;    # XXX is there a better way to pass parameters?

sub from
{   my $self = shift;

    my $column      = $CHANGED_PARAMS->{column};
    my $field       = $column->field;
    my $value_field = $column->value_field;

    # XXX These queries use the raw value of the field (e.g. id in the case of
    # an enum) rather than their textual value. This means that a value changed
    # between different enums with the same textual value will be returned as
    # having changed. Might want to change to true textual values.

    # XXX Change to DBIx::Class::Helper::WindowFunctions ?
    my $window = "first_value(${field}_2.$value_field) OVER (
        PARTITION BY record_earlier.current_id ORDER BY record_earlier.created DESC
    ) as first_value";

    # XXX It would be nice to pull the Current resultset from somewhere common,
    # with things like "records.approval = 0" already set
    local $GADS::Schema::Result::Record::RECORD_EARLIER_BEFORE =
        $CHANGED_PARAMS->{date};
    my $query = $self->schema->resultset('Current')->search(
        {
            'records.approval'     => 0,
            'me_other.instance_id' => $CHANGED_PARAMS->{instance_id},
            'records.created'      => { '>' => $CHANGED_PARAMS->{date} },
        },
        {
            alias   => 'me_other',
            columns => [
                'me_other.id', $column->field . '.' . $value_field,
                \$window,
            ],
            join => {
                records => [
                    $column->field,
                    'record_later',
                    {
                        record_earlier => $column->field,
                    },
                ]
            },

            #group_by => 'me_other.id',
        },
    )->as_query;
    local $GADS::Schema::Result::Record::RECORD_EARLIER_BEFORE = undef;
    return $query;
}

1;
