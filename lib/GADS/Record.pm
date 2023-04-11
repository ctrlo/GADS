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

package GADS::Record;

use CtrlO::PDF 0.06;
use DateTime;
use DateTime::Format::Strptime qw( );
use DBIx::Class::ResultClass::HashRefInflator;
use GADS::AlertSend;
use GADS::Config;
use GADS::Datum::Autocur;
use GADS::Datum::Calc;
use GADS::Datum::Count;
use GADS::Datum::Curval;
use GADS::Datum::Date;
use GADS::Datum::Daterange;
use GADS::Datum::Enum;
use GADS::Datum::File;
use GADS::Datum::Filval;
use GADS::Datum::ID;
use GADS::Datum::Integer;
use GADS::Datum::Person;
use GADS::Datum::Rag;
use GADS::Datum::Serial;
use GADS::Datum::String;
use GADS::Datum::Tree;
use GADS::Layout;
use Log::Report 'linkspace';
use JSON qw(encode_json);
use PDF::Table 0.11.0; # Needed for colspan feature
use POSIX ();
use Scope::Guard qw(guard);
use Session::Token;
use URI::Escape;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;
use namespace::clean;

with 'GADS::Role::Presentation::Record';

# When clear() is called the layout is also cleared. This property can be used
# to seed the layout to an existing value when it is rebuilt
has _seed_layout => (
    is      => 'rw',
    clearer => 1,
);

# Preferably this is passed in to prevent extra
# DB reads, but loads it if it isn't
has layout => (
    is      => 'lazy',
    clearer => 1,
    trigger  => sub {
        # Pass in record to layout, used for filtered curvals
        my ($self, $layout) = @_;
        $layout->record($self);
    },
);

sub _build_layout
{   my $self = shift;

    if (my $layout = $self->_seed_layout)
    {
        $self->_clear_seed_layout;
        return $layout;
    }

    my $instance_id = $self->_set_instance_id
        or panic "instance_id not set to create layout object";

    return GADS::Layout->new(
        user        => $self->user,
        schema      => $self->schema,
        instance_id => $instance_id,
        record      => $self,
        config      => GADS::Config->instance,
    );
}

has _set_instance_id => (
    is => 'rw',
);

has schema => (
    is       => 'rw',
    required => 1,
);

has user => (
    is       => 'rw',
    required => 1,
);

has record => (
    is      => 'rw',
    clearer => 1,
);

# Subroutine to create a slightly more advanced predication for "record" above
sub has_record
{   my $self = shift;
    my $rec = $self->record or return;
    %$rec and return 1;
}

# The parent linked record as a GADS::Record object
has linked_record => (
    is => 'lazy',
);

sub _build_linked_record
{   my $self = shift;
    my $linked = GADS::Record->new(
        user   => $self->user,
        layout => $self->layout,
        schema => $self->schema,
    );
    $linked->find_current_id($self->linked_id);
    $linked;
}

has set_record_created => (
    is      => 'rw',
    clearer => 1,
);

has set_record_created_user => (
    is      => 'rw',
    clearer => 1,
);

# Should be set true if we are processing an approval
has doing_approval => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

# Array ref with column IDs
has columns => (
    is      => 'rw',
);

sub has_fields
{   my ($self, $field_ids) = @_;
    foreach my $id (@$field_ids)
    {
        return 0 if !$self->_columns_retrieved_index->{$id};
    }
    return 1;
}

has is_group => (
    is => 'ro',
);

has group_cols => (
    is => 'ro',
);

has id_count => (
    is      => 'rwp',
    clearer => 1,
);

has _columns_retrieved_index => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build__columns_retrieved_index
{   my $self = shift;
    panic "test" if !$self->columns_retrieved_do;
    +{ map { $_->id => 1 } @{$self->columns_retrieved_do} };
}

# XXX Can we not reference the parent Records entry somehow
# or vice-versa?
# Value containing the actual columns retrieved.
# In "normal order" as per layout.
has columns_retrieved_no => (
    is => 'rw',
);

# Value containing the actual columns retrieved.
# In "dependent order", needed for calcvals
has columns_retrieved_do => (
    is => 'rw',
);

# Same as GADS::Records property
has columns_selected => (
    is => 'rw',
);

has columns_render => (
    is      => 'rw',
    default => sub { [] },
);

has columns_recalc_extra => (
    is => 'rw',
);

# Whether this is a new record, not yet in the database
has new_entry => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    clearer => 1,
    builder => sub { !$_[0]->current_id },
);

has record_id => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        $self->_set_record_id($self->record);
    },
);

has record_id_old => (
    is => 'rw',
);

# The ID of the parent record that this is related to, in the
# case of a linked record
has linked_id => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    clearer => 1,
    coerce  => sub { $_[0] || undef }, # empty string from form submit
    builder => sub {
        my $self = shift;
        $self->current_id or return;
        my $current = $self->schema->resultset('Current')->find($self->current_id)
            or return;
        $current->linked_id;
    },
);

has linked_record_id => (
    is => 'rw',
);

# The ID of the parent record that this is a child to, in the
# case of a child record
has parent_id => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    clearer => 1,
    coerce  => sub { $_[0] || undef },
    builder => sub {
        my $self = shift;
        $self->current_id or return;
        my $current = $self->schema->resultset('Current')->find($self->current_id)
            or return;
        $current->parent_id;
    },
);

has parent => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_parent
{   my $self = shift;
    return unless $self->parent_id;
    my $parent = GADS::Record->new(
        user   => $self->user,
        layout => $self->layout,
        schema => $self->schema,
    );
    $parent->find_current_id($self->parent_id);
    $parent;
}

has child_record_ids => (
    is      => 'rwp',
    isa     => ArrayRef,
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        return [] if $self->parent_id;
        my @children = $self->schema->resultset('Current')->active_rs->search({
            parent_id => $self->current_id,
        })->get_column('id')->all;
        \@children;
    },
);

has serial => (
    is  => 'lazy',
    isa => Maybe[Int],
);

sub _build_serial
{   my $self = shift;
    return unless $self->current_id;
    $self->schema->resultset('Current')->find($self->current_id)->serial;
}

has is_draft => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_is_draft
{   my $self = shift;
    return $self->record->{draftuser_id}
        if $self->record && exists $self->record->{draftuser_id};
    return undef if $self->new_entry;
    $self->schema->resultset('Current')->find($self->current_id)->draftuser_id;
}

has approval_id => (
    is => 'rw',
);

# Whether this is an approval record for a new entry.
# Used when checking permissions for approving
has approval_of_new => (
    is      => 'lazy',
    isa     => Bool,
    clearer => 1,
);

# Whether to initialise fields that have no value
has init_no_value => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

# Whether this is a record for approval
has approval_flag => (
    is  => 'rwp',
    isa => Bool,
);

# The associated record if this is a record for approval
has approval_record_id => (
    is  => 'rwp',
    isa => Maybe[Int],
);

has include_approval => (
    is => 'rw',
);

# A way of forcing the write function to know that this record
# has changed. For example, if removing a field from a child
# record, which would otherwise go unnoticed
has changed => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

# Whether the record has changed (i.e. if any fields have changed). This only
# includes fields that are input as a user, as a record will often have a value
# changed just by performing an edit (e.g. last edited time)
sub is_edited
{   my $self = shift;
    return !! grep {
        $_->changed
    } grep {
        $_->column->userinput
    } map {
        $self->fields->{$_}
    }
    keys %{$self->fields};
}

has current_id => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    coerce  => sub { defined $_[0] ? int $_[0] : undef }, # Ensure integer for JSON encoding
    clearer => 1,
    builder => sub {
        my $self = shift;
        $self->record or return undef;
        $self->record->{current_id};
    },
);

has fields => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        $self->_transform_values;
    },
);

has createdby => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        return undef if $self->new_entry;
        my $createdby_col = $self->layout->column_by_name_short('_version_user');
        if (!$self->record)
        {
            my $user_id = $self->schema->resultset('Record')->find(
                $self->record_id
            )->createdby->id;
            return $self->_person({ id => $user_id }, $createdby_col);
        }
        $self->fields->{$createdby_col->id};
    },
);

has set_deletedby => (
    is      => 'rw',
    trigger => sub { shift->clear_deletedby },
);

has deletedby => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        # Don't try and build if we are a new entry. By the time this is called,
        # the current ID may have been removed from the database due to a rollback
        return if $self->new_entry;
        my $deletedby_col = $self->layout->column_by_name_short('_deleted_by');
        if (!$self->record)
        {
            $self->record_id or return;
            my $user = $self->schema->resultset('Record')->find(
                $self->record_id
            )->deletedby or return undef;
            return $self->_person({ id => $user->id }, $deletedby_col);
        }
        my $value = $self->set_deletedby or return undef;
        return $self->_person($value, $self->layout->column($deletedby_col->id));
    },
);

sub _person
{   my ($self, $value, $column) = @_;
    GADS::Datum::Person->new(
        record           => $self,
        record_id        => $self->record_id,
        current_id       => $self->current_id,
        column           => $column,
        schema           => $self->schema,
        layout           => $self->layout,
        init_value       => $value,
    );
}

has created => (
    is      => 'lazy',
    isa     => DateAndTime,
    clearer => 1,
);

sub _build_created
{   my $self = shift;
    return $self->schema->storage->datetime_parser->parse_datetime(
        $self->record->{created}
    ) if $self->record && exists $self->record->{created};
    return $self->schema->resultset('Record')->find($self->record_id)->created;
}

has set_deleted => (
    is      => 'rw',
    trigger => sub { shift->clear_deleted },
);

has deleted => (
    is      => 'lazy',
    isa     => Maybe[DateAndTime],
    clearer => 1,
);

sub _build_deleted
{   my $self = shift;
    # Don't try and build if we are a new entry. By the time this is called,
    # the current ID may have been removed from the database due to a rollback
    return if $self->new_entry;
    if (!$self->record)
    {
        $self->current_id or return;
        return $self->schema->resultset('Record')->find($self->record_id)->deleted;
    }
    $self->set_deleted or return undef;
    $self->schema->storage->datetime_parser->parse_datetime(
        $self->set_deleted
    );
}

# Whether to take results from some previous point in time
has rewind => (
    is  => 'ro',
    isa => Maybe[DateAndTime],
);

has is_historic => (
    is      => 'lazy',
    isa     => Bool,
    clearer => 1,
);

sub _build_approval_of_new
{   my $self = shift;
    # record_id could either be an approval record itself, or
    # a record. If it's an approval record, get its record
    my $record_id = $self->approval_id || $self->record_id;

    my $record = $self->schema->resultset('Record')->find($record_id);
    $record = $record->record if $record->record; # Approval
    $self->schema->resultset('Record')->search({
        'me.id' => $record->id,
        'record_previous.id'       => undef,
    },{
        join => 'record_previous',
    })->count;
}

