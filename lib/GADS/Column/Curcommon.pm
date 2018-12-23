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

package GADS::Column::Curcommon;

use GADS::Config;
use GADS::Records;
use Log::Report 'linkspace';
use Scalar::Util qw/blessed/;

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

extends 'GADS::Column';

has '+is_curcommon' => (
    default => 1,
);

has override_permissions => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub {
        my $self = shift;
        return 0 unless $self->has_options;
        $self->options->{override_permissions};
    },
    trigger => sub { $_[0]->clear_options },
    predicated => 1,
);

sub clear
{   my $self = shift;
    $self->clear_filtered_values;
    $self->clear_values_index;
    $self->clear_all_values;
    $self->clear_view;
    $self->clear_layout_parent;
    $self->clear_curval_field_ids_all;
    $self->clear_curval_fields_all;
    $self->clear_curval_field_ids;
    $self->clear_curval_fields;
    $self->clear_curval_field_ids_index;
    $self->clear_curval_fields_multivalue;
}

has refers_to_instance_id => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    coerce  => sub { $_[0] || undef },
    builder => '_build_refers_to_instance_id',
);

has layout_parent => (
    is      => 'lazy',
    clearer => 1,
);

has '+can_multivalue' => (
    default => 1,
);

has '+variable_join' => (
    default => 1,
);

has '+has_filter_typeahead' => (
    default => 1,
);

has '+fixedvals' => (
    default => 1,
);

sub tjoin
{   my ($self, %options) = @_;
    $self->make_join(map { $_->tjoin } @{$self->curval_fields_retrieve(%options)});
}

has curval_field_ids => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        my @curval_field_ids = $self->schema->resultset('CurvalField')->search({
            parent_id => $self->id,
        }, {
            join     => 'child',
            order_by => 'child.position',
        })->all;
        return [map { $_->child_id } @curval_field_ids];
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

sub _build_curval_fields
{   my $self = shift;
    [ map { $self->layout_parent->column($_) } @{$self->curval_field_ids} ];
}

has curval_field_ids_index => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => 1,
);

sub _build_curval_field_ids_index
{   my $self = shift;
    my @vals = @{$self->curval_field_ids};
    my %vals = map { $_ => undef } @vals;
    \%vals;
}

# All the curval fields that are multivalue
has curval_fields_multivalue => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _build_curval_fields_multivalue
{   my $self = shift;
    [grep { $_->multivalue } @{$self->curval_fields}];
}

# The fields to actually retrieve. This will either be the same as
# the standard curval_fields, or will include additional fields that
# will be stored for calculated fields or record edits
sub curval_field_ids_retrieve
{   my ($self, %options) = @_;
    $options{all_fields}
        ? $self->curval_field_ids_all
        : $self->curval_field_ids;
}

has curval_field_ids_all => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _build_curval_field_ids_all
{   my $self = shift;
    my @curval_field_ids = $self->schema->resultset('Layout')->search({
        instance_id => $self->layout_parent->instance_id,
    }, {
        order_by => 'me.position',
    })->all;
    return [map { $_->id } @curval_field_ids];
}

sub curval_fields_retrieve
{   my ($self, %options) = @_;
    $options{all_fields}
        ? $self->curval_fields_all
        : $self->curval_fields;
};

has curval_fields_all => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _build_curval_fields_all
{   my $self = shift;
    [ map { $self->layout_parent->column($_) } @{$self->curval_field_ids_all} ];
}

sub sort_columns
{   my $self = shift;
    map { $_->sort_columns } @{$self->curval_fields};
}

sub sort_parent
{   my $self = shift;
    $self; # This field is the parent for sort columns
}

# Does this column reference the field?
sub has_curval_field
{   my ($self, $field) = @_;
    exists $self->curval_field_ids_index->{$field};
}

has view => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_view
{   my $self = shift;
    my $view = GADS::View->new(
        instance_id => $self->refers_to_instance_id,
        filter      => $self->filter,
        layout      => $self->layout_parent,
        schema      => $self->schema,
        user        => undef,
    );
    # Replace any "special" $short_name values with their actual value from the
    # record. If sub_values fails (due to record not being ready yet), then the
    # view is not built
    return unless $view->filter->sub_values($self->layout);
    return $view;
}

has all_ids => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_all_ids
{   my $self = shift;
    [
        $self->schema->resultset('Current')->search({
            instance_id => $self->refers_to_instance_id,
        })->get_column('id')->all
    ];
}

has filtered_values => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

