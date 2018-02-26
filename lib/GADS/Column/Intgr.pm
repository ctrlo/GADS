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

package GADS::Column::Intgr;

use Log::Report 'linkspace';
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

has '+numeric' => (
    default => 1,
);

has '+addable' => (
    default => 1,
);

has '+return_type' => (
    builder => sub { 'integer' },
);

sub validate
{   my ($self, $value, %options) = @_;

    foreach my $v (ref $value ? @$value : $value)
    {
        if ($v && $v !~ /^-?[0-9]+$/)
        {
            return 0 unless $options{fatal};
            error __x"'{int}' is not a valid integer for '{col}'",
                int => $v, col => $self->name;
        }
    }
    1;
}

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Intgr')->search({ layout_id => $id })->delete;
}

1;

