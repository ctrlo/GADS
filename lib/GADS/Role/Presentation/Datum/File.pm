package GADS::Role::Presentation::Datum::File;

use Moo::Role;

sub presentation
{   my $self = shift;

    my $base = $self->presentation_base;

    $base->{files} = $self->files;

    return $base;
}

1;
