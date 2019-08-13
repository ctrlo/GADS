package GADS::Role::Presentation::Column::Person;

use Moo::Role;

sub after_presentation
{   my ($self, $return) = @_;

    $return->{default_to_login} = $self->default_to_login;
    $return->{people}           = $self->people;
}

1;
