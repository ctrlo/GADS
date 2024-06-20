package GADS::Role::Presentation::Datum::Rag;

use Moo::Role;

sub presentation
{   my $self = shift;

    my $base = $self->presentation_base;

    delete $base->{value};

    $base->{grade} = $self->as_grade;

    return $base;
}

1;
