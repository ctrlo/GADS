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

has approval_id => (
    is => 'rw',
);

# Whether to initialise fields that have no value
has init_no_value => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

# Add / Remove approval flag
has approval_flag => (
    is      => 'rw',
    trigger => sub {
        my ($self, $value) = @_;
        $self->schema->resultset('Record')->find($self->record_id)->update({approval => $value});
    }
);

has include_approval => (
    is => 'rw',
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
        include_approval => $self->include_approval,
    );

    my $rinfo = $records->construct_search;
    $self->columns_retrieved($records->columns_retrieved);

    my @search     = @{$rinfo->{search}};
    my @limit      = @{$rinfo->{limit}};
    my $prefetches = $rinfo->{prefetches};
    my $joins      = $rinfo->{joins};

    unshift @$prefetches, ('current', 'createdby', 'approvedby'); # Add info about related current record

    my $root_table;
    if (my $record_id = $find{record_id})
    {
        push @limit, ("me.id" => $record_id);
        $root_table = 'Record';
    }
    elsif (my $current_id = $find{current_id})
    {
        push @limit, ("me.id" => $current_id);
        $prefetches = {'record' => $prefetches};
        $joins      = {'record' => $joins};
        $root_table = 'Current';
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
    $record = $record->{record} if $find{current_id};
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
    my $fields;
    #foreach my $column ($self->layout->all(order_dependencies => 1))
    foreach my $column (@{$self->columns_retrieved})
    {
        my $dependent_values;
        foreach my $dependent (@{$column->depends_on})
        {
            $dependent_values->{$dependent} = $fields->{$dependent};
        }
        my $value = $original->{$column->field};
        unless ($self->init_no_value)
        {
            if (ref $column->join eq 'HASH')
                 { next unless defined $value->{value}; }
            else { next unless defined $value; }
        }

        # FIXME Don't collect file content in sql query
        delete $value->{value}->{content} if $column->type eq "file";
        $fields->{$column->id} = $column->class->new(
            record_id        => $self->record_id,
            current_id       => $self->current_id,
            set_value        => $original->{$column->field},
            column           => $column,
            dependent_values => $dependent_values,
            schema           => $self->schema,
            layout           => $self->layout,
            datetime_parser  => $self->schema->storage->datetime_parser,
            force_update     => $self->force_update,
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
        $fields->{$column->id} = $column->class->new(
            record_id        => $self->record_id,
            set_value        => undef,
            column           => $column,
            schema           => $self->schema,
            layout           => $self->layout,
            datetime_parser  => $self->schema->storage->datetime_parser,
        );
    }
    $self->fields($fields);
}

sub write
{   my $self = shift;

    $self->new_entry(1) unless $self->current_id;

    # Create a new overall record if it's new, otherwise
    # load the old values
    if ($self->new_entry)
    {
        error __"No permissions to add a new entry"
            if $self->user && !$self->user->{permission}->{create};
    }
    else
    {
        error __"No permissions to update an entry"
            if $self->user && !$self->user->{permission}->{update};
    }

    my $noapproval = !$self->user
                   || $self->user->{permission}->{update_noneed_approval}
                   || $self->user->{permission}->{approver};

    # First loop round: sanitise and see which if any have changed
    my %appfields; # Any fields that need approval
    my ($need_app, $need_rec); # Whether a new approval_rs or record_rs needs to be created
    foreach my $column ($self->layout->all)
    {
        next unless $column->userinput;
        my $datum = $self->fields->{$column->id};

        # Check for blank value
        if (!$column->optional && $datum->blank)
        {
            # Only warn if it was previously blank, otherwise it might
            # be a read-only field for this user
            !$self->new_entry && !$datum->changed
                ? mistake __x"'{col}' is no longer optional, but was previously blank for this record.", col => $column->{name}
                : error __x"'{col}' is not optional. Please enter a value.", col => $column->{name};
        }

        error __x"Field {name} is read only", name => $column->name
            if $datum->changed && $column->permission == READONLY && !$noapproval;

        if (!$self->new_entry && $datum->changed)
        {
            # Update to record and the field has changed
            if ($column->approve)
            {
                # Field needs approval
                if ($noapproval)
                {
                    # User has permission to not need approval
                    $need_rec = 1;
                }
                else {
                    # This needs an approval record
                    $need_app = 1;
                    $appfields{$column->id} = 1;
                }
            }
            else {
                # Field can be updated openly (OPEN)
                $need_rec = 1;
            }
        }
        if ($self->new_entry)
        {
            # New record
            if ($noapproval)
            {
                # User has permission to create new without approval
                if (($column->permission == APPROVE || $column->permission == READONLY)
                    && !$noapproval)
                {
                    # But field needs permission
                    $need_app = 1;
                    $appfields{$column->id} = 1;
                }
                else {
                    $need_rec = 1;
                }
            }
            else {
                # Whole record creation needs approval
                $need_app = 1;
                $appfields{$column->id} = 1;
            }
        }
    }

    # Anything to update?
    return unless $need_app || $need_rec;

    # New record?
    if ($self->new_entry)
    {
        my $serial;
        my $id = $self->schema->resultset('Current')->create({serial => $serial})->id;
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
    my %columns_changed; my @columns_cached;
    foreach my $column ($self->layout->all)
    {
        next unless $column->userinput;
        my $datum = $self->fields->{$column->id};

        if ($need_rec) # For new records, only set if user has create permissions without approval
        {
            my $v;
            # Need to write all values regardless
            if ($column->permission == OPEN || $noapproval)
            {
                $columns_changed{$column->id} = $column if $datum->changed;

                # Write new value
                $self->_field_write($column, $datum);
            }
            else {
                # Write old value
                $self->_field_write($column, $datum, old => 1);
            }
        }
        if ($need_app)
        {
            # Only need to write values that need approval
            next unless $appfields{$column->id};
            $self->_field_write($column, $datum, approval => 1);
        }

    }

    # Finally update the current record tracking, if we've created a new
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

    # Write cached values
    foreach my $col ($self->layout->all(userinput => 0))
    {
        # Get old value
        my $old = defined $self->fields->{$col->id} ? $self->fields->{$col->id}->as_string : "";
        # Force new value to be written
        my $dependent_values;
        foreach my $dependent (@{$col->depends_on})
        {
            $dependent_values->{$dependent} = $self->fields->{$dependent};
        }
        my $new = $col->class->new(
            current_id       => $self->current_id,
            record_id        => $self->record_id,
            column           => $col,
            dependent_values => $dependent_values,
            schema           => $self->schema,
            layout           => $self->layout,
        );
        # Changed?
        $columns_changed{$col->{id}} = $col if $old ne $new->as_string;
    }

    # Send any alerts
    # GADS::Alert->process($self->current_id, \%columns_changed);
}

sub _field_write
{   my ($self, $column, $datum, %options) = @_;

    if ($column->userinput)
    {
        my $table = $column->table;
        if ($options{old})
        {
            # Copy old table value
            my $old_rs = $self->schema->resultset($table)->search({
                record_id => $self->record_id_old,
                layout_id => $column->id,
            });
            $old_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
            my ($old_row) = $old_rs->all;
            delete $old_row->{id};
            $old_row->{record_id} = $self->record_id;
            $self->schema->resultset($table)->create($old_row);
        }
        else {
            my $entry = {
                layout_id => $column->id,
            };
            $entry->{record_id} = $options{approval} ? $self->approval_id : $self->record_id;
            if ($column->type eq "daterange")
            {
                $entry->{from}  = $datum->from_dt;
                $entry->{to}    = $datum->to_dt;
                $entry->{value} = $datum->as_string;
            }
            elsif ($column->type =~ /(file|enum|tree|person)/)
            {
                $entry->{value} = $datum->id;
            }
            else {
                $entry->{value} = $datum->value;
            }
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

    my @records = $self->schema->resultset('Record')->search({
        current_id => $id
    })->all;

    foreach my $record (@records)
    {
        $self->_delete_record_values($record->id);
    }
    $self->schema->resultset('Current')->find($id)->update({ record_id => undef });
    $self->schema->resultset('Record') ->search({ current_id => $id })->update({ record_id => undef });
    $self->schema->resultset('AlertCache')->search({ current_id => $id })->delete;
    $self->schema->resultset('Record') ->search({ current_id => $id })->delete;
    $self->schema->resultset('Current')->find($id)->delete;
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