sub _build_is_historic
{   my $self = shift;
    my $current_rec_id = $self->record->{current}->{record_id};
    $current_rec_id && $current_rec_id != $self->record_id;
}

# Remove IDs from record, to effectively make this a new unwritten
# record. Used when prefilling values.
sub remove_id
{   my $self = shift;
    $self->current_id(undef);
    $self->linked_id(undef);
    $self->clear_new_entry;
    my $created_col = $self->layout->column_by_name_short('_created');
    $self->fields->{$created_col->id}->set_value(DateTime->now);
}

sub find_record_id
{   my ($self, $record_id, %options) = @_;
    my $search_instance_id = $options{instance_id};
    my $record = $self->schema->resultset('Record')->find($record_id)
        or error __x"Record version ID {id} not found", id => $record_id;
    my $instance_id = $record->current->instance_id;
    error __x"Record ID {id} invalid for table {table}", id => $record_id, table => $search_instance_id
        if $search_instance_id && $search_instance_id != $instance_id;
    $self->_set_instance_id($instance_id);
    $self->_find(record_id => $record_id, %options);
}

sub find_current_id
{   my ($self, $current_id, %options) = @_;
    return unless $current_id;
    my $search_instance_id = $options{instance_id};
    $current_id =~ /^[0-9]+$/
        or error __x"Invalid record ID {id}", id => $current_id;
    my $current = $self->schema->resultset('Current')->find($current_id)
        or error __x"Record ID {id} not found", id => $current_id;
    my $instance_id = $current->instance_id;
    error __x"Record ID {id} invalid for table {table}", id => $current_id, table => $search_instance_id
        if $search_instance_id && $search_instance_id != $current->instance_id;
    $self->_set_instance_id($current->instance_id);
    $self->_find(current_id => $current_id, %options);
}

sub find_chronology_id
{   my ($self, $current_id, %options) = @_;
    return unless $current_id;
    $current_id =~ /^[0-9]+$/
        or error __x"Invalid record ID {id}", id => $current_id;
    my $current = $self->schema->resultset('Current')->find($current_id)
        or error __x"Record ID {id} not found", id => $current_id;
    my $instance_id = $current->instance_id;
    $self->_set_instance_id($current->instance_id);
    $self->_find(current_id => $current_id, chronology => 1);
}

sub find_draftuser_id
{   my ($self, $draftuser_id, %options) = @_;
    $draftuser_id =~ /^[0-9]+$/
        or error __x"Invalid draft user ID {id}", id => $draftuser_id;
    $self->_set_instance_id($options{instance_id})
        if $options{instance_id};
    # Don't normally want to throw fatal errors if a draft does not exist
    $self->_find(draftuser_id => $draftuser_id, no_errors => 1, %options);
}

sub find_serial_id
{   my ($self, $serial_id) = @_;
    return unless $serial_id;
    $serial_id =~ /^[0-9]+$/
        or error __x"Invalid serial ID {id}", id => $serial_id;
    my $current = $self->schema->resultset('Current')->search({
        serial      => $serial_id,
        instance_id => $self->layout->instance_id,
    })->next
        or error __x"Serial ID {id} not found", id => $serial_id;
    $self->_seed_layout($self->layout);
    $self->_find(current_id => $current->id);
}

sub find_deleted_currentid
{   my ($self, $current_id) = @_;
    $self->find_current_id($current_id, deleted => 1)
}

sub find_deleted_recordid
{   my ($self, $record_id) = @_;
    $self->find_record_id($record_id, deleted => 1)
}

# Returns new GADS::Record object, doesn't change current one
sub find_unique
{   my ($self, $column, $value, @retrieve_columns) = @_;

    return $self->find_current_id($value)
        if $column->id == $self->layout->column_id;

    my $serial_col = $self->layout->column_by_name_short('_serial');
    return $self->find_serial_id($value)
        if $column->id == $serial_col->id;

    # First create a view to search for this value in the column.
    my $filter = encode_json({
        rules => [{
            field       => $column->id,
            id          => $column->id,
            type        => $column->type,
            value       => $value,
            value_field => $column->value_field_as_index($value), # May need to use value ID instead of string as search
            operator    => 'equal',
        }]
    });
    my $view = GADS::View->new(
        filter      => $filter,
        instance_id => $self->layout->instance_id,
        layout      => $self->layout,
        schema      => $self->schema,
        user        => undef,
    );
    @retrieve_columns = ($column->id)
        unless @retrieve_columns;
    # Do not limit by user
    local $GADS::Schema::IGNORE_PERMISSIONS_SEARCH = 1;
    my $records = GADS::Records->new(
        user    => undef, # Do not want to limit by user
        rows    => 1,
        view    => $view,
        layout  => $self->layout,
        schema  => $self->schema,
        columns => \@retrieve_columns,
    );

    # Might be more, but one will do
    my $r = $records->single;
    # Horrible hack. The record of layout will have been overwritten during the
    # above searches. Needs to be changed back to this record.
    $self->layout->record($self);
    # Another nasty hack. Make the user of the retrieved record the same as the
    # user on which find_unique() was called. This affects imports, in ensuring
    # that the user of the new record version is as per the user running the
    # import
    $r->user($self->user) if $r;
    return $r;
}

sub clear
{   my $self = shift;
    $self->clear_record;
    $self->clear_current_id;
    $self->clear_record_id;
    $self->clear_linked_id;
    $self->clear_parent_id;
    $self->clear_parent;
    $self->clear_child_record_ids;
    $self->clear_approval_of_new;
    $self->clear_fields;
    $self->clear_createdby;
    $self->clear_created;
    $self->clear_set_record_created,
    $self->clear_set_record_created_user,
    $self->clear_is_historic;
    $self->clear_new_entry;
    $self->clear_layout;
    $self->clear_id_count;
}