has all_values => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _records_from_db
{   my ($self, %options) = @_;

    my $ids = $options{ids};

    # $ids is optional
    panic "Entering curval _build_values and PANIC_ON_CURVAL_BUILD_VALUES is true"
        if !$ids && $ENV{PANIC_ON_CURVAL_BUILD_VALUES};

    # Not the normal request layout
    my $layout = $self->layout_parent
        or return; # No layout or fields set

    my $view;
    if (!$ids && !$options{no_filter})
    {
        $view = $self->view
            or return; # record not ready yet for sub_values
    }

    my $records = GADS::Records->new(
        user              => $self->override_permissions ? undef : $self->layout->user,
        view              => $view,
        layout            => $layout,
        schema            => $self->schema,
        columns           => $self->curval_field_ids_retrieve(all_fields => $options{all_fields}),
        limit_current_ids => $ids,
        # Sort on all columns displayed as the Curval. Don't do all columns
        # retrieved, as this could include a whole load of multivalues which
        # are then fetched from the DB
        sort              => [ map { { id => $_ } } @{$self->curval_field_ids} ],
        is_draft          => 1, # XXX Only set this when parent record is draft?
    );

    return $records;
}

# Function to return the values for the drop-down selector, but only the
# selected ones. This makes rendering the edit page quicker, as in the case of
# a filtered drop-down, the values will be fetched each time it gets the
# focus anyway
sub selected_values
{   my ($self, $datum) = @_;
    return [
        map { $self->_format_row($_->{record}) } @{$datum->values}
    ];
}

sub _build_filtered_values
{   my $self = shift;
    return [] if $self->value_selector ne 'dropdown';
    my $records = $self->_records_from_db
        or return [];
    my @values;
    while (my $r = $records->single)
    {
        push @values, $self->_format_row($r);
    }

    \@values;
}

sub _build_all_values
{   my $self = shift;
    return [] if $self->value_selector ne 'dropdown';
    my $records = $self->_records_from_db(no_filter => 1)
        or return [];
    my @values;
    while (my $r = $records->single)
    {
        push @values, $self->_format_row($r);
    }

    \@values;
}

has values_index => (
    is        => 'lazy',
    isa       => HashRef,
    predicate => 1,
    clearer   => 1,
);

sub _build_values_index
{   my $self = shift;
    my @values = @{$self->all_values};
    my %values = map { $_->{id} => $_->{value} } @values;
    \%values;
}

sub filter_value_to_text
{   my ($self, $id) = @_;
    # Check for valid ID (in case search filter is corrupted) - Pg will choke
    # on invalid IDs
    $id =~ /^[0-9]+$/ or return '';
    my ($row) = $self->ids_to_values([$id]);
    $row->{value};
}

# Used to return a formatted value for a single datum. Normally called from a
# Datum::Curval object
sub ids_to_values
{   my ($self, $ids) = @_;
    my $rows = $self->_get_rows($ids);
    map { $self->_format_row($_) } @$rows;
}

sub field_values_for_code
{   my $self = shift;
    my $values = $self->field_values(@_, all_fields => 1);

    my @retrieve_cols = grep {
        $_->name_short
    } @{$self->curval_fields_retrieve(all_fields => 1)};

    my $return = {};

    foreach my $cid (keys %$values)
    {
        foreach my $col (@retrieve_cols)
        {
            $return->{$cid}->{$col->name_short} = $values->{$cid}->{$col->id} && $values->{$cid}->{$col->id}->for_code;
        }
    }

    $return;
}

sub field_values
{   my ($self, %params) = @_;
    # If the column hasn't been built with all_columns, then we'll need to
    # retrieve all the columns (otherwise only the ones defined for display in
    # the record will be available).  The rows would normally only need to be
    # retrieved when a single record is being written.
    my $rows;
    # See if any of the requested rows have not had all columns built
    my $need_all = $params{all_fields} && $params{rows};
    if ($params{ids} || $need_all)
    {
        my $cids = $params{ids} || [ map { $_->current_id } @{$params{rows}} ];
        $rows = $self->_get_rows($cids, all_fields => $params{all_fields});
    }
    elsif ($params{rows}) {
        $rows = $params{rows}
    }
    else {
        panic "Neither rows not ids passed to all_field_values";
    }
    +{
        map {
            my $row = $_;
            $row->current_id => {
                map {
                    defined $row->fields->{$_->id}
                        or panic __x"Missing field {name}. Was Records build with all fields?", name => $_->name;
                    $_->id => $row->fields->{$_->id}
                } grep {
                    $_->type !~ /(autocur|curval)/ # Prevent recursive loops
                } @{$self->curval_fields_retrieve(all_fields => $params{all_fields})}
            },
        } @$rows
    }
}

