package GADS::Role::Presentation::Record;

use Moo::Role;

sub _presentation_map_columns {
    my ($self, @columns) = @_;

    my @mapped = map {
        $_->presentation(datum_presentation => $self->fields->{$_->id}->presentation);
    } @columns;

    return \@mapped;
}

sub presentation {
    my ($self, @columns) = @_;

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
                if ($seen || $display_field_id == $previous->id)
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
        instance_id     => $self->layout->instance_id,
        columns         => $self->_presentation_map_columns(@columns),
        indent          => $indent,
        deleted         => $self->deleted,
        deletedby       => $self->deletedby,
        createdby       => $self->createdby,
        user_can_delete => $self->user_can_delete,
        user_can_edit   => $self->layout->user_can('write_existing'),
    }
}

1;
