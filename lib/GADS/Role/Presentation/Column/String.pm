package GADS::Role::Presentation::Column::String;

use Moo::Role;

sub after_presentation
{   my ($self, $return) = @_;

    $return->{textbox}    = $self->textbox;
    $return->{max_length} = $self->max_length;
}

1;
