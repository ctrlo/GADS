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

    return {
        parent_id       => $self->parent_id,
        current_id      => $self->current_id,
        instance_id     => $self->layout->instance_id,
        columns         => $self->_presentation_map_columns(@columns),
        deleted         => $self->deleted,
        deletedby       => $self->deletedby,
        createdby       => $self->createdby,
        user_can_delete => $self->user_can_delete,
    }
}

1;
