package GADS::Role::Presentation::Records;

use Moo::Role;

sub presentation {
    my $self = shift;

    return [
        map $_->presentation(group => $self->is_group), @{$self->results}
    ];
}

1;
