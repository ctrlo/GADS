package GADS::Role::Presentation::Datum::File;

use Moo::Role;

sub presentation {
    my $self = shift;

    return {
        type     => $self->column->type,
        name     => $self->name,
        id       => $self->id,
        mimetype => $self->mimetype,
    };
}

1;
