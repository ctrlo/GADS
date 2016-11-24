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
use JSON qw(encode_json);
use Log::Report;

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

after 'build_values' => sub {
    my ($self, $original) = @_;

    if ($original->{typeahead})
    {
        $self->typeahead(1);
    }
};

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

has typeahead => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    default => 0,
    coerce  => sub { $_[0] ? 1 : 0 },
);

has layout_parent => (
    is => 'lazy',
);

has curval_field_ids => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my @curval_field_ids = $self->schema->resultset('CurvalField')->search({
            parent_id => $self->id,
        }, {
            join     => 'child',
            order_by => 'child.position',
        })->all;
        [map { $_->child_id } @curval_field_ids];
    },
    trigger => sub {
        $_[0]->clear_curval_fields;
    },
);

has curval_fields => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

has curval_field_ids_index => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build_curval_field_ids_index
{   my $self = shift;
    my @vals = @{$self->curval_field_ids};
    my %vals = map { $_ => undef } @vals;
    \%vals;
}

sub _build_curval_fields
{   my $self = shift;
    [ map { $self->layout_parent->column($_) } @{$self->curval_field_ids} ];
}

# Does this column reference the field?
sub has_curval_field
{   my ($self, $field) = @_;
    exists $self->curval_field_ids_index->{$field};
}

has values => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _records_from_db
{   my ($self, $id) = @_;

    panic "Entering curval _build_values and PANIC_ON_CURVAL_BUILD_VALUES is true"
        if $ENV{PANIC_ON_CURVAL_BUILD_VALUES};

    # Not the normal request layout
    my $layout = $self->layout_parent
        or return; # No layout or fields set

    my $current_ids = $id && [$id];
    my $records = GADS::Records->new(
        user        => undef,
        layout      => $layout,
        schema      => $self->schema,
        columns     => $self->curval_field_ids,
        current_ids => $current_ids,
        # Sort on all columns displayed as the Curval
        sort        => [ map { { id => $_ } } @{$self->curval_field_ids} ],
    );

    return $records;
}

sub _build_values
{   my $self = shift;
    my $records = $self->_records_from_db
        or return [];
    my @values;
    while (my $r = $records->single)
    {
        push @values, $self->_format_value($r);
    }

    \@values;
}

has values_index => (
    is        => 'lazy',
    isa       => HashRef,
    predicate => 1,
);

sub _build_values_index
{   my $self = shift;
    my @values = @{$self->values};
    my %values = map { $_->{id} => $_->{value} } @values;
    \%values;
}

# Used to return a formatted value for a single datum. Normally called from a
# Datum::Curval object
sub value
{   my ($self, $id) = @_;
    $id or return;
    return $self->values_index->{$id}
        if $self->has_values_index; # Do not build unnecessarily (expensive)
    my $records = $self->_records_from_db($id)
        or return;
    my ($row) = @{$records->results};
    $self->_format_value($row);
}

# Use an around so that we can stick the whole lot in transaction
around 'write' => sub {
    my $orig  = shift;

    # $@ may be the result of a previous Log::Report::Dispatcher::Try block (as
    # an object) and may evaluate to an empty string. If so, txn_scope_guard
    # warns as such, so undefine to prevent the warning
    undef $@;
    my $guard = $_[0]->schema->txn_scope_guard;

    $orig->(@_); # Normal column write

    my $self = shift;
    my $layout_parent = $self->layout_parent
        or error __"Please select a table to link to";


    !@{$self->curval_field_ids} && !$ENV{GADS_ALLOW_BLANK_CURVAL}
        and error __"Please select some fields to use from the other table";

    # Check whether we are linking to a table that already links back to this one
    if ($self->schema->resultset('Layout')->search({
        'me.instance_id'    => $layout_parent->instance_id,
        'me.type'           => 'curval',
        'child.instance_id' => $self->layout->instance_id,
    },{
        join => {'curval_fields_parents' => 'child'},
    })->count)
    {
        error __x qq(Cannot use columns from table "{table}" as it contains a column that links back to this table),
            table => $layout_parent->name;

    }

    my @curval_field_ids;
    foreach my $field (@{$self->curval_field_ids})
    {
        # Skip fields not part of referred instance
        my $field_full = $layout_parent->column($field)
            or next;
        # Check whether field is a curval - can't refer recursively
        next if $field_full->type eq 'curval';
        my $field_hash = {
            parent_id => $self->id,
            child_id  => $field,
        };
        $self->schema->resultset('CurvalField')->create($field_hash)
            unless $self->schema->resultset('CurvalField')->search($field_hash)->count;
        push @curval_field_ids, $field;
    }

    # Then delete any that no longer exist
    my $search = { parent_id => $self->id };
    $search->{child_id} = { '!=' =>  [ -and => @curval_field_ids ] }
        if @curval_field_ids;
    $self->schema->resultset('CurvalField')->search($search)->delete;

    # Update typeahead option
    $self->schema->resultset('Layout')->find($self->id)->update({
        typeahead   => $self->typeahead,
    });

    $guard->commit;
};

sub _build_layout_parent
{   my $self = shift;
    $self->refers_to_instance or return;
    GADS::Layout->new(
        user                     => undef, # Allow all columns
        user_permission_override => 1,
        schema                   => $self->schema,
        config                   => GADS::Config->instance,
        instance_id              => $self->refers_to_instance,
    );
}

sub values_beginning_with
{   my ($self, $match) = @_;
    # First create a view to search for this value in the column.
    my @rules = map {
        +{
            field    => $_->id,
            id       => $_->id,
            type     => $_->type,
            value    => $match,
            operator => $_->return_type eq 'string' ? 'begins_with' : 'equal',
        },
    } @{$self->curval_fields};
    my $filter = encode_json({
        condition => 'OR',
        rules     => [@rules],
    });
    my $view = GADS::View->new(
        instance_id => $self->refers_to_instance,
        layout      => $self->layout_parent,
        schema      => $self->schema,
        user        => undef,
    );
    $view->filter($filter) if $match;
    my $records = GADS::Records->new(
        user    => undef, # Do not want to limit by user
        rows    => 10,
        view    => $view,
        layout  => $self->layout_parent,
        schema  => $self->schema,
        columns => $self->curval_field_ids,
    );

    my @results;
    foreach my $row (@{$records->results})
    {
        push @results, $self->_format_value($row, 'name');
    }
    @results;
}

sub _format_value
{   my ($self, $row, $value_key) = @_;
    $value_key ||= 'value';
    my @values = map { $row->fields->{$_} } @{$self->curval_field_ids};
    my $text = join ', ', @values;
    +{
        id         => $row->current_id,
        $value_key => $text,
    };
}

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Curval')->search({ layout_id => $id })->delete;
    $schema->resultset('CurvalField')->search({ parent_id => $id })->delete;
}

1;
