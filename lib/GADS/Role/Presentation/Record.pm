package GADS::Role::Presentation::Record;

use Moo::Role;

sub _presentation_map_columns {
    my ($self, %options) = @_;

    my @columns = @{delete $options{columns}};

    my @mapped = map {
        $_->presentation(datum_presentation => $self->fields->{$_->id}->presentation, %options);
    } @columns;

    return @mapped;
}

sub edit_columns
{   my ($self, %options) = @_;

    my %permissions = $options{approval} && $options{new}
        ? (user_can_approve_new => 1)
        : $options{approval}
        ? (user_can_approve_existing => 1)
        : $options{new}
        ? (user_can_write_new => 1)
        : (user_can_readwrite_existing => 1);

    my @columns = $self->layout->all(sort_by_topics => 1, can_child => $options{child}, %permissions, exclude_internal => 1);

    @columns = grep $_->type ne 'file', @columns
        if $options{bulk} && $options{bulk} eq 'update';

    return @columns;
}

sub presentation {
    my ($self, %options) = @_;

    # For an edit show all relevant fields for edit, otherwise assume record
    # read and show all view columns
    my @columns = $options{edit}
        ? $self->edit_columns(%options)
        : $options{curval_fields}
        ? @{$options{curval_fields}}
        : $options{group}
        ? @{$self->columns_view}
        : $options{purge}
        ? $self->layout->column_id
        : @{$self->columns_view};

    $options{record} = $self;

    # Work out the indentation each field should have. A field will be indented
    # if it has a display condition of an immediately-previous field. This will
    # be recursive as long as there are additional display-dependent fields.
    my $indent = {}; my $this_indent = {}; my $previous;
    foreach my $col (@columns)
    {
        if ($col->has_display_field)
        {
            foreach my $display_field_id (@{$col->display_field_col_ids})
            {
                my ($seen) = grep { $_ == $display_field_id } keys %$this_indent;
                if ($seen || ($previous && $display_field_id == $previous->id))
                {
                    $indent->{$col->id} = $seen && $indent->{$seen} ? ($indent->{$seen} + 1) : 1;
                    $this_indent->{$col->id} = $indent->{$col->id};
                    last;
                }
                $indent->{$col->id} = 0;
                $this_indent = {
                    $col->id => 0,
                };
            }
        }
        else {
            $indent->{$col->id} = 0;
            $this_indent = {
                $col->id => 0,
            };
        }
        $previous = $col;
    }

    my %topics; my $order; my %has_editable;
    my @presentation_columns = $self->_presentation_map_columns(%options, columns => \@columns);
    foreach my $col (@presentation_columns)
    {
        my $topic_id = $col->{topic_id} || 0;
        if (!$topics{$topic_id})
        {
            # Topics are listed in the order of their first column to appear in
            # the layout
            $order++;
            $topics{$topic_id} = {
                order    => $order,
                topic    => $col->{topic},
                columns  => [],
                topic_id => $topic_id,
            }
        }
        $has_editable{$topic_id} = 1
            if $col->{display_for_edit};
        push @{$topics{$topic_id}->{columns}}, $col;
    }

    my @topics = sort { $a->{order} <=> $b->{order} } values %topics;

    $_->{has_editable} = $has_editable{$_->{topic_id}}
        foreach @topics;

    my $version_datetime_col = $self->layout->column_by_name_short('_version_datetime');
    my $created_user_col     = $self->layout->column_by_name_short('_created_user');
    my $created_datetime_col = $self->layout->column_by_name_short('_created');
    my $return = {
        parent_id       => $self->parent_id,
        linked_id       => $self->linked_id,
        current_id      => $self->current_id,
        record_id       => $self->record_id,
        instance_id     => $self->layout->instance_id,
        columns         => \@presentation_columns,
        topics          => \@topics,
        indent          => $indent,
        deleted         => $self->deleted,
        deletedby       => $self->deletedby,
        user_can_delete => $self->user_can_delete,
        user_can_edit   => $self->layout->user_can('write_existing'),
        id_count        => $self->id_count,
        versions        => [$self->versions],
        has_rag_column  => !!(grep { $_->type eq 'rag' } @columns),
        new_entry       => $self->new_entry,
        is_draft        => $self->is_draft,
    };

    if (!$self->new_entry)
    {
        $return->{version_user} = $self->layout->column_by_name_short('_version_user')->presentation(
            datum_presentation => $self->createdby->presentation, %options
        );
        $return->{version_datetime} = $version_datetime_col->presentation(
            datum_presentation => $self->fields->{$version_datetime_col->id}->presentation, %options
        );
        $return->{created_user} = $created_user_col->presentation(
            datum_presentation => $self->fields->{$created_user_col->id}->presentation, %options
        );
        $return->{created_datetime} = $created_datetime_col->presentation(
            datum_presentation => $self->fields->{$created_datetime_col->id}->presentation, %options
        );
    }

    return $return;
}

1;