# XXX This whole section is getting messy and duplicating a lot of code from
# GADS::Records. Ideally this needs to share the same code.
sub _find
{   my ($self, %find) = @_;

    # First clear applicable properties
    $self->clear;

    # If deleted, make sure user has access to purged records
    error __"You do not have access to this deleted record"
        if $find{deleted} && !$self->layout->user_can("purge") && !$GADS::Schema::IGNORE_PERMISSIONS;

    my %params = (
        user                    => $self->user,
        layout                  => $self->layout,
        schema                  => $self->schema,
        columns                 => $self->columns,
        rewind                  => $self->rewind,
        is_deleted              => $find{deleted},
        is_draft                => $find{draftuser_id} || $find{include_draft},
        no_view_limits          => !!$find{draftuser_id},
        include_approval        => $self->include_approval,
        include_children        => 1,
        ignore_view_limit_extra => 1,
    );
    my $records = GADS::Records->new(%params);

    $self->columns_retrieved_do($records->columns_retrieved_do);
    $self->columns_retrieved_no($records->columns_retrieved_no);
    $self->columns_selected($records->columns_selected);
    $self->columns_render($records->columns_render);

    my $record = {}; my $limit = 10; my $page = 1; my $first_run = 1; my $current_id; my @record_ids;
    while (1)
    {
        # No linked here so that we get the ones needed in accordance with this loop (could be either)
        my @prefetches = $records->jpfetch(prefetch => 1, search => 1, limit => $limit, page => $page); # Still need search in case of view limit
        last if !@prefetches && !$first_run;
        my %options = $find{current_id} || $find{draftuser_id} ? () : (root_table => 'record', no_current => 1);
        my $search = $records->search_query(prefetch => 1, linked => 1, limit => $limit, page => $page, chronology => $find{chronology}, %options);
         # Still need search in case of view limit
        @prefetches = $records->jpfetch(prefetch => 1, search => 1, linked => 0, limit => $limit, page => $page, %options);

        my $root_table;
        if (my $record_id = $find{record_id})
        {
            unshift @prefetches, (
                {
                    'current' => [
                        'deletedby',
                        $records->linked_hash(prefetch => 1, limit => $limit, page => $page),
                    ],
                },
            ); # Add info about related current record
            push @$search, { 'me.id' => $record_id };
            $root_table = 'Record';
        }
        elsif ($find{current_id} || $find{draftuser_id})
        {
            if ($find{current_id})
            {
                push @$search, {
                    'me.id' => $find{current_id},
                };
            }
            elsif ($find{draftuser_id})
            {
                push @$search, {
                    'me.draftuser_id' => $find{draftuser_id},
                };
                push @$search, {
                    'curvals.id'      => undef,
                };
            }
            else {
                panic "Unexpected find parameters";
            }
            @prefetches = (
                $records->linked_hash(prefetch => 1, limit => $limit, page => $page),
                'deletedby',
                'currents',
                {
                    'record_single' => [
                        'record_later',
                        @prefetches,
                    ],
                },
            );
            $root_table = 'Current';
        }
        else {
            panic "record_id or current_id needs to be passed to _find";
        }

        local $GADS::Schema::Result::Record::REWIND = $records->rewind_formatted
            if $records->rewind;

        # Don't specify linked for fetching columns, we will get whataver is needed linked or not linked
        my @columns_fetch = $records->columns_fetch(search => 1, limit => $limit, page => $page, %options); # Still need search in case of view limit
        my $has_linked = $records->has_linked(prefetch => 1, limit => $limit, page => $page, %options);
        my $base = $find{record_id} ? 'me' : $records->record_name(prefetch => 1, search => 1, limit => $limit, page => $page);
        push @columns_fetch, {id => "$base.id"};
        push @columns_fetch, $find{record_id} ? {deleted => "current.deleted"} : {deleted => "me.deleted"};
        push @columns_fetch, $find{record_id} ? {linked_id => "current.linked_id"} : {linked_id => "me.linked_id"};
        push @columns_fetch, {linked_record_id => "record_single.id"}
            if $has_linked;
        push @columns_fetch, $find{record_id} ? {draftuser_id => "current.draftuser_id"} : {draftuser_id => "me.draftuser_id"};
        push @columns_fetch, {current_id => "$base.current_id"};
        push @columns_fetch, {created => "$base.created"};
        push @columns_fetch, "deletedby.$_" foreach @GADS::Column::Person::person_properties;

        # If fetch a draft, then make sure it's not a draft curval that's part of
        # another draft record
        push @prefetches, 'curvals' if $find{draftuser_id};

        my $params = {
            join     => [@prefetches],
            columns  => \@columns_fetch,
        };
        $params->{order_by} = 'record_single.created'
            if $find{chronology};
        my $result = $self->schema->resultset($root_table)->search(
            [
                -and => $search
            ], $params
        );

        $result->result_class('DBIx::Class::ResultClass::HashRefInflator');

        my @recs = $result->all;
        return if !@recs && $find{no_errors};
        @recs or error __"Requested record not found";

        # We shouldn't normally receive more than one record here, as multiple
        # values for single fields are retrieved separately. However, if a
        # field was previously a multiple-value field, and it was subsequently
        # changed to a single-value field, then there may be some remaining
        # multiple values for the single-value field. In that case, multiple
        # records will be returned from the database.
        my $last_record_id;
        foreach my $rec (@recs)
        {
            my $record_id = $rec->{id};
            foreach my $key (keys %$rec)
            {
                # If we have multiple records, check whether we already have a
                # value for that field, and if so add it, but only if it is
                # different to the first (the ID will be different)
                if ($key =~ /^field/ && $record->{$record_id}->{$key})
                {
                    my @existing = ref $record->{$record_id}->{$key} eq 'ARRAY' ? @{$record->{$record_id}->{$key}} : ($record->{$record_id}->{$key});
                    @existing = grep { $_->{id} } @existing;
                    push @existing, $rec->{$key}
                        if ! grep { $rec->{$key}->{id} == $_->{id} } @existing;
                    $record->{$record_id}->{$key} = \@existing;
                }
                else {
                    $record->{$record_id}->{$key} = $rec->{$key};
                }
            }
            $self->linked_id($rec->{linked_id}) if exists $rec->{linked_id};
            $self->linked_record_id($rec->{linked_record_id}) if exists $rec->{linked_record_id};
            $self->set_deleted($rec->{deleted}) if exists $rec->{deleted};
            $self->set_deletedby($rec->{deletedby}) if exists $rec->{deletedby};
            $current_id ||= $rec->{current_id};
            push @record_ids, $record_id
                if $first_run && (!$last_record_id || $record_id != $last_record_id);
            $last_record_id = $record_id;
        }
        $page++;
        $first_run = 0;
    }

    $self->clear_is_draft;

    # Find the user that created this record. XXX Ideally this would be done as
    # part of the original query, as it is for GADS::Records. See comment above
    # about this function
    my $first = $self->schema->resultset('Record')->search({
        current_id => $current_id,
    })->get_column('id')->min;
    my $user = $self->schema->resultset('Record')->find($first)->createdby;
    $self->set_record_created_user({$user->get_columns})
        if $user;

    # Fetch and add multi-values
    my @record_objects;
    if ($find{chronology})
    {
        foreach my $record_id (@record_ids)
        {
            my $record_hash = $record->{$record_id};
            push @record_objects, GADS::Record->new(
                schema                  => $self->schema,
                record                  => $record_hash,
                user                    => $self->user,
                layout                  => $self->layout,
                columns_retrieved_no    => $self->columns_retrieved_no,
                columns_retrieved_do    => $self->columns_retrieved_do,
                columns_selected        => $self->columns_selected,
                columns_render          => $self->columns_render,
                set_deleted             => $self->set_deleted,
                set_deletedby           => $self->set_deletedby,
                set_record_created      => $self->set_record_created,
                set_record_created_user => $self->set_record_created_user,
            );
            # Set data for this original record to the current version (latest)
            $self->record($record->{$record_ids[-1]});
        }
    }
    else {
        my ($rec) = values %$record;
        @record_objects = ($self);
        $self->record($rec);

        push @record_ids, $record->{linked}->{record_id}
            if $record->{linked} && $record->{linked}->{record_id};

        if ($self->_set_approval_flag($record->{approval}))
        {
            $self->_set_approval_record_id($record->{record_id}); # Related record if this is approval record
        }

        # Fetch and merge and multi-values
        $records->fetch_multivalues(
            record_ids    => \@record_ids,
            retrieved     => [map $record->{$_}, @record_ids],
            records       => \@record_objects,
            is_draft      => $find{draftuser_id},
            already_seen  => $records->already_seen,
        );
    }

    if ($find{chronology})
    {
        my @chronology; my $last_record;
        foreach my $record (@record_objects)
        {
            $records->rewind($record->created);
            $records->fetch_multivalues(
                record_ids   => [$record->record_id],
                retrieved    => [$record->{$record->record_id}],
                records      => [$record],
                is_draft     => $find{draftuser_id},
                already_seen => $records->already_seen,
            );
            my @changed;
            foreach my $column (@{$record->columns_retrieved_no})
            {
                next if $column->internal;
                my $datum = $record->fields->{$column->id};
                my $last_datum = $last_record && $last_record->fields->{$column->id};

                if (
                    (!$last_record && !$datum->blank)
                    || ($last_record && $last_datum->as_string ne $datum->as_string)
                )
                {
                    if ($column->type eq 'curval' && $last_record)
                    {
                        my %old_ids = map { $_->{id} => $_ } @{$last_datum->values};
                        my %new_ids = map { $_->{id} => $_ } @{$datum->values};
                        my @values;
                        # Check each value for whether it is added, removed or changed.
                        # Look through old values first
                        foreach my $id (keys %old_ids)
                        {
                            my $old_value = $old_ids{$id};
                            my $status;
                            # Removed?
                            if (!$new_ids{$id})
                            {
                                $old_value->{status} = "Removed";
                                $old_value->{version_id} = $old_value->{record}->record_id;
                                push @values, $old_value;
                            }
                            else {
                                # Changed?
                                my $new_value = delete $new_ids{$id};
                                next if $old_value->{value} eq $new_value->{value};
                                $new_value->{status} = "Changed";
                                $new_value->{version_id} = $new_value->{record}->record_id;
                                push @values, $new_value;
                            }
                        }
                        # Anything left has been added
                        foreach my $id (keys %new_ids)
                        {
                            my $new_value = $new_ids{$id};
                            $new_value->{status} = "Added";
                            $new_value->{version_id} = $new_value->{record}->record_id;
                            push @values, $new_value;
                        }
                        foreach my $v (@values)
                        {
                        }
                        push @changed, $column->presentation(datum_presentation => $datum->presentation(values => \@values))
                    }
                    else {
                        push @changed, $column->presentation(datum_presentation => $datum->presentation)
                    }
                }

            }
            push @chronology, {
                editor   => $record->createdby,
                datetime => $record->created,
                changed  => \@changed,
            };
            $last_record = $record;
        }
        $self->_set_chronology(\@chronology);
    }

    $self; # Allow chaining
}

has chronology => (
    is => 'rwp',
);

sub clone
{   my $self = shift;
    my $cloned = GADS::Record->new(
        user   => $self->user,
        layout => $self->layout,
        schema => $self->schema,
    );
    $cloned->fields({});
    $cloned->fields->{$_} = $self->fields->{$_}->clone(fresh => 1, record => $cloned, current_id => undef, record_id => undef)
        foreach keys %{$self->fields};
    return $cloned;
}

sub load_remembered_values
{   my ($self, %options) = @_;

    $self->_set_instance_id($options{instance_id})
        if $options{instance_id};
    # First see if there's a draft. If so, use that instead
    if ($self->user->has_draft($self->layout->instance_id))
    {
        $self->_set_instance_id($self->layout->instance_id)
            if !$options{instance_id};
        if ($self->find_draftuser_id($self->user->id))
        {
            # Set created date to latest time rather than time draft was saved,
            # in case used in any calculated values
            my $record_created_col = $self->layout->column_by_name_short('_created');
            $self->initialise_field($self->fields, $record_created_col->id);
            $self->remove_id;
            return;
        }
        $self->initialise;
    }

    my @remember = map {$_->id} $self->layout->all(remember => 1)
        or return;

    my $lastrecord = $self->schema->resultset('UserLastrecord')->search({
        'me.instance_id'  => $self->layout->instance_id,
        user_id           => $self->user->id,
        'current.deleted' => undef,
    },{
        join => {
            record => 'current',
        },
    })->next
        or return;

    # When loading the previous record, don't use the permissions of the
    # current user. The record may no longer be available to the user due to
    # view limits. The user won't actually be able to see the record, they will
    # just see values that they previously entered themselves.
    local $GADS::Schema::IGNORE_PERMISSIONS = 1;
    my $previous = GADS::Record->new(
        user   => undef,
        layout => $self->layout,
        schema => $self->schema,
    );

    $previous->columns(\@remember);
    $previous->include_approval(1);
    $previous->find_record_id($lastrecord->record_id);

    # Use the column object from the current record not the "previous" record,
    # as otherwise the column's layout object goes out of scope and is not
    # available due to its weakref
    $self->fields->{$_->id} = $previous->fields->{$_->id}->clone(record => $self, column => $self->layout->column($_->id))
        foreach @{$previous->columns_retrieved_do};
    # The layout's record will have been updated to $previous, so set it back
    # to the correct record
    $self->layout->record($self);

    if ($previous->approval_flag)
    {
        # The last edited record was one for approval. This will
        # be missing values, so get its associated main record,
        # and use the values for that too.
        # There will only be an associated main record if some
        # values did not need approval
        if ($previous->approval_record_id)
        {
            my $child = GADS::Record->new(
                user             => $self->user,
                layout           => $self->layout,
                schema           => $self->schema,
                include_approval => 1,
            );
            $child->find_record_id($self->approval_record_id);
            foreach my $col ($self->layout->all(user_can_write_new => 1, userinput => 1))
            {
                # See if the record above had a value. If not, fill with the
                # approval record's value
                $self->fields->{$col->id} = $child->fields->{$col->id}->clone(record => $self)
                    if !$self->fields->{$col->id}->has_value && $col->remember;
            }
        }
    }
}
sub versions
{   my $self = shift;
    my $search = {
        'current_id' => $self->current_id,
        approval     => 0,
    };
    $search->{'me.created'} = { '<' => $self->schema->storage->datetime_parser->format_datetime($self->rewind) }
        if $self->rewind;
    my @records = $self->schema->resultset('Record')->search($search,{
        prefetch => 'createdby',
        order_by => { -desc => ['me.created', 'me.id'] } # id needed for tests that write at the same time
    })->all;
    @records;
}

sub _set_record_id
{   my ($self, $record) = @_;
    $record->{id};
}

