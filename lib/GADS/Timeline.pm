=pod
GADS - Globally Accessible Data Store
Copyright (C) 2018 Ctrl O Ltd

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

package GADS::Timeline;

use DateTime;
use HTML::Entities qw/encode_entities/;
use JSON qw(encode_json);
use GADS::Graph::Data;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;
use List::Util  qw(min max);

use constant {
    AT_BIGBANG  => DateTime->new(year => 0),
    AT_BIGCHILL => DateTime->new(year => 9999),
};

has type => (
    is       => 'ro',
    required => 1,
);

has label_col_id => (
    is => 'ro',
);

has group_col_id => (
    is => 'ro',
);

has color_col_id => (
    is => 'ro',
);

has _used_color_keys => (
    is      => 'ro',
    default => sub { +{} },
);

has colors => (
    is => 'lazy',
);

sub _build_colors
{   my $self = shift;
    my $used = $self->_used_color_keys;
    [ map +{ key => $_, color => $self->graph->get_color($_) }, keys %$used ];
}

has groups => (
    is      => 'ro',
    default => sub { +{} },
);

has _group_count => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

has retrieved_from => (
    is      => 'rwp',
    isa     => Maybe[DateAndTime],
);

has retrieved_to => (
    is      => 'rwp',
    isa     => Maybe[DateAndTime],
);

has records => (
    is      => 'ro',
);

sub clear
{   my $self = shift;
    $self->records->clear;
    $self->clear_items;
}

has _all_items_index => (
    is      => 'ro',
    default => sub { +{} },
);

has items => (
    is      => 'lazy',
    clearer => 1,
);

has graph => (
    is      => 'lazy',
);

# from DateTime to miliseconds
sub _tick($) { shift->epoch * 1000 }

# Need a Graph::Data instance to get relevant colors
sub _build_graph
{   my $self = shift;
    GADS::Graph::Data->new(
        schema  => $self->records->schema,
        records => undef,
    );
}

