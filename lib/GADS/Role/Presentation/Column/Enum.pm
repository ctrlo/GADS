package GADS::Role::Presentation::Column::Enum;

use Moo::Role;

sub after_presentation
{   my ($self, $return) = @_;

    $return->{select_values} = $self->enumvals;
}

1;
