
=pod
GADS - Globally Accessible Data Store
Copyright (C) 2019 Ctrl O Ltd

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

package GADS::Datum::Count;

use Log::Report 'linkspace';
use Moo;

extends 'GADS::Datum';

has value => (
    is      => 'rw',
    lazy    => 1,
    trigger => sub { $_[0]->blank(defined $_[1] ? 0 : 1) },
    builder => sub {
        my $self = shift;
        $self->init_value->[0];
    },
);

sub as_string
{   my $self = shift;
    defined $self->value or return '';
    $self->as_integer . " unique";
}

sub as_integer
{   my $self = shift;
    return if !defined $self->value;
    int $self->value || 0;
}

sub _build_blank
{   my $self = shift;
    !!defined $self->value;
}

sub _build_for_code
{   my $self = shift;
    $self->string;
}

sub for_table
{   my $self   = shift;
    my $return = $self->for_table_template;
    $return->{type}   = 'count';
    $return->{values} = [ $self->as_string ];
    $return;
}

1;