sub _create_datum
{   my ($self, $column, $value) = @_;

    my $child_unique = ref $value eq 'ARRAY' && @$value > 0
        ? $value->[0]->{child_unique} # Assume same for all parts of value
        : ref $value eq 'HASH' && exists $value->{child_unique}
        ? $value->{child_unique}
        : undef;
    my %params = (
        record           => $self,
        record_id        => $self->record_id,
        current_id       => $self->current_id,
        child_unique     => $child_unique,
        column           => $column,
        init_no_value    => $self->init_no_value,
        schema           => $self->schema,
        layout           => $self->layout,
    );
    # Do not add initial value for calculated fields that are aggregate and
    # defined as recalc. This means that the value will automatically
    # calculate from the other aggregate field values instead
    $params{init_value} = ref $value eq 'ARRAY' ? $value : defined $value ? [$value] : []
        unless ($self->is_group && $column->aggregate && $column->aggregate eq 'recalc')
            || ($self->is_draft && !$column->userinput); # Calc fields are not saved for a draft
    my $class = $self->is_group && !$column->numeric && !$self->group_cols->{$column->id}
        ? 'GADS::Datum::Count'
        : $column->class;
    $class->new(%params);
}

sub _transform_values
{   my $self = shift;

    my $original = $self->record or panic "Record data has not been set";

    my $fields = {}; my @cols;
    if ($self->is_group)
    {
        my %cols = map { $_->id => $_ } @{$self->columns_selected}, @{$self->columns_recalc_extra};
        $cols{$_->id} = $_ foreach @{$self->columns_retrieved_no};
        @cols = values %cols;
    }
    else {
        my %cols = map { $_->id => $_ } @{$self->columns_render};
        $cols{$_->id} = $_ foreach @{$self->columns_retrieved_no};
        @cols = values %cols;
    }
    foreach my $column (@cols)
    {
        next if $column->internal;
        my $key = $self->linked_id && $column->link_parent ? $column->link_parent->field : $column->field;
        # If this value was retrieved as part of a grouping, and if it's a sum,
        # then the field key will be appended with "_sum". XXX Ideally we'd
        # have a better way of knowing this has happened, but this should
        # suffice for the moment.
        if ($self->is_group)
        {
            if ($column->numeric)
            {
                $key = $key."_sum";
            }
            elsif (!$self->group_cols->{$column->id}) {
                $key = $key."_distinct";
            }
        }
        my $value = $self->linked_id && $column->link_parent ? $original->{$key} : $original->{$key};
        $fields->{$column->id} = $self->_create_datum($column, $value);
    }

    $self->_set_id_count($original->{id_count});

    my $column_id = $self->layout->column_id;
    $fields->{$column_id->id} = GADS::Datum::ID->new(
        record           => $self,
        record_id        => $self->record_id,
        current_id       => $self->current_id,
        column           => $column_id,
        schema           => $self->schema,
        layout           => $self->layout,
    );
    my $created = $self->layout->column_by_name_short('_version_datetime');
    $fields->{$created->id} = GADS::Datum::Date->new(
        record           => $self,
        record_id        => $self->record_id,
        current_id       => $self->current_id,
        column           => $created,
        schema           => $self->schema,
        layout           => $self->layout,
        init_value       => [ { value => $original->{created} } ],
    );

    my $version_user_col = $self->layout->column_by_name_short('_version_user');
    my $version_user_val = $original->{createdby} || $original->{$version_user_col->field};
    $fields->{$version_user_col->id} = $self->_person($version_user_val, $version_user_col);

    my $createdby_col = $self->layout->column_by_name_short('_created_user');
    my $created_val = $self->set_record_created_user;
    if (!$created_val) # Single record retrieval does not set this
    {
        my $created_val_id = $self->schema->resultset('Record')->search({
            current_id => $self->current_id,
        })->get_column('created')->min;
    }
    $fields->{$createdby_col->id} = $self->_person($created_val, $createdby_col);

    my $record_created_col = $self->layout->column_by_name_short('_created');
    my $record_created = $self->set_record_created;
    if (!$record_created) # Single record retrieval does not set this
    {
        $record_created = $self->schema->resultset('Record')->search({
            current_id => $self->current_id,
        })->get_column('created')->min;
    }
    $fields->{$record_created_col->id} = GADS::Datum::Date->new(
        record           => $self,
        record_id        => $self->record_id,
        current_id       => $self->current_id,
        column           => $record_created_col,
        schema           => $self->schema,
        layout           => $self->layout,
        init_value       => [ { value => $record_created } ],
    );

    my $serial_col = $self->layout->column_by_name_short('_serial');
    $fields->{$serial_col->id} = GADS::Datum::Serial->new(
        record           => $self,
        value            => $self->serial,
        record_id        => $self->record_id,
        current_id       => $self->current_id,
        column           => $serial_col,
        schema           => $self->schema,
        layout           => $self->layout,
    );
    $fields;
}

sub values_by_shortname
{   my ($self, %params) = @_;
    my @names = @{$params{names}};
    +{
        map {
            my $col = $self->layout->column_by_name_short($_)
                or error __x"Short name {name} does not exist", name => $_;
            my $linked = $self->linked_id && $col->link_parent;
            my $datum = $self->get_field_value($col)
                or panic __x"Value for column {name} missing. Possibly missing entry in layout_depend?", name => $col->name;
            my $d = $self->fields->{$col->id}->is_awaiting_approval # waiting approval, use old value
                ? $self->fields->{$col->id}->oldvalue
                : $linked && $self->fields->{$col->id}->oldvalue # linked, and linked value has been overwritten
                ? $self->fields->{$col->id}->oldvalue
                : $self->fields->{$col->id};
            # Retain and provide recurse-prevention information.
            $_ => $d->for_code(fields => $params{all_possible_names}, already_seen_code => $params{already_seen_code});
        } @names
    };
}

# Initialise empty record for new write. Optionally specify the instance ID
# that the record should be initiliased to (either this must be set or the
# layout property must contain a valid layout object)
sub initialise
{   my ($self, %options) = @_;
    my $instance_id = $options{instance_id};
    $self->_set_instance_id($instance_id)
        if $instance_id;
    my $fields = {};
    foreach my $column ($self->layout->all(include_internal => 1))
    {
        $self->initialise_field($fields, $column->id);
    }

    $self->columns_retrieved_do([ $self->layout->all(include_internal => 1) ]);
    $self->fields($fields);
}

sub initialise_field
{   my ($self, $fields, $id) = @_;
    my $layout = $self->layout;
    my $column = $layout->column($id);
    if ($self->linked_id && $column->link_parent)
    {
        $fields->{$id} = $self->linked_record->fields->{$column->link_parent->id};
    }
    else {
        my $f = $column->class->new(
            record           => $self,
            record_id        => $self->record_id,
            column           => $column,
            schema           => $self->schema,
            layout           => $self->layout,
            datetime_parser  => $self->schema->storage->datetime_parser,
        );
        # Unlike other fields this has a default value, so set it now.
        # XXX Probably need to do created_by field as well.
        $f->set_value(DateTime->now, is_parent_value => 1)
            if $column->name_short && $column->name_short eq '_created';
        $fields->{$id} = $f;
    }
}

sub approver_can_action_column
{   my ($self, $column) = @_;
    $self->approval_of_new && $column->user_can('approve_new')
      || !$self->approval_of_new && $column->user_can('approve_existing')
}

sub write_linked_id
{   my ($self, $linked_id) = @_;

    error __"You do not have permission to link records"
        unless $self->layout->user_can("link");

    my $guard = $self->schema->txn_scope_guard;
    # Blank existing values first, otherwise they will be read instead of
    # linked values under some circumstances
    if ($linked_id)
    {
        $self->fields->{$_->id}->set_value('')
            foreach $self->layout->all(linked => 1);
        # There is some mileage in sending alerts here, but given that the
        # values are probably about to be updated with a linked value, there
        # seems little point
        $self->write(no_alerts => 1);
    }
    my $current = $self->schema->resultset('Current')->find($self->current_id);
    $current->update({ linked_id => $linked_id });
    $self->linked_id($linked_id);
    $guard->commit;
}

sub columns_to_show_write
{   my $self = shift;
    $self->new_entry
        ? $self->layout->all(user_can_write_new => 1, userinput => 1)
        : $self->layout->all(user_can_write_existing => 1, userinput => 1)
}

sub delete_user_drafts
{   my $self = shift;
    if ($self->user && $self->user->has_draft($self->layout->instance_id))
    {
        while (1)
        {
            local $GADS::Schema::IGNORE_PERMISSIONS = 1;
            my $draft = GADS::Record->new(
                user   => undef,
                layout => $self->layout,
                schema => $self->schema,
            );
            $draft->find_draftuser_id($self->user->id, instance_id => $self->layout->instance_id)
                or last;
            # Find and delete any draft subrecords associated with this draft
            my @purge_curval = map { $draft->fields->{$_->id} } grep { $_->type eq 'curval' } $draft->layout->all;
            $draft->delete_current;
            $draft->purge_current;
            $_->purge_drafts foreach @purge_curval;
        }
        # Horribly hacky: reset reference to current self within the layout.
        # This is used by filtered value fields (e.g. curval) to retrieve
        # values from the record
        $self->layout->record($self);
    }
}

has submission_token => (
    is => 'lazy',
);

sub _build_submission_token
{   my $self = shift;
    for (1..10) # Prevent infinite loops - highly unlikely to be more than 10 clashes
    {
        my $token = Session::Token->new(length => 32)->get;
        try { # will bork on duplicate
            $self->schema->resultset('Submission')->create({
                created => DateTime->now,
                token   => $token,
            });
        };
        return $token unless $@;
    }
    return undef;
}

has _need_rec => (
    is        => 'rw',
    isa       => Bool,
    clearer   => 1,
    predicate => 1,
);

has _need_app => (
    is        => 'rw',
    isa       => Bool,
    clearer   => 1,
    predicate => 1,
);


has already_submitted_error => (
    is      => 'rwp',
    isa     => Bool,
    default => 0,
);

has selector_id => (
    is => 'lazy',
);

sub _build_selector_id
{   my $self = shift;
    # In theory could clash, but very unlikely, and it's also unlikely there
    # will be more than a few entries in total that can clash
    my $token = Session::Token->new(length => 32)->get;
    $self->is_draft ? "query_".$self->current_id : $self->new_entry ? "new_$token" : $self->current_id;
}

