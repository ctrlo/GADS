=pod
GADS - Globally Accessible Data Store
Copyright (C) 2014 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

package GADS::RecordsGroup;

use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;

extends 'GADS::Records';

# The aggregate operator to use
has operator => (
    is  => 'rw',
    isa => Str,
);

has columns => (
    is  => 'rw',
    isa => ArrayRef,
);

# The following dr_* properties specify whether to select values across a
# daterange, interpolating as required
has dr_column => (
    is  => 'rw',
    isa => Maybe[Int],
);

has dr_column_parent => (
    is => 'rw',
);

has dr_interval => (
    is  => 'rw',
    isa => Maybe[Str],
);

has dr_from => (
    is  => 'rwp',
    isa => DateAndTime,
);

has dr_to => (
    is  => 'rwp',
    isa => DateAndTime,
);

has dr_y_axis_id => (
    is => 'rw',
);

sub _compare_col
{   my ($self, $col1, $col2) = @_;
    return 0 if $col1->{id} != $col2->{id};
    return 0 if $col1->{operator} ne $col2->{operator};
    return 0 if ($col1->{parent} xor $col2->{parent});
    return 1 if !$col1->{parent} && !$col2->{parent};
    return 0 if $col1->{parent}->id != $col2->{parent}->id;
    return 1;
}

