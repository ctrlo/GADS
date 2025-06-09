package GADS::Role::Presentation::Column::File;

use Moo::Role;

sub after_presentation
{   my ($self, $return) = @_;

    $return->{extra_values} = $self->extra_values;
}

1;
