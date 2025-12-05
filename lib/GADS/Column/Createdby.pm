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

package GADS::Column::Createdby;

use Log::Report 'linkspace';
use Moo;

extends 'GADS::Column::Person';

with 'GADS::Role::Presentation::Column::Createdby';

has '+value_field' => (
    default => 'value',
);

sub _build_table
{   my $self = shift;
    'Createdby';
}

sub _build_sprefix
{   my $self = shift;
    'createdby';
}

has '+internal' => (
    default => 1,
);

has '+userinput' => (
    default => 0,
);

sub tjoin
{   my $self = shift;
    # If this is the column for the person that created the initial record
    # rather than the current version, then do not return a join. This is
    # because the join will be used to join to the current version record, and
    # therefore will only return the user who created that. By returning no
    # join, the column is not added to the list of main joins and columns to be
    # returned when the record is retrieved (the value will be retrieved
    # separately).
    return undef if $self->name_short eq '_created_user';
    'createdby';
}

around '_build_retrieve_fields' => sub {
    my $orig = shift;
    my $self = shift;
    # See comments above regarding this field type
    return if $self->name_short eq '_created_user';
    return $orig->(@_);
};

# Different to normal function, this will fetch users when passed a list of IDs
sub fetch_multivalues
{   my ($self, $user_ids) = @_;

    my %user_ids = map { $_ => 1 } grep { $_ } @$user_ids; # De-duplicate

    my $m_rs = $self->schema->resultset('User')->search({
        'me.id' => [keys %user_ids],
    });
    $m_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my %users = map { $_->{id} => $_ } $m_rs->all;
    return \%users;
}

1;
