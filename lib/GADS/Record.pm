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

use DateTime;
use DateTime::Format::Strptime qw( );
use DBIx::Class::ResultClass::HashRefInflator;
use GADS::AlertSend;
use GADS::Config;
use GADS::Datum::Calc;
use GADS::Datum::Curval;
use GADS::Datum::Date;
use GADS::Datum::Daterange;
use GADS::Datum::Enum;
use GADS::Datum::File;
use GADS::Datum::Integer;
use GADS::Datum::Person;
use GADS::Datum::Rag;
use GADS::Datum::String;
use GADS::Datum::Tree;
use GADS::Util         qw(:all);
use Log::Report;
use JSON qw(encode_json);
use POSIX ();

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;
use namespace::clean;

# Preferably this is passed in to prevent extra
# DB reads, but loads it if it isn't
has layout => (
    is       => 'rw',
    required => 1,
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
);

# The parent linked record, if applicable
has linked_record => (
    is      => 'rw',
);

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

# Whether this is a new record, not yet in the database
has new_entry => (
    is      => 'rw',
    isa     => Bool,
    clearer => 1,
    default => 0,
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
    lazy    => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        $self->_set_current_id($self->record);
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
        return unless $self->record;
        GADS::Datum::Person->new(
            record_id        => $self->record_id,
            set_value        => {value => $self->record->{createdby}},
            schema           => $self->schema,
            layout           => $self->layout,
        );
    },
);

has created => (
    is      => 'lazy',
    isa     => DateAndTime,
    clearer => 1,
);

sub _build_created
{   my $self = shift;
    return unless $self->record;
    $self->schema->storage->datetime_parser->parse_datetime(
        $self->record->{created}
    );
}

