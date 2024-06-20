package GADS::Role::Presentation::Datum::Enum;

use Moo::Role;

sub presentation
{   my $self = shift;

    my $base = $self->presentation_base;

    $base->{id_hash}        = $self->id_hash;
    $base->{deleted_values} = $self->deleted_values;

    return $base;
}

1;
