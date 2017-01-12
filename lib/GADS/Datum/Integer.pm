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

use Log::Report;
use Moo;
use namespace::clean;

extends 'GADS::Datum';

has set_value => (
    is       => 'rw',
    trigger  => sub {
        my ($self, $value) = @_;
        ($value) = @$value if ref $value eq 'ARRAY';
        $value = undef if defined $value && !$value && $value !~ /^0+$/; # Can be empty string, generating warnings
        $self->column->validate($value, fatal => 1);
        $self->changed(1) if (!defined($self->value) && defined $value)
            || (!defined($value) && defined $self->value)
            || (defined $self->value && defined $value && $self->value != $value);
        $self->oldvalue($self->clone);
        $self->value($value) if defined $value || $self->init_no_value;
    },
);

has value => (
    is      => 'rw',
    lazy    => 1,
    trigger => sub { $_[0]->blank(defined $_[1] ? 0 : 1) },
    builder => sub {
        my $self = shift;
        $self->has_init_value or return;
        my $value = $self->init_value->[0]->{value};
        $self->has_value(1) if defined $value || $self->init_no_value;
        $value;
    },
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
    my $int  = int ($self->value // 0);
}

sub for_code
{   my $self = shift;
    $self->value or return undef;
    int $self->value;
}

1;
