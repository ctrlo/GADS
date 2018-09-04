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

use CtrlO::PDF;
use DateTime;
use DateTime::Format::Strptime qw( );
use DBIx::Class::ResultClass::HashRefInflator;
use GADS::AlertSend;
use GADS::Config;
use GADS::Datum::Autocur;
use GADS::Datum::Calc;
use GADS::Datum::Curval;
use GADS::Datum::Date;
use GADS::Datum::Daterange;
use GADS::Datum::Enum;
use GADS::Datum::File;
use GADS::Datum::ID;
use GADS::Datum::Integer;
use GADS::Datum::Person;
use GADS::Datum::Rag;
use GADS::Datum::Serial;
use GADS::Datum::String;
use GADS::Datum::Tree;
use Log::Report 'linkspace';
use JSON qw(encode_json);
use POSIX ();
use Scope::Guard qw(guard);

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;
use namespace::clean;

with 'GADS::Role::Presentation::Record';

# Preferably this is passed in to prevent extra
# DB reads, but loads it if it isn't
has layout => (
    is       => 'rw',
    required => 1,
    trigger  => sub {
        # Pass in record to layout, used for filtered curvals
        my ($self, $layout) = @_;
        $layout->record($self);
    },
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
    is => 'rw',
);

# Subroutine to create a slightly more advanced predication for "record" above
sub has_record
{   my $self = shift;
    my $rec = $self->record or return;
    %$rec and return 1;
}

# The raw parent linked record from the database, if applicable
has linked_record_raw => (
    is      => 'rw',
);

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

has record_created => (
    is => 'lazy',
);

sub _build_record_created
{   my $self = shift;
    $self->schema->resultset('Record')->search({
        current_id => $self->current_id,
    })->get_column('created')->min;
}

# Should be set true if we are processing an approval
has doing_approval => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has base_url => (
    is  => 'rw',
);

# Array ref with column IDs
has columns => (
    is      => 'rw',
);

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

