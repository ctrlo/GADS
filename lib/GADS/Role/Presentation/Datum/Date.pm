package GADS::Role::Presentation::Datum::Date;

use Moo::Role;

sub presentation {
    my $self = shift;

    my $base = $self->presentation_base;

    $base->{purged} = $self->is_purged;

    return $base;
}

1;