sub _get_rows
{   my ($self, $ids, %options) = @_;
    @$ids or return;
    my $return;
    if ($self->has_values_index) # Do not build unnecessarily (expensive)
    {
        $return = [ map { $self->values_index->{$_} } @$ids ];
    }
    else {
        $return = $self->_records_from_db(ids => $ids, %options)->results;
    }
    error __x"Invalid Curval ID list {ids}", ids => "@$ids"
        if @$return != @$ids;
    $return;
}

sub _update_curvals
{   my ($self, %options) = @_;

    my $id   = $options{id};
    my $rset = $options{rset};

    !@{$self->curval_field_ids} && !$ENV{GADS_ALLOW_BLANK_CURVAL}
        and error __"Please select some fields to use from the other table";

    my $layout_parent = $self->layout_parent;

    my @curval_field_ids;
    foreach my $field (@{$self->curval_field_ids})
    {
        # Skip fields not part of referred instance
        my $field_full = $layout_parent->column($field)
            or next;
        # Check whether field is a curval - can't refer recursively
        next if $field_full->type eq 'curval';
        my $field_hash = {
            parent_id => $id,
            child_id  => $field,
        };
        $self->schema->resultset('CurvalField')->create($field_hash)
            unless $self->schema->resultset('CurvalField')->search($field_hash)->count;
        push @curval_field_ids, $field;
    }

    # Then delete any that no longer exist
    my $search = { parent_id => $id };
    $search->{child_id} = { '!=' =>  [ -and => @curval_field_ids ] }
        if @curval_field_ids;
    $self->schema->resultset('CurvalField')->search($search)->delete;

}

sub _build_layout_parent
{   my $self = shift;
    $self->refers_to_instance_id or return;
    GADS::Layout->new(
        user                     => $self->layout->user,
        user_permission_override => 1,
        schema                   => $self->schema,
        config                   => GADS::Config->instance,
        instance_id              => $self->refers_to_instance_id,
    );
}

sub values_beginning_with
{   my ($self, $match) = @_;
    $self->view or return; # Record not ready yet in sub_values
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
    my $filter = GADS::Filter->new(
        as_hash => {
            condition => 'AND',
            rules     => [
                {
                    condition => 'OR',
                    rules     => [@rules],
                },
                $self->view->filter->as_hash,
            ],
        },
        layout => $self->layout_parent,
    );
    my $view = GADS::View->new(
        instance_id => $self->refers_to_instance_id,
        layout      => $self->layout_parent,
        schema      => $self->schema,
        user        => undef,
    );
    $view->filter($filter) if $match;
    my $records = GADS::Records->new(
        user    => $self->override_permissions ? undef : $self->layout->user,
        rows    => 10,
        view    => $view,
        layout  => $self->layout_parent,
        schema  => $self->schema,
        columns => $self->curval_field_ids,
    );

    my @results;
    foreach my $row (@{$records->results})
    {
        push @results, $self->_format_row($row, value_key => 'name');
    }
    map { +{ id => $_->{id}, name => $_->{name} } } @results;
}

sub _format_row
{   my ($self, $row, %options) = @_;
    my $value_key = $options{value_key} || 'value';
    my @col_ids   = @{$self->curval_field_ids};
    my @values;
    foreach my $fid (@{$self->curval_field_ids})
    {
        push @values, $row->fields->{$fid};
    }
    my $text     = $self->format_value(@values);
    +{
        id         => $row->current_id,
        record     => $row,
        $value_key => $text,
        values     => \@values,
    };
}

sub format_value
{   shift; join ', ', map { $_ || '' } @_;
}

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Curval')->search({ layout_id => $id })->delete;
    $schema->resultset('CurvalField')->search({ parent_id => $id })->delete;
}

around export_hash => sub {
    my $orig = shift;
    my ($self, $values, %options) = @_;
    my $hash = $orig->(@_);
    my $report = $options{report_only} && $self->id;
    $hash->{refers_to_instance_id} = $self->refers_to_instance_id;
    $hash->{curval_field_ids}      = $self->curval_field_ids;
    return $hash;
};

around import_after_all => sub {
    my $orig = shift;
    my ($self, $values, %options) = @_;
    my $mapping = $options{mapping};
    my @field_ids = map { $mapping->{$_} } @{$values->{curval_field_ids}};
    $self->curval_field_ids(\@field_ids);

    # Update any field IDs contained within a filter - need to recurse deeply
    # into the JSON structure
    my $filter = GADS::Filter->new(as_json => $values->{filter});
    foreach my $f (@{$filter->filters})
    {
        $f->{id} = $mapping->{$f->{id}};
        $f->{field} = $mapping->{$f->{field}};
        delete $f->{column_id}; # XXX See comments in GADS::Filter
    }
    $filter->clear_as_json;
    $self->filter($filter);

    $orig->(@_);
};

1;
