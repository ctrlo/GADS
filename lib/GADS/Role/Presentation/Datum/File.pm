package GADS::Role::Presentation::Datum::File;

use Moo::Role;

sub presentation {
    my $self = shift;

    my $base = $self->presentation_base;

    $base->{files} = $self->files;
    $base->{purged} = $self->is_purged;

    return $base;
}

1;
