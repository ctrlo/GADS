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

with 'GADS::Role::Curcommon::RelatedField';

has '+option_names' => (
    default => sub { [qw/override_permissions limit_rows/] },
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

sub show_add { 0 } # For compatibility with curval when used as is_curcommon

sub _build_sprefix { 'current' };

sub _build_refers_to_instance_id
{   my $self = shift;
    $self->related_field or return undef;
    $self->related_field->instance_id;
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

    return if $options{override};

    my $rset = $options{rset};

    $self->related_field_id
        or error __x"Please select a field that refers to this table";

    $rset->update({
        related_field => $self->related_field_id,
    });

    $self->_update_curvals(%options);

    # Clear what may be cached values that should be updated after write
    $self->clear;

    return ();
};

# Autocurs are defined as not user input, so they get updated during
# update-cached. This makes sure that it does nothing silently
sub update_cached {}

# Not applicable for autocurs - there is no filtering for an autocur column as
# there is with curvals
sub filter_view_is_ready
{   my $self = shift;
    return 1;
}

has view => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {},
);

sub fetch_multivalues
{   my ($self, $record_ids, %options) = @_;

    return if !@$record_ids;

    local $GADS::Schema::IGNORE_PERMISSIONS = 1 if $self->override_permissions;
    # Always ignore permissions of fields in the actual search. This doesn't
    # affect any filters that may be applied, but is in fact the opposite: if a
    # limited view is defined (using fields the user does not have access to)
    # then this ensures it is properly applied
    local $GADS::Schema::IGNORE_PERMISSIONS_SEARCH = 1;

    my $m_rs = $self->multivalue_rs($record_ids);
    $m_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @values = $m_rs->all;
    my $records = GADS::Records->new(
        already_seen            => $options{already_seen},
        user                    => $self->layout->user,
        layout                  => $self->layout_parent,
        schema                  => $self->schema,
        columns                 => $self->curval_field_ids_retrieve(all_fields => $self->retrieve_all_columns, %options),
        limit_current_ids       => [map { $_->{record}->{current_id} } @values],
        include_children        => 1, # Ensure all autocur records are shown even if they have the same text content
        ignore_view_limit_extra => 1,
    );
    my %retrieved;
    while (my $record = $records->single)
    {
        $retrieved{$record->current_id} = $record;
    }

    # It shouldn't happen under normal circumstances, but there is a chance
    # that a record will have multiple values of the same curval. In this case
    # the autocur will contain multiple values, so we de-duplicate here.
    my @v; my $done = {};
    foreach (@values)
    {
        next unless exists $retrieved{$_->{record}->{current_id}};
        my $cid = $_->{record}->{current_id};
        my $rid = $_->{value}->{records}->[0]->{id};
        push @v, +{
            layout_id => $self->id,
            record_id => $rid,
            value     => $retrieved{$cid},
        } unless $done->{$cid}->{$rid};
        $done->{$cid}->{$rid} = 1;
    }
    return @v;
}

sub multivalue_rs
{   my ($self, $record_ids) = @_;

    # If this is called with undef record_ids, then make sure we don't search
    # for that, otherwise a large number of unreferenced curvals could be
    # returned
    $record_ids = [ grep { defined $_ } @$record_ids ];
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
