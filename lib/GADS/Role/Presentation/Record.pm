package GADS::Role::Presentation::Record;

use Moo::Role;

sub _presentation_map_columns {
    my ($self, @columns) = @_;

    my @fields = values %{ $self->fields };
    
    my @mapped;

    COLUMN: foreach my $column (@columns) {
        foreach my $field (@fields) {
            if ($field->column->name eq $column->name) {
                push @mapped, {
                    is_multivalue => $column->multivalue,
                    value         => $field->presentation
                };

                next COLUMN;
            }
        }
    }

    return \@mapped;
}

sub presentation {
    my ($self, @columns) = @_;

    return {
        parent_id => $self->parent_id,
        id        => $self->current_id,
        columns   => $self->_presentation_map_columns(@columns) 
        
    }
}

1;
