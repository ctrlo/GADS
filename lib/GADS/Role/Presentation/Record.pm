package GADS::Role::Presentation::Record;

use Moo::Role;

sub _presentation_map_columns {
    my ($self, @columns) = @_;

    my @mapped = map {
        +{
            is_multivalue => $_->multivalue,
            type          => $_->type,
            data          => $self->fields->{$_->id}->presentation,
            name          => $_->name
        }
    } @columns;

    return \@mapped;
}

sub presentation {
    my ($self, @columns) = @_;

    return {
        parent_id  => $self->parent_id,
        current_id => $self->current_id,
        columns    => $self->_presentation_map_columns(@columns) 
        
    }
}

1;
