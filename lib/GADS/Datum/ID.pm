
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

package GADS::Datum::ID;

use Log::Report 'linkspace';
use Moo;

extends 'GADS::Datum';

has value => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_value
{   my $self = shift;
    $self->current_id;
}

sub _build_blank
{   my $self = shift;
    !$self->value;
}

sub for_table
{   my $self   = shift;
    my $return = $self->for_table_template;
    $return->{values}    = $self->value ? [ $self->as_string ] : [];
    $return->{parent_id} = $self->record->parent_id;
    $return;
}

sub as_string
{   my $self = shift;
    $self->value;
}

sub as_integer
{   my $self = shift;
    $self->value || undef;
}

sub _build_for_code
{   my $self = shift;
    $self->as_integer;
}

1;

