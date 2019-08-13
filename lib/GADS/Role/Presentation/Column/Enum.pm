package GADS::Role::Presentation::Column::Enum;

use Moo::Role;

sub after_presentation
{   my ($self, $return) = @_;

    $return->{enumvals} = $self->enumvals;
}

1;
