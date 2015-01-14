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

package GADS::Datum::Tree;

use Moo;
use namespace::clean;

use overload '""' => \&as_string;

extends 'GADS::Datum';

has set_value => (
    is       => 'rw',
    required => 1,
    trigger  => sub {
        my ($self, $value) = @_;
        my $first_time = 1 unless $self->has_id;
        my $new_id;
        if (ref $value)
        {
            # From database, with enumval table joined
            if ($value = $value->{value})
            {
                $new_id = $value->{id};
                $self->text($value->{value});
            }
        }
        elsif (defined $value) {
            # User input
            !$value || $self->column->node($value)
                or error __x"'{int}' is not a valid tree node ID for '{col}'"
                    , int => $value, col => $self->column->name;
            $value = undef if !$value; # Can be empty string, generating warnings
            $new_id = $value;
            # Look up text value
            my $node = $self->column->node($value);
            $self->text($node->{value}) if $node;
        }
        unless ($first_time)
        {
            # Previous value
            $self->changed(1) if (!defined($self->id) && defined $value)
                || (!defined($value) && defined $self->id)
                || (defined $self->id && defined $value && $self->id != $value);
            $self->oldvalue($self->id);
        }
        $self->id($new_id);
    },
);

has id => (
    is        => 'rw',
    predicate => 1,
    trigger   => sub { $_[0]->blank(defined $_[1] ? 0 : 1) },
);

has text => (
    is        => 'rw',
);

sub as_string
{   my $self = shift;
    $self->text // "";
}

1;
