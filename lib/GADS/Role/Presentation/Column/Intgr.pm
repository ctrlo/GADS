package GADS::Role::Presentation::Column::Intgr;

use Moo::Role;

sub after_presentation
{   my ($self, $return) = @_;

    $return->{show_calculator} = $self->show_calculator;
}

1;
