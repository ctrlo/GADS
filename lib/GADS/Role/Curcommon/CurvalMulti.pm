package GADS::Role::Curcommon::CurvalMulti;

use Moo::Role;

sub fetch_multivalues
{   my ($self, $record_ids, %options) = @_;

    local $SL::Schema::IGNORE_PERMISSIONS = 1 if $self->override_permissions;
    # Always ignore permissions of fields in the actual search. This doesn't
    # affect any filters that may be applied, but is in fact the opposite: if a
    # limited view is defined (using fields the user does not have access to)
    # then this ensures it is properly applied
    local $SL::Schema::IGNORE_PERMISSIONS_SEARCH = 1;

    # Order by record_id so that all values for one record are grouped together
    # (enabling later code to work)
    my $m_rs = $self->schema->resultset('Curval')->search({
        'me.record_id'      => $record_ids,
        'me.layout_id'      => $self->id,
    },{
        order_by => 'me.record_id',
    });
    $m_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @values = $m_rs->all;
    my $records = GADS::Records->new(
        user                    => $self->layout->user,
        rewind                  => $options{rewind},
        layout                  => $self->layout_parent,
        schema                  => $self->schema,
        columns                 => $self->curval_field_ids,
        already_seen            => $options{already_seen},
        include_deleted         => 1,
        limit_current_ids       => [map { $_->{value} } @values],
        is_draft                => $options{is_draft},
        columns                 => $self->curval_field_ids_retrieve(all_fields => $self->retrieve_all_columns, %options),
        max_results             => $self->limit_rows,
        ignore_view_limit_extra => 1,
    );

    # We need to retain the order of retrieved records, so that they are shown
    # in the correct order within each field. This order is defined with the
    # default sort for each table
    my %retrieved; my $order;
    while (my $record = $records->single)
    {
        $retrieved{$record->current_id} = {
            record => $record,
            order  => ++$order, # store order
        };
    }

    my @return; my @single; my $last_record_id;
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
