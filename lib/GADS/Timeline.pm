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
    is => 'ro',
    default => sub { +{} },
);

has colors => (
    is => 'lazy',
);

sub _build_colors
{   my $self = shift;
    my %keys = %{$self->_used_color_keys};
    [ map {
        my $color = $self->graph->get_color($_);
        +{ key => $_, color => $color };
    } keys %keys ];
}

has groups => (
    is => 'ro',
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
    is => 'ro',
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
    is => 'lazy',
);

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

    my $layout = $self->records->layout;

    # Add on any extra required columns for labelling etc
    my @extra;
    push @extra, $self->label_col_id
        if $self->label_col_id && $layout->column($self->label_col_id);
    push @extra, $self->group_col_id
        if $self->group_col_id && $layout->column($self->group_col_id);
    push @extra, $self->color_col_id
        if $self->color_col_id && $layout->column($self->color_col_id);
    $self->records->columns_extra([map { +{ id => $_ } } @extra]);

    # All the data values
    my @items;
    my $multiple_dates;
    my $records  = $self->records;
    my $find_min = $self->records->from && !$self->records->to ? $self->records->from->clone->truncate(to => 'day') : undef;
    my $find_max = !$self->records->from && $self->records->to ? $self->records->to->clone->truncate(to => 'day')->add(days => 1) : undef;
    my @columns = @{$records->columns_retrieved_no};
    foreach my $column (@columns)
    {
        push @columns, @{$column->curval_fields}
            if $column->is_curcommon;
    }
    my $date_column_count = grep { $_->return_type eq "daterange" || $_->return_type eq "date" } @columns;

    while (my $record  = $records->single)
    {
        my @group_to_add = $self->group_col_id
                && $layout->column($self->group_col_id)
                && $layout->column($self->group_col_id)->user_can('read')
            ? @{$record->fields->{$self->group_col_id}->text_all}
            : (undef);

        my $count;
        my ($min_of_this, $max_of_this);
        foreach my $group_to_add (@group_to_add)
        {
            my @dates; my @titles;
            my $had_date_col; # Used to detect multiple date columns in this view
            my %curcommon_values;
            foreach my $column (@columns)
            {
                next if $self->color_col_id && $self->color_col_id == $column->id;

                if ($column->is_curcommon)
                {
                    foreach my $row (@{$record->fields->{$column->id}->field_values})
                    {
                        foreach my $cur_col_id (keys %$row)
                        {
                            $curcommon_values{$cur_col_id} ||= [];
                            push @{$curcommon_values{$cur_col_id}}, $row->{$cur_col_id};
                        }
                    }
                    next;
                }

                # Get item value
                my @d = $curcommon_values{$column->id}
                    ? @{$curcommon_values{$column->id}}
                    : ($record->fields->{$column->id});

                foreach my $d (@d)
                {
                    $d or next;

                    # Only show unique items of children, otherwise will be a lot of
                    # repeated entries
                    next if $record->parent_id && !$d->child_unique;

                    if ($column->return_type eq "daterange" || $column->return_type eq "date")
                    {
                        $multiple_dates = 1 if $had_date_col;
                        $had_date_col = 1;
                        next unless $column->user_can('read');

                        # Create colour if need be
                        my $color;
                        if ($self->type eq 'calendar' || (!$self->color_col_id && $date_column_count > 1))
                        {
                            $color = $self->graph->get_color($column->name);
                            $self->_used_color_keys->{$column->name} = 1;
                        }

                        # Push value onto stack
                        if ($column->type eq "daterange")
                        {
                            foreach my $range (@{$d->values})
                            {
                                # It's possible that values from other columns not within
                                # the required range will have been retrieved. Don't bother
                                # adding them
                                if (
                                    (!$records->to || $range->start <= $records->to)
                                    && (!$records->from || $range->end >= $records->from)
                                ) {
                                    push @dates, {
                                        from       => $range->start,
                                        to         => $range->end,
                                        color      => $color,
                                        column     => $column->id,
                                        count      => ++$count,
                                        daterange  => 1,
                                        current_id => $d->record->current_id,
                                    };
                                    if ($find_min)
                                    {
                                        $self->_set_retrieved_from($range->start->clone)
                                            if (!$find_min || $range->start > $find_min)
                                                && (!defined $self->retrieved_from || $range->start < $self->retrieved_from);
                                        $self->_set_retrieved_from($range->end->clone)
                                            if (!$find_min || $range->end > $find_min)
                                                && (!defined $self->retrieved_from || $range->end < $self->retrieved_from);
                                        $min_of_this = $range->start->clone
                                            if (!$find_min || $range->start > $find_min)
                                                && (!defined $min_of_this || $range->start < $min_of_this);
                                        $min_of_this = $range->end->clone
                                            if (!$find_min || $range->end > $find_min)
                                                && (!defined $min_of_this || $range->end < $min_of_this);
                                    }
                                    if ($find_max)
                                    {
                                        $self->_set_retrieved_to($range->end->clone)
                                            if (!$find_max || $range->end < $find_max)
                                                && (!defined $self->retrieved_to || $range->end > $self->retrieved_to);
                                        $self->_set_retrieved_to($range->start->clone)
                                            if (!$find_max || $range->start < $find_max)
                                                && (!defined $self->retrieved_to || $range->start > $self->retrieved_to);
                                        $max_of_this = $range->end->clone
                                            if (!$find_max || $range->end < $find_max)
                                                && (!defined $max_of_this || $range->end > $max_of_this);
                                        $max_of_this = $range->start->clone
                                            if (!$find_max || $range->start < $find_max)
                                                && (!defined $max_of_this || $range->start > $max_of_this);
                                    }
                                }
                            }
                        }
                        else {
                            my @vs = $d->column->type eq 'date' ? @{$d->values} : @{$d->value};
                            foreach my $val (@vs)
                            {
                                $val or next;
                                if (
                                    (!$records->from || $val >= $records->from)
                                    && (!$records->to || $val <= $records->to)
                                ) {
                                    push @dates, {
                                        from       => $val,
                                        to         => $val,
                                        color      => $color,
                                        column     => $column->id,
                                        count      => 1,
                                        current_id => $d->record->current_id,
                                    };
                                    if ($find_min)
                                    {
                                        $self->_set_retrieved_from($val->clone)
                                            if !defined $self->retrieved_from || $val < $self->retrieved_from;
                                        $min_of_this = $val->clone
                                            if (!$find_min || $val > $find_min)
                                                && (!defined $min_of_this || $val < $min_of_this);
                                    }
                                    if ($find_max)
                                    {
                                        $self->_set_retrieved_to($val->clone)
                                            if !defined $self->retrieved_to || $val > $self->retrieved_to;
                                        $max_of_this = $val->clone
                                            if (!$find_max || $val < $find_max)
                                                && (!defined $max_of_this || $val > $max_of_this);
                                    }
                                }
                            }
                        }
                    }
                    else {
                        next if $column->type eq "rag";
                        # Check if the user has selected only one label
                        next if $self->label_col_id && $self->label_col_id != $column->id;
                        # Don't add grouping text to title
                        next if $self->group_col_id && $self->group_col_id == $column->id;
                        # Not a date value, push onto title
                        # Don't want full HTML, which includes hyperlinks etc
                        push @titles, {col => $column, value => $d} if $d->as_string;
                    }
                }
            }
            if (my $label_id = $self->label_col_id)
            {
                @titles = ({
                    col   => $records->layout->column($label_id),
                    value => $record->fields->{$label_id},
                })
                # Value for this record may not exist or be blank
                if $record->fields->{$label_id} && $record->fields->{$label_id}->as_string;
            }

            # If a specific field is set to colour-code by, then use that and
            # override any previous colours set for multiple date fields
            my $item_color; my $color_key = '';
            if (my $color = $self->color_col_id)
            {
                if ($record->fields->{$color})
                {
                    if ($color_key = $record->fields->{$color}->as_string)
                    {
                        $item_color = $self->graph->get_color($color_key);
                        $self->_used_color_keys->{$color_key} = 1;
                    }
                }
            }

            my $item_group;
            if ($group_to_add)
            {
                unless ($item_group = $self->groups->{$group_to_add})
                {
                    $item_group = $self->_group_count($self->_group_count + 1);
                    $self->groups->{$group_to_add} = $item_group;
                }
            }

            # Create title label
            my $title = join ' - ', map { $_->{value}->as_string } grep { $_->{col}->type ne 'file' } @titles;
            my $title_abr = length $title > 50 ? substr($title, 0, 45).'...' : $title;

            foreach my $d (@dates)
            {
                next unless $d->{from} && $d->{to};
                my $add = $multiple_dates && $records->layout->column($d->{column})->name;
                my $title_i = $add ? "$title ($add)" : $title;
                my $title_i_abr = $add ? "$title_abr ($add)" : $title_abr;
                my $cid = $d->{current_id} || $record->current_id;
                if ($self->type eq 'calendar')
                {
                    my $item = {
                        "url"   => "/record/" . $cid,
                        "color" => $d->{color},
                        "title" => $title_i_abr,
                        "id"    => $record->current_id,
                        "start" => $d->{from}->epoch*1000,
                        "end"   => $d->{to}->epoch*1000,
                    };
                    push @items, $item;
                }
                else {
                    my $uid  = "$cid+$d->{column}+$d->{count}";
                    next if $self->_all_items_index->{$uid};
                    my @values = map {
                        +{
                            name  => $_->{col}->name,
                            value => $_->{value}->html,
                        };
                    } @titles;
                    my $item = {
                        "content"  => $title_i,
                        "id"       => $uid,
                        current_id => $cid,
                        "start"    => $d->{from}->epoch * 1000,
                        "group"    => $item_group,
                        column     => $d->{column},
                        dt         => $d->{from},
                        values     => \@values,
                    };
                    # Set to date field colour unless specific colour field chosen
                    $item_color = $d->{color}
                        if !$self->color_col_id && $date_column_count > 1;
                    $item->{style} = qq(background-color: $item_color)
                        if $item_color;
                    # Add one day, otherwise ends at 00:00:00, looking like day is not included
                    $item->{end}    = $d->{to}->clone->add( days => 1 )->epoch * 1000 if $d->{daterange};
                    $item->{single} = $d->{from}->epoch * 1000 if !$d->{daterange};
                    $self->_all_items_index->{$item->{id}} = 1;
                    push @items, $item;
                }
            }
        }
        $self->_set_retrieved_to($min_of_this)
            if $find_min && (!$self->retrieved_to || $min_of_this > $self->retrieved_to);
        $self->_set_retrieved_from($max_of_this)
            if $find_max && (!$self->retrieved_from || $max_of_this < $self->retrieved_from);
    }

    if (!@items)
    {
        # XXX Results in multiple warnings when this routine is called more
        # than once per page
        mistake __"There are no date fields in this view to display"
            if !grep { $_->return_type =~ /date/ } @columns;
    }

    \@items;
}

1;