# options (mostly used by onboard):
# - update_only: update the values of the existing record instead of creating a
# new version. This allows updates that aren't recorded in the history, and
# allows the correcting of previous versions that have since been changed.
# - force_mandatory: allow blank mandatory values
# - no_change_unless_blank: bork on updates to existing values unless blank
# - dry_run: do not actually perform any writes, test only
# - no_alerts: do not send any alerts for changed values
# - version_datetime: write version date as this instead of now
# - version_userid: user ID for this version if override required
# - missing_not_fatal: whether missing mandatory values are not fatal (but still reported)
# - submitted_fields: an array ref of the fields to check on initial
#   submission. Fields not contained in here will not be checked for missing
#   values. Used in conjunction with missing_not_fatal to only report on some
#   fields
sub write
{   my ($self, %options) = @_;

    # Normally all write options are passed to further writes within
    # this call. Don't pass the submission token though, otherwise it
    # will bork as having already been used
    my $submission_token = delete $options{submission_token};

    # First check the submission token to see if this has already been
    # submitted. Do this as quickly as possible to prevent chance of 2 very
    # quick submissions, and do it before the guard so that the submitted token
    # is visible as quickly as possible
    if ($submission_token && !$options{dry_run})
    {
        my $sub = $self->schema->resultset('Submission')->search({
            token => $submission_token,
        })->next;
        if ($sub) # Should always be found, but who knows
        {
            # The submission table has a unique constraint on the token and
            # submitted fields. If we have already been submitted, then we
            # won't be able to write a new submitted version of this token, and
            # the record insert will therefore fail.
            try {
                $self->schema->resultset('Submission')->create({
                    token     => $sub->token,
                    created   => DateTime->now,
                    submitted => 1,
                });
            };
            # If the above borks, assume that the token has already been submitted
            if ($@)
            {
                $self->_set_already_submitted_error(1);
                error __"This form has already been submitted and is currently being processed";
            }
        }
    }

    # See whether this instance is set to not record history. If so, override
    # update_only option to ensure it is only an update
    $options{update_only} = 1 if $self->layout->forget_history;

    my $guard = $self->schema->txn_scope_guard;

    error __"Cannot save draft of existing record" if $options{draft} && !$self->new_entry;

    # Create a new overall record if it's new, otherwise
    # load the old values
    if ($self->new_entry)
    {
        error __"No permissions to add a new entry"
            unless $self->layout->user_can('write_new');
    }

    if ($self->parent_id)
    {
        # Check whether this is an attempt to create a child of
        # a child record
        error __"Cannot create a child record for an existing child record"
            if $self->schema->resultset('Current')->search({
                id        => $self->parent_id,
                parent_id => { '!=' => undef },
            })->count;
    }

    # Don't allow editing rewind record - would cause unexpected things with
    # things such as "changed" tests
    if ($self->rewind)
    {
        error __"Unable to edit record that has been retrieved with rewind";
    }

    my @cols = $options{submitted_fields}
        ? @{$options{submitted_fields}}
        : $self->layout->all(userinput => 1);

    # There may be a situation whereby a form has been loaded and fields that
    # contain values are hidden as a result of display dependencies (which may
    # have changed since the record was last edited). A user will expect hidden
    # values to be blank (and they certainly can't see them for review), as may
    # calculated fields. Therefore, manually set to empty any such hidden
    # values. The exception is if an import is being done and the user has
    # selected for values not to be changed unless blank. In this circumstance
    # unexpected behaviour can take place, whereby fields that a user hasn't
    # even imported are set to blank, which will then throw errors as a result
    # of the option.
    $self->set_blank_dependents(submission_token => $submission_token, columns => \@cols)
        unless $options{no_change_unless_blank};

    # First loop round: sanitise and see which if any have changed
    my %allow_update = map { $_ => 1 } @{$options{allow_update} || []};
    my ($need_app, $need_rec, $child_unique); # Whether a new approval_rs or record_rs needs to be created
    $need_rec = 1 if $self->changed;
    # Whether any topics cannot be written because of missing fields in
    # other topics
    my %no_write_topics;
    foreach my $column (@cols)
    {
        my $datum = $self->fields->{$column->id}
            or next; # Will not be set for child records

        # Check for blank value
        if (
            (!$self->parent_id || $column->can_child)
            && !$self->linked_id
            && !$column->optional
            && $datum->blank
            && !$options{force_mandatory}
            && !$options{draft}
            && $column->user_can('write')
        )
        {
            # Do not require value if the field has not been showed because of
            # display condition
            if (!$datum->dependent_not_shown(submission_token => $submission_token))
            {
                if (my $topic = $column->topic && $column->topic->prevent_edit_topic)
                {
                    # This setting means that we can write this missing
                    # value, but we will be unable to write another topic
                    # later
                    $no_write_topics{$topic->id} ||= {
                        topic   => $topic,
                        columns => [],
                    };
                    push @{$no_write_topics{$topic->id}->{columns}}, $column;
                }
                else {
                    # Only warn if it was previously blank and already shown,
                    # otherwise it might be a read-only field for this user. No
                    # need for submission_token (for stored filtered values) as
                    # these will have already been stored for the
                    # previously-written record.
                    if (!$self->new_entry && !$datum->changed && !$datum->oldvalue->dependent_not_shown_previous)
                    {
                        mistake __x"'{col}' is no longer optional, but was previously blank for this record.", col => $column->{name};
                    }
                    else {
                        my $msg = __x"'{col}' is not optional. Please enter a value.", col => $column->name;
                        error $msg
                            unless $options{missing_not_fatal};
                        report { is_fatal => 0 }, ERROR => $msg;
                    }
                }
            }
        }

        if ($self->doing_approval && $self->approval_of_new)
        {
            error __x"You do not have permission to approve new values of new records"
                if $datum->changed && !$column->user_can('approve_new');
        }
        elsif ($self->doing_approval)
        {
            error __x"You do not have permission to approve edits of existing records"
                if $datum->changed && !$column->user_can('approve_existing');
        }
        elsif ($self->new_entry)
        {
            error __x"You do not have permission to add data to field {name}", name => $column->name
                if !$datum->blank && !$column->user_can('write_new');
        }
        elsif ($datum->changed && !$column->user_can('write_existing'))
        {
            # If the user does not have write access to the field, but has
            # permission to create child records, then we want to allow them
            # to add a blank field to the child record. If they do, they
            # will land here, so we check for that and only error if they
            # have entered a value.
            if ($datum->blank && $self->parent_id)
            {
                # Force new record to write if this is the only change
                $need_rec = 1;
            }
            else {
                error __x"You do not have permission to edit field {name}", name => $column->name;
            }
        }

        #  Check for no change option, used by onboarding script
        if ($options{no_change_unless_blank} && !$self->new_entry && $datum->changed && !$datum->oldvalue->blank)
        {
            error __x"Attempt to change {name} from \"{old}\" to \"{new}\" but no changes are allowed to existing data",
                old => $datum->oldvalue->as_string, new => $datum->as_string, name => $column->name
                if !$allow_update{$column->id} && lc $datum->oldvalue->as_string ne lc $datum->as_string && $datum->oldvalue->as_string;
        }

        # Don't check for unique if this is a child record and it hasn't got a unique value.
        # If the value has been de-selected as unique, the datum will be changed, and it
        # may still have a value in it, although this won't be written.
        if ($column->isunique && !$datum->blank && ($self->new_entry || $datum->changed) && !($self->parent_id && !$column->can_child))
        {
            # Check for other columns with this value.
            foreach my $val (@{$datum->search_values_unique})
            {
                if (my $r = $self->find_unique($column, $val))
                {
                    # as_string() used as will be encoded on message display
                    error __x(qq(Field "{field}" must be unique but value "{value}" already exists in record {id}),
                        field => $column->name, value => $datum->as_string, id => $r->current_id)
                            if $self->new_entry || $self->current_id != $r->current_id;
                }
            }
        }

        # Set any values that should take their values from the parent record.
        # These are are set now so that any subsquent code values have their
        # dependent values already set.
        if ($self->parent_id && !$column->can_child && $column->userinput) # Calc values always unique
        {
            my $datum_parent = $self->parent->fields->{$column->id};
            $datum->set_value($datum_parent->set_values, is_parent_value => 1);
        }

        if ($self->doing_approval)
        {
            # See if the user has something that could be approved
            $need_rec = 1 if $self->approver_can_action_column($column);
        }
        elsif ($self->new_entry)
        {
            # New record. Approval needed?
            if ($column->user_can('write_new_no_approval') || $options{draft})
            {
                # User has permission to not need approval
                $need_rec = 1;
            }
            elsif ($column->user_can('write_new')) {
                # This needs an approval record
                trace __x"Approval needed because of no immediate write access to column {id}",
                    id => $column->id;
                $need_app = 1;
                $datum->is_awaiting_approval(1);
            }
        }
        elsif ($datum->changed)
        {
            # Update to record and the field has changed
            # Approval needed?
            if ($column->user_can('write_existing_no_approval'))
            {
                $need_rec = 1;
            }
            elsif ($column->user_can('write_existing')) {
                # This needs an approval record
                trace __x"Approval needed because of no immediate write access to column {id}",
                    id => $column->id;
                $need_app = 1;
                $datum->is_awaiting_approval(1);
            }
        }
        $child_unique = 1 if $column->can_child;
    }

    # If a new record, ensure that the time of the version exactly matches the
    # time of record creation. This is so that calculated fields can use this
    # comparison to see if the 2 are the same and therefore it is likely a new
    # record.
    my $created_date = $options{version_datetime}
        ? $options{version_datetime}
        : $self->new_entry
        ? $self->fields->{$self->layout->column_by_name_short('_created')->id}->values->[0]
        : DateTime->now;

    my $user_id = $self->user ? $self->user->id : undef;

    my $createdby = $options{version_userid} || $user_id;
    if (!$options{update_only} || $self->layout->forget_history)
    {
        # Keep original record values when only updating the record, except
        # when the update_only is happening for forgetting version history, in
        # which case we want to record these details
        my $created = $self->layout->column_by_name_short('_version_datetime');
        $self->fields->{$created->id}->set_value($created_date, is_parent_value => 1);
        my $versionby_col = $self->layout->column_by_name_short('_version_user');
        $self->fields->{$versionby_col->id}->set_value($createdby, no_validation => 1, is_parent_value => 1);
    }

    if ($self->new_entry)
    {
        my $createdby_col = $self->layout->column_by_name_short('_created_user');
        $self->fields->{$createdby_col->id}->set_value($createdby, no_validation => 1, is_parent_value => 1);
    }

    # Test duplicate unique calc values
    foreach my $column ($self->layout->all)
    {
        next if !$column->has_cache || !$column->isunique;
        my $datum = $self->fields->{$column->id};
        if (
            !$datum->blank # Not blank
            && ($self->new_entry || $datum->changed) # and changed or a new entry
            && (!$self->parent_id # either not a child
                || grep {$_->can_child} $column->param_columns # or is a calc value that may be different to parent
            )
        )
        {
            $datum->re_evaluate;
            # Check for other columns with this value.
            foreach my $val (@{$datum->search_values_unique})
            {
                if (my $r = $self->find_unique($column, $val))
                {
                    # as_string() used as will be encoded on message display
                    error __x(qq(Field "{field}" must be unique but value "{value}" already exists in record {id}),
                        field => $column->name, value => $datum->as_string, id => $r->current_id);
                }
            }
        }
    }

    # Check whether any values have been written to topics which cannot be
    # written to yet
    foreach my $topic (values %no_write_topics)
    {
        foreach my $col ($topic->{topic}->fields)
        {
            error __x"You cannot write to {col} until the following fields have been completed: {fields}",
                col => $col->name, fields => join ', ', map { $_->name } @{$topic->{columns}}
                    if !$self->fields->{$col->id}->blank;
        }
    }

    # Error if child record as no fields selected
    error __"There are no child fields defined to be able to create a child record"
        if $self->parent_id && !$child_unique && $self->new_entry;

    # Anything to update?
    if(   !($need_app || $need_rec || $options{update_only})
       || $options{dry_run} )
    {   $guard->commit;  # commit nothing, just finish guard
        return;
    }

    # New record?
    if ($self->new_entry)
    {
        $self->delete_user_drafts unless $options{no_draft_delete}; # Delete any drafts first, for both draft save and full save
        my $instance_id = $self->layout->instance_id;
        my $current = $self->schema->resultset('Current')->create({
            parent_id    => $self->parent_id,
            linked_id    => $self->linked_id,
            instance_id  => $instance_id,
            draftuser_id => $options{draft} && $user_id,
        });

        # Create unique serial. This should normally only take one attempt, but
        # if multiple records are being written concurrently, then the unique
        # constraint on the serial column will fail on a duplicate. In that
        # case, roll back to the save point and try again.
        while (1)
        {
            last if $options{draft};
            my $serial = $self->schema->resultset('Current')->search({
                instance_id => $instance_id,
            })->get_column('serial')->max;
            $serial++;

            my $svp = $self->schema->storage->svp_begin;
            try {
                $current->update({ serial => $serial });
            };
            if ($@) {
                $self->schema->storage->svp_rollback;
            }
            else {
                $self->schema->storage->svp_release;
                last;
            }
        }

        $self->current_id($current->id);
    }

    if ($need_rec && !$options{update_only})
    {
        my $id = $self->schema->resultset('Record')->create({
            current_id => $self->current_id,
            created    => $created_date,
            createdby  => $createdby,
        })->id;
        $self->record_id_old($self->record_id) if $self->record_id;
        $self->record_id($id);
    }
    elsif ($self->layout->forget_history)
    {
        $self->schema->resultset('Record')->find($self->record_id)->update({
            created   => $created_date,
            createdby => $createdby,
        });
    }

    my $column_id = $self->layout->column_id;
    $self->fields->{$column_id->id}->current_id($self->current_id);
    $self->fields->{$column_id->id}->clear_value; # Will rebuild as current_id

    if ($need_app)
    {
        my $id = $self->schema->resultset('Record')->create({
            current_id => $self->current_id,
            created    => DateTime->now,
            record_id  => $self->record_id,
            approval   => 1,
            createdby  => $user_id,
        })->id;
        $self->approval_id($id);
    }

    if ($self->new_entry && $user_id && !$options{draft})
    {
        # New entry, so save record ID to user for retrieval of previous
        # values if needed for another new entry. Use the approval ID id
        # it exists, otherwise the record ID.
        my $id = $self->approval_id || $self->record_id;
        my $this_last = {
            user_id     => $user_id,
            instance_id => $self->layout->instance_id,
        };
        my ($last) = $self->schema->resultset('UserLastrecord')->search($this_last)->all;
        if ($last)
        {
            $last->update({ record_id => $id });
        }
        else {
            $this_last->{record_id} = $id;
            $self->schema->resultset('UserLastrecord')->create($this_last);
        }
    }

    $self->_need_rec($need_rec);
    $self->_need_app($need_app);
    $self->write_values(%options, submission_token => $submission_token) unless $options{no_write_values};

    # Finally delete any related cached filter values, meaning that any later
    # attempts to delete the referenced current IDs will not throw a database
    # relation error
    if ($submission_token)
    {
        my $s = $self->schema->resultset('Submission')->search({
            token => $submission_token
        });
        my $iid = $s->next->id;
        $self->schema->resultset('FilteredValue')->search({
            submission_id => $iid,
        })->delete;
    }

    $guard->commit;

    # Only now send notification emails, as we could have rolled back before
    # the commit
    if (!$self->is_draft)
    {
        $self->fields->{$_->id}->send_notify
            foreach $self->layout->all_people_notify;
    }
}

