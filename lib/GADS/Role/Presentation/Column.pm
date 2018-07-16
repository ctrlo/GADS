package GADS::Role::Presentation::Column;

use Moo::Role;

sub presentation {
    my ($self, %options) = @_;

    return {
        id            => $self->id,
        type          => $self->type,
        name          => $self->name,
        is_multivalue => $self->multivalue,
        helptext      => $self->helptext,
        data          => $options{datum_presentation},
    };
}

1;
