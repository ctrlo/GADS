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
use namespace::clean;

extends 'GADS::Datum';

after set_value => sub {
    my ($self, $value) = @_;
    $self->oldvalue($self->clone);
    ($value) = @$value if ref $value eq 'ARRAY';
    $value = undef if defined $value && !$value && $value !~ /^0+$/; # Can be empty string, generating warnings
    if ($value && $value =~ m!^\h*\(\h*([\*\+\-/])\h*([0-9]+)\h*\)\h*$!)
    {
        my $op = $1; my $amount = $2;
        # Still count as valid written if currently blank
        if (defined $self->value)
        {
            my $old = $self->value;
            $value = eval "$old $op $amount";
        }
        else {
            $value = undef;
        }
    }
    else {
        $self->column->validate($value, fatal => 1);
    }
    $self->changed(1) if (!defined($self->value) && defined $value)
        || (!defined($value) && defined $self->value)
        || (defined $self->value && defined $value && $self->value != $value);
    $self->value($value);
};

has value => (
    is      => 'rw',
    lazy    => 1,
    trigger => sub { $_[0]->blank(defined $_[1] ? 0 : 1) },
    builder => sub {
        my $self = shift;
        $self->has_init_value or return;
        my $value = $self->init_value->[0];
        $value = $value->{value} if ref $value eq 'HASH';
        $self->has_value(1) if defined $value || $self->init_no_value;
        $value;
    },
);

sub _build_blank {
    defined $_[0]->value && $_[0]->value =~ /.+/ ? 0 : 1;
}

around 'clone' => sub {
    my $orig = shift;
    my $self = shift;
    $orig->($self, value => $self->value, @_);
};

sub as_string
{   my $self = shift;
    $self->value // "";
}

sub as_integer
{   my $self = shift;
    my $int  = int ($self->value // 0);
}

sub _build_for_code
{   my $self = shift;
    defined $self->value or return undef;
    int $self->value;
}

1;
