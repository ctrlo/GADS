package GADS::Role::Presentation::Datum::Tree;

use Moo::Role;

sub presentation
{   my $self = shift;

    my $base = $self->presentation_base;

    $base->{ids}           = $self->ids;
    $base->{ids_as_params} = $self->ids_as_params;

    return $base;
}

1;