sub _build_results
{   my ($self, %options) = @_;

    # Build the full query first, to ensure that all join numbers etc are
    # calculated correctly
    my $search_query    = $self->search_query(search => 1, sort => 1);

    # Work out the field name to select, and the appropriate aggregate function
    my @select_fields;
    my @cols = @{$self->columns};
    my @parents;
    foreach my $col (@cols)
    {
        my $column = $self->layout->column($col->{id});
        $col->{column} = $column;
        $col->{operator} ||= 'max';
        # If it's got a parent curval, then add that too
        if ($col->{parent_id})
        {
            my $parent = $self->layout->column($col->{parent_id});
            push @parents, {
                id       => $parent->id,
                column   => $parent,
                operator => $col->{operator},
                group    => $col->{group},
            };
            $col->{parent} = $parent;
        }
        # If it's a curval, then add all its subfields
        if ($column->type eq 'curval')
        {
            foreach (@{$column->curval_fields})
            {
                push @cols, {
                    id       => $_->id,
                    column   => $_,
                    operator => $col->{operator},
                    parent   => $column,
                    group    => $col->{group},
                };
            }
        }
    }

    # Combine and flatten columns
    unshift @cols, @parents;
    my @newcols;
    foreach my $col (@cols)
    {
        my ($existing) = grep { $self->_compare_col($col, $_) } @newcols;
        if ($existing)
        {
            $existing->{group} ||= $col->{group};
        }
        else {
            push @newcols, $col;
        }
    }
    @cols = @newcols;

    # Add all columns first so that join numbers are correct
    foreach my $col (@cols)
    {
        my $column = $col->{column};
        next if $column->internal;
        my $parent = $col->{parent};
        # If the column is a curcommon, then we need to make sure that it is
        # included even if it is a multivalue (when it would normally be
        # excluded). The reason is that it will otherwise not cause the related
        # record_later searches to be generated when the curval sub-field is
        # retrieved in the same query
        $self->add_prefetch($column, group => $col->{group}, parent => $parent);
        $self->add_prefetch($column->link_parent, linked => 1, group => $col->{group}, parent => $parent)
            if $column->link_parent;
    }

    foreach my $col (@cols)
    {
        my $op = $col->{operator};
        my $column = $col->{column};
        my $parent = $col->{parent};

        my $select;
        my $as = $column->field;
        $as = $as.'_sum' if $op eq 'sum';
        $as = $as.'_count' if $op eq 'count';

        # The select statement to get this column's value varies depending on
        # what we want to retrieve. If we're selecting a field with multiple
        # values, then we have to run this as a separate subquery, otherwise if
        # there are more than one multiple-value retrieval then that aggregates
        # will be counting multiple times for each set of multiple values (due
        # to the multiple joins)

        # Field is either multivalue or its parent is
        if (($column->multivalue || ($parent && $parent->multivalue)) && !$col->{group})
        {
            # Assume curval if it's a parent - we need to search the curval
            # table for all the curvals that are part of the records retrieved.
            # XXX add search query?
            if ($parent)
            {
                my $f_rs = $self->schema->resultset('Curval')->search({
                    'mecurval.record_id' => {
                        -ident => 'record_single_2.id' # Match against main query's records
                    },
                    'mecurval.layout_id' => $parent->id,
                    'record_later.id'    => undef,
                },
                {
                    alias => 'mecurval', # Can't use default "me" as already used in main query
                    join => {
                        'value' => {
                            'record_single' => [
                                'record_later',
                                $column->tjoin,
                            ],
                        },
                    },
                });
                if ($column->numeric && $op eq 'sum')
                {
                    $select = $f_rs->get_column((ref $column->tjoin eq 'HASH' ? 'value_2' :  $column->field).".".$column->value_field)->sum_rs->as_query;
                }
                else {
                    $select = $f_rs->get_column((ref $column->tjoin eq 'HASH' ? 'value_2' :  $column->field).".".$column->value_field)->max_rs->as_query;
                }
            }
            # Otherwise a standard subquery select for that type of field
            else {
                $select = $self->schema->resultset('Current')
                    ->correlate('record_single') # Correlate against main query's records
                    ->related_resultset($column->field)
                    ->get_column($column->value_field);
                # Also need to add the main search query, otherwise if we take
                # all the field's values for each record, then we won't be
                # filtering the non-matched ones in the case of multivalue
                # fields
                my $searchq = $self->search_query(search => 1, extra_column => $column, linked => 1);
                push @$searchq, {
                    'mefield.id' => {
                        -ident => 'me.id'
                    },
                };
                $select = $self->schema->resultset('Current')->search(
                    [-and => $searchq ],
                    {
                        alias => 'mefield',
                        join  => [
                            [$self->linked_hash(search => 1, extra_column => $column)],
                            {
                                'record_single' => [ # The (assumed) single record for the required version of current
                                    'record_later',  # The record after the single record (undef when single is latest)
                                    $self->jpfetch(search => 1, linked => 0, extra_column => $column),
                                ],
                            },
                        ],
                    },
                )->get_column($self->fqvalue($column, search => 1, linked => 0, extra_column => $column));
                if ($column->numeric && $op eq 'sum')
                {
                    $select = $select->sum_rs->as_query;
                }
                else {
                    $select = $select->max_rs->as_query;
                }
            }
        }
        # Standard single-value field - select directly, no need for a subquery
        else {
            $select = $self->fqvalue($column, prefetch => 1, group => 1, search => 0, linked => 0, parent => $parent, retain_join_order => 1);
        }

        push @select_fields, {
            $op => $select,
            -as => $as,
        };
        # Also add linked column if required
        push @select_fields, {
            $op => $self->fqvalue($column->link_parent, prefetch => 1, search => 0, linked => 1, parent => $parent, retain_join_order => 1),
            -as => $as."_link",
        } if $column->link_parent;
    }

    push @select_fields, {
        count => \1,
        -as   => 'id_count',
    };

    # If we want to aggregate by month, we need to do some tricky conditional
    # summing. We can't do this with the abstraction layer, so need to resort
    # to literal SQL
    if ($self->dr_column)
    {
        my $increment  = $self->dr_interval.'s'; # Increment between x-axis values
        my $dr_col     = $self->layout->column($self->dr_column); # The daterange column for x-axis
        my $field      = $dr_col->field;
        my $field_link = $dr_col->link_parent && $dr_col->link_parent->field; # Related link field

        if ($self->dr_column_parent)
        {
            $self->add_prefetch($self->dr_column_parent, include_multivalue => 1);
            $self->add_prefetch($dr_col, include_multivalue => 1, parent => $self->dr_column_parent);
        }
        else {
            $self->add_prefetch($dr_col, include_multivalue => 1);
        }

        # First find out earliest and latest date in this result set
        my $select = [
            { min => "$field.from", -as => 'start_date'},
            { max => "$field.to", -as => 'end_date'},
        ];
        my $search = $self->search_query(search => 1, prefetch => 1, linked => 0);
        # Include linked field if applicable
        if ($field_link)
        {
            push @$select, (
                { min => "$field_link.from", -as => 'start_date_link'},
                { max => "$field_link.to", -as => 'end_date_link'},
            );
        }

        local $GADS::Schema::Result::Record::REWIND = $self->rewind_formatted
            if $self->rewind;
        my ($result) = $self->schema->resultset('Current')->search(
            [-and => $search], {
                select => $select,
                join   => [
                    $self->linked_hash(search => 1, prefetch => 1),
                    {
                        'record_single' => [
                            'record_later',
                            $self->jpfetch(search => 1, prefetch => 1, linked => 0),
                        ],
                    },
                ],
            },
        )->all;

        my $dt_parser = $self->schema->storage->datetime_parser;
        # Find min/max dates from above, including linked field if required
        my $daterange_from = $self->_min_date(
            $result->get_column('start_date'),
            ($field_link ? $result->get_column('start_date_link') : undef)
        );
        my $daterange_to   = $self->_max_date(
            $result->get_column('end_date'),
            ($field_link ? $result->get_column('end_date_link') : undef)
        );


        if ($daterange_from && $daterange_to)
        {
            $daterange_from->truncate(to => $self->dr_interval);
            $daterange_to->truncate(to => $self->dr_interval);
            # Pass dates back to caller
            $self->_set_dr_from($daterange_from);
            $self->_set_dr_to  ($daterange_to);

            # The literal CASE statement, which we reuse for each required period
            my $from_field      = $self->quote("$field.from");
            my $to_field        = $self->quote("$field.to");
            my $from_field_link = $field_link && $self->quote($field_link.".from");
            my $to_field_link   = $field_link && $self->quote($field_link.".to");
            my ($dr_y_axis)     = grep { $_->{id} == $self->dr_y_axis_id } @cols;
            my $col_val         = $self->fqvalue($dr_y_axis->{column}, search => 1, prefetch => 1);

            my $case = $field_link
                ? "CASE WHEN "
                  . "($from_field < %s OR $from_field_link < %s) "
                  . "AND ($to_field >= %s OR $to_field_link >= %s) "
                  . "THEN %s ELSE 0 END"
                : "CASE WHEN $from_field"
                  . " < %s AND $to_field"
                  . " >= %s THEN %s ELSE 0 END";

            my $pointer = $daterange_from->clone;
            while ($pointer->epoch <= $daterange_to->epoch)
            {
                # Add the required timespan to the CASE statement
                my $from  = $self->schema->storage->dbh->quote(
                    $dt_parser->format_date($pointer->clone->add($increment => 1))
                );
                my $to    = $self->schema->storage->dbh->quote(
                    $dt_parser->format_date($pointer)
                );
                my $sum   = $dr_y_axis->{operator} eq 'count' ? 1 : $col_val;
                my $casef = $field_link
                          ? sprintf($case, $from, $from, $to, $to, $sum)
                          : sprintf($case, $from, $to, $sum);
                # Finally add it to the select, naming it after the epoch of
                # the time-period start
                push @select_fields, {
                    sum => \$casef,
                    -as => $pointer->epoch,
                };
                # Also add link parent field as well if required
                if ($dr_y_axis->{column}->link_parent)
                {
                    my $col_val_link = $self->fqvalue($dr_y_axis->{column}->link_parent, linked => 1, search => 1, prefetch => 1);
                    my $sum   = $dr_y_axis->{operator} eq 'count' ? 1 : $col_val_link;
                    my $casef = $field_link
                              ? sprintf($case, $from, $from, $to, $to, $sum)
                              : sprintf($case, $from, $to, $sum);
                    push @select_fields, {
                        sum => \$casef,
                        -as => $pointer->epoch."_link",
                    };
                }
                $pointer->add($increment => 1);
            }
        }
    }

    my @g;
    # Add on the actual columns to group by in the SQL statement
    foreach (grep { $_->{group} } @cols)
    {
        my $col = $self->layout->column($_->{id});
        # Whether we need to pluck a particular date value, used to group the
        # x-axis to days, months etc.
        if (my $pluck = $_->{pluck}) {

            push @g, $self->schema->resultset('Current')->dt_SQL_pluck(
                { -ident => $self->fqvalue($col, search => 1, prefetch => 1) }, 'year'
            );

            push @g, $self->schema->resultset('Current')->dt_SQL_pluck(
                { -ident => $self->fqvalue($col, search => 1, prefetch => 1) }, 'month'
            ) if $pluck eq 'month' || $pluck eq 'day';

            push @g, $self->schema->resultset('Current')->dt_SQL_pluck(
                { -ident => $self->fqvalue($col, search => 1, prefetch => 1) }, 'day_of_month'
            ) if $pluck eq 'day';

        } else {
            if ($col->link_parent)
            {
                $self->add_group($col);
                my $main = $self->fqvalue($col, group => 1, search => 0, prefetch => 1, retain_join_order => 1);
                $self->add_group($col->link_parent, linked => 1);
                my $link = $self->fqvalue($col->link_parent, group => 1, search => 0, prefetch => 1, linked => 1, retain_join_order => 1);
                push @g, $self->schema->resultset('Current')->helper_concat(
                     { -ident => $main },
                     { -ident => $link },
                );
            }
            else {
                if ($_->{parent})
                {
                    $self->add_group($_->{parent});
                    $self->add_group($col, parent => $_->{parent});
                }
                else {
                    $self->add_group($col);
                }
                push @g, $self->fqvalue($col, group => 1, search => 0, prefetch => 1, retain_join_order => 1, parent => $_->{parent});
            }
        }
    };

    my $q = $self->search_query(prefetch => 1, search => 1, retain_join_order => 1, group => 1); # Called first to generate joins

    my $select = {
        select => [@select_fields],
        join     => [
            $self->linked_hash(group => 1, prefetch => 1, search => 0, retain_join_order => 1),
            {
                'record_single' => [
                    'record_later',
                    $self->jpfetch(group => 1, prefetch => 1, search => 0, linked => 0, retain_join_order => 1),
                ],
            },
        ],
        group_by => [@g],
    };

    local $GADS::Schema::Result::Record::REWIND = $self->rewind_formatted
        if $self->rewind;

    my $result = $self->schema->resultset('Current')->search(
        $self->_cid_search_query, $select
    );

    [$result->all];
}

sub _min_date { shift->_min_max_date('min', @_) };
sub _max_date { shift->_min_max_date('max', @_) };

sub _min_max_date
{   my ($self, $action, $date1, $date2) = @_;
    my $dt_parser = $self->schema->storage->datetime_parser;
    my $d1 = $date1 && $dt_parser->parse_date($date1);
    my $d2 = $date2 && $dt_parser->parse_date($date2);
    return $d1 if !$d2;
    return $d2 if !$d1;
    if ($action eq 'min') {
        return $d1 if $d1->epoch < $d2->epoch;
    } else {
        return $d1 if $d1->epoch > $d2->epoch;
    }
    return $d2;
}

1;

