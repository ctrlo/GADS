package GADS::Role::Presentation::Datum::Rag;

use Moo::Role;

sub presentation {
    my $self = shift;

    return {
        type    => $self->column->type,
        grade   => $self->as_grade
    };
}

1;
