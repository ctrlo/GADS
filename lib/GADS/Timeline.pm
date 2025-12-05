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
use MooX::Types::MooseLike::Base qw(Maybe Int);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;
use List::Util  qw(min max);
use Scalar::Util qw/blessed/;

use constant {
    AT_BIGBANG  => DateTime::Infinite::Past->new,
    AT_BIGCHILL => DateTime::Infinite::Future->new,
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

has all_group_values => (
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
    is      => 'lazy',
    clearer => 1,
);

sub _build_groups { +{} }

has _group_count => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

# Where to show the timeline from by default. Because when retrieving records,
# we can end up with some items (in the same record) being retrieved that we
# weren't expecting, this tells the browser the sensible place to show from.
# This will also take into account long date ranges, where we only want to show
# part of the range.
has display_from => (
    is      => 'rwp',
    isa     => Maybe[DateAndTime],
    # Do not set to an infinite value, should be undef instead
    coerce  => sub { return undef if ref($_[0]) =~ /Infinite/; $_[0] },
);

# Same as above
has display_to => (
    is      => 'rwp',
    isa     => Maybe[DateAndTime],
    # Do not set to an infinite value, should be undef instead
    coerce  => sub { return undef if ref($_[0]) =~ /Infinite/; $_[0] },
);

has records => (
    is      => 'ro',
);

sub clear
{   my $self = shift;
    $self->records->clear;
    $self->clear_items;
    $self->_set_display_from(undef);
    $self->_set_display_to(undef);
    $self->clear_groups;
    $self->_group_count(0);
    $self->_clear_all_items_index;
}

has _all_items_index => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { +{} },
    clearer => 1,
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

    my $group_col = $layout->column($self->group_col_id);
    my $color_col = $layout->column($self->color_col_id);
    my $label_col = $layout->column($self->label_col_id);

    # Add on any extra required columns for labelling etc
    my @extra = map { $_ ? +{ id => $_->id } : () }
        $label_col, $group_col, $color_col;

    $records->columns_extra(\@extra);

    my $from_min =  $from && !$to ? $from->clone->truncate(to => 'day') : undef;
    my $to_max   = !$from &&  $to ? $to->clone->truncate(to => 'day')->add(days => 1) : undef;

    # Don't show the ID by default on the timeline as it clutters each item. It
    # can be added as a field if required
    my @columns  = grep $_->type ne 'id', @{$records->columns_render};

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

    if ($self->all_group_values && $group_col && $group_col->fixedvals)
    {
        foreach my $val ($group_col->values_for_timeline)
        {
            my $item_group = $self->_group_count($self->_group_count + 1);
            $self->groups->{$val} = $item_group;
        }
    }

    my @items;
    while (my $record  = $records->single)
    {
        my @groups_to_add;
        @groups_to_add = @{$record->get_field_value($group_col)->text_all}
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
            {   my @d = $record->get_field_value($column);

                if ($column->is_curcommon)
                {   # We need the main value (for the pop-up) and also any dates
                    # within it to add to the timeline separately.
                    # First all date columns in this curcommon:
                    my @date_cols = grep $_->return_type eq 'date' || $_->return_type eq 'daterange',
                        @{$column->curval_fields};
                    # Now get those values from all records within
                    foreach my $rec (map $_->{record}, $record->get_field_value($column)->all_records)
                    {
                        push @d, $rec->get_field_value($_)
                            foreach @date_cols;
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
                    if($self->type eq 'calendar' || ( !$color_col && $date_column_count > 1 ))
                    {   $color = $self->graph->get_color($column->name);
                        $self->_used_color_keys->{$column->name} = 1;
                    }

                    my (@spans, $is_range);
                    if($column_datum->return_type eq 'daterange')
                    {   @spans    = map +[ $_->start, $_->end ], @{$d->values};
                        $is_range = 1;
                    }
                    else
                    {   @spans    = map +[ $_, $_ ],
                            @{$d->values};
                    }

                    foreach my $span (@spans)
                    {   my ($start, $end) = @$span;

                        # Timespan must overlap to select.
                        # For dates without times, we need to truncate to just
                        # a date the value we are selecting from, because
                        # that's what will be retrieved from the database. For
                        # example, if selecting a from of 2nd September 14:53,
                        # then the database query will have simply been from a
                        # date of and including 2nd September, in which case a
                        # record with that date will have been selected. If we
                        # didn't truncate the time, then the record would be
                        # discarded at this point, as the from time of 14:53 is
                        # after the midnight time of the retrieved record.
                        my $from_check = $from && $from->clone;
                        $from_check->truncate(to => 'day') if $from_check && !$column->has_time;

                        my $from_test = $self->records->exclusive_of_from
                            ? (!$from_check || $end > $from_check)
                            : (!$from_check || $end >= $from_check);
                        my $to_test = $self->records->exclusive_of_to
                            ? (!$to || $start < $to)
                            : (!$to || $start <= $to);
                        $from_test && $to_test
                             or next;

                        push @dates, +{
                            from       => $start,
                            to         => $end,
                            color      => $color,
                            column     => $column_datum->id,
                            count      => ++$seqnr,
                            daterange  => $is_range,
                            has_time   => $column->has_time,
                            current_id => $d->record->current_id,
                        };
                    }
                }
            }

            $oldest = min $oldest, map $_->{from}, @dates;
            $newest = max $newest, map $_->{to}, @dates;

            my @titles;
            if(!$label_col)
            {   push @titles, grep {
                       # RAG colours are not much use on a label
                       $_->{col}->type ne "rag"

                       # Don't add grouping text to title
                    && ($group_col ? $group_col->id : 0) != $_->{col}->id
                    && ($color_col ? $color_col->id : 0) != $_->{col}->id
                } @values;
            }
            elsif(my $label = $record->get_field_value($label_col))
            {   push @titles, +{
                    col   => $layout->column($label_col->id),
                    value => $label,
                } if $label->as_string;
            }

            # If a specific field is set to colour-code by, then use that and
            # override any previous colours set for multiple date fields
            my ($item_color, $color_key) = (undef, '');
            if($color_col && (my $c = $record->get_field_value($color_col)))
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

                # Additional items for the same record and field can appear at
                # any time, in particular if grouped by the field. Ensure that
                # exactly the same items is not added twice.
                my $uid  = join '+', $cid, $d->{column};
                $uid  = join '+', $uid, $group_to_add if $group_to_add;
                ! $self->_all_items_index->{$uid}
                    or next DATE;
                $self->_all_items_index->{$uid} = 1;

                # Exclude ID for pop-up values as it's included in the pop-up title
                my @popup_values = map +{
                    name  => encode_entities($_->{col}->name),
                    value => $_->{value}->html,
                }, grep !$_->{col}->name_short || $_->{col}->name_short ne '_id', @values;

                my %item = (
                    content    => "$title$add",
                    id         => $uid,
                    current_id => $cid,
                    start      => _tick $d->{from},
                    group      => $item_group,
                    column     => $d->{column},
                    dt         => $d->{from},
                    dt_to      => $d->{to},
                    values     => \@popup_values,
                );

                # Set to date field colour unless specific colour field chosen
                $item_color = $d->{color}
                    if !$self->color_col_id && $date_column_count > 1;

                $item{style} = qq(background-color: $item_color)
                    if $item_color;

                if($d->{daterange})
                {   # Add one day, otherwise ends at 00:00:00, looking like day is not included
                    my $v = $d->{to}->clone;
                    $v->add(days => 1) unless $d->{has_time};
                    $item{end}    = _tick $v;
                    $item{has_time} = $d->{has_time};
                }
                else
                {   $item{single} = _tick $d->{from};
                }

                push @items, \%item;
            }
        }

        $self->_set_display_from($newest)
            if $newest < ($self->display_from || AT_BIGCHILL);

        $self->_set_display_to($oldest)
            if $oldest > ($self->display_to || AT_BIGBANG);
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
