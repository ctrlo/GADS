package GADS::Role::Presentation::Chronology;

use Moo::Role;

sub chronology {
    my ($self) = @_;

    return $self->presentation if $self->can('presentation');

    # placeholder for now - this will be replaced with a more sensible implementation
    return { id => $self->id, };
}

1;
