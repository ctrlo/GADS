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

use Log::Report 'linkspace';
use GADS::Users;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

our @person_properties = qw/id email username firstname surname freetext1 freetext2 organisation department_id team_id title value/;

# Convert based on whether ID or full name provided
sub value_field_as_index
{   my ($self, $value) = @_;
    return 'id' if !$value || $value =~ /^[0-9]+$/;
    return $self->value_field;
}

has '+has_filter_typeahead' => (
    default => 1,
);

has '+fixedvals' => (
    default => 1,
);

has '+option_names' => (
    default => sub { [qw/default_to_login/] },
);

sub _build_retrieve_fields
{   my $self = shift;
    \@person_properties;
}

has default_to_login => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub {
        my $self = shift;
        return 0 unless $self->has_options;
        $self->options->{default_to_login};
    },
    trigger => sub { $_[0]->reset_options },
);

sub _build_sprefix { 'value' };

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

sub tjoin
{   my $self = shift;
    +{$self->field => 'value'};
}

sub random
{   my $self = shift;
    my %hash = %{$self->people_hash};
    $hash{(keys %hash)[rand keys %hash]}->value;
}

has '+autocomplete_has_id' => (
    default => 1,
);

sub resultset_for_values
{   my $self = shift;
    return $self->schema->resultset('User')->active;
}

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Person')->search({ layout_id => $id })->delete;
}

1;

