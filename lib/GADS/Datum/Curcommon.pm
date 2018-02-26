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

package GADS::Datum::Curcommon;

use HTML::Entities qw/encode_entities/;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Datum';

with 'GADS::Role::Presentation::Datum::Curcommon';

sub set_value
{   my ($self, $value) = @_;
    my $clone = $self->clone; # Copy before changing text
    my @values = sort grep {$_} ref $value eq 'ARRAY' ? @$value : ($value);
    $self->column->validate($_, fatal => 1) foreach @values;
    my @old     = sort @{$self->ids};
    my $changed = "@values" ne "@old";
    $self->_set_written_valid(!!@values);
    if ($changed)
    {
        $self->changed(1);
        $self->_set_ids(\@values);
        # Need to clear initial values, to ensure new value is built from this new ID
        $self->_clear_text_all;
        $self->_clear_text_hash;
        $self->clear_text;
        $self->clear_init_value;
        $self->_clear_init_value_hash;
        $self->_clear_records;
        $self->clear_blank;
    }
    $self->oldvalue($clone);
    $self->_set_written_to(0) if $self->value_next_page;
}

# Hash with various values built from init_value. Used to populate
# specific value properties
has _init_value_hash => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

sub _build__init_value_hash
{   my $self = shift;
    if ($self->has_init_value) # May have been cleared after write
    {
        # initial value can either include whole record or just be ID. Assume
        # that they will be all one or the other
        my (@ids, @records);
        foreach my $v (@{$self->init_value})
        {
            my ($record, $id) = $self->_transform_value($v);
            push @records, $record if $record;
            push @ids, $id if $id;
        }
        +{
            records => \@records,
            ids     => \@ids,
        };
    }
    else {
        +{};
    }
}

has _records => (
    is      => 'lazy',
    isa     => Maybe[ArrayRef],
    clearer => 1,
);

sub _build__records
{   my $self = shift;
    $self->_init_value_hash->{records};
}

sub _build_blank
{   my $self = shift;
    @{$self->ids} ? 0 : 1;
}

around 'ready_to_write' => sub {
    my $orig = shift;
    my $self = shift;
    # If the master sub returns 0, return that here
    my $initial = $orig->($self, @_);
    return 0 if !$initial;
    # Otherwise continue tests
    foreach my $col (@{$self->column->filter->columns_in_subs($self->column->layout)})
    {
        return 0 if !$self->record->fields->{$col->id}->written_to;
    }
    return 1;
};

has text => (
    is        => 'rwp',
    isa       => Str,
    lazy      => 1,
    builder   => 1,
    clearer   => 1,
    predicate => 1,
);

sub _build_text
{   my $self = shift;
    join '; ', map { $_->{value} } @{$self->_text_all};
}

# Internal text, array ref of all individual text values
has _text_all => (
    is        => 'rw',
    isa       => ArrayRef,
    lazy      => 1,
    clearer   => 1,
    predicate => 1,
    builder   => sub {
        my $self = shift;
        if ($self->_records)
        {
            return [ map { $self->column->_format_row($_) } @{$self->_records} ];
        }
        else {
            return $self->column->ids_to_values($self->ids, fatal => 1);
        }
    }
);

has _text_hash => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

sub _build__text_hash
{   my $self = shift;
    +{
        map { $_->{id} => $_->{value} } @{$self->_text_all}
    };
}

has id_hash => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_id_hash
{   my $self = shift;
    +{ map { $_ => 1 } @{$self->ids} };
}

has ids => (
    is      => 'rwp',
    isa     => Maybe[ArrayRef],
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_init_value_hash->{ids} || [];
    },
);

sub id
{   my $self = shift;
    $self->column->multivalue
        and panic "Cannot return single id value for multivalue field";
    $self->ids->[0];
}

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    # Only pass text in if it's already been built
    my %params = (
        ids => $self->ids,
    );
    $params{_text_all}  = $self->_text_all if $self->_has_text_all;
    $params{init_value} = $self->init_value if $self->has_init_value;
    $orig->($self, %params);
};

sub as_string
{   my $self = shift;
    $self->text // "";
}

sub as_integer
{   my $self = shift;
    $self->id // 0;
}

sub html_form
{   my $self = shift;
    $self->ids;
}

sub html_withlinks
{   my $self = shift;
    $self->as_string or return "";
    my @return;
    foreach my $v (@{$self->_text_all})
    {
        my $string = encode_entities $v->{value};
        my $link = "/record/$v->{id}?oi=".$self->column->refers_to_instance_id;
        push @return, qq(<a href="$link">$string</a>);
    }
    join '; ', @return;
}

sub field_values
{   my $self = shift;
    $self->_records
        ? $self->column->field_values(rows => $self->_records)
        : $self->column->field_values(ids => $self->ids);
}

sub field_values_for_code
{   my $self = shift;
    $self->_records
        ? $self->column->field_values_for_code(rows => $self->_records)
        : $self->column->field_values_for_code(ids => $self->ids);
}

sub for_code
{   my ($self, %options) = @_;

    # Get all field data in one chunk
    my $field_values = $self->field_values_for_code;

    my @values = map {
        +{
            id           => int $_, # Ensure passed to Lua as number not string
            value        => $self->_text_hash->{$_},
            field_values => $field_values->{$_},
        }
    } (@{$self->ids});

    $self->column->multivalue ? \@values : $values[0];
}

1;
