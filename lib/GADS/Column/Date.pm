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

package GADS::Column::Date;

use DateTime::Format::CLDR;
use Log::Report;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

has '+return_type' => (
    builder => sub { 'date' },
);

sub validate
{   my ($self, $value, %options) = @_;
    return 1 if !$value;
    if (!$self->parse_date($value))
    {
        return 0 unless $options{fatal};
        error __x"Invalid date '{value}' for {col}. Please enter as {format}.",
            value => $value, col => $self->name, format => $self->dateformat;
    }
    1;
}

sub validate_search
{   my $self = shift;
    my ($value, %options) = @_;
    $value or return 1;
    $value eq 'CURDATE' and return 1;
    $self->validate(@_);
}

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Date')->search({ layout_id => $id })->delete;
}

1;

