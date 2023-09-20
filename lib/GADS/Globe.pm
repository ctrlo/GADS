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

use GADS::RecordsGlobe;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;

has records => (
    is => 'lazy',
);

sub _build_records
{   my $self = shift;
    GADS::RecordsGlobe->new(
        is_group    => $self->is_group,
        max_results => 1000,
        %{$self->records_options},
    );
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

sub _parse_col
{   my ($self, $in, $type) = @_;
    my ($parent_id, $child_id);
    $in or return undef;
    if ($in =~ /^([0-9]+)_([0-9]+)$/)
    {
        $parent_id = $1;
        $child_id = $2;
    }
    else {
        $child_id = $in;
    }
    return $type eq 'parent' ? $parent_id : $child_id;
}

sub _parse_parent
{   my $self = shift;
    $self->_parse_col(shift, 'parent');
}

sub _parse_child
{   my $self = shift;
    $self->_parse_col(shift, 'child');
}

has group_col_id => (
    is => 'ro',
);

has group_col => (
    is => 'lazy',
);

sub _build_group_col
{   my $self = shift;
    $self->layout->column($self->_parse_child($self->group_col_id));
}

has group_col_parent => (
    is => 'lazy',
);

sub _build_group_col_parent
{   my $self = shift;
    $self->layout->column($self->_parse_parent($self->group_col_id));
}

has group_col_operator => (
    is => 'lazy',
);

sub _build_group_col_operator
{   my $self = shift;
    $self->group_col && $self->group_col->numeric ? 'sum' : 'max';
}

has color_col_id => (
    is => 'ro',
);

has color_col => (
    is => 'lazy',
);

sub _build_color_col
{   my $self = shift;
    $self->layout->column($self->_parse_child($self->color_col_id));
}

has color_col_parent => (
    is => 'lazy',
);

sub _build_color_col_parent
{   my $self = shift;
    $self->layout->column($self->_parse_parent($self->color_col_id));
}

has color_col_operator => (
    is => 'lazy',
);

sub _build_color_col_operator
{   my $self = shift;
    $self->color_col && $self->color_col->numeric ? 'sum' : 'max';
}

has color_col_is_count => (
    is  => 'lazy',
    isa => Bool,
);

sub _build_color_col_is_count
{   my $self = shift;
    $self->color_col_id && $self->color_col_id eq '-1' ? 1 : 0;
}

has has_color_col => (
    is  => 'lazy',
    isa => Bool,
);

sub _build_has_color_col
{   my $self = shift;
    return 1 if $self->color_col;
    return 1 if $self->color_col_is_count;
    return 0;
}

has label_col_id => (
    is => 'ro',
);

has label_col => (
    is => 'lazy',
);

sub _build_label_col
{   my $self = shift;
    $self->layout->column($self->_parse_child($self->label_col_id));
}

has label_col_parent => (
    is => 'lazy',
);

sub _build_label_col_parent
{   my $self = shift;
    $self->layout->column($self->_parse_parent($self->label_col_id));
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

has is_choropleth => (
    is  => 'lazy',
    isa => Bool,
);

sub _build_is_choropleth
{   my $self = shift;
    return 0 if !$self->has_color_col;
    return 1 if $self->color_col_is_count; # Choropleth by record count
    return $self->color_col && $self->color_col->numeric ? 1 : 0;
}

has is_group => (
    is => 'lazy',
);

sub _build_is_group
{   my $self = shift;
    return 1 if $self->has_color_col || $self->group_col || $self->has_label_col;
    return 0;
}

has _columns => (
    is => 'lazy',
);

sub _build__columns
{   my $self = shift;
    my @columns = @{$self->records->columns_render};
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

    my $records = $self->records;

    # Add on any extra required columns for labelling etc
    my @extra;

    push @extra, { col => $self->group_col, parent => $self->group_col_parent, operator => $self->group_col_operator, group => !$self->group_col->numeric }
        if ($self->group_col);
    push @extra, { col => $self->color_col, parent => $self->color_col_parent, operator => $self->color_col_operator, group => !$self->color_col->numeric }
        if ($self->color_col);
    push @extra, { col => $self->label_col, parent => $self->label_col_parent, group => !$self->label_col->numeric }
        if $self->label_col;

    # Messier than it should be, but if there is no globe column in the view
    # and only one in the layout, then add it on, otherwise nothing will be
    # shown
    if (my $view_id = $records->view && $records->view->id)
    {
        my %existing = map { $_->{col}->id => 1 } @extra;
        # Only add view columns if we're not grouping resuylts, otherwise the
        # column information will not be used (see addition of hover labelling
        # below)
        if (!$self->is_group)
        {
            push @extra, map { +{ col => $_ } } grep { !$existing{$_->id} }
                @{$records->columns_render};
        }
        my @gc = $records->layout->all(is_globe => 1, user_can_read => 1);
        my $has_globe;
        $has_globe = 1
            if grep { $_->{col}->return_type eq 'globe' } @extra;
        push @extra, { col => $gc[0], group => $self->is_group }
            if @gc == 1 && !$has_globe;
    }
    else {
        push @extra, map { +{ col => $_ } } $records->layout->all(user_can_read => 1);
    }

    if ($self->is_group)
    {
        $_->{group} = 1 foreach grep { $_->{col}->return_type eq 'globe' } @extra;
    }

    $self->records->columns([map {
        +{
            id        => $_->{col}->id,
            parent_id => $_->{parent} && $_->{parent}->id,
            operator  => $_->{operator} || 'max',
            group     => $_->{group},
        }
    } @extra]);

    # All the data values
    my %countries;

    # Each row will be retrieved with each type of grouping if applicable
    while (my $record = $records->single)
    {
        if ($self->is_group)
        {
            my @this_countries;
            my ($value_color, $value_label, $value_group, $color);
            if ($self->has_color_col)
            {
                if ($self->color_col_is_count)
                {
                    $value_color = $record->get_column('id_count');
                }
                else {
                    my $field = $self->color_col->field;
                    $field .= "_sum" if $self->color_col_operator eq 'sum';
                    $value_color = $record->get_column($field);
                    if (!$self->color_col->numeric)
                    {
                        $color = $self->graph->get_color($value_color);
                        $self->_used_color_keys->{$value_color} = 1;
                    }
                }
            }

            if ($self->label_col)
            {
                $value_label = $self->label_col->type eq 'curval'
                    ? $self->_format_curcommon($self->label_col, $record)
                    : $record->get_column($self->label_col->field);
                $value_label ||= '<blank>';
            }

            if ($self->group_col)
            {
                my $field = $self->group_col->field;
                $field .= "_sum" if $self->group_col_operator eq 'sum';
                $value_group = $self->group_col->type eq 'curval'
                    ? $self->_format_curcommon($self->group_col, $record)
                    : $record->get_column($field) || '<blank>';
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
                    my $label = _to_svg $item->{value_label};
                    $values->{label_text}->{$label || '_count'} ||= 0;
                    $values->{label_text}->{$label || '_count'} += $item->{id_count};
                }
            }

            # color
            if ($self->has_color_col)
            {
                if ($self->is_choropleth)
                {
                    $values->{color_sum} ||= 0;
                    $values->{color_sum} += $item->{value_color} if $item->{value_color};
                    $values->{group_sums} ||= [];
                    # Add individual group totals, if not already added in previous label
                    push @{$values->{group_sums}}, { text => $item->{value_group}, sum => $item->{value_color} }
                        if $self->group_col && !($self->label_col && $self->color_col_id eq $self->label_col_id);
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
        $hover = "$country<br>$hover"; # Add country to hover
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
        z            => [ map { $_->{z} } @item_return ],
        text         => [ map { $_->{hover} } @item_return ],
        locations    => [ map { $_->{location} } @item_return ],
        showscale    => $self->is_choropleth ? \1 : \0,
        type         => $self->is_group ? 'choropleth' : 'scattergeo',
        hoverinfo    => 'text',
        locationmode => 'country names',
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
            text         => [ map { $_->{label} } @item_return ],
            locations    => [ map { $_->{location} } @item_return ],
            hoverinfo    => 'text',
            hovertext    => [ map { $_->{hover} } @item_return ],
            mode         => 'text',
            type         => 'scattergeo',
            locationmode => 'country names',
        };
        push @return, $r;
    }

    return {
        data   => \@return,
        params => {
            view_id                     => $self->records_options->{view} && $self->records_options->{view}->id,
            layout_identifier           => $self->records_options->{layout}->identifier,
            globe_fields                => [ map $_->{col}->field, grep $_->{col}->return_type eq 'globe', @extra ],
            default_view_limit_extra_id => $self->records_options->{layout}->default_view_limit_extra_id,
        },
    };
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

