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
use Log::Report;
use Moo;
use namespace::clean;

extends 'GADS::Datum';

has set_value => (
    is       => 'rw',
    trigger  => sub {
        my ($self, $value) = @_;
        $value =~ /\h+$/ if !ref $value && $value;
        if (my $regex = !ref $value && $self->column->force_regex)
        {
            error __x"Invalid value \"{value}\" for {field}", value => $value, field => $self->column->name
                if $value !~ /^$regex$/;
        }
        if ($self->has_value)
        {
            # Previous value
            $self->changed(1)
                if defined($self->value) && defined($value) && $self->value ne $value;
            $self->oldvalue($self->clone);
        }
        $self->value(
            (ref $value ? $value->{value} : $value) || ""
        ) if defined $value || $self->init_no_value;
    },
);

has value => (
    is        => 'rw',
    trigger   => sub { $_[0]->blank($_[1] ? 0 : 1) },
    predicate => 1,
);

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self, value => $self->value);
};

sub as_string
{   my $self = shift;
    $self->value // "";
}

sub as_integer
{   my $self = shift;
    no warnings 'numeric';
    int ($self->value // 0);
}

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

