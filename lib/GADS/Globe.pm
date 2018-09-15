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

package GADS::Globe;

use GADS::Records;
use GADS::RecordsGroup;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;

has records => (
    is => 'lazy',
);

sub _build_records
{   my $self = shift;
    my $type = $self->is_group ? 'GADS::RecordsGroup' : 'GADS::Records';
    $type->new(max_results => 1000, %{$self->records_options});
}

has records_options => (
    is  => 'ro',
    isa => HashRef,
);

has layout => (
    is => 'lazy',
);

sub _build_layout
{   my $self = shift;
    # Need to get direct from options not from the records object, as layout is
    # needed to establish the value of is_group when building records attribute
    $self->records_options->{layout};
}

sub clear
{   my $self = shift;
    $self->records->clear;
    $self->clear_data;
}

has data => (
    is      => 'lazy',
    clearer => 1,
);

has group_col_id => (
    is => 'ro',
);

has group_col => (
    is => 'lazy',
);

sub _build_group_col
{   my $self = shift;
    $self->layout->column($self->group_col_id);
}

has color_col_id => (
    is => 'ro',
);

has color_col => (
    is => 'lazy',
);

sub _build_color_col
{   my $self = shift;
    $self->layout->column($self->color_col_id);
}

has label_col_id => (
    is => 'ro',
);

has label_col => (
    is => 'lazy',
);

sub _build_label_col
{   my $self = shift;
    !$self->label_col_id || $self->label_col_id < 0
        and return;
    $self->layout->column($self->label_col_id);
}

has has_label_col => (
    is  => 'lazy',
    isa => Bool,
);

sub _build_has_label_col
{   my $self = shift;
    return 1 if $self->label_col;
    return 1 if $self->label_col_id && $self->label_col_id < 0;
    return 0;
}

has _group_by => (
    is => 'lazy',
);

sub _build__group_by
{   my $self = shift;

    $self->is_group or return;

    my @group_by = map {
        +{ id => $_->id }
    } grep {
        $_->return_type eq "globe"
    } @{$self->_columns};

    push @group_by, { id => $self->color_col->id }
        if $self->color_col && !$self->color_col->numeric;

    push @group_by, { id => $self->label_col_id }
        if $self->label_col && !$self->label_col->numeric
            && (!$self->color_col || $self->label_col_id != $self->color_col->id);

    push @group_by, { id => $self->group_col->id }
        if $self->group_col && !$self->group_col->numeric
            && (!$self->color_col || $self->group_col->id != $self->color_col->id)
            && (!$self->label_col || $self->group_col->id != $self->label_col->id);

    \@group_by;
}

has is_choropleth => (
    is => 'lazy',
);

sub _build_is_choropleth
{   my $self = shift;
    $self->color_col && $self->color_col->numeric;
}

has is_group => (
    is => 'lazy',
);

sub _build_is_group
{   my $self = shift;
    return 1 if $self->color_col || $self->group_col || $self->has_label_col;
    return 0;
}

has _columns => (
    is => 'lazy',
);

sub _build__columns
{   my $self = shift;
    my @columns = @{$self->records->columns_retrieved_no};
    foreach my $column (@columns)
    {
        push @columns, @{$column->curval_fields}
            if $column->is_curcommon;
    }
    \@columns;
}

has _columns_globe => (
    is => 'lazy',
);

sub _build__columns_globe
{   my $self = shift;
    [ grep { $_->return_type eq "globe" } @{$self->_columns} ];
}

