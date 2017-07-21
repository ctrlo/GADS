package GADS::Role::Presentation::Datum::Curval;

use Moo::Role;

sub presentation {
    my $self = shift;

    return {
        type => $self->column->type,
        text => $self->text,
        id   => $self->id,
        ids  => $self->ids
    };
}

1;
