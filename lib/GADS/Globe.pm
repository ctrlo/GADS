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
    $type->new(%{$self->records_options});
}

has records_options => (
    is  => 'ro',
    isa => HashRef,
);

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

has color_col_id => (
    is => 'ro',
);

has _group_by => (
    is => 'lazy',
);

sub _build__group_by
{   my $self = shift;

    $self->_aggregate_col or return;

    my @group_by = map {
        +{ id => $_->id }
    } grep {
        $_->return_type eq "globe"
    } @{$self->_columns};

    push @group_by, { id => $self->color_col_id }
        if $self->color_col_id;

    \@group_by;
}

has is_choropleth => (
    is => 'lazy',
);

sub _build_is_choropleth
{   my $self = shift;
    $self->_aggregate_col && $self->records->operator eq 'sum';
}

has is_group => (
    is => 'lazy',
);

sub _build_is_group
{   my $self = shift;
    !!$self->_aggregate_col;
}

has _aggregate_col => (
    is => 'lazy',
);

sub _build__aggregate_col
{   my $self = shift;
    # $self->records not ready when this is called
    return $self->records_options->{layout}->column($self->color_col_id)
        if $self->color_col_id;
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
    push @extra, $self->group_col_id if $self->group_col_id;
    push @extra, $self->color_col_id if $self->color_col_id;
    $self->records->columns_extra([@extra]);

    # All the data values
    my %countries;
    my $records = $self->records;

    if ($self->is_group)
    {
        $records->column_id($self->_aggregate_col->id);
        $records->operator($self->_aggregate_col->numeric ? 'sum' : 'max');
        $records->group_by($self->_group_by);
    }

    while (my $record = $records->single)
    {
        if ($self->is_group)
        {
            my @this_countries;
            my $group_value = $record->get_column($self->_aggregate_col->field."_".$records->operator);

            foreach my $column (@{$self->_columns_globe})
            {
                my $country = $record->get_column($column->field)
                    or next;

                push @this_countries, $country;
            }

            my $color;
            if ($self->color_col_id && $self->records->operator ne 'sum')
            {
                $color = $self->graph->get_color($group_value);
                $self->_used_color_keys->{$group_value} = 1;
            }
            foreach my $this_country (@this_countries)
            {
                $countries{$this_country} ||= [];
                push @{$countries{$this_country}}, {
                    id_count => $record->get_column('id_count'),
                    value    => $group_value,
                    color    => $color,
                };
            }
        }
        else {
            my @titles; my @this_countries; my $color;
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
                    color      => $color,
                };
            }
        }
    }

    my @return; my $count;
    foreach my $country (keys %countries)
    {
        my $z = 0;
        $count++;
        my @items = @{$countries{$country}};

        my @item_titles;
        my @colors;

        if ($self->is_group && !$self->is_choropleth)
        {
            my %item_count;
            foreach my $item (@items)
            {
                $item_count{$item->{value}} ||= 0;
                $item_count{$item->{value}} += $item->{id_count};
                push @colors, $item->{color};
            }
            @items = map { +{ value => $_, id_count => $item_count{$_} } } keys %item_count;
        }

        foreach my $item (@items)
        {
            if ($self->is_choropleth)
            {
                $z += $item->{value};
            }
            elsif ($self->is_group)
            {
                push @item_titles, "$item->{value}: $item->{id_count}";
            }
            else {
                my $t = join "", map {
                    '<b>' . $_->{col}->name . ':</b> '
                    . _to_svg($_->{value})
                    . '<br>'
                } grep { $_->{col}->type ne 'file' } @{$item->{titles}};
                $t = "<i>Record ID $item->{current_id}</i><br>$t" if @items > 1;
                push @item_titles, $t;
                push @colors, $item->{color} if $item->{color};
            }
        };

        my %uniq  = map { $_ => 1 } @colors;
        my $color = keys %uniq == 1 ? $colors[0] : 'grey';
        push @return, {
            text     => $self->is_choropleth ? "Total: $z" : join('<br>', @item_titles),
            location => $country,
            index    => $self->color_col_id ? $count : 1,
            color    => $color,
            z        => $z,
        };
    }

    if (!@return)
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

    my $return = {
        z             => [ map { $_->{z} } @return ],
        text          => [ map { $_->{text} } @return ],
        locations     => [ map { $_->{location} } @return ],
        showscale     => $self->is_choropleth ? \1 : \0,
        type          => $self->is_group ? 'choropleth' : 'scattergeo',
        hoverinfo     => 'text',
        countrycolors => $self->is_choropleth ? undef : [map { $_->{color}} @return],
    };
    $return->{marker} = $marker if $marker;
    $return;
}

1;

