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

with 'GADS::Role::Presentation::Column::Curcommon';

has '+is_curcommon' => (
    default => 1,
);

# Dummy functions, overridden in child classes
sub value_selector { '' }
sub show_add { 0 }
sub has_subvals { 0 }
sub data_filter_fields { '' }

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
    trigger => sub { $_[0]->reset_options },
    predicated => 1,
);

has limit_rows => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub {
        my $self = shift;
        return 0 unless $self->has_options;
        $self->options->{limit_rows};
    },
    coerce  => sub { $_[0] ? int $_[0] : undef },
    trigger => sub { $_[0]->reset_options },
    predicated => 1,
);

sub clear
{   my $self = shift;
    $self->clear_values_index;
    $self->clear_all_values;
    $self->clear_view;
    $self->clear_layout_parent;
    $self->clear_curval_field_ids_all;
    $self->clear_curval_field_ids;
    $self->clear_curval_field_ids_index;
}

sub values_for_timeline
{   my $self = shift;
    map $_->{value}, @{$self->filtered_values};
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

has '+use_id_in_filter' => (
    default => 1,
);

sub tjoin
{   my ($self, %options) = @_;
    $self->make_join(map { $_->tjoin(already_seen => $options{already_seen}) } grep { !$_->internal } @{$self->curval_fields_retrieve(%options)});
}

sub _build_fetch_with_record
{   my $self = shift;
    return 0 if $self->multivalue;
    return 1 if !$self->layout_parent || !$self->layout_parent->user;
    return 0 if $self->schema->resultset('ViewLimit')->search({
        'me.user_id'       => $self->layout_parent->user->id,
        'view.instance_id' => $self->layout_parent->instance_id,
    },{
        join => 'view',
    })->next;
    return 1;
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
        [ map $_->child_id, @curval_field_ids ];
    },
);

