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

use Carp qw(confess);
use DateTime;
use DateTime::Format::Strptime qw( );
use DBIx::Class::ResultClass::HashRefInflator;
use GADS::AlertSend;
use GADS::Datum::Calc;
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

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
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

has columns_retrieved => (
    is => 'rw',
);

# Whether this is a new record, not yet in the database
has new_entry => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has record_id => (
    is      => 'rw',
    lazy    => 1,
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
    coerce  => sub { $_[0] || undef }, # empty string from form submit
    builder => sub {
        my $self = shift;
        my $current = $self->schema->resultset('Current')->find($self->current_id)
            or return;
        $current->linked_id;
    },
);

# The ID of the parent record that this is related to, in the
# case of a related record
has parent_id => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $current = $self->schema->resultset('Current')->find($self->current_id)
            or return;
        $current->parent_id;
    },
);

has related_records => (
    is      => 'rwp',
    isa     => ArrayRef,
    default => sub { [] },
);

has approval_id => (
    is => 'rw',
);

# Whether this is an approval record for a new entry.
# Used when checking permissions for approving
has approval_of_new => (
    is  => 'lazy',
    isa => Bool,
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
# has changed. For example, if removing a field from a related
# record, which would otherwise go unnoticed
has changed => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has current_id => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_set_current_id($self->record);
    },
);

has fields => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_transform_values;
    },
);

