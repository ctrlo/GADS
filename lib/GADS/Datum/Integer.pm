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

package GADS::Datum::Integer;

use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Datum';

after set_value => sub {
    my ($self, $value) = @_;


    $value = [$value] if ref $value ne 'ARRAY'; # Allow legacy single values as scalar
    $value ||= [];
    my @values = sort grep {defined $_} @$value; # Take a copy first
    my $clone = $self->clone;
    my @old_ints = sort grep defined $_, @{$self->values};

    my @values2;
    foreach my $value (@values)
    {
        $value = undef if defined $value && !$value && $value !~ /^0+$/; # Can be empty string, generating warnings
        if ($value && $value =~ m!^\h*\(\h*([\*\+\-/])\h*([0-9]+)\h*\)\h*$!)
        {
            # Arithmatic, assume bulk update with only one input value
            my $op = $1; my $amount = $2;
            # Still count as valid written if currently blank
            foreach my $v (@{$self->values})
            {
                if (defined $v)
                {
                    push @values2, eval "$v $op $amount";
                }
            }
        }
        else {
            $self->column->validate($value, fatal => 1);
            push @values2, $value
                if defined $value;
        }
    }

    my $changed = (@values2 || @old_ints) && (@values2 != @old_ints || "@values2" ne "@old_ints");
    $self->changed($changed);

    if ($changed)
    {
        $self->changed(1);
        $self->_set_values([@values2]);
        $self->clear_html_form;
        $self->clear_blank;
    }
    $self->oldvalue($clone);
};

has values => (
    is        => 'rwp',
    isa       => ArrayRef,
    lazy      => 1,
    builder   => sub {
        my $self = shift;
        $self->has_init_value or return [];
        my @values = map { ref $_ eq 'HASH' ? $_->{value} : $_ } @{$self->init_value};
        $self->has_value(!!@values);
        $self->has_value(1) if @values || $self->init_no_value;
        [@values];
    },
);

has html_form => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_html_form
{   my $self = shift;
    my @values = @{$self->values};
    # Ensure at least one value for the form
    @values = (undef) if !@values;
    [ map { defined($_) ? $_ : '' } @values ];
}

sub _build_blank {
    my $self = shift;
    ! grep { length $_ } @{$self->values};
}

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self, values => $self->values, @_);
};

sub for_table
{   my $self = shift;
    my $return = $self->for_table_template;
    $return->{values} = $self->values;
    $return;
}

sub as_string
{   my $self = shift;
    my @values = grep defined $_, @{$self->values};
    return '' if !@values;
    join ', ', @values;
}

sub as_integer { panic "No longer implemented" }

sub _build_for_code
{   my ($self, %options) = @_;
    my @values = map int $_, grep defined $_, @{$self->values};
    @values = (undef) if !@values;
    $self->column->multivalue || @values > 1 ? \@values : $values[0];
}

1;
