package GADS::Role::Presentation::Column::Curval;

use Moo::Role;

sub after_presentation
{   my ($self, $return) = @_;

    $return->{filtered_values} = $self->filtered_values;
}

1;
