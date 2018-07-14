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
use Log::Report 'linkspace';

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column::Curcommon';

sub _build_refers_to_instance_id
{   my $self = shift;
    my ($random) = $self->schema->resultset('CurvalField')->search({
        parent_id => $self->id,
    });
    return $random->child->instance->id if $random;
    if (@{$self->curval_field_ids})
    {
        # Maybe it hasn't been written yet, try again
        my $random_id = $self->curval_field_ids->[0];
        my $random = $self->schema->resultset('Layout')->find($random_id);
        return $random->instance->id if $random;
    }
    return undef;
}

sub make_join
{   my ($self, @joins) = @_;
    return $self->field
        if !@joins;
    +{
        $self->field => {
            value => {
                record_single => ['record_later', @joins],
            }
        }
    };
}

has autocurs => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_autocurs
{   my $self = shift;
    [
        $self->schema->resultset('Layout')->search({
            type          => 'autocur',
            related_field => $self->id,
        })->all
    ];
}

sub write_special
{   my ($self, %options) = @_;

    my $id   = $options{id};
    my $rset = $options{rset};

    unless ($options{override})
    {
        my $layout_parent = $self->layout_parent
            or error __"Please select a table to link to";

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
        $self->_update_curvals(%options);
    }

    # Update typeahead option
    $rset->update({
        typeahead   => $self->typeahead,
    });

    # Clear what may be cached values that should be updated after write
    $self->clear;

    return ();
};

sub validate
{   my ($self, $value, %options) = @_;
    return 1 if !$value;
    my $fatal = $options{fatal};
    if ($value !~ /^[0-9]+$/)
    {
        return 0 if !$fatal;
        error __x"Value for {column} must be an integer", column => $self->name;
    }
    if (!$self->schema->resultset('Current')->search({ instance_id => $self->refers_to_instance_id, id => $value })->next)
    {
        return 0 if !$fatal;
        error __x"{id} is not a valid record ID for {column}", id => $value, column => $self->name;
    }
    1;
}

sub validate_search
{   my $self = shift;
    my ($value, %options) = @_;
    if (!$value)
    {
        return 0 unless $options{fatal};
        error __x"Search value cannot be blank for {col}.",
            col => $self->name;
    }
    elsif ($value !~ /^[0-9]+$/) {
        return 0 unless $options{fatal};
        error __x"Search value must be an ID number for {col}.",
            col => $self->name;
    }
    1;
}

sub fetch_multivalues
{   my ($self, $record_ids) = @_;

    my $m_rs = $self->schema->resultset('Curval')->search({
        'me.record_id'      => $record_ids,
        'me.layout_id'      => $self->id,
    });
    $m_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @values = $m_rs->all;
    my $records = GADS::Records->new(
        user        => $self->override_permissions ? undef : $self->layout->user,
        layout      => $self->layout_parent,
        schema      => $self->schema,
        columns     => $self->curval_field_ids_retrieve,
        current_ids => [map { $_->{value} } @values],
    );
    my %retrieved;
    while (my $record = $records->single)
    {
        $retrieved{$record->current_id} = $record;
    }

    map {
        +{
            layout_id => $self->id,
            record_id => $_->{record_id},
            value     => $_->{value} && $retrieved{$_->{value}},
        }
    } @values;
}

sub multivalue_rs
{   my ($self, $record_ids) = @_;
    $self->schema->resultset('Curval')->search({
        'me.record_id'      => $record_ids,
        'me.layout_id'      => $self->id,
    });
}

sub random
{   my $self = shift;
    $self->all_ids->[rand @{$self->all_ids}];
}

1;
