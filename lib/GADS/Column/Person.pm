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
use GADS::PeopleFilter;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

with 'GADS::Role::Presentation::Column::Person';

our @person_properties = qw/id email username firstname surname freetext1 freetext2 organisation department_id team_id title value/;

has set_filter => (
    is      => 'rw',
    clearer => 1,
);

has '+filter' => (
    builder => sub {
        my $self = shift;
        GADS::PeopleFilter->new(
            as_json => $self->set_filter || ($self->_rset && $self->_rset->filter),
            layout => $self->layout
        )
    },
);

# Convert based on whether ID or full name provided
sub value_field_as_index
{   my ($self, $value) = @_;
    my @values = ref $value eq 'ARRAY' ? @$value : $value;
    my $type;
    foreach (@values)
    {
        last if $type && $type ne 'id';
        if (!$_ || /^[0-9]+$/)
        {
            $type = 'id';
        }
        else {
            $type = $self->value_field;
        }
    }
    return $type;
}

has '+has_filter_typeahead' => (
    default => 1,
);

has '+fixedvals' => (
    default => 1,
);

has '+option_names' => (
    default => sub { [qw/default_to_login notify_on_selection notify_on_selection_message notify_on_selection_subject/] },
);

has '+can_multivalue' => (
    default => 1,
);

sub _build_retrieve_fields
{   my $self = shift;
    \@person_properties;
}

sub values_for_timeline
{   my $self = shift;
    map $_->value, @{$self->people};
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

has notify_on_selection => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub {
        my $self = shift;
        return 0 unless $self->has_options;
        $self->options->{notify_on_selection};
    },
    trigger => sub { $_[0]->reset_options },
);

has notify_on_selection_subject => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        return '' unless $self->has_options;
        $self->options->{notify_on_selection_subject};
    },
    trigger => sub { $_[0]->reset_options },
);

has notify_on_selection_message => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        return '' unless $self->has_options;
        $self->options->{notify_on_selection_message};
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

sub id_to_hash
{   my ($self, $id) = @_;
    $id or return undef;
    my $prs = $self->schema->resultset('User')->search({ id => $id });
    $prs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    return $prs->next;
}

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

sub resultset_for_values
{   my $self = shift;
    return $self->schema->resultset('User')->active;
}

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Person')->search({ layout_id => $id })->delete;
}

sub import_value
{   my ($self, $value) = @_;

    $self->schema->resultset('Person')->create({
        record_id    => $value->{record_id},
        layout_id    => $self->id,
        child_unique => $value->{child_unique},
        value        => $value->{value},
    });
}

sub values_beginning_with {
    my ( $self, $match_string, %options ) = @_;

    my $resultset = $self->resultset_for_values;
    my @value;
    my $value_field = 'me.' . $self->value_field;
    $match_string =~ s/([_%])/\\$1/g;
    my $search =
      $match_string
      ? {
        $value_field => {
            -like => "${match_string}%",
        },
      }
      : $options{noempty}
      && !$match_string ? { \"0 = 1" }    # Nothing to match, return nothing
      :                   {};
    if ($resultset) {
        my $match_result = $resultset->search(
            $search,
            {
                rows => 10,
            },
        ).search(undef, $self->filter->person_filter);
        if ( $self->fixedvals ) {
            @value = map {
                {
                    id    => $_->get_column('id'),
                    label => $_->get_column( $self->value_field ),
                }
            } $match_result->search(
                {},
                {
                    select => [
                        {
                            max => 'me.id',
                            -as => 'id',
                        },
                        $value_field
                    ],
                    group_by => $value_field,
                }
            )->all;
        }
        else {
            @value = $match_result->search(
                {},
                {
                    select => {
                        max => $value_field,
                        -as => $value_field,
                    },
                }
            )->get_column($value_field)->all;
        }
    }
    return @value;
}

1;

