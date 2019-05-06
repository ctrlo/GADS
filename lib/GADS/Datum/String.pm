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

package GADS::Datum::String;

use HTML::FromText;
use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Datum';

with 'GADS::Role::Presentation::Datum::String';

after set_value => sub {
    my ($self, $value) = @_;
    $value = [$value] if ref $value ne 'ARRAY'; # Allow legacy single values as scalar
    $value ||= [];
    my @values = grep {defined $_} @$value; # Take a copy first
    my $clone = $self->clone;
    my @text_all = sort @values;
    my @old_texts = @{$self->text_all};

    # Trim entries, but only if changed. Don't use $changed, as the act of
    # trimming could affect whether a value has changed or not
    if ("@text_all" ne "@old_texts")
    {
        s/\h+$// for @values;
    }
    my $changed = "@text_all" ne "@old_texts";

    if (my $regex = $self->column->force_regex)
    {
        foreach my $val (@values)
        {
            my $msg = __x"Invalid value \"{value}\" for {field}", value => $val, field => $self->column->name;
            # Empty values are not checked - these should be done in optional value for field
            if ($val && $val !~ /^$regex$/)
            {
                $changed ? error($msg) : warning($msg);
            }
        }
    }
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
    [ map { defined($_) ? $_ : '' } @{$self->values} ];
}

has text_all => (
    is      => 'rwp',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->values;
        [ map { defined $_ ? $_ : '' } @{$self->values} ];
    },
);

sub _build_blank {
    my $self = shift;
    ! grep { length $_ } @{$self->values};
}

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self, values => $self->values, text_all => $self->text_all, @_);
};

sub as_string
{   my $self = shift;
    join ', ', @{$self->text_all};
}

sub as_integer { panic "Not implemented" }

sub html_withlinks
{   my $self = shift;
    my $string = $self->as_string;
    text2html(
        $string,
        urls      => 1,
        email     => 1,
        metachars => 1,
    );
}

1;

