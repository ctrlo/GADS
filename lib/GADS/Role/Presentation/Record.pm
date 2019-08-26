package GADS::Role::Presentation::Record;

use Moo::Role;

sub _presentation_map_columns {
    my ($self, %options) = @_;

    my @columns = @{delete $options{columns}};

    my @mapped = map {
        $_->presentation(datum_presentation => $self->fields->{$_->id}->presentation, %options);
    } @columns;

    return \@mapped;
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

    my @columns = $self->layout->all(sort_by_topics => 1, can_child => $options{child}, userinput => 1, %permissions);

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

    return {
        parent_id       => $self->parent_id,
        current_id      => $self->current_id,
        record_id       => $self->record_id,
        instance_id     => $self->layout->instance_id,
        columns         => $self->_presentation_map_columns(%options, columns => \@columns),
        indent          => $indent,
        deleted         => $self->deleted,
        deletedby       => $self->deletedby,
        createdby       => $self->createdby,
        user_can_delete => $self->user_can_delete,
        user_can_edit   => $self->layout->user_can('write_existing'),
        id_count        => $self->id_count,
    }
}

1;
