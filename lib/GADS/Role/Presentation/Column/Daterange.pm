package GADS::Role::Presentation::Column::Daterange;

use Moo::Role;

sub after_presentation
{   my ($self, $return) = @_;

    $return->{show_datepicker} = $self->show_datepicker;
}

1;