sub write_values
{   my ($self, %options) = @_;

    # Should never happen if this is called straight after write()
    $self->_has_need_app && $self->_has_need_rec
        or panic "Called out of order - need_app and need_rec not set";

    my $guard = $self->schema->txn_scope_guard;

    # Write all the values
    my @columns_changed;
    my @columns_cached;
    my %update_autocurs;
    foreach my $column ($self->layout->all(order_dependencies => 1))
    {
        # Prevent warnings when writing incomplete calc values on draft
        next if $options{draft} && !$column->userinput;

        my $datum = $self->get_field_value($column); #$self->fields->{$column->id};
        next if $self->linked_id && $column->link_parent; # Don't write all values if this is a linked record

        if ($column->internal)
        {
            push @columns_changed, $column if $datum->changed;
            next; # No need to go on and write
        }

        if ($self->_need_rec || $options{update_only}) # For new records, $need_rec is only set if user has create permissions without approval
        {
            my $v;
            # Need to write all values regardless. This will either be the
            # updated and approved value, if updated before arriving here,
            # or the existing value otherwise
            if ($self->doing_approval)
            {
                # Write value regardless (either new approved or existing)
                $self->_field_write($column, $datum);
                # Leave records where they are unless this user can
                # action the approval
                next unless $self->approver_can_action_column($column);
                # And delete value in approval record
                $self->schema->resultset($column->table)->search({
                    record_id => $self->approval_id,
                    layout_id => $column->id,
                })->delete;
            }
            else {
                if (
                    ($self->new_entry && $column->user_can('write_new_no_approval'))
                    || (!$self->new_entry && $column->user_can('write_existing_no_approval'))
                    || (!$column->userinput)
                )
                {
                    # Write new value
                    $self->_field_write($column, $datum, %options);
                    push @columns_changed, $column if $datum->changed;
                }
                elsif ($self->new_entry) {
                    # Write value. It's a new entry and the user doesn't have
                    # write access to this field. This will write a blank
                    # value.
                    $self->_field_write($column, $datum) if !$column->userinput;
                }
                elsif ($column->user_can('write'))
                {
                    # Approval required, write original value
                    panic "update_only set but attempt to hold write for approval"
                        if $options{update_only}; # Shouldn't happen, makes no sense
                    $self->_field_write($column, $datum, old => 1);
                }
                else {
                    # Value won't have changed. Write current value (old
                    # value will not be set if it hasn't been updated)
                    # Write old value
                    $self->_field_write($column, $datum, %options);
                }
            }
        }
        if ($self->_need_app)
        {
            # Only need to write values that need approval
            next unless $datum->is_awaiting_approval;
            $self->_field_write($column, $datum, approval => 1)
                if ($self->new_entry && !$datum->blank)
                    || (!$self->new_entry && $datum->changed);
        }

    }

    # Note any records that will need updating that have an autocur field that refers to this
    # No need to do this for child records which have a "copied"
    # values, as they will otherwise be done twice
    foreach my $column (grep $_->type eq 'curval', $self->layout->all)
    {
        if (!$self->parent_id || $column->can_child)
        {
            foreach my $autocur (@{$column->autocurs})
            {
                # Do nothing with deleted records
                my $datum = $self->fields->{$column->id};
                my %deleted = map { $_ => 1 } @{$datum->ids_deleted};

                # Work out which ones have changed. We only want to
                # re-evaluate records that have actually changed, for both
                # performance reasons and to send the correct alerts
                #
                # First, establish which current IDs might be affected
                my %affected = map { $_ => 1 } grep { !$deleted{$_} } @{$datum->ids_affected};

                # Then see if any fields depend on this autocur (e.g. code fields)
                foreach my $layout_depend ($autocur->layouts_depend_depends_on->all)
                {
                    # To reduce unnecessary updates, only count ones which may have an effect...
                    my $depends_on = $layout_depend->depend_on;
                    my $code = $self->layout->column($layout_depend->layout_id)->code;
                    # ... don't include ones from a completely different table
                    next unless $depends_on->related_field->instance_id == $self->layout->instance_id;
                    # ... don't include unless they have a short name that is in the calculated field
                    next unless grep $code =~ /\Q$_\E(?![_a-z0-9])/i, map $_->name_short,
                        grep $_->name_short, @columns_changed;

                    # If they do, we will need to re-evaluate them all
                    $update_autocurs{$_} ||= []
                        foreach keys %affected;
                }

                # If the value hasn't changed at all, skip on
                next unless $datum->changed;

                # If it has changed, work out which one have been added or
                # removed. Annotate these with the autocur ID, so we can
                # mark that as changed with this value
                foreach my $cid (@{$datum->ids_changed})
                {
                    next if $deleted{$cid};
                    $update_autocurs{$cid} ||= [];
                    push @{$update_autocurs{$cid}}, $autocur->id;
                }
            }
        }
    }

    # If this is an approval, see if there is anything left to approve
    # in this record. If not, delete the stub record.
    if ($self->doing_approval)
    {
        my $remaining = $self->schema->resultset('String')->search({ record_id => $self->approval_id })->count
          || $self->schema->resultset('Intgr')->search({ record_id => $self->approval_id })->count
          || $self->schema->resultset('Person')->search({ record_id => $self->approval_id })->count
          || $self->schema->resultset('Date')->search({ record_id => $self->approval_id })->count
          || $self->schema->resultset('Daterange')->search({ record_id => $self->approval_id })->count
          || $self->schema->resultset('File')->search({ record_id => $self->approval_id })->count
          || $self->schema->resultset('Enum')->search({ record_id => $self->approval_id })->count;
        if (!$remaining)
        {
            # Nothing left for this approval record. Is there a last_record flag?
            # If so, change that to the main record's flag instead.
            my ($lr) = $self->schema->resultset('UserLastrecord')->search({
                record_id => $self->approval_id,
            })->all;
            $lr->update({ record_id => $self->record_id }) if $lr;

            # Delete approval stub
            $self->schema->resultset('Record')->find($self->approval_id)->delete;
        }
    }

    # Do we need to update any child records that rely on the
    # values of this parent record?
    if (!$options{draft})
    {
        foreach my $child_id (@{$self->child_record_ids})
        {
            my $child = GADS::Record->new(
                user   => $self->user,
                layout => $self->layout,
                schema => $self->schema,
            );
            $child->find_current_id($child_id);
            foreach my $col ($self->layout->all(order_dependencies => 1, exclude_internal => 1))
            {
                my $datum_child = $child->fields->{$col->id};
                if ($col->userinput)
                {
                    my $datum_parent = $self->fields->{$col->id};
                    $datum_child->set_value($datum_parent->set_values, is_parent_value => 1)
                        unless $col->can_child;
                }
                # Calc/rag values will be evaluated during write()
            }
            $child->write(%options, update_only => 1, submission_token => undef);
        }

        # Update any records with an autocur field that are referred to by this.
        # Get list of current IDs we need to update:
        my @update;
        foreach my $cid (keys %update_autocurs)
        {
            # Check whether this record is one that we're going to write
            # anyway. If so, skip.
            next if grep { $_->current_id == $cid } @{$self->_records_to_write_after};
            push @update, $cid;
        }
        # Group by tables so we can process together
        my %update;
        foreach my $c ($self->schema->resultset('Current')->search({ id => \@update }))
        {
            $update{$c->instance_id} ||= [];
            push @{$update{$c->instance_id}}, $c->id;
        }
        foreach my $instance_id (keys %update)
        {
            # User may not have access by this point due to limited views on
            # the curval field, which would result in record not being found to
            # update. Given that we are simply recalculating calc fields user
            # is not required anyway, so use undef.
            local $GADS::Schema::IGNORE_PERMISSIONS = 1;
            my $layout = $self->layout->clone(instance_id => $instance_id);
            my $records = GADS::Records->new(
                schema            => $self->schema,
                user              => undef,
                layout            => $layout,
                limit_current_ids => $update{$instance_id},
            );
            # For each record, flag the autocur as changed (this parent record)
            # and re-evalute calcs
            while (my $record = $records->single)
            {
                $record->fields->{$_}->changed(1)
                    foreach @{$update_autocurs{$record->current_id}};
                $record->write(%options, update_only => 1, re_evaluate => 1, submission_token => undef);
            }
        }
    }

    $_->write_values(%options)
        foreach @{$self->_records_to_write_after};
    $self->_clear_records_to_write_after;

    # Alerts can cause SQL errors, due to the unique constraints
    # on the alert cache columns. Therefore, commit what we've
    # done so far, and don't do alerts in a transaction
    $guard->commit;

    # Send any alerts
    if (!$options{no_alerts} && !$options{draft})
    {
        # Possibly not the best way to do alerts, but certainly the
        # simplest. Spin up a new alert sender for each changed record
        my $alert_send = GADS::AlertSend->new(
            layout      => $self->layout,
            schema      => $self->schema,
            user        => $self->user,
            current_ids => [$self->current_id],
            columns     => [map $_->id, @columns_changed],
            current_new => $self->new_entry,
        );

        if ($ENV{GADS_NO_FORK})
        {
            $alert_send->process;
            return;
        }
        if (my $kid = fork)
        {
            # will fire off a worker and then abandon it, thus making reaping
            # the long running process (the grndkid) init's (pid1) problem
            waitpid($kid, 0); # wait for child to start grandchild and clean up
        }
        else {
            if (my $grandkid = fork) {
                POSIX::_exit(0); # the child dies here
            }
            else {
                # We should already be in a try() block, probably with
                # hidden messages. These messages will never be written, as
                # we exit the process.  Therefore, stop the hiding of
                # messages for this part of the code.
                my $parent_try = dispatcher 'active-try'; # Boolean false
                $parent_try->hide('NONE');

                # We must catch exceptions here, otherwise we will never
                # reap the process. Set up a guard to be doubly-sure this
                # happens.
                my $guard = guard { POSIX::_exit(0) };
                # Despite the guard, we still operate in a try block, so as to catch
                # the messages from any exceptions and report them accordingly.
                # Only collect messages at warning or higher, otherwise
                # thousands of trace messages are stored which use lots of
                # memory.
                try { $alert_send->process } hide => 'ALL', accept => 'WARNING-'; # This takes a long time
                $@->reportAll(is_fatal => 0);
            }
        }
    }
    $self->clear_new_entry; # written to database, no longer new
    $self->_clear_need_rec;
    $self->_clear_need_app;
}

