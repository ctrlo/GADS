package GADS::Role::Presentation::Records;

use Moo::Role;

sub presentation {
    my ($self, @columns) = @_;

    return [
        map $_->presentation(@columns), @{$self->results}
    ];
}

1;
