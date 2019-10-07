package GADS::Role::Presentation::Column::Curcommon;

use Moo::Role;

sub after_presentation
{   my ($self, $return, %options) = @_;

    $return->{layout_parent}      = $self->layout_parent;
    $return->{value_selector}     = $self->value_selector;
    $return->{show_add}           = $self->show_add;
    $return->{has_subvals}        = $self->has_subvals;
    $return->{filtered_values}    = $self->filtered_values
        if $options{edit};
    $return->{data_filter_fields} = $self->data_filter_fields;
}

1;