has force_update => (
    is => 'rw',
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
{   my ($self, $record_id) = @_;
    my $instance_id = $self->schema->resultset('Record')->find($record_id)->current->instance_id;
    $self->_check_instance($instance_id);
    $self->_find(record_id => $record_id);
}

sub find_current_id
{   my ($self, $current_id) = @_;
    return unless $current_id;
    my $instance_id = $self->schema->resultset('Current')->find($current_id)->instance_id;
    $self->_check_instance($instance_id);
    $self->_find(current_id => $current_id);
}

# Returns new GADS::Record object, doesn't change current one
sub find_unique
{   my ($self, $column, $value, @retrieve_columns) = @_;

    return $self->find_current_id($value)
        if $column->id == -1;

    # First create a view to search for this value in the column.
    my $filter = encode_json({
        rules => [{
            field    => $column->id,
            id       => $column->id,
            type     => $column->type,
            value    => $value,
            operator => 'equal',
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

    my $records = GADS::Records->new(
        user             => $self->user,
        layout           => $self->layout,
        schema           => $self->schema,
        columns          => $self->columns,
        include_approval => $self->include_approval,
    );

    $self->columns_retrieved_do($records->columns_retrieved_do);
    $self->columns_retrieved_no($records->columns_retrieved_no);

    my $search     = $find{current_id} ? $records->search_query : $records->search_query(root_table => 'record');
    my @prefetches = $records->jpfetch(prefetch => 1);
    my $joins      = [$records->jpfetch(search => 1)];

    my $root_table;
    if (my $record_id = $find{record_id})
    {
        unshift @prefetches, (
            {
                'current' => $records->linked_hash
            },
            'createdby',
            'approvedby'
        ); # Add info about related current record
        push @$search, ("me.id" => $record_id);
        $root_table = 'Record';
    }
    elsif (my $current_id = $find{current_id})
    {
        push @$search, {"me.id" => $current_id};
        unshift @prefetches, ('current', 'createdby', 'approvedby'); # Add info about related current record
        @prefetches = (
            $records->linked_hash,
            'currents',
            {
                'record' => [@prefetches],
            },
        );
        $joins      = {'record' => $joins};
        $root_table = 'Current';
    }
    else {
        panic "record_id or current_id needs to be passed to _find";
    }

    my $result = $self->schema->resultset($root_table)->search(
        [
            -and => $search
        ],
        {
            prefetch => [@prefetches],
            join     => $joins,
        },
    );

    $result->result_class('DBIx::Class::ResultClass::HashRefInflator');

    my ($record) = $result->all;
    $record or error __"Requested record not found";
    if ($find{current_id})
    {
        $self->linked_id($record->{linked_id});
        $self->parent_id($record->{parent_id});
        $self->linked_record($record->{linked}->{record});
        my @child_record_ids = map { $_->{id} } @{$record->{currents}};
        $self->_set_child_record_ids(\@child_record_ids);
        $record = $record->{record};
    }
    else {
        $self->linked_id($record->{current}->{linked_id});
        # Add the whole linked record. If we are building a historic record,
        # then this will not be used. Instead the values will be replaced
        # with the actual values of that record, which may or may not have
        # values
        $self->linked_record($record->{current}->{linked}->{record});
    }
    if ($self->_set_approval_flag($record->{approval}))
    {
        $self->_set_approval_record_id($record->{record_id}); # Related record if this is approval record
    }
    $self->record($record);
    $self; # Allow chaining
}

sub versions
{   my $self = shift;
    my @records = $self->schema->resultset('Record')->search({
        'current_id' => $self->current_id,
        approval     => 0,
    },{
        order_by => { -desc => 'created' }
    })->all;
    @records;
}

sub _set_record_id
{   my ($self, $record) = @_;
    $record->{id};
}

sub _set_current_id
{   my ($self, $record) = @_;
    $record->{current_id};
}

sub _transform_values
{   my $self = shift;

    my $original = $self->record or panic "Record data has not been set";

    my $fields = {};
    # We must fo these columns in dependent order, otherwise the
    # column values may not exist for the calc values.
    foreach my $column (@{$self->columns_retrieved_do})
    {
        my $dependent_values;
        foreach my $dependent (@{$column->depends_on})
        {
            $dependent_values->{$dependent} = $fields->{$dependent};
        }
        my $value = $original->{$column->field};
        $value = $self->linked_record && $self->linked_record->{$column->link_parent->field}
            if $self->linked_id && $column->link_parent && !$self->is_historic;

        # FIXME XXX Don't collect file content in sql query
        delete $value->{value}->{content} if $column->type eq "file";
        my $force_update = (
            $self->force_update && grep { $_ == $column->id } @{$self->force_update}
        ) ? 1 : 0;
        $fields->{$column->id} = $column->class->new(
            record_id        => $self->record_id,
            current_id       => $self->current_id,
            set_value        => $value,
            child_unique     => $value->{child_unique},
            column           => $column,
            dependent_values => $dependent_values,
            init_no_value    => $self->init_no_value,
            schema           => $self->schema,
            layout           => $self->layout,
            datetime_parser  => $self->schema->storage->datetime_parser,
            force_update     => $force_update,
        );
    }
    $fields;
}

# Initialise empty record for new write
sub initialise
{   my $self = shift;
    my $fields;
    foreach my $column ($self->layout->all)
    {
        next unless $column->userinput;
        $fields->{$column->id} = $self->initialise_field($column->id);
    }
    $self->fields($fields);
}

sub initialise_field
{   my ($self, $id) = @_;
    my $layout = $self->layout;
    my $column = $layout->column($id);
    $column->class->new(
        record_id        => $self->record_id,
        set_value        => undef,
        column           => $column,
        schema           => $self->schema,
        layout           => $self->layout,
        datetime_parser  => $self->schema->storage->datetime_parser,
    );
}

sub approver_can_action_column
{   my ($self, $column) = @_;
    $self->approval_of_new && $column->user_can('approve_new')
      || !$self->approval_of_new && $column->user_can('approve_existing')
}

sub write_linked_id
{   my $self = shift;
    my $current = $self->schema->resultset('Current')->find($self->current_id);
    $current->update({ linked_id => $self->linked_id });
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

    # $@ may be the result of a previous Log::Report::Dispatcher::Try block (as
    # an object) and may evaluate to an empty string. If so, txn_scope_guard
    # warns as such, so undefine to prevent the warning
    undef $@;
    my $guard = $self->schema->txn_scope_guard;

    $self->new_entry(1) unless $self->current_id;

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

    # First loop round: sanitise and see which if any have changed
    my %appfields; # Any fields that need approval
    my %allow_update = map { $_ => 1 } @{$options{allow_update} || []};
    my ($need_app, $need_rec, $child_unique); # Whether a new approval_rs or record_rs needs to be created
    $need_rec = 1 if $self->changed;
    foreach my $column ($self->layout->all)
    {
        next unless $column->userinput;
        my $datum = $self->fields->{$column->id}
            or next; # Will not be set for child records

        # Check for blank value
        if (!$self->parent_id && !$self->linked_id && !$column->optional && $datum->blank && !$options{force_mandatory})
        {
            # Only warn if it was previously blank, otherwise it might
            # be a read-only field for this user
            !$self->new_entry && !$datum->changed
                ? mistake __x"'{col}' is no longer optional, but was previously blank for this record.", col => $column->{name}
                : error __x"'{col}' is not optional. Please enter a value.", col => $column->{name};
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
        if ($column->isunique && !$datum->blank && ($self->new_entry || $datum->changed) && !($self->parent_id && !$datum->child_unique))
        {
            # Check for other columns with this value.
            if (my $r = $self->find_unique($column, $datum->as_string))
            {
                # as_string() used as will be encoded on message display
                error __x(qq(Field "{field}" must be unique but value "{value}" already exists in record {id}),
                    field => $column->name, value => $datum->as_string, id => $r->current_id);
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
            if ($column->user_can('write_new_no_approval'))
            {
                # User has permission to not need approval
                $need_rec = 1;
            }
            elsif ($column->user_can('write_new')) {
                # This needs an approval record
                trace __x"Approval needed because of no immediate write access to column {id}",
                    id => $column->id;
                $need_app = 1;
                $appfields{$column->id} = 1;
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
                $appfields{$column->id} = 1;
            }
        }
        $child_unique = 1 if $datum->child_unique;
    }

    # Error if child record as no fields selected
    error __"Please select at least one field to include in the child record"
        if $self->parent_id && !$child_unique;

    # Anything to update?
    return if !($need_app || $need_rec) && !$options{update_only};

    # Dummy run?
    return if $options{dry_run};

    # New record?
    if ($self->new_entry)
    {
        my $current = {
            parent_id   => $self->parent_id,
            linked_id   => $self->linked_id,
            instance_id => $self->layout->instance_id,
        };
        my $id = $self->schema->resultset('Current')->create($current)->id;
        $self->current_id($id);
    }

    my $user_id = $self->user ? $self->user->{id} : undef;

    if ($need_rec && !$options{update_only})
    {
        my $created_date = $options{version_datetime} || DateTime->now;
        my $createdby = $options{version_userid} || $user_id;
        my $id = $self->schema->resultset('Record')->create({
            current_id => $self->current_id,
            created    => $created_date,
            createdby  => $createdby,
        })->id;
        $self->record_id_old($self->record_id) if $self->record_id;
        $self->record_id($id);
    };

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

    if ($self->new_entry && $user_id)
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
    foreach my $column ($self->layout->all)
    {
        next unless $column->userinput;
        my $datum = $self->fields->{$column->id};
        if ($self->parent_id && !$datum->child_unique)
        {
            $datum = $self->parent->fields->{$column->id}->clone;
            $datum->current_id($self->current_id);
            $datum->record_id($self->record_id);
            $self->fields->{$column->id} = $datum;
        }
        next if $self->linked_id && !$datum; # Don't write all values if this is a linked record

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
                )
                {
                    push @{$columns_changed{$self->current_id}}, $column->id if $datum->changed;

                    # Write new value
                    $self->_field_write($column, $datum, %options);
                }
                elsif ($self->new_entry) {
                    # Write value. It's a new entry and the user doesn't have
                    # write access to this field. This will write a blank
                    # value.
                    $self->_field_write($column);
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
        if ($need_app)
        {
            # Only need to write values that need approval
            next unless $appfields{$column->id};
            $self->_field_write($column, $datum, approval => 1)
                if ($self->new_entry && !$datum->blank)
                    || (!$self->new_entry && $datum->changed);
        }

    }

    # Update the current record tracking, if we've created a new
    # permanent record, or a new record requiring approval
    if ($need_rec && !$options{update_only})
    {
        $self->schema->resultset('Current')->find($self->current_id)->update({
            record_id => $self->record_id
        });
    }
    elsif ($need_app && $self->new_entry)
    {
        $self->schema->resultset('Current')->find($self->current_id)->update({
            record_id => $self->approval_id
        });
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

    # Write cached values.
    foreach my $col ($self->layout->all(userinput => 0, order_dependencies => 1))
    {
        # Get old value
        my $old = $self->fields->{$col->id};
        # Force new value to be written
        my $dependent_values;
        foreach my $dependent (@{$col->depends_on})
        {
            $dependent_values->{$dependent}
                = $appfields{$dependent}
                ? $self->fields->{$dependent}->oldvalue
                : $self->fields->{$dependent};
        }
        my $new = $col->class->new(
            current_id       => $self->current_id,
            record_id        => $self->record_id,
            column           => $col,
            dependent_values => $dependent_values,
            schema           => $self->schema,
            layout           => $self->layout,
        );
        $self->fields->{$col->id} = $new;
        # Changed? There may not always be an old. E.g. new record, new value
        # in child record, new field added since previous record was created
        if ($old && !$new->equal($old->value, $new->value))
        {
            push @{$columns_changed{$self->current_id}}, $col->id;
        }
        elsif (!$old)
        {
            $new->value; # Force value to be evaluated and written
        }
    }

    # Do we need to update any child records that rely on the
    # values of this parent record?
    foreach my $child_id (@{$self->child_record_ids})
    {
        my $child = GADS::Record->new(
            user   => undef,
            layout => $self->layout,
            schema => $self->schema,
        );
        $child->find_current_id($child_id);
        foreach my $col ($self->layout->all(userinput => 1))
        {
            my $datum_child = $child->fields->{$col->id};
            my $datum_parent = $child->fields->{$col->id};
            $datum_child->set_value($datum_parent->value)
                unless $datum_child->child_unique;
        }
        $child->force_update(1); # Ensure all code values are updated
        $child->write(%options, update_only => 1);
    }

    # Alerts can cause SQL errors, due to the unique constraints
    # on the alert cache columns. Therefore, commit what we've
    # done so far, and don't do alerts in a transaction
    $guard->commit;

    # Send any alerts
    unless ($options{no_alerts})
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
                waitpid($kid, 0); # let the child die
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
                    my $parent_try = dispatcher 'active-try';
                    $parent_try->hide('NONE');

                    # We must catch exceptions here, otherwise we
                    # will never reap the process.
                    try { $alert_send->process } hide => 'ALL'; # This takes a long time
                    my $success = $@->died ? 0 : 1;
                    $@->reportAll(is_fatal => 0);
                    POSIX::_exit(0); # grandchild dies here
                }
            }
        }
    }
}

sub _field_write
{   my ($self, $column, $datum, %options) = @_;

    if ($column->userinput)
    {
        my $datum_write = $options{old} ? $datum->oldvalue : $datum;
        my $table = $column->table;
        my $entry = {
            child_unique => $datum ? $datum->child_unique : 0, # No datum for new invisible fields
            layout_id    => $column->id,
        };
        $entry->{record_id} = $options{approval} ? $self->approval_id : $self->record_id;
        if ($datum_write) # Possible that we're writing a blank value
        {
            if ($column->type eq "daterange")
            {
                $entry->{from}  = $datum_write->from_dt;
                $entry->{to}    = $datum_write->to_dt;
                $entry->{value} = $datum_write->as_string || undef; # Don't write empty strings for missing values
            }
            elsif ($column->type =~ /(file|enum|tree|person|curval)/)
            {
                $entry->{value} = $datum_write->id;
            }
            else {
                $entry->{value} = $datum_write->value;
            }
            if ($column->type eq 'string' && $datum_write->value)
            {
                $entry->{value_index} = lc substr $datum_write->value, 0, 128;
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
            if (@rows)
            {
                panic "Database error: multiple values for record ID {record_id} field {layout_id}",
                    record_id => $entry->{record_id}, layout_id => $entry->{layout_id} if @rows > 1;
                my ($row) = @rows;
                $row->update($entry);
            }
            else {
                # Doesn't exist, probably new column since record was written
                $create = 1;
            }
        }

        if (!$options{update_only} || $create) {
            $self->schema->resultset($table)->create($entry);
        }
    }
}

# Just delete this version
sub delete
{   my $self = shift;
    $self->_delete_record_values($self->record_id);
    $self->schema->resultset('Record')->find($self->record_id)->delete;
}

# Delete the record (version), plus its parent current (entire row)
# along with all related records
sub delete_current
{   my $self = shift;

    error __"You do not have permission to delete records"
        unless !$self->user
             || $self->user->{permission}->{delete}
             || $self->user->{permission}->{delete_noneed_approval};

    my $id = $self->current_id
        or panic __"No current_id specified for delete";

    $self->schema->resultset('Current')->search({
        id => $id,
        instance_id => $self->layout->instance_id,
    })->count
        or error "Invalid ID $id";

    my @records = $self->schema->resultset('Record')->search({
        current_id => $id
    })->all;

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
        $record->delete_current;
    }

    foreach my $record (@records)
    {
        $self->_delete_record_values($record->id);
    }
    $self->schema->resultset('Current')->find($id)->update({ record_id => undef });
    $self->schema->resultset('Record') ->search({ current_id => $id })->update({ record_id => undef });
    $self->schema->resultset('Curval') ->search({ value => $id })->update({ value => undef });
    $self->schema->resultset('AlertCache')->search({ current_id => $id })->delete;
    $self->schema->resultset('Record')->search({ current_id => $id })->delete;
    $self->schema->resultset('AlertSend')->search({ current_id => $id })->delete;
    $self->schema->resultset('Current')->find($id)->delete;
    $guard->commit;
}

sub _delete_record_values
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

