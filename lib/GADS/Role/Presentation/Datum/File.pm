package GADS::Role::Presentation::Datum::File;

use Moo::Role;

sub presentation {
    my $self = shift;

    my $base = $self->presentation_base;
    delete $base->{value};

    $base->{name}     = $self->name;
    $base->{id}       = $self->id;
    $base->{mimetype} = $self->mimetype;

    return $base;
}

1;