has createdby => (
    is      => 'rw',
    lazy    => 1,
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

has force_update => (
    is => 'rw',
);

has is_historic => (
    is  => 'lazy',
    isa => Bool,
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

sub find_record_id
{   my ($self, $record_id) = @_;
    $self->_find(record_id => $record_id);
}

sub find_current_id
{   my ($self, $current_id) = @_;
    return unless $current_id;
    $self->_find(current_id => $current_id);
}

sub _find
{   my ($self, %find) = @_;
    my $records = GADS::Records->new(
        user             => $self->user,
        layout           => $self->layout,
        schema           => $self->schema,
        columns          => $self->columns,
    );

    my $rinfo = $records->construct_search;
    $self->columns_retrieved($records->columns_retrieved);

    my @limit      = @{$rinfo->{limit}};
    my $prefetches = $records->prefetches;
    my $joins      = $records->joins;
    my @search     = @{$rinfo->{search}};


    my $root_table;
    if (my $record_id = $find{record_id})
    {
        unshift @$prefetches, (
            {
                'current' => $records->linked_hash
            },
            'createdby',
            'approvedby'
        ); # Add info about related current record
        push @limit, ("me.id" => $record_id);
        $root_table = 'Record';
        unless ($self->include_approval)
        {
            push @search, (
                { 'me.approval'         => 0 },
                { 'me.record_id'        => undef },
                { 'current.instance_id' => $self->layout->instance_id },
            );
        }
    }
    elsif (my $current_id = $find{current_id})
    {
        push @limit, ("me.id" => $current_id);
        unshift @$prefetches, ('current', 'createdby', 'approvedby'); # Add info about related current record
        $prefetches = [
            $records->linked_hash,
            'currents',
            {
                'record' => $prefetches,
            },
        ];
        $joins      = {'record' => $joins};
        $root_table = 'Current';
        unless ($self->include_approval)
        {
            push @search, (
                {'record.approval' => 0},
                {'record.record_id' => undef},
            );
        }
        push @search, { 'me.instance_id' => $self->layout->instance_id };
    }
    else {
        confess "record_id or current_id needs to be passed to _find";
    }

    my $search = [-and => [@search, @limit]];

    my $select = {
        prefetch => $prefetches,
        join     => $joins,
    };

    my $result = $self->schema->resultset($root_table)->search(
        $search, $select
    );

    $result->result_class('DBIx::Class::ResultClass::HashRefInflator');

    my ($record) = $result->all;
    $record or error __"Requested record not found";
    if ($find{current_id})
    {
        $self->linked_id($record->{linked_id});
        $self->parent_id($record->{parent_id});
        $self->linked_record($record->{linked}->{record});
        my @related_records = map { $_->{id} } @{$record->{currents}};
        $self->_set_related_records(\@related_records);
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
}

sub versions
{   my $self = shift;
    my @records = $self->schema->resultset('Record')->search({
        'current_id' => $self->current_id,
        approval     => 0,
        record_id    => undef
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

    my $original = $self->record or confess "Record data has not been set";

    my $fields = {};
    #foreach my $column ($self->layout->all(order_dependencies => 1))
    foreach my $column (@{$self->columns_retrieved})
    {
        my $dependent_values;
        foreach my $dependent (@{$column->depends_on})
        {
            $dependent_values->{$dependent} = $fields->{$dependent};
        }
        my $value = $original->{$column->field};
        $value = $self->linked_record && $self->linked_record->{$column->link_parent->field}
            if $self->linked_id && $column->link_parent && !$self->is_historic;
        next if $self->parent_id && !defined $value;

        # FIXME XXX Don't collect file content in sql query
        delete $value->{value}->{content} if $column->type eq "file";
        my $force_update = (
            $self->force_update && grep { $_ == $column->id } @{$self->force_update}
        ) ? 1 : 0;
        $fields->{$column->id} = $column->class->new(
            record_id        => $self->record_id,
            current_id       => $self->current_id,
            set_value        => $value,
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

sub write
{   my ($self, %options) = @_;

    my $guard = $self->schema->txn_scope_guard;

    $self->new_entry(1) unless $self->current_id;

    # Create a new overall record if it's new, otherwise
    # load the old values
    if ($self->new_entry)
    {
        error __"No permissions to add a new entry"
            unless $self->layout->user_can('write_new');
    }

    my $force_mandatory = $options{force} && $options{force} eq 'mandatory' ? 1 : 0;

    # First loop round: sanitise and see which if any have changed
    my %appfields; # Any fields that need approval
    my ($need_app, $need_rec); # Whether a new approval_rs or record_rs needs to be created
    $need_rec = 1 if $self->changed;
    foreach my $column ($self->layout->all)
    {
        next unless $column->userinput;
        my $datum = $self->fields->{$column->id}
            or next; # Will not be set for related records

        # Check for blank value
        if (!$self->parent_id && !$self->linked_id && !$column->optional && $datum->blank && !$force_mandatory)
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
            error __x"You do not have permission to edit field {name}", name => $column->name;
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
    }

    # Anything to update?
    return unless $need_app || $need_rec;

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

    if ($need_rec)
    {
        my $id = $self->schema->resultset('Record')->create({
            current_id => $self->current_id,
            created    => DateTime->now,
            createdby  => $user_id,
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
        $self->schema->resultset('User')->find($self->user->{id})->update({ lastrecord => $id });
    }


    # Write all the values
    my @columns_changed; my @columns_cached;
    foreach my $column ($self->layout->all)
    {
        next unless $column->userinput;
        my $datum = $self->fields->{$column->id};
        next if ($self->parent_id || $self->linked_id) && !$datum; # Don't write all values if this is a related/linked record

        if ($need_rec) # For new records, only set if user has create permissions without approval
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
                    push @columns_changed, $column->id if $datum->changed;

                    # Write new value
                    $self->_field_write($column, $datum);
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
                    $self->_field_write($column, $datum, old => 1);
                }
                else {
                    # Value won't have changed. Write current value (old
                    # value will not be set if it hasn't been updated)
                    # Write old value
                    $self->_field_write($column, $datum);
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
    if ($need_rec)
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
            my ($user) = $self->schema->resultset('User')->search({
                lastrecord => $self->approval_id,
            })->all;
            $user->update({ lastrecord => $self->record_id }) if $user;
            $self->schema->resultset('Record')->find($self->approval_id)->delete;
        }
    }

    # Write cached values
    foreach my $col ($self->layout->all(userinput => 0, order_dependencies => 1))
    {
        # Get old value
        my $old = defined $self->fields->{$col->id} ? $self->fields->{$col->id}->as_string : "";
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
        # Changed?
        push @columns_changed, $col->id if $old ne $new->as_string;
    }

    # Alerts can cause SQL errors, due to the unique constraints
    # on the alert cache columns. Therefore, commit what we've
    # done so far, and don't do alerts in a transaction
    $guard->commit;

    # Send any alerts
    unless ($options{no_alerts})
    {
        my $alert_send = GADS::AlertSend->new(
            layout      => $self->layout,
            schema      => $self->schema,
            user        => $self->user,
            base_url    => $self->base_url,
            current_ids => [$self->current_id],
            columns     => \@columns_changed,
        );
        fork and return;
        $alert_send->process;
        exit;
    }
}

sub _field_write
{   my ($self, $column, $datum, %options) = @_;

    if ($column->userinput)
    {
        my $datum_write = $options{old} ? $datum->oldvalue : $datum;
        my $table = $column->table;
        my $entry = {
            layout_id => $column->id,
        };
        $entry->{record_id} = $options{approval} ? $self->approval_id : $self->record_id;
        if ($datum_write) # Possible that we're writing a blank value
        {
            if ($column->type eq "daterange")
            {
                $entry->{from}  = $datum_write->from_dt;
                $entry->{to}    = $datum_write->to_dt;
                $entry->{value} = $datum_write->as_string;
            }
            elsif ($column->type =~ /(file|enum|tree|person)/)
            {
                $entry->{value} = $datum_write->id;
            }
            else {
                $entry->{value} = $datum_write->value;
            }
        }
        $self->schema->resultset($table)->create($entry);
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

    # Start transaction
    my $guard = $self->schema->txn_scope_guard;

    foreach my $record (@records)
    {
        $self->_delete_record_values($record->id);
    }
    $self->schema->resultset('Current')->find($id)->update({ record_id => undef });
    $self->schema->resultset('Record') ->search({ current_id => $id })->update({ record_id => undef });
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
    $self->schema->resultset('User')     ->search({ lastrecord => $rid })->update({ lastrecord => undef });
}

1;