sub set_blank_dependents
{   my ($self, %options) = @_;

    foreach my $column (@{$options{columns}})
    {
        # Don't attempt any blanking if the user is editing an existing record
        # and they do not have access to the field
        next if !$self->new_entry && !$column->user_can('write_existing');
        my $datum = $self->get_field_value($column);
        $datum->set_value('')
            if $datum->dependent_not_shown(submission_token => $options{submission_token})
                && ($datum->column->can_child || !$self->parent_id);
    }
}

# A list of any records to write at the end of writing this one. This is used
# when writing subrecords - the full record may not be able to be written at
# the time of write as it may refer to this one
has _records_to_write_after => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { [] },
    clearer => 1,
);

sub _field_write
{   my ($self, $column, $datum, %options) = @_;

    return if $column->no_value_to_write;

    if ($column->userinput)
    {
        my $datum_write = $options{old} ? $datum->oldvalue : $datum;
        my $table = $column->table;
        my $entry = {
            child_unique => $datum ? $column->can_child : 0, # No datum for new invisible fields
            layout_id    => $column->id,
        };
        $entry->{record_id} = $options{approval} ? $self->approval_id : $self->record_id;
        my @entries;
        if ($datum_write) # Possible that we're writing a blank value
        {
            if ($column->type eq "daterange")
            {
                if (!@{$datum_write->values})
                {
                    $entry->{from}  = undef;
                    $entry->{to}    = undef;
                    $entry->{value} = undef,
                    push @entries, $entry; # No values, but still need to write null value
                }
                my @texts = @{$datum_write->text_all};
                foreach my $range (@{$datum_write->values})
                {
                    my %entry = %$entry; # Copy to stop referenced values being overwritten
                    $entry{from}  = $range->start;
                    $entry{to}    = $range->end;
                    $entry{value} = shift @texts;
                    push @entries, \%entry;
                }
            }
            elsif ($column->type =~ /(file|enum|tree|person|curval|filval)/)
            {
                if ($column->type eq 'curval' && $column->show_add)
                {
                    foreach my $record (@{$datum_write->values_as_query_records})
                    {
                        my $created_col = $self->layout->column_by_name_short('_version_datetime');
                        my $created = $self->fields->{$created_col->id}->values->[0];
                        $record->write(%options,
                            no_draft_delete  => 1,
                            no_write_values  => 1,
                            submission_token => undef,
                            # Ensure version times match between parent and
                            # child records. This is used in chronology view to
                            # ensure the correct versions at the time of record
                            # edit are used
                            version_datetime => $created, 
                        );
                        push @{$self->_records_to_write_after}, $record
                            if $record->is_edited;
                        my $id = $record->current_id;
                        my %entry = %$entry; # Copy to stop referenced id being overwritten
                        $entry{value} = $id;
                        push @entries, \%entry;
                    }
                }
                my @ids = @{$datum_write->ids};
                # Were any values not visible by the user writing?
                if ($column->type eq 'curval' && !$self->new_entry && $datum_write->column->multivalue)
                {
                    # If the user hasn't edited this field, we still need to
                    # check whether there are other records they didn't have
                    # access to. If the value hasn't changed, then we also need
                    # to get any IDs from query records, in case the user has
                    # written back the same value using the form
                    my @old_ids = $datum_write->changed
                        ? @{$datum_write->oldvalue->ids}
                        : (@{$datum_write->ids}, map $_->current_id, @{$datum_write->values_as_query_records});
                    my $search = {
                        layout_id => $column->id,
                        record_id => $self->record_id_old,
                    };
                    $search->{value} = { '!=' => [ -and => @old_ids, @ids ] }
                        if @old_ids;
                    push @ids, $self->schema->resultset('Curval')->search($search)->get_column('value')->all;
                }
                foreach my $id (@ids)
                {
                    my %entry = %$entry; # Copy to stop referenced id being overwritten
                    $entry{value} = $id;
                    push @entries, \%entry;
                }
                if ($column->type eq 'curval' && $column->delete_not_used)
                {
                    my @ids_deleted;
                    foreach my $id_deleted (@{$datum->ids_removed})
                    {
                        my $is_used;
                        foreach my $refers (@{$column->layout_parent->referred_by})
                        {
                            my $refers_layout = GADS::Layout->new(
                                user        => $self->layout->user,
                                schema      => $self->schema,
                                config      => GADS::Config->instance,
                                instance_id => $refers->instance_id,
                            );
                            my $rules = GADS::Filter->new(
                                as_hash => {
                                    rules     => [{
                                        id       => $refers->id,
                                        type     => 'string',
                                        value    => $id_deleted,
                                        operator => 'equal',
                                    }],
                                },
                            );
                            my $view = GADS::View->new( # Do not write to database!
                                name        => 'Temp',
                                filter      => $rules,
                                instance_id => $refers->instance_id,
                                layout      => $refers_layout,
                                schema      => $self->schema,
                                user        => undef,
                            );
                            local $GADS::Schema::IGNORE_PERMISSIONS = 1;
                            my $refers_records = GADS::Records->new(
                                user    => undef,
                                view    => $view,
                                columns => [],
                                layout  => $refers_layout,
                                schema  => $self->schema,
                            );
                            $is_used = $refers_records->count;
                            last if $is_used;
                        }
                        if (!$is_used)
                        {
                            # We should only be here if the user did have
                            # access to the relevant record, otherwise it would
                            # not be in the old IDs of the field. However, the
                            # user may no longer have access to it due to
                            # changes in other values they have made (including
                            # the deletion of it itself). Therefore, do not
                            # require user to delete the record.
                            my $record = GADS::Record->new(
                                user     => undef,
                                layout   => $column->layout_parent,
                                schema   => $self->schema,
                            );
                            $record->find_current_id($id_deleted);
                            $record->delete_current(override => 1, deletedby => $self->user->id);
                            push @ids_deleted, $id_deleted;
                        }
                    }
                    $datum->ids_deleted(\@ids_deleted);
                }
                if (!@entries)
                {
                    $entry->{value} = undef;
                    push @entries, $entry; # No values, but still need to write null value
                }
            }
            elsif ($column->type eq 'string')
            {
                if (!@{$datum_write->values})
                {
                    $entry->{value} = undef,
                    $entry->{value_index} = undef,
                    push @entries, $entry; # No values, but still need to write null value
                }
                foreach my $value (@{$datum_write->values})
                {
                    my %entry = %$entry; # Copy to stop referenced values being overwritten
                    $entry{value} = $value;
                    $entry{value_index} = lc substr $value, 0, 128
                        if defined $value;
                    push @entries, \%entry;
                }

            }
            elsif ($column->type eq 'date')
            {
                if (!@{$datum_write->values})
                {
                    $entry->{value} = undef,
                    push @entries, $entry; # No values, but still need to write null value
                }
                foreach my $value (@{$datum_write->values})
                {
                    my %entry = %$entry; # Copy to stop referenced values being overwritten
                    $entry{value} = $value;
                    push @entries, \%entry;
                }

            }
            else {
                $entry->{value} = $datum_write->value;
                push @entries, $entry;
            }
        }

        my $create;
        if ($options{update_only})
        {
            # Would be better to use find() here, but not all tables currently
            # have unique constraints. Also, we might want to add multiple values
            # for each field in the future
            my @rows = $self->schema->resultset($table)->search({
                record_id => $entry->{record_id},
                layout_id => $entry->{layout_id},
            })->all;
            foreach my $row (@rows)
            {
                if (my $entry = pop @entries)
                {
                    $row->update($entry);
                }
                else {
                    $row->delete; # Now less values than before
                }
            }
        }
        # For update_only, there might still be some @entries to be written
        $self->schema->resultset($table)->create($_)
            foreach @entries;
    }
    else {
        $datum->record_id($self->record_id);
        $datum->re_evaluate(submission_token => $options{submission_token}, new_entry => $self->new_entry);
        if ($column->return_type eq 'error')
        {
            error $datum->as_string if $datum->as_string;
        }
        $datum->write_value(submission_token => $options{submission_token});
    }
}

