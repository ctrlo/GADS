package GADS::Role::Presentation::Datum;

use Moo::Role;

sub presentation {    
    my $self = shift;
    return {
        type  => $self->column->type,
        value => $self->as_string
    };
}

1;
