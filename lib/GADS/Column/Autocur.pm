=pod
GADS - Globally Accessible Data Store
Copyright (C) 2017 Ctrl O Ltd

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

package GADS::Column::Autocur;

use GADS::Config;
use GADS::Records;
use Log::Report 'linkspace';

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column::Curcommon';

has '+option_names' => (
    default => sub { [qw/override_permissions/] },
);

has '+multivalue' => (
    coerce => sub { 1 },
);

has '+userinput' => (
    default => 0,
);

has '+no_value_to_write' => (
    default => 1,
);

has '+value_field' => (
    default => 'id',
);

sub _build_sprefix { 'current' };

sub _build_refers_to_instance_id
{   my $self = shift;
    $self->related_field->instance_id;
}

has related_field => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        $self->schema->resultset('Layout')->find($self->related_field_id);
    }
);

has related_field_id => (
    is      => 'rw',
    isa     => Maybe[Int], # undef when importing and ID not known at creation
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_rset && $self->_rset->get_column('related_field');
    },
    trigger => sub {
        my ($self, $value) = @_;
        $self->clear_related_field;
    },
);

sub _build_related_field_id
{   my $self = shift;
    $self->related_field->id;
}

# XXX At some point these individual refers_from properties should be replaced
# by an object representing the whole column. That will be easier if/when the
# column object can be easily generated with an ID value
has refers_from_field => (
    is => 'lazy',
);

sub _build_refers_from_field
{   my $self = shift;
    "field".$self->related_field->id;
}

has refers_from_value_field => (
    is => 'lazy',
);

sub _build_refers_from_value_field
{   my $self = shift;
    "value";
}

has curval_joins => (
    is => 'lazy',
);

sub _build_curval_joins
{   my $self = shift;
    my @join = map { $_->join } @{$self->curval_fields_retrieve};
    push @join, $self->refers_from_field;
    \@join;
}

sub make_join
{   my ($self, @joins) = @_;
    +{
        $self->field => {
            record => {
                current => {
                    record_single => ['record_later', @joins],
                }
            }
        }
    };
}

sub write_special
{   my ($self, %options) = @_;

    my $rset = $options{rset};

    $rset->update({
        related_field => $self->related_field_id,
    });

    $self->_update_curvals(%options) unless $options{override};

    # Clear what may be cached values that should be updated after write
    $self->clear;

    return ();
};

# Autocurs are defined as not user input, so they get updated during
# update-cached. This makes sure that it does nothing silently
sub update_cached {}

sub fetch_multivalues
{   my ($self, $record_ids) = @_;

    my $m_rs = $self->multivalue_rs($record_ids);
    $m_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @values = $m_rs->all;
    my $records = GADS::Records->new(
        user             => $self->override_permissions ? undef : $self->layout->user,
        layout           => $self->layout_parent,
        schema           => $self->schema,
        columns          => $self->curval_field_ids_retrieve,
        current_ids      => [map { $_->{record}->{current_id} } @values],
        include_children => 1, # Ensure all autocur records are shown even if they have the same text content
    );
    my %retrieved;
    while (my $record = $records->single)
    {
        $retrieved{$record->current_id} = $record;
    }

    map {
        +{
            layout_id => $self->id,
            record_id => $_->{value}->{records}->[0]->{id},
            value     => $retrieved{$_->{record}->{current_id}},
        }
    } grep {
        exists $retrieved{$_->{record}->{current_id}}
    } @values;
}

sub multivalue_rs
{   my ($self, $record_ids) = @_;
    my $subquery = $self->schema->resultset('Current')->search({
            'record_later.id' => undef,
    },{
        join => {
            'record_single' => 'record_later'
        },
    })->get_column('record_single.id')->as_query;

    $self->schema->resultset('Curval')->search({
        'me.record_id' => { -in => $subquery },
        'me.layout_id' => $self->related_field->id,
        'records.id'   => $record_ids,
    },{
        prefetch => [
            'record',
            {
                value => 'records',
            },
        ],
    });

}

around export_hash => sub {
    my $orig = shift;
    my $self = shift;
    my %options = @_;
    my $hash = $orig->($self, @_);
    $hash->{related_field_id} = $self->related_field_id;
    $hash;
};

around import_after_all => sub {
    my $orig = shift;
    my ($self, $values, %options) = @_;
    my $mapping = $options{mapping};
    my $report = $options{report_only};
    my $new_id = $mapping->{$values->{related_field_id}};
    notice __x"Update: related_field_id from {old} to {new}", old => $self->related_field_id, new => $new_id
        if $report && $self->related_field_id != $new_id;
    $self->related_field_id($new_id);
    $orig->(@_);
};

1;