has _used_color_keys => (
    is      => 'ro',
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

my %tosvg = qw/  > gt   < lt    & amp /;

sub _to_svg($)
{   my $s = shift;
    $s =~ s/([<>&])/\&${tosvg{$1}};/g;
    $s;
}

sub _build_data
{   my $self = shift;

    # Add on any extra required columns for labelling etc
    my @extra;
    push @extra, $self->group_col->id if $self->group_col;
    push @extra, $self->color_col->id if $self->color_col;
    push @extra, $self->label_col->id if $self->label_col;
    $self->records->columns_extra([@extra]);

    # All the data values
    my %countries;
    my $records = $self->records;

    $records->group_by($self->_group_by)
        if $self->is_group;

    # Each row will be retrieved with each type of grouping if applicable
    while (my $record = $records->single)
    {
        if ($self->is_group)
        {
            my @this_countries;
            my ($value_color, $value_label, $value_group, $color);
            if ($self->color_col)
            {
                my $op = $self->color_col->numeric ? 'sum' : 'max';
                $value_color = $record->get_column($self->color_col->field);
                if (!$self->color_col->numeric)
                {
                    $color = $self->graph->get_color($value_color);
                    $self->_used_color_keys->{$value_color} = 1;
                }
            }

            if ($self->label_col)
            {
                my $op = $self->label_col->numeric ? 'sum' : 'max';
                $value_label = $self->label_col->type eq 'curval'
                    ? $self->_format_curcommon($self->label_col, $record)
                    : $record->get_column($self->label_col->field);
            }

            if ($self->group_col)
            {
                my $op = $self->group_col->numeric ? 'sum' : 'max';
                $value_group = $self->group_col->type eq 'curval'
                    ? $self->_format_curcommon($self->group_col, $record)
                    : $record->get_column($self->group_col->field);
            }

            foreach my $column (@{$self->_columns_globe})
            {
                my $country = $record->get_column($column->field)
                    or next;

                push @this_countries, $country;
            }

            foreach my $this_country (@this_countries)
            {
                $countries{$this_country} ||= [];
                push @{$countries{$this_country}}, {
                    id_count    => $record->get_column('id_count'),
                    value_color => $value_color,
                    color       => $color,
                    value_label => $value_label,
                    value_group => $value_group,
                };
            }
        }
        else {
            my @titles; my @this_countries;
            foreach my $column (@{$self->_columns})
            {
                my $d = $record->fields->{$column->id}
                    or next;

                # Only show unique items of children, otherwise will be a lot of
                # repeated entries
                next if $record->parent_id && !$d->child_unique;

                if ($column->return_type eq "globe")
                {
                    push @this_countries, $d->as_string;
                }
                else {
                    next if $column->type eq "rag";
                    push @titles, {col => $column, value => $d->as_string} if $d->as_string;
                }
            }

            foreach my $this_country (@this_countries)
            {
                $countries{$this_country} ||= [];
                push @{$countries{$this_country}}, {
                    current_id => $record->current_id,
                    titles     => \@titles,
                };
            }
        }
    }

    my @item_return; my $count;
    foreach my $country (keys %countries)
    {
        $count++;
        my @items = @{$countries{$country}};

        my @colors;

        my $values;
        foreach my $item (@items)
        {
            # label
            if ($self->has_label_col)
            {
                if ($self->label_col && $self->label_col->numeric)
                {
                    $values->{label_sum} ||= 0;
                    $values->{label_sum} += $item->{value_label} if $item->{value_label};
                    push @{$values->{group_sums}}, { text => $item->{value_group}, sum => $item->{value_label} }
                        if $self->group_col;
                }
                else {
                    $values->{label_text}->{$item->{value_label} || '_count'} ||= 0;
                    $values->{label_text}->{$item->{value_label} || '_count'} += $item->{id_count};
                }
            }

            # color
            if ($self->color_col)
            {
                if ($self->is_choropleth)
                {
                    $values->{color_sum} ||= 0;
                    $values->{color_sum} += $item->{value_color} if $item->{value_color};
                    $values->{group_sums} ||= [];
                    # Add individual group totals, if not already added in previous label
                    push @{$values->{group_sums}}, { text => $item->{value_group}, sum => $item->{value_color} }
                        if $self->group_col && !($self->label_col && $self->color_col->id == $self->label_col->id);
                }
                else {
                    $values->{color_text}->{$item->{value_color}} ||= 0;
                    $values->{color_text}->{$item->{value_color}} += $item->{id_count};
                    $values->{color} = !$values->{color} || $values->{color} eq $item->{color} ? $item->{color} : 'grey';
                }
            }

            # group
            if ($self->group_col)
            {
                if ($self->group_col->numeric)
                {
                    $values->{group_sum} ||= 0;
                    $values->{group_sum} += $item->{value_group} if $item->{value_group};
                }
                else {
                    $values->{group_text}->{$item->{value_group}} ||= 0;
                    $values->{group_text}->{$item->{value_group}} += $item->{id_count};
                }
            }

            # hover
            if (!$self->is_group)
            {
                my $t = join "", map {
                    '<b>' . $_->{col}->name . ':</b> '
                    . _to_svg($_->{value})
                    . '<br>'
                } grep { $_->{col}->type ne 'file' } @{$item->{titles}};
                $t = "<i>Record ID $item->{current_id}</i><br>$t" if @items > 1;
                $values->{hover} ||= [];
                push @{$values->{hover}}, $t;
            }
        };

        # If we've grouped by a numeric value, then we will label/hover with
        # the information of how much is in each grouping
        my $group_sums = $values->{group_sums}
            && join('<br>', map { _to_svg("$_->{text}: $_->{sum}") } @{$values->{group_sums}});

        # Hover will depend on the display options
        my $hover = $self->is_choropleth && $self->group_col # Colour by number, and grouped
            ? $group_sums
            : $self->is_choropleth # Colour by number, just that number
            ? "Total: $values->{color_sum}"
            : $self->label_col && $self->label_col->numeric && $self->group_col # Numeric label and grouped
            ? $group_sums
            : $self->label_col && $self->label_col->numeric # Numeric label, just that on its own
            ? "Total: $values->{label_sum}"
            : $self->color_col # Colour by text
            ? join('<br>', map { "$_: $values->{color_text}->{$_}" } keys %{$values->{color_text}})
            : $self->group_col && $self->group_col->numeric # Group by number
            ? "Total: $values->{group_sum}"
            : $self->group_col
            ? join('<br>', map { "$_: $values->{group_text}->{$_}" } keys %{$values->{group_text}})
            : $self->has_label_col # Label by text
            ? join('<br>', map { $_ eq '_count' ? $values->{label_text}->{$_} : "$_: $values->{label_text}->{$_}" } keys %{$values->{label_text}})
            : join('<br>', @{$values->{hover}});
        my $r = {
            hover    => $hover,
            location => $country,
            index    => $self->color_col ? $count : 1,
            color    => $values->{color},
            z        => $values->{color_sum},
        };

        # Only add a label if selected by user
        $r->{label}    = $self->group_col && $self->label_col && $self->label_col->numeric
            ? $group_sums
            : $self->label_col && $self->label_col->numeric
            ? $values->{label_sum}
            : join('<br>', map { $_ eq '_count' ? $values->{label_text}->{$_} : "$_: $values->{label_text}->{$_}" } keys %{$values->{label_text}})
            if $self->has_label_col;

        push @item_return, $r;
    }

    if (!@item_return)
    {
        mistake __"There are no globe fields in this view to display"
            if !@{$self->_columns_globe};
    }

    my $marker = !$self->is_group && +{
        size => 15,
        line => {
            width => 2,
        },
    };

    my $r = {
        z             => [ map { $_->{z} } @item_return ],
        text          => [ map { $_->{hover} } @item_return ],
        locations     => [ map { $_->{location} } @item_return ],
        showscale     => $self->is_choropleth ? \1 : \0,
        type          => $self->is_group ? 'choropleth' : 'scattergeo',
        hoverinfo     => 'text',
    };
    $r->{countrycolors} = $self->is_choropleth
        ? undef
        : $self->color_col
        ? [map { $_->{color}} @item_return]
        : [('#D3D3D3') x scalar @item_return];

    $r->{marker} = $marker if $marker;
    my @return = ($r);

    if ($self->has_label_col) # Add as second trace
    {
        # Need to add a hover as well, otherwise there is a dead area where the
        # hover doesn't appear
        my $r = {
            text      => [ map { $_->{label} } @item_return ],
            locations => [ map { $_->{location} } @item_return ],
            hoverinfo => 'text',
            hovertext => [ map { $_->{hover} } @item_return ],
            mode      => 'text',
            type      => 'scattergeo',
        };
        push @return, $r;
    }

    return \@return;
}

sub uniq_join
{   my %uniq = map { $_ => 1 } @_;
    join ', ', keys %uniq;
}

sub _format_curcommon
{   my ($self, $column, $line) = @_;
    $line->get_column($column->field) or return;
    my $id = $line->get_column($column->field);
    my $text = $column->format_value(map { $line->get_column($_->field) } @{$column->curval_fields});
    qq(<a href="/record/$id">$text</a>);
}

1;

