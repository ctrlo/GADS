package GADS::Role::Presentation::Column::Curcommon;

use Moo::Role;

sub after_presentation
{   my ($self, $return) = @_;

    $return->{layout_parent}   = $self->layout_parent;
    $return->{value_selector}  = $self->value_selector;
    $return->{show_add}        = $self->show_add;
    $return->{filtered_values} = $self->filtered_values;
}

1;