sub user_can_delete
{   my $self = shift;
    return 0 unless $self->current_id;
    return $self->layout->user_can("delete");
}

sub user_can_purge
{   my $self = shift;
    return 0 unless $self->current_id;
    return $self->layout->user_can("purge");
}

# Mark this entire record and versions as deleted
sub delete_current
{   my ($self, %options) = @_;

    error __"You do not have permission to delete records"
        if !$options{override} && $self->user && !$self->user_can_delete;

    my $current = $self->schema->resultset('Current')->search({
        id          => $self->current_id,
        instance_id => $self->layout->instance_id,
    })->next
        or error "Unable to find current record to delete";

    $current->update({
        deleted   => DateTime->now,
        deletedby => $options{deletedby} || ($self->user && $self->user->id),
    });
}

# Delete this this version completely from database
sub purge
{   my $self = shift;
    error __"You do not have permission to purge records"
        unless !$self->user || $self->user_can_purge;
    $self->_purge_record_values($self->record_id);
    $self->schema->resultset('Record')->find($self->record_id)->delete;
}

sub restore
{   my $self = shift;
    error __"You do not have permission to restore records"
        unless !$self->user || $self->user_can_purge;
    $self->schema->resultset('Current')->find($self->current_id)->update({
        deleted => undef,
    });
}

sub as_json
{   my ($self, $view) = @_;
    my $return;
    my @col_ids = $view ? @{$view->columns} : (map $_->id, $self->layout->all_user_read);
    foreach my $col_id (@col_ids)
    {
        my $col = $self->layout->column($col_id);
        my $short = $col->name_short or next;
        $return->{$short} = $self->fields->{$col->id}->as_string;
    }
    encode_json $return;
}

sub as_query
{   my ($self, %options) = @_;
    my @queries;
    foreach my $col ($self->layout->all(userinput => 1, user_can_read => 1))
    {
        next if $options{exclude_curcommon} && $col->is_curcommon;
        my $datum = $self->get_field_value($col);
        panic __x"Field {id} is missing from record", id => $col->id
            if !$datum;
        push @queries, $col->field."=".uri_escape_utf8($_)
            foreach @{$datum->html_form};
    }
    return join '&', @queries;
}

sub get_field_value
{   my ($self, $column) = @_;
    return $self->fields->{$column->id}
        if $self->fields->{$column->id};

    my $record_id = $self->record_id_old || $self->record_id;

    my $raw;
    if ($column->type eq 'autocur')
    {
        my $already_seen = Tree::DAG_Node->new({name => 'root'});
        $raw = [$column->fetch_multivalues([$record_id], already_seen => $already_seen)];
        # Ensure no memory leaks - tree needs to be destroyed
        $already_seen->delete_tree;
    }
    else {
        my $result = $self->schema->resultset($column->table)->search({
            record_id => $record_id,
            layout_id => $column->id,
        });
        $result->result_class('DBIx::Class::ResultClass::HashRefInflator');
        $raw = [$result->all];
    }
    my $datum = $self->_create_datum($column, $raw);
    # Cache in record
    $self->fields->{$column->id} = $datum;
}

sub for_code
{   my ($self, %params) = @_;
    my $return;
    foreach my $col (@{$params{columns}})
    {
        my $datum = $self->get_field_value($col);
        $return->{$col->name_short} = $datum->for_code(fields => $params{fields}, already_seen_code => $params{already_seen_code});
    }
    $return;
}

sub pdf
{   my $self = shift;

    my $dateformat = GADS::Config->instance->dateformat;
    my $now = DateTime->now;
    $now->set_time_zone('Europe/London');
    my $now_formatted = $now->format_cldr($dateformat)." at ".$now->hms;
    my $updated = $self->created->format_cldr($dateformat)." at ".$self->created->hms;

    my $config = GADS::Config->instance;
    my $header = $config && $config->gads && $config->gads->{header};
    my $pdf = CtrlO::PDF->new(
        header => $header,
        footer => "Downloaded by ".$self->user->value." on $now_formatted",
    );

    $pdf->add_page;
    $pdf->heading('Record '.$self->current_id);
    $pdf->heading('Last updated by '.$self->createdby->as_string." on $updated", size => 12);

    my $data =[
        ['Field', 'Value'],
    ];
    my $max_fields;
    foreach my $col ($self->layout->all_user_read)
    {
        my $datum = $self->fields->{$col->id};
        next if $datum->dependent_not_shown;
        if ($col->is_curcommon)
        {
            my $first = 1;
            foreach my $line (@{$datum->values})
            {
                my $field_count;
                my @l = ($first ? $col->name : '');
                foreach my $v (@{$line->{values}})
                {
                    push @l, $v;
                    $field_count++;
                }
                push @$data, \@l;
                $first = 0;
                $max_fields = $field_count if !$max_fields || $max_fields < $field_count;
            }
        }
        else {
            push @$data, [
                $col->name,
                $datum->as_string,
            ],
        }
    }

    my $hdr_props = {
        repeat     => 1,
        justify    => 'center',
        font_size  => 8,
    };

    my $cell_props = [];
    foreach my $d (@$data)
    {
        my $has = @$d;
        # $max_fields does not include field name
        my $gap = $max_fields - $has + 1;
        push @$d, undef for (1..$gap);
        push @$cell_props, [
            (undef) x ($has - 1),
            {colspan => $gap + 1}
        ];
    }

    $pdf->table(
        data       => $data,
        cell_props => $cell_props,
    );

    $pdf;
}

# Delete the record entirely from the database, plus its parent current (entire
# row) along with all related records
sub purge_current
{   my $self = shift;

    error __"You do not have permission to purge records"
        unless !$self->user || $self->user_can_purge;

    my $id = $self->current_id
        or panic __"No current_id specified for purge";

    my $crs = $self->schema->resultset('Current')->search({
        id => $id,
        instance_id => $self->layout->instance_id,
    })->next
        or error __x"Invalid ID {id}", id => $id;

    $crs->deleted
        or error __"Cannot purge record that is not already deleted";

    if (my @recs = $self->schema->resultset('Current')->search({
        'curvals.value' => $id,
    },{
        prefetch => {
            records => 'curvals',
        },
    })->all)
    {
        my $recs = join ', ', map {
            my %fields;
            foreach ($_->records) {
                foreach ($_->curvals) {
                    $fields{$_->layout->name} = 1;
                }
            }
            my $names = join ', ', keys %fields;
            $_->id." ($names)";
        } @recs;
        error __x"The following records refer to this record as a value (possibly in a historical version): {records}",
            records => $recs;
    }

    $self->schema->resultset('FilteredValue')->search({
        current_id => $id,
    })->delete;

    my @records = $self->schema->resultset('Record')->search({
        current_id => $id
    })->all;

    # Get creation details for logging at end
    my $createdby = $self->createdby;
    my $created   = $self->created;

    # Start transaction.
    # $@ may be the result of a previous Log::Report::Dispatcher::Try block (as
    # an object) and may evaluate to an empty string. If so, txn_scope_guard
    # warns as such, so undefine to prevent the warning
    undef $@;
    my $guard = $self->schema->txn_scope_guard;

    # Delete child records first
    foreach my $child (@{$self->child_record_ids})
    {
        my $record = GADS::Record->new(
            user   => $self->user,
            layout => $self->layout,
            schema => $self->schema,
        );
        $record->find_current_id($child);
        $record->purge_current;
    }

    foreach my $record (@records)
    {
        $self->_purge_record_values($record->id);
    }
    $self->schema->resultset('Record') ->search({ current_id => $id })->update({ record_id => undef });
    $self->schema->resultset('AlertCache')->search({ current_id => $id })->delete;
    $self->schema->resultset('Record')->search({ current_id => $id })->delete;
    $self->schema->resultset('AlertSend')->search({ current_id => $id })->delete;
    $self->schema->resultset('Current')->find($id)->delete;
    $guard->commit;

    my $user_id = $self->user && $self->user->id;
    info __x"Record ID {id} purged by user ID {user} (originally created by user ID {createdby} at {created}",
        id => $id, user => $user_id, createdby => $createdby->id, created => $created;
}

sub _purge_record_values
{   my ($self, $rid) = @_;
    $self->schema->resultset('Ragval')   ->search({ record_id  => $rid })->delete;
    $self->schema->resultset('Calcval')  ->search({ record_id  => $rid })->delete;
    $self->schema->resultset('Enum')     ->search({ record_id  => $rid })->delete;
    $self->schema->resultset('String')   ->search({ record_id  => $rid })->delete;
    $self->schema->resultset('Intgr')    ->search({ record_id  => $rid })->delete;
    $self->schema->resultset('Daterange')->search({ record_id  => $rid })->delete;
    $self->schema->resultset('Date')     ->search({ record_id  => $rid })->delete;
    $self->schema->resultset('Person')   ->search({ record_id  => $rid })->delete;
    $self->schema->resultset('File')     ->search({ record_id  => $rid })->delete;
    $self->schema->resultset('Curval')   ->search({ record_id  => $rid })->delete;
    # Remove record from any user lastrecord references
    $self->schema->resultset('UserLastrecord')->search({
        record_id => $rid,
    })->delete;
}

1;

