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

package GADS::Datum::Daterange;

use DateTime;
use DateTime::Format::DateManip;
use DateTime::Span;
use GADS::SchemaInstance;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/ArrayRef/;

extends 'GADS::Datum';

with 'GADS::DateTime';

has schema => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        GADS::SchemaInstance->instance;
    },
);

# Set datum value with value from user
after set_value => sub {
    my ($self, $all, %options) = @_;
    $all ||= [];
    my @all = @$all; # Take a copy first
    my $clone = $self->clone;
    shift @all if @all % 2 == 1 && !$all[0]; # First is hidden value from form
    my @values;
    while (@all)
    {
        # Allow multiple sets of dateranges to be submitted in array ref blocks
        # or as one long array, 2 elements per range
        my $first = shift @all;
        my ($start, $end) = ref $first eq 'ARRAY' ? @$first : ($first, shift @all);
        my @dt = $self->parse_daterange([$start, $end], source => 'user', %options);
        push @values, @dt if @dt;
    }
    my @text_all = sort map { $self->_as_string($_) } @values;
    my @old_texts = @{$self->text_all};
    my $changed = "@text_all" ne "@old_texts";
    if ($changed)
    {
        $self->changed(1);
        $self->_set_values([@values]);
        $self->_set_text_all([@text_all]);
        $self->clear_html_form;
        $self->clear_blank;
    }
    $self->oldvalue($clone);
};

has values => (
    is      => 'rwp',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->init_value or return [];
        my @values = map { $self->parse_daterange($_, source => 'db') } @{$self->init_value};
        $self->has_value(!!@values);
        [@values];
    },
    coerce  => sub {
        my $values = shift;
        # If the timezone is floating, then assume it is UTC (e.g. from MySQL
        # database which do not have timezones stored). Set it as UTC, as
        # otherwise any changes to another timezone will not make any effect
        foreach my $v (@$values)
        {
            $v->start->time_zone->is_floating && $v->set_time_zone('UTC');
            #$v->end->time_zone->is_floating && $v->end->set_time_zone('UTC');
        }
        return $values;
    },
);

has text_all => (
    is      => 'rwp',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        [ map { $self->_as_string($_) } @{$self->values} ];
    },
);

sub _build_blank
{   my $self = shift;
    ! grep { $_->start && $_->end } @{$self->values};
}

# Can't use predicate, as value may not have been built on
# second time it's set
has has_value => (
    is => 'rw',
);

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->(
        $self,
        values => $self->values,
        schema => $self->schema,
        @_,
    );
};

# XXX Why is this needed? Error when creating new record otherwise
sub as_integer
{   my $self = shift;
    $self->value; # Force update of values
    $self->value && $self->value->start ? $self->value->start->epoch : 0;
}

sub as_string
{   my $self = shift;
    join ', ', @{$self->text_all};
}

sub _as_string
{   my ($self, $range) = @_;
    my $format = $self->column->dateformat;
    $self->daterange_as_string($range, $format);
}

sub for_table
{   my $self = shift;
    my $return = $self->for_table_template;
    $return->{values} = $self->text_all;
    $return;
}

has html_form => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_html_form
{   my $self = shift;
    [ map {
        $_->start->format_cldr($self->column->dateformat),
        $_->end->format_cldr($self->column->dateformat),
    } @{$self->values} ];
}

sub filter_value
{   my $self = shift;
    $self->text_all->[0];
}

sub search_values_unique
{   shift->text_all;
}

sub _build_for_code
{   my $self = shift;
    return undef if !$self->column->multivalue && $self->blank;
    my @return = map {
        +{
            from  => $self->date_for_code($_->start),
            to    => $self->date_for_code($_->end),
            value => $self->_as_string($_),
        };
    } @{$self->values};

    $self->column->multivalue || @return > 1 ? \@return : $return[0];
}

1;