sub _build_items
{   my $self = shift;

    my $records = $self->records;
    my $to      = $records->to;
    my $from    = $records->from;
    my $layout  = $records->layout;

    my $group_col_id = $self->group_col_id;
    my $color_col_id = $self->color_col_id;
    my $label_col_id = $self->label_col_id;

    # Add on any extra required columns for labelling etc
    my @extra = map { $_ && $layout->column($_) ? +{ id => $_ } : () }
        $label_col_id, $group_col_id, $color_col_id;

    $records->columns_extra(\@extra);

    my $find_min =  $from && !$to ? $from->clone->truncate(to => 'day') : undef;
    my $find_max = !$from &&  $to ? $to->clone->truncate(to => 'day')->add(days => 1) : undef;

    my @columns  = grep $_->user_can('read'), @{$records->columns_retrieved_no};

    my $date_column_count = 0;
    foreach my $column (@columns)
    {
        my @cols = $column;
        push @cols, @{$column->curval_fields}
            if $column->is_curcommon;

        foreach my $col (@cols)
        {   my $rt = $col->return_type;
            $date_column_count++
                if $rt eq 'daterange' || $rt eq 'date';
        }
    }

    my @items;
    while (my $record  = $records->single)
    {   my $fields     = $record->fields;

        my $group_col  = $group_col_id ? $layout->column($group_col_id) : undef;
        my @groups_to_add;
        @groups_to_add = @{$fields->{$group_col_id}->text_all}
            if $group_col && $group_col->user_can('read');

        @groups_to_add
            or push @groups_to_add, undef;

        if ($self->group_col_id)
        {
            # If the grouping value is blank for this record, then set it to a
            # suitable textual value, otherwise it won't be rendered on the
            # timeline
            $_ ||= '<blank>' for @groups_to_add;
        }

        my $seqnr  = 0;
        my $oldest = AT_BIGCHILL;
        my $newest = AT_BIGBANG;

        foreach my $group_to_add (@groups_to_add)
        {
            my (@dates, @values);

            foreach my $column (@columns)
            {   my @d = $fields->{$column->id};

                if ($column->is_curcommon)
                {   # We need the main value (for the pop-up) and also any dates
                    # within it to add to the timeline separately.
                    foreach my $row (@{$fields->{$column->id}->field_values})
                    {
                        foreach my $cur_col (values %$row)
                        {   my $rt = $cur_col->column->return_type;
                            push @d, $cur_col
                                if $rt eq 'date' || $rt eq 'daterange';
                        }
                    }
                }

         DATUM: foreach my $d (grep defined, @d)
                {
                    # Only show unique items of children, otherwise will be
                    # a lot of repeated entries.
                    next DATUM if $record->parent_id && !$d->child_unique;

                    my $column_datum = $d->column;
                    my $rt = $column_datum->return_type;
                    unless($rt eq 'daterange' || $rt eq 'date')
                    {   # Not a date value, push onto labels.
                        # Don't want full HTML, which includes hyperlinks etc
                        push @values, +{ col => $column_datum, value => $d }
                            if $d->as_string;

                        next DATUM;
                    }

                    # Create colour if need be
                    my $color;
                    if($self->type eq 'calendar' || ( !$color_col_id && $date_column_count > 1 ))
                    {   $color = $self->graph->get_color($column->name);
                        $self->_used_color_keys->{$column->name} = 1;
                    }

                    my (@spans, $is_range);
                    if($column_datum->type eq 'daterange')
                    {   @spans    = map +[ $_->start, $_->end ], @{$d->values};
                        $is_range = 1;
                    }
                    else
                    {   my $type  = $d->column->type;
#XXX above, we check for 'return_type', here it is 'type'
                        @spans    = map +[ $_, $_ ],
                            $type eq 'date' || $type eq 'createddate' ? @{$d->values} : @{$d->value};
                    }

                    foreach my $span (@spans)
                    {   my ($start, $end) = @$span;

                        # Timespan must overlap to select
                        (!$from || $end >= $from) && (!$to || $start <= $to)
                             or next;

                        push @dates, +{
                            from       => $start,
                            to         => $end,
                            color      => $color,
                            column     => $column_datum->id,
                            count      => ++$seqnr,
                            daterange  => $is_range,
                            current_id => $d->record->current_id,
                        };
                    }
                }
            }

            $oldest = min $oldest, map $_->{from}, @dates;
            $newest = max $newest, map $_->{to}, @dates;

            my @titles;
            if(!$label_col_id)
            {   push @titles, grep {
                       # RAG colours are not much use on a label
                       $_->{col}->type ne "rag"

                       # Don't add grouping text to title
                    && ($group_col_id ||0) != $_->{col}->id
                    && ($color_col_id ||0) != $_->{col}->id
                } @values;
            }
            elsif(my $label = $fields->{$label_col_id})
            {   push @titles, +{
                    col   => $layout->column($label_col_id),
                    value => $label,
                } if $label->as_string;
            }

            # If a specific field is set to colour-code by, then use that and
            # override any previous colours set for multiple date fields
            my ($item_color, $color_key) = (undef, '');
            if($color_col_id && (my $c = $fields->{$color_col_id}))
            {   if($color_key = $c->as_string)
                {   $item_color = $self->graph->get_color($color_key);
                    $self->_used_color_keys->{$color_key} = 1;
                }
            }

            my $item_group;
            if($group_to_add)
            {   unless($item_group = $self->groups->{$group_to_add})
                {   $item_group = $self->_group_count($self->_group_count + 1);
                    $self->groups->{$group_to_add} = $item_group;
                }
            }

            # Create title label, filenames are ugly
            my $title = join ' - ', map $_->{value}->as_string,
                grep $_->{col}->type ne 'file', @titles;

            my $title_abr = length $title > 50 ? substr($title, 0, 45).'...' : $title;

      DATE: foreach my $d (@dates)
            {   my $add = $date_column_count > 1
                  ? ' ('.$layout->column($d->{column})->name.')' : '';

                my $cid = $d->{current_id} || $record->current_id;

                if ($self->type eq 'calendar')
                {   push @items, +{
                        url   => "/record/$cid",
                        color => $d->{color},
                        title => "$title_abr$add",
                        id    => $record->current_id,
                        start => _tick $d->{from},
                        end   => _tick $d->{to},
                    };
                    next DATE;
                }

                my $uid  = join '+', $cid, $d->{column}, $d->{count};
                ! $self->_all_items_index->{$uid}
                    or next DATE;

                my @popup_values = map +{
                    name  => $_->{col}->name,
                    value => $_->{value}->html,
                }, @values;

                my %item = (
                    content    => "$title$add",
                    id         => $uid,
                    current_id => $cid,
                    start      => _tick $d->{from},
                    group      => $item_group,
                    column     => $d->{column},
                    dt         => $d->{from},
                    values     => \@popup_values,
                );

                # Set to date field colour unless specific colour field chosen
                $item_color = $d->{color}
                    if !$self->color_col_id && $date_column_count > 1;

                $item{style} = qq(background-color: $item_color)
                    if $item_color;

                if($d->{daterange})
                {   # Add one day, otherwise ends at 00:00:00, looking like day is not included
                    $item{end}    = _tick $d->{to}->clone->add(days => 1);
                }
                else
                {   $item{single} = _tick $d->{from};
                }

                $self->_all_items_index->{$uid} = 1;
                push @items, \%item;
            }
        }

        if($find_min && $oldest > ($self->retrieved_to || AT_BIGBANG))
        {   $oldest = $find_min if $oldest < $find_min;
            $self->_set_retrieved_to($oldest);
        }

        if($find_max && $newest < ($self->retrieved_from || AT_BIGCHILL))
        {   $newest = $find_max if $newest > $find_max;
            $self->_set_retrieved_from($newest);
        }
    }

    if(!@items)
    {   # XXX Results in multiple warnings when this routine is called more
        # than once per page
        mistake __"There are no date fields in this view to display"
            if !$date_column_count;
    }

    \@items;
}

1;
