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

package GADS::Column::Curval;

use GADS::Config;
use GADS::Records;
use Log::Report;

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

has refers_to_instance => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => 1,
    coerce  => sub { $_[0] || undef },
);

sub _build_refers_to_instance
{   my $self = shift;
    my ($random) = $self->schema->resultset('CurvalField')->search({
        parent_id => $self->id,
    });
    $random or return;
    $random->child->instance->id;
}

has curval_fields => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my @curval_fields = $self->schema->resultset('CurvalField')->search({
            parent_id => $self->id,
        })->all;
        [map { $_->child_id } @curval_fields];
    },
);

has curval_fields_index => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build_curval_fields_index
{   my $self = shift;
    my @vals = @{$self->curval_fields};
    my %vals = map { $_ => undef } @vals;
    \%vals;
}

# Does this column reference the field?
sub has_curval_field
{   my ($self, $field) = @_;
    exists $self->curval_fields_index->{$field};
}

has values => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_values
{   my $self = shift;

    # Not the normal request layout
    my $layout = $self->_layout_from_instance;

    my $records = GADS::Records->new(
        user             => undef,
        layout           => $layout,
        schema           => $self->schema,
    );

    $records->search(
        columns => $self->curval_fields,
    );

    my @values;
    my @cols = @{$records->columns_retrieved};
    foreach my $r (@{$records->results})
    {
        my $text = join ", ", map { $r->fields->{$_->id} } @cols;
        push @values, {
            id    => $r->current_id,
            value => $text,
        };
    }

    \@values;
}

has values_index => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build_values_index
{   my $self = shift;
    my @values = @{$self->values};
    my %values = map { $_->{id} => $_->{value} } @values;
    \%values;
}

sub value
{   my ($self, $id) = @_;
    $id or return;
    $self->values_index->{$id};
}

# Use an around so that we can stick the whole lot in transaction
around 'write' => sub {
    my $orig  = shift;
    my $guard = $_[0]->schema->txn_scope_guard;

    $orig->(@_); # Normal column write

    my $self = shift;
    my $layout_from_instance = $self->_layout_from_instance;

    my @curval_fields;
    foreach my $field (@{$self->curval_fields})
    {
        # Skip fields not part of referred instance
        next unless $layout_from_instance->column($field);
        my $field_hash = {
            parent_id => $self->id,
            child_id  => $field,
        };
        $self->schema->resultset('CurvalField')->create($field_hash)
            unless $self->schema->resultset('CurvalField')->search($field_hash)->count;
        push @curval_fields, $field;
    }

    # Then delete any that no longer exist
    my $search = { parent_id => $self->id };
    $search->{child_id} = { '!=' =>  [ -and => @curval_fields ] }
        if @curval_fields;
    $self->schema->resultset('CurvalField')->search($search)->delete;
    $guard->commit;
};

before 'delete' => sub {
    my $self = shift;
    $self->schema->resultset('CurvalField')->search({ parent_id => $self->id })->delete;
};

sub _layout_from_instance
{   my $self = shift;
    GADS::Layout->new(
        user        => undef, # Allow all columns
        schema      => $self->schema,
        config      => GADS::Config->instance,
        instance_id => $self->refers_to_instance,
    );
}

1;
