package GADS::Role::Presentation::Column::Curcommon;

use JSON qw(encode_json);
use Moo::Role;

sub after_presentation
{   my ($self, $return, %options) = @_;

    $return->{layout_parent}      = $self->layout_parent;
    $return->{value_selector}     = $self->value_selector;
    $return->{show_add}           = $self->show_add;
    $return->{has_subvals}        = $self->has_subvals;
    $return->{data_filter_fields} = $self->data_filter_fields;
    $return->{typeahead_use_id}   = 1;
    $return->{limit_rows}         = $self->limit_rows;
    $return->{modal_field_ids}    = encode_json $self->curval_field_ids;
    # Expensive to build, so avoid if possible. Only needed for an edit, and no
    # point if they are filtered from record values as they will be rebuilt
    # anyway
    $return->{filtered_values}    = $self->filtered_values($options{record}->submission_token)
        if $options{edit} && !$self->has_subvals;
}

1;
