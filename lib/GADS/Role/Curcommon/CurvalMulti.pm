package GADS::Role::Curcommon::CurvalMulti;

use Moo::Role;

sub fetch_multivalues
{   my ($self, $record_ids, %options) = @_;

    local $GADS::Schema::IGNORE_PERMISSIONS = 1 if $self->override_permissions;
    # Always ignore permissions of fields in the actual search. This doesn't
    # affect any filters that may be applied, but is in fact the opposite: if a
    # limited view is defined (using fields the user does not have access to)
    # then this ensures it is properly applied
    local $GADS::Schema::IGNORE_PERMISSIONS_SEARCH = 1;

    # First find out the values required (record IDs to retrieve). Order by
    # record_id so that all values for one record are grouped together
    # (enabling later code to work)
    my $m_rs = $self->schema->resultset('Curval')->search({
        'me.record_id'      => $record_ids,
        'me.layout_id'      => $self->id,
    },{
        order_by => 'me.record_id',
    });
    $m_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @values = $m_rs->all;

    # Keep a track of sheet joins in a tree. Add this column to the tree.
    my $tree = $options{already_seen};
    my $child = Tree::DAG_Node->new({name => $self->id});
    $tree->add_daughter($child);

    # Now retrive the records
    my $records = GADS::Records->new(
        user                    => $self->layout->user,
        rewind                  => $options{rewind},
        layout                  => $self->layout_parent,
        schema                  => $self->schema,
        columns                 => $self->curval_field_ids,
        already_seen            => $child,
        include_deleted         => 1,
        is_draft                => $options{is_draft},
        columns                 => $self->curval_field_ids_retrieve(all_fields => $self->retrieve_all_columns, %options, already_seen => $child),
        max_results             => $self->limit_rows,
        ignore_view_limit_extra => 1,
    );
    my %retrieved; my $order; my @return;
    # If limiting by rows, run a separate query for each record's curval value
    # to retrieve. These can't be run at the same time by limiting the record
    # IDs to retrieve, as we're not able to order at this stage. XXX Ideally we
    # would use a lateral join to retrieve in one go, see:
    # https://stackoverflow.com/questions/1124603/ and
    # http://lists.scsys.co.uk/pipermail/dbix-class/2015-February/011920.html
    if ($self->limit_rows)
    {
        # Group the values into each record
        my %values_grouped;
        foreach my $v (@values)
        {
            $values_grouped{$v->{record_id}} ||= [];
            push @{$values_grouped{$v->{record_id}}}, $v if $v->{value};
        }
        # Now retrieve each of those groups
        foreach my $rec (keys %values_grouped)
        {
            next unless @{$values_grouped{$rec}}; # No values
            $records->limit_current_ids([map { $_->{value} } @{$values_grouped{$rec}}]);

            # We need to retain the order of retrieved records, so that they are shown
            # in the correct order within each field. This order is defined with the
            # default sort for each table
            while (my $record = $records->single)
            {
                push @return, {
                    layout_id => $self->id,
                    record_id => $rec,
                    value     => $record,
                };
            }
            $records->clear_records;
        }
    }
    else {
        # Standard retrieval
        $records->limit_current_ids([map { $_->{value} } @values]);
        while (my $record = $records->single)
        {
            $retrieved{$record->current_id} = {
                record => $record,
                order  => ++$order, # store order
            };
        }
        my @single; my $last_record_id;
        foreach my $v (@values)
        {
            if ($last_record_id && $last_record_id != $v->{record_id})
            {
                @single = sort { ($a->{order}||0) <=> ($b->{order}||0) } @single;
                push @return, @single;
                @single = ();
            }
            push @single, {
                layout_id => $self->id,
                record_id => $v->{record_id},
                value     => $v->{value} && $retrieved{$v->{value}}->{record},
                order     => $v->{value} && $retrieved{$v->{value}}->{order},
            };
            $last_record_id = $v->{record_id};
        };
        # Use previously stored order to sort records - records can be part of
        # multiple values
        @single = sort { ($a->{order}||0) <=> ($b->{order}||0) } @single;
        push @return, @single;
    }

    return @return;
}

sub multivalue_rs
{   my ($self, $record_ids) = @_;
    $self->schema->resultset('Curval')->search({
        'me.record_id'      => $record_ids,
        'me.layout_id'      => $self->id,
    });
}

1;