# Record-specific flags for columns that should be stored with this record
has column_flags => (
    is      => 'ro',
    default => sub { +{} },
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
        my @children = $self->schema->resultset('Current')->search({
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
        if (!$self->record)
        {
            my $user_id = $self->schema->resultset('Record')->find(
                $self->record_id
            )->createdby->id;
            return $self->_person({ id => $user_id }, $self->layout->column(-13));
        }
        $self->fields->{-13};
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
        if (!$self->record)
        {
            $self->record_id or return;
            my $user = $self->schema->resultset('Record')->find(
                $self->record_id
            )->deletedby or return undef;
            return $self->_person({ id => $user->id }, $self->layout->column(-14));
        }
        my $value = $self->set_deletedby or return undef;
        return $self->_person($value, $self->layout->column(-14));
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
    if (!$self->record)
    {
        return $self->schema->resultset('Record')->find($self->record_id)->created;
    }
    $self->schema->storage->datetime_parser->parse_datetime(
        $self->record->{created}
    );
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

    my ($record) = $self->schema->resultset('Record')->search({
        id       => $record_id,
    })->all;
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
}

sub _check_instance
{   my ($self, $instance_id_new) = @_;
    if ($self->layout->instance_id != $instance_id_new)
    {
        # Check it's valid for this site first
        $self->schema->resultset('Instance')->find($instance_id_new)
            or return;
        my $layout = GADS::Layout->new(
            user        => $self->user,
            schema      => $self->schema,
            config      => GADS::Config->instance,
            instance_id => $instance_id_new,
        );
        $self->layout($layout);
    }
}

sub find_record_id
{   my ($self, $record_id, %options) = @_;
    my $search_instance_id = $options{instance_id};
    my $record = $self->schema->resultset('Record')->find($record_id)
        or error __x"Record version ID {id} not found", id => $record_id;
    my $instance_id = $record->current->instance_id;
    error __x"Record ID {id} invalid for table {table}", id => $record_id, table => $search_instance_id
        if $search_instance_id && $search_instance_id != $instance_id;
    $self->_check_instance($instance_id);
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
    $self->_check_instance($instance_id);
    $self->_find(current_id => $current_id, %options);
}

sub find_draftuser_id
{   my ($self, $draftuser_id, %options) = @_;
    $draftuser_id =~ /^[0-9]+$/
        or error __x"Invalid draft user ID {id}", id => $draftuser_id;
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
        if $column->id == -11;

    return $self->find_serial_id($value)
        if $column->id == -16;

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
    my $records = GADS::Records->new(
        user    => undef, # Do not want to limit by user
        rows    => 1,
        view    => $view,
        layout  => $self->layout,
        schema  => $self->schema,
        columns => \@retrieve_columns,
    );

    # Might be more, but one will do
    return pop @{$records->results};
}

sub clear
{   my $self = shift;
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
    $self->clear_is_historic;
    $self->clear_new_entry;
}

sub _find
{   my ($self, %find) = @_;

    # First clear applicable properties
    $self->clear;

    # If deleted, make sure user has access to purged records
    error __"You do not have access to this deleted record"
        if $find{deleted} && !$self->layout->user_can("purge");

    my $records = GADS::Records->new(
        user                => $self->user,
        layout              => $self->layout,
        schema              => $self->schema,
        columns             => $self->columns,
        rewind              => $self->rewind,
        is_deleted          => $find{deleted},
        is_draft            => $find{draftuser_id} ? 1 : 0,
        include_approval    => $self->include_approval,
        view_limit_extra_id => undef, # Remove any default extra view
    );

    $self->columns_retrieved_do($records->columns_retrieved_do);
    $self->columns_retrieved_no($records->columns_retrieved_no);

    my $search     = $find{current_id} || $find{draftuser_id}
        ? $records->search_query(prefetch => 1, linked => 1)
        : $records->search_query(root_table => 'record', prefetch => 1, linked => 1, no_current => 1);
    my @prefetches = $records->jpfetch(prefetch => 1, search => 1, linked => 0); # Still need search in case of view limit

    my $root_table;
    if (my $record_id = $find{record_id})
    {
        unshift @prefetches, (
            {
                'current' => [
                    'deletedby',
                    $records->linked_hash(prefetch => 1),
                ],
            },
            {
                'createdby' => 'organisation',
            },
            'approvedby'
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
        unshift @prefetches, (
            {
                'createdby' => 'organisation',
            },
            'approvedby'
        ); # Add info about related current record
        @prefetches = (
            $records->linked_hash(prefetch => 1),
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

    my @columns_fetch = $records->columns_fetch(search => 1); # Still need search in case of view limit
    push @columns_fetch, $records->columns_fetch(search => 1, linked => 1); # Still need search in case of view limit
    my $base = $find{record_id} ? 'me' : 'record_single_2';
    push @columns_fetch, {id => "$base.id"};
    push @columns_fetch, $find{record_id} ? {deleted => "current.deleted"} : {deleted => "me.deleted"};
    push @columns_fetch, {linked_id => "linked.id"};
    push @columns_fetch, {'linked.record_id' => "record_single.id"};
    push @columns_fetch, {current_id => "$base.current_id"};
    push @columns_fetch, {created => "$base.created"};
    push @columns_fetch, "createdby.$_" foreach @GADS::Column::Person::person_properties;
    push @columns_fetch, "deletedby.$_" foreach @GADS::Column::Person::person_properties;

    # If fetch a draft, then make sure it's not a draft curval that's part of
    # another draft record
    push @prefetches, 'curvals' if $find{draftuser_id};

    my $result = $self->schema->resultset($root_table)->search(
        [
            -and => $search
        ],
        {
            join    => [@prefetches],
            columns => \@columns_fetch,
        },
    );

    $result->result_class('DBIx::Class::ResultClass::HashRefInflator');

    my ($record) = $result->all;
    return if !$record && $find{no_errors};
    $record or error __"Requested record not found";

    $self->linked_id($record->{linked_id});
    $self->set_deleted($record->{deleted});
    $self->set_deletedby($record->{deletedby});

    # Fetch and merge and multi-values
    my @record_ids = ($record->{id});
    push @record_ids, $record->{linked}->{record_id}
        if $record->{linked} && $record->{linked}->{record_id};

    if ($self->_set_approval_flag($record->{approval}))
    {
        $self->_set_approval_record_id($record->{record_id}); # Related record if this is approval record
    }
    $self->record($record);

    # Fetch and add multi-values
    $records->fetch_multivalues(
        record_ids => \@record_ids,
        retrieved  => [$record],
        records    => [$self],
        is_draft   => $find{draftuser_id},
    );

    $self; # Allow chaining
}

sub clone_as_new_from
{   my ($self, $from) = @_;
    $self->find_current_id($from);
    $self->remove_id;
    $self;
}

sub load_remembered_values
{   my $self = shift;

    # First see if there's a draft. If so, use that instead
    if ($self->user->has_draft($self->layout->instance_id))
    {
        $self->find_draftuser_id($self->user->id);
        $self->remove_id;
        return;
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

    my $previous = GADS::Record->new(
        user   => $self->user,
        layout => $self->layout,
        schema => $self->schema,
    );

    $previous->columns(\@remember);
    $previous->include_approval(1);
    $previous->find_record_id($lastrecord->record_id);

    $self->fields->{$_->id} = $previous->fields->{$_->id}->clone(record => $self)
        foreach @{$previous->columns_retrieved_do};

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
                base_url         => request->base,
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
    $search->{'created'} = { '<' => $self->schema->storage->datetime_parser->format_datetime($self->rewind) }
        if $self->rewind;
    my @records = $self->schema->resultset('Record')->search($search,{
        order_by => { -desc => 'created' }
    })->all;
    @records;
}

sub _set_record_id
{   my ($self, $record) = @_;
    $record->{id};
}

sub _transform_values
{   my $self = shift;

    my $original = $self->record or panic "Record data has not been set";

    my $fields = {};
    # If any columns are multivalue, then the values will not have been
    # prefetched, as prefetching can result in an exponential amount of
    # rows being fetched from the database in one go. It's better to pull
    # all types of value together though, so we store them in this hashref.
    my $multi_values = {};
    # We must do these columns in dependent order, otherwise the
    # column values may not exist for the calc values.
    foreach my $column (@{$self->columns_retrieved_do})
    {
        my $value = $self->linked_id && $column->link_parent ? $original->{$column->link_parent->field} : $original->{$column->field};
        $value = $self->linked_record_raw && $self->linked_record_raw->{$column->link_parent->field}
            if $self->linked_record_raw && $column->link_parent && !$self->is_historic;

        my $child_unique = ref $value eq 'ARRAY' && @$value > 0
            ? $value->[0]->{child_unique} # Assume same for all parts of value
            : ref $value eq 'HASH' && exists $value->{child_unique}
            ? $value->{child_unique}
            : undef;
        $fields->{$column->id} = $column->class->new(
            record           => $self,
            record_id        => $self->record_id,
            current_id       => $self->current_id,
            init_value       => ref $value eq 'ARRAY' ? $value : defined $value ? [$value] : [],
            child_unique     => $child_unique,
            column           => $column,
            init_no_value    => $self->init_no_value,
            schema           => $self->schema,
            layout           => $self->layout,
        );
    }
    $fields->{-11} = GADS::Datum::ID->new(
        record           => $self,
        record_id        => $self->record_id,
        current_id       => $self->current_id,
        column           => $self->layout->column(-11),
        schema           => $self->schema,
        layout           => $self->layout,
    );
    $fields->{-12} = GADS::Datum::Date->new(
        record           => $self,
        record_id        => $self->record_id,
        current_id       => $self->current_id,
        column           => $self->layout->column(-12),
        schema           => $self->schema,
        layout           => $self->layout,
        init_value       => [ { value => $original->{created} } ],
    );
    $fields->{-13} = $self->_person($original->{createdby}, $self->layout->column(-13));
    $fields->{-15} = GADS::Datum::Date->new(
        record           => $self,
        record_id        => $self->record_id,
        current_id       => $self->current_id,
        column           => $self->layout->column(-15),
        schema           => $self->schema,
        layout           => $self->layout,
        init_value       => [ { value => $self->record_created } ],
    );
    $fields->{-16} = GADS::Datum::Serial->new(
        record           => $self,
        value            => $self->serial,
        record_id        => $self->record_id,
        current_id       => $self->current_id,
        column           => $self->layout->column(-16),
        schema           => $self->schema,
        layout           => $self->layout,
    );
    $fields;
}

sub values_by_shortname
{   my ($self, @names) = @_;
    +{
        map {
            my $col = $self->layout->column_by_name_short($_)
                or error __x"Short name {name} does not exist", name => $_;
            my $linked = $self->linked_id && $col->link_parent;
            my $datum = $self->fields->{$col->id}
                or panic __x"Value for column {name} missing. Possibly missing entry in layout_depend?", name => $col->name;
            my $d = $self->fields->{$col->id}->is_awaiting_approval # waiting approval, use old value
                ? $self->fields->{$col->id}->oldvalue
                : $linked && $self->fields->{$col->id}->oldvalue # linked, and linked value has been overwritten
                ? $self->fields->{$col->id}->oldvalue
                : $self->fields->{$col->id};
            $_ => $d->for_code;
        } @names
    };
}

# Initialise empty record for new write
sub initialise
{   my $self = shift;
    my $fields;
    foreach my $column ($self->layout->all(include_internal => 1))
    {
        $fields->{$column->id} = $self->initialise_field($column->id);
    }
    $self->fields($fields);
}

sub initialise_field
{   my ($self, $id) = @_;
    my $layout = $self->layout;
    my $column = $layout->column($id);
    if ($self->linked_id && $column->link_parent)
    {
        $self->linked_record->fields->{$column->link_parent->id};
    }
    else {
        $column->class->new(
            record           => $self,
            record_id        => $self->record_id,
            column           => $column,
            schema           => $self->schema,
            layout           => $self->layout,
            datetime_parser  => $self->schema->storage->datetime_parser,
        );
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
            my $draft = GADS::Record->new(
                user     => undef,
                layout   => $self->layout,
                schema   => $self->schema,
            );
            $draft->find_draftuser_id($self->user->id)
                or last;
            $draft->delete_current;
            $draft->purge_current;
        }
    }
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
sub write
{   my ($self, %options) = @_;

    # See whether this instance is set to not record history. If so, override
    # update_only option to ensure it is only an update
    $options{update_only} = 1 if $self->layout->forget_history;

    # $@ may be the result of a previous Log::Report::Dispatcher::Try block (as
    # an object) and may evaluate to an empty string. If so, txn_scope_guard
    # warns as such, so undefine to prevent the warning
    undef $@;
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

    # This will be called before a write for a normal edit, to allow checks on
    # next/prev values, but we call it here again now, for other writes that
    # haven't explicitly called it
    $self->set_blank_dependents;

    # First loop round: sanitise and see which if any have changed
    my %allow_update = map { $_ => 1 } @{$options{allow_update} || []};
    my ($need_app, $need_rec, $child_unique); # Whether a new approval_rs or record_rs needs to be created
    $need_rec = 1 if $self->changed;
    # Whether any topics cannot be written because of missing fields in
    # other topics
    my %no_write_topics;
    foreach my $column ($self->layout->all)
    {
        next unless $column->userinput;
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
            if (!$datum->dependent_not_shown)
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
                    # Only warn if it was previously blank, otherwise it might
                    # be a read-only field for this user
                    if (!$self->new_entry && !$datum->changed)
                    {
                        mistake __x"'{col}' is no longer optional, but was previously blank for this record.", col => $column->{name};
                    }
                    else {
                        error __x"'{col}' is not optional. Please enter a value.", col => $column->name;
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
                        field => $column->name, value => $datum->as_string, id => $r->current_id);
                }
            }
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
        if $self->parent_id && !$child_unique;

    # Anything to update?
    return if !($need_app || $need_rec) && !$options{update_only};

    # Dummy run?
    return if $options{dry_run};

    my $created_date = $options{version_datetime} || DateTime->now;

    my $user_id = $self->user ? $self->user->id : undef;

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
        $self->fields->{-15}->set_value($created_date);
    }

    my $createdby = $options{version_userid} || $user_id;
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

    $self->fields->{-11}->current_id($self->current_id);
    $self->fields->{-11}->clear_value; # Will rebuild as current_id
    if (!$options{update_only} || $self->layout->forget_history)
    {
        # Keep original record values when only updating the record, except
        # when the update_only is happening for forgetting version history, in
        # which case we want to record these details
        $self->fields->{-12}->set_value($created_date);
        $self->fields->{-13}->set_value($createdby, no_validation => 1);
    }

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

    # Write all the values
    my %columns_changed = ($self->current_id => []);
    my @columns_cached;
    my %update_autocurs;
    foreach my $column ($self->layout->all(order_dependencies => 1))
    {
        # Prevent warnings when writing incomplete calc values on draft
        next if $options{draft} && !$column->userinput;

        my $datum = $self->fields->{$column->id};
        if ($self->parent_id && !$column->can_child && $column->userinput) # Calc values always unique
        {
            my $datum_parent = $self->parent->fields->{$column->id};
            #$datum->current_id($self->current_id);
            #$datum->record_id($self->record_id);
            #$self->fields->{$column->id} = $datum;
            $datum->set_value($datum_parent->html_form, is_parent_value => 1);
        }
        next if $self->linked_id && $column->link_parent; # Don't write all values if this is a linked record

        if ($need_rec || $options{update_only}) # For new records, $need_rec is only set if user has create permissions without approval
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

                    push @{$columns_changed{$self->current_id}}, $column->id if $datum->changed;
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
            # Note any records that will need updating that have an autocur field that refers to this
            if ($column->type eq 'curval')
            {
                foreach my $autocur (@{$column->autocurs})
                {
                    # Work out which ones have changed. We only want to
                    # re-evaluate records that have actually changed, for both
                    # performance reasons and to send the correct alerts
                    #
                    # First, establish which current IDs might be affected
                    my %affected = map { $_ => 1 } @{$datum->ids_affected};

                    # Then see if any fields depend on this autocur (e.g. code fields)
                    if ($autocur->layouts_depend_depends_on->count)
                    {
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
                        $update_autocurs{$cid} ||= [];
                        push @{$update_autocurs{$cid}}, $autocur->id;
                    }
                }
            }
        }
        if ($need_app)
        {
            # Only need to write values that need approval
            next unless $datum->is_awaiting_approval;
            $self->_field_write($column, $datum, approval => 1)
                if ($self->new_entry && !$datum->blank)
                    || (!$self->new_entry && $datum->changed);
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
                user   => undef,
                layout => $self->layout,
                schema => $self->schema,
            );
            $child->find_current_id($child_id);
            foreach my $col ($self->layout->all(order_dependencies => 1))
            {
                my $datum_child = $child->fields->{$col->id};
                if ($col->userinput)
                {
                    my $datum_parent = $self->fields->{$col->id};
                    $datum_child->set_value($datum_parent->html_form, is_parent_value => 1)
                        unless $col->can_child;
                }
                # Calc/rag values will be evaluated during write()
            }
            $child->write(%options, update_only => 1);
        }

        # Update any records with an autocur field that are referred to by this
        foreach my $cid (keys %update_autocurs)
        {
            my $record = GADS::Record->new(
                user     => $self->user,
                layout   => $self->layout,
                schema   => $self->schema,
                base_url => $self->base_url,
            );
            $record->find_current_id($cid);
            $record->fields->{$_}->changed(1)
                foreach @{$update_autocurs{$cid}};
            $record->write(%options, update_only => 1, re_evaluate => 1);
        }
    }

    # Alerts can cause SQL errors, due to the unique constraints
    # on the alert cache columns. Therefore, commit what we've
    # done so far, and don't do alerts in a transaction
    $guard->commit;

    # Send any alerts
    if (!$options{no_alerts} && !$options{draft})
    {
        # Possibly not the best way to do alerts, but certainly the
        # simplest. Spin up a new alert sender for each changed record
        foreach my $cid (keys %columns_changed)
        {
            my $alert_send = GADS::AlertSend->new(
                layout      => $self->layout,
                schema      => $self->schema,
                user        => $self->user,
                base_url    => $self->base_url,
                current_ids => [$cid],
                columns     => $columns_changed{$cid},
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
                    if (my $parent_try = dispatcher 'active-try')
                    {
                        $parent_try->hide('NONE');
                    }

                    # We must catch exceptions here, otherwise we will never
                    # reap the process. Set up a guard to be doubly-sure this
                    # happens.
                    my $guard = guard { POSIX::_exit(0) };
                    # Despite the guard, we still operate in a try block, so as to catch
                    # the messages from any exceptions and report them accordingly
                    try { $alert_send->process } hide => 'ALL'; # This takes a long time
                    $@->reportAll(is_fatal => 0);
                }
            }
        }
    }
    $self->clear_new_entry; # written to database, no longer new
}

sub set_blank_dependents
{   my $self = shift;

    foreach my $column ($self->layout->all)
    {
        if (my $display_field = $column->display_field)
        {
            my $datum = $self->fields->{$column->id};
            $datum->set_value('')
                if $datum->dependent_not_shown && ($datum->column->can_child || !$self->parent_id);
        }
    }
}

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
            elsif ($column->type =~ /(file|enum|tree|person|curval)/)
            {
                if ($column->type eq 'curval')
                {
                    foreach my $record (@{$datum_write->values_as_query_records})
                    {
                        $record->write(%options, no_draft_delete => 1);
                        my $id = $record->current_id;
                        my %entry = %$entry; # Copy to stop referenced id being overwritten
                        $entry{value} = $id;
                        push @entries, \%entry;
                    }
                }
                foreach my $id (@{$datum_write->ids})
                {
                    my %entry = %$entry; # Copy to stop referenced id being overwritten
                    $entry{value} = $id;
                    push @entries, \%entry;
                }
                if ($column->type eq 'curval' && $column->delete_not_used)
                {
                    foreach my $deleted_id (@{$datum->ids_deleted})
                    {
                        my $is_used;
                        foreach my $refers (@{$column->layout_parent->referred_by})
                        {
                            my $refers_layout = GADS::Layout->new(
                                user                     => $self->layout->user,
                                user_permission_override => 1,
                                schema                   => $self->schema,
                                config                   => GADS::Config->instance,
                                instance_id              => $refers->instance_id,
                            );
                            my $rules = GADS::Filter->new(
                                as_hash => {
                                    rules     => [{
                                        id       => $refers->id,
                                        type     => 'string',
                                        value    => $deleted_id,
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
                            my $record = GADS::Record->new(
                                user     => $self->user,
                                layout   => $column->layout_parent,
                                schema   => $self->schema,
                            );
                            $record->find_current_id($deleted_id);
                            $record->delete_current(override => 1);
                        }
                    }
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
        $datum->re_evaluate;
        $datum->write_value;
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
        deletedby => $self->user && $self->user->id
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
{   my $self = shift;
    my $return;
    foreach my $col ($self->layout->all_user_read)
    {
        my $short = $col->name_short or next;
        $return->{$short} = $self->fields->{$col->id}->as_string;
    }
    encode_json $return;
}

sub pdf
{   my $self = shift;

    my $dateformat = GADS::Config->instance->dateformat;
    my $now = DateTime->now->format_cldr($dateformat)." at ".DateTime->now->hms;
    my $updated = $self->created->format_cldr($dateformat)." at ".$self->created->hms;

    my $pdf = CtrlO::PDF->new(
        footer => "Downloaded by ".$self->user->value." on $now",
    );

    $pdf->add_page;
    $pdf->heading('Record '.$self->current_id);
    $pdf->heading('Last updated by '.$self->createdby->as_string." on $updated", size => 12);

    my $data =[
        ['Field', 'Value'],
    ];
    foreach my $col ($self->layout->all_user_read)
    {
        my $datum = $self->fields->{$col->id};
        next if $datum->dependent_not_shown;
        push @$data, [
            $col->name,
            $datum->as_string,
        ],
    }

    my $hdr_props = {
        repeat     => 1,
        justify    => 'center',
        font_size  => 8,
    };

    $pdf->table(
        data => $data,
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