sub curval_fields
{   my $self = shift;
    [ map { $self->layout_parent->column($_, permission => 'read') } @{$self->curval_field_ids} ];
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
sub curval_fields_multivalue
{   my ($self, %options) = @_;
    # Assume that as this is already a curval, that if we're rendering it as a
    # record then we don't need curvals within curvals, which saves on the data
    # being retrieved from the database
    [grep { !$_->is_curcommon && $_->multivalue } @{$self->curval_fields_retrieve(%options)}];
}

has curval_field_ids_all => (
    is      => 'lazy',
    isa     => ArrayRef,
    clearer => 1,
);

sub _build_curval_field_ids_all
{   my $self = shift;
    # First check if this curval does not have any fields (should not normally
    # happen)
    return [] if !@{$self->curval_field_ids};
    my @curval_field_ids = $self->schema->resultset('Layout')->search({
        internal    => 0,
        instance_id => $self->layout_parent->instance_id,
    }, {
        order_by => 'me.position',
    })->all;
    return [map { $_->id } @curval_field_ids];
}

sub curval_field_ids_retrieve
{   my ($self, %options) = @_;
    [ map { $_->id } @{$self->curval_fields_retrieve(%options)} ];
}

# Work out the columns we need to retrieve for the records that are a part of
# this value. We try and retrieve the minimum possible. This may be just the
# selected columns of the field, or it may need more: in the case of a curval
# we need may need all columns for an edit, or if the value is being used
# within a calc field then we will also need more. XXX This could be further
# improved, so as only retrieving the code fields that are needed.
sub curval_fields_retrieve
{   my ($self, %options) = @_;
    my $all = $options{all_fields} ? $self->curval_fields_all : $self->curval_fields;
    # Prevent recursive loops of fields that refer to each other
    if (my $tree = $options{already_seen_code})
    {
        my %exists = map { $_->name => 1 } $tree->ancestors;
        $all = [grep !$exists{$_->id}, @$all];
    }
    $all;
};

sub curval_fields_all
{   my $self = shift;
    [ map { $self->layout_parent->column($_, permission => 'read') } @{$self->curval_field_ids_all} ];
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

    # We want to honour the permissions for the fields that we retrieve,
    # but apply filtering regardless (for curval filter fields)
    local $GADS::Schema::IGNORE_PERMISSIONS = 1 if $self->override_permissions;
    local $GADS::Schema::IGNORE_PERMISSIONS_SEARCH = 1;

    my $is_draft = $self->layout->record && $self->layout->record->is_draft;
    my $records = GADS::Records->new(
        user                    => $self->layout->user,
        view                    => $view,
        rewind                  => $options{rewind},
        layout                  => $layout,
        schema                  => $self->schema,
        columns                 => $self->curval_field_ids_retrieve(%options),
        limit_current_ids       => $ids,
        ignore_view_limit_extra => 1,
        include_deleted         => $options{include_deleted},
        # Needed for producing records for autocur code values
        include_children        => 1,
        # XXX This should only be set when the calling parent record is a
        # draft, otherwise the draft records could potentially be used in other
        # records when they shouldn't be visible (and could be removed after
        # draft becomes permanent record).
        # Also, only add draft records if the show_add selector is enabled.
        # This is really a bit of a workaround, as it's possible that the
        # show-add modal for one curval field could contain a curval back to
        # the parent field. This can lead to its own problems (as all_fields
        # for the curval will not have been loaded, meaning that calc fields
        # cannot be evaluated for the draft record in the drop-down), so given
        # that the curval in the pop-up modal wouldn't normally contain a
        # show-add, this ensures those problems don't transpire.
        is_draft             => $is_draft && $self->show_add && $self->layout->user && $self->layout->user->id,
    );
    # If there is no default sort on the table, then sort on all columns
    # displayed as the Curval. Don't do all columns retrieved, as this could
    # include a whole load of multivalues which are then fetched from the DB
    $records->sort([ map { { id => $_ } } @{$self->curval_field_ids} ])
        if !$layout->sort_layout_id;

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

sub filval_fields { () }

sub filtered_values
{   my ($self, $submission_token) = @_;
    return [] if $self->value_selector ne 'dropdown';
    my $records = $self->_records_from_db;

    local $GADS::Schema::IGNORE_PERMISSIONS = 1 if $self->override_permissions;
    # Ensure that any filters applied to the field are applied regardless of
    # whether the user has access to those fields used for filtering
    local $GADS::Schema::IGNORE_PERMISSIONS_SEARCH = 1;

    my $submission = $self->schema->resultset('Submission')->search({
        token => $submission_token,
    })->next;
    if ($submission)
    {
        foreach my $filval_field (@{$self->filval_fields})
        {
            $self->schema->resultset('FilteredValue')->search({
                submission_id => $submission->id,
                layout_id     => $filval_field->id,
            })->delete;
        }
    }

    if (!$records || !$records->count)
    {
        # If nothing matches for the filtered values, then write a blank value,
        # just so that we know this function has been called. This can be used
        # later to check whether this function has been called, and call it if
        # it hasn't.
        if ($submission)
        {
            foreach my $filval_field (@{$self->filval_fields})
            {
                $self->schema->resultset('FilteredValue')->create({
                    submission_id => $submission->id,
                    layout_id     => $filval_field->id,
                    current_id    => undef,
                });
            }
        }
        return [];
    }

    my @values;
    while (my $r = $records->single)
    {
        push @values, $self->_format_row($r);
        if ($submission)
        {
            foreach my $filval_field (@{$self->filval_fields})
            {
                # If a user clicks the filtered-curval field multiple times, then
                # this sub can be run multiple times in different processes,
                # resulting in the creation of duplicate values. A unique
                # constraint is added to prevent this, and a try block used to
                # catch exceptions generated by multiple insertions. In an ideal
                # world we would clear out the list on each request and only
                # populate the latest, but that's difficult to achieve without
                # using some sort of blocking transactions (the default guard
                # doesn't help)
                try {
                    $self->schema->resultset('FilteredValue')->create({
                        submission_id => $submission->id,
                        layout_id     => $filval_field->id,
                        current_id    => $r->current_id,
                    });
                };
            }
        }
    }

    push @values, map $self->_format_row($_), @{$self->layout->record->fields->{$self->id}->values_as_query_records}
        if $self->show_add;

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
    my $return;
    # Exceptions are raised if trying to convert an invalid ID into a value.
    # This can happen when a filter has been set up and then its referred-to
    # curval record is deleted
    try {
        $id =~ /^[0-9]+$/ or return '';
        my ($row) = $self->ids_to_values([$id]);
        $return = $row->{value};
    };
    $return;
}

sub id_as_string
{   my ($self, $id) = @_;
    $id or return '';
    my @vals =  $self->ids_to_values([$id]);
    $vals[0]->{value};
}

# Used to return a formatted value for a single datum. Normally called from a
# Datum::Curval object
sub ids_to_values
{   my ($self, $ids, %options) = @_;
    my $rows = $self->_get_rows($ids, %options);
    map { $self->_format_row($_) } @$rows;
}

sub field_values_for_code
{   my $self = shift;
    my %options = @_;
    my $already_seen_code = $options{already_seen_code};
    my $values = $self->field_values(@_, all_fields => 1);

    my @retrieve_cols = grep {
        $_->name_short
    } @{$self->curval_fields_retrieve(all_fields => 1, %options)};

    my $return = {};

    foreach my $cid (keys %$values)
    {
        foreach my $col (@retrieve_cols)
        {
            if (my $d = $values->{$cid}->{$col->id})
            {
                # Ensure that the "global" (within parent datum) already_seen
                # hash is passed around all sub-datums.
                $d->already_seen_code($already_seen_code);
                # As we delve further into more values, increase the level for
                # each curval/autocur
                $d->already_seen_level($options{level} + ($col->is_curcommon ? 1 : 0));
                $return->{$cid}->{$col->name_short} = $d->for_code;
            }
        }
        $return->{$cid}->{record} = $values->{$cid}->{record};
    }

    $return;
}

sub field_values
{   my ($self, %params) = @_;

    # $param{all_fields}: retrieve all fields of the rows. If the column of the
    # row hasn't been built with all_columns, then we'll need to retrieve all
    # the columns (otherwise only the ones defined for display in the record
    # will be available).  The rows would normally only need to be retrieved
    # when a single record is being written.

    $params{rows} || $params{ids}
        or panic "Neither rows not ids passed to all_field_values";

    # Array for the rows to be returned
    my @rows;

    my @need_ids; # IDs of those records that need to be fully retrieved

    # See if any of the requested rows have not had all columns built and
    # therefore a rebuild is required
    if ($params{all_fields} && $params{rows})
    {
        # We have full database rows, so now let's see if any of them were not
        # build with the all columns flag.
        # Those that need to be retrieved
        my $curval_field_ids = $self->curval_field_ids_retrieve(all_fields => $params{all_fields}, %params);
        @need_ids = map {
            $_->current_id
        } grep {
            !$_->has_fields($curval_field_ids)
        } @{$params{rows}};
        # Those that don't can be added straight to the return array
        @rows = grep {
            $_->has_fields($curval_field_ids)
        } @{$params{rows}};
        my %has_rows = map { $_->current_id => 1 } grep $_->current_id, @{$params{rows}};
        push @need_ids, grep !$has_rows{$_}, @{$params{all_ids}};
    }
    elsif ($params{all_fields})
    {
        # This section is if we have only been passed IDs, in which case we
        # will need to retrieve the rows
        @need_ids = @{$params{ids}};
    }
    if (@need_ids)
    {
        push @rows, @{$self->_get_rows(\@need_ids, %params)};
    }
    elsif ($params{rows}) {
        # Just use existing rows
        @rows = @{$params{rows}};
    }

    my %return;
    foreach my $row (@rows)
    {
        my $ret;
        # Curval values that have not been written yet don't have an ID
        next if !$row->current_id;
        foreach my $col (@{$self->curval_fields_retrieve(all_fields => $params{all_fields}, %params)})
        {
            # Prevent recursive loops. It's possible that a curval and autocur
            # field will recursively refer to each other. This is complicated
            # by calc fields including these - when the values to pass into the
            # code are generated, we check that we're not producing recursively
            # inside each other. Calc and rag fields can have input fields that
            # refer back to this (e.g. curval has a code field, the code field
            # has an autocur field, the autocur refers back to the curval).
            #
            # Check whether the field has already been seen, but ensure that it
            # was seen at a different recursive level to where we are now. This
            # is because for multivalue curval fields, the same field will be
            # seen multiple times for multiple records at the same array level.
            next if $params{already_seen_code}->{$col->id}
                && $params{already_seen_code}->{$col->id} != $params{level};
            defined $row->fields->{$col->id}
                or panic __x"Missing field {name}. Was Records build with all fields?", name => $col->name;
            $ret->{$col->id} = $row->fields->{$col->id};
            $params{already_seen_code}->{$col->id} = $params{level};
        }
        my $values = $self->_format_row($row)->{values};
        $ret->{record} = $self->format_value(@$values),
        $return{$row->current_id} = $ret;
    }
    return \%return;
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
        foreach my $id (@$ids)
        {
            # Check the cache in the layout first. There may have been another
            # curval fields that has already retrieved the full values of these
            # same records. If everything is available then use it, otherwise
            # if only some are missing retrieve from scratch to ensure any
            # ordering is correct (the chances are that either all or none will
            # be needed)
            if (my $rec = $self->layout->cached_records->{$id})
            {
                push @$return, $rec;
            }
            else {
                $return = $self->_records_from_db(ids => $ids, include_deleted => 1, %options)->results;
                if ($options{all_fields})
                {
                    $self->layout->cached_records->{$_->current_id} = $_
                        foreach @$return;
                }
                last;
            }
        }
    }
    # Remove any values that are for deleted records. These could be in the ids
    # passed into this function, and it's not possible to know without fetching
    # them.
    my %deleted = map { $_->current_id => 1 } grep $_->deleted, @$return;
    my @ids = grep !$deleted{$_}, @$ids;
    $return = [grep !$deleted{$_->current_id}, @$return];
    error __x"Invalid Curval ID list {ids}", ids => "@ids"
        if @$return != @ids;
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
        # Skip fields not part of referred instance. This can happen when a
        # user changes the instance that is referred to, in which case fields
        # may still be selected and submitted from the no-longer-displayed
        # table's list of fields
        my $field_full = $layout_parent->column($field);
        $field_full->instance_id == $layout_parent->instance_id
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
    $self->layout->clone(instance_id => $self->refers_to_instance_id);
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

sub values_beginning_with
{   my ($self, $match, %options) = @_;
    return if !$self->filter_view_is_ready; # Record not ready yet in sub_values
    # First create a view to search for this value in the column.
    my @conditions = map {
        +{
            field    => $_->id,
            id       => $_->id,
            type     => $_->type,
            value    => $match,
            operator => $_->return_type eq 'string' ? 'begins_with' : 'equal',
        },
    } @{$self->curval_fields};
    my @rules = (
        {
            condition => 'OR',
            rules     => [@conditions],
        },
    );
    push @rules, $self->view->filter->as_hash
        if $self->view;
    my $filter = GADS::Filter->new(
        as_hash => {
            condition => 'AND',
            rules     => \@rules,
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
    local $GADS::Schema::IGNORE_PERMISSIONS = 1
        if $self->override_permissions;
    my $records = GADS::Records->new(
        user    => $self->layout->user,
        rows    => 10,
        view    => $view,
        layout  => $self->layout_parent,
        schema  => $self->schema,
        columns => $self->curval_field_ids,
    );

    my @results;
    if ($match || !$options{noempty})
    {
        foreach my $row (@{$records->results})
        {
            push @results, $self->_format_row($row, value_key => 'name');
        }
    }
    map { +{ id => $_->{id}, label => $_->{name}, html => $_->{html} } } @results;
}

sub _format_row
{   my ($self, $row, %options) = @_;
    my $value_key = $options{value_key} || 'value';
    my @values;
    my @html;
    foreach my $fid (@{$self->curval_field_ids})
    {
        next if !$self->override_permissions && !$self->layout_parent->column($fid, permission => 'read');
        push @html, $row->fields->{$fid}->html;
        push @values, $row->fields->{$fid}->as_string;
    }
    my $text     = $self->format_value(@values);
    my $html     = join ', ', grep $_, @html;
    my $as_query = ($row->is_draft || !$row->current_id) && $row->as_query;
    +{
        id          => $row->current_id,
        value_id    => $as_query || $row->current_id,
        selector_id => $row->selector_id,
        record      => $row,
        $value_key  => $text,
        values      => \@values,
        html        => $html,
    };
}

sub format_value
{   shift; join ', ', map { $_ || '' } @_;
}

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Curval')->search({ layout_id => $id })->delete;
    $schema->resultset('CurvalField')->search({ parent_id => $id })->delete;
    $schema->resultset('FilteredValue')->search({ layout_id => $id })->delete;
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
    # into the JSON structure. Do not set layout now, as it will cause column
    # IDs to be validated and removed, which have not been mapped yet
    my $filter = GADS::Filter->new(as_json => $values->{filter});
    foreach my $f (@{$filter->filters})
    {
        my $field_id = $f->{id};
        if ($field_id =~ /^([0-9]+)\_([0-9]+)$/)
        {
            $field_id = $mapping->{$1} .'_'. $mapping->{$2};
        }
        else {
            $field_id = $mapping->{$field_id};
        }
        $f->{id} = $field_id
            or panic "Missing ID";
        $f->{field} = $field_id;
        delete $f->{column_id}; # XXX See comments in GADS::Filter
    }
    $filter->clear_as_json;
    $filter->layout($self->layout);
    $self->filter($filter);

    $orig->(@_);
};

1;
