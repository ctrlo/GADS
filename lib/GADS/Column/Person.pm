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

package GADS::Column::Person;

use Log::Report;
use GADS::Users;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

has '+value_field_as_index' => (
    default => 'id',
);

has people => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        GADS::Users->new(schema => $self->schema)->all;
    },
);

has people_hash => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my @all = @{$self->people};
        my %all = map { $_->id => $_ } @all;
        \%all;
    },
);

after build_values => sub {
    my ($self, $original) = @_;

    my ($file_option) = $original->{file_options}->[0];
    if ($file_option)
    {
        $self->file_options({ filesize => $file_option->{filesize} });
    }
};

sub _build_join
{   my $self = shift;
    +{$self->field => 'value'};
}

sub random
{   my $self = shift;
    my %hash = %{$self->people_hash};
    $hash{(keys %hash)[rand keys %hash]}->value;
}

sub resultset_for_values
{   my $self = shift;
    return $self->schema->resultset('User');
}

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Person')->search({ layout_id => $id })->delete;
}

1;

