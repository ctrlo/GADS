package GADS::Role::Presentation::Datum;

use Moo::Role;

sub presentation { shift->presentation_base(@_) } # Default, overridden

sub presentation_base {
    my ($self, %options) = @_;
    return {
        type                => $options{type} || ($self->isa('GADS::Datum::Count') ? 'count' : $self->column->type),
        value               => $self->as_string,
        has_value           => $self->has_value,
        filter_value        => $self->filter_value,
        blank               => $self->blank,
        dependent_not_shown => $self->dependent_not_shown,
        html_form           => $self->html_form,
        record_id           => $self->record && $self->record->record_id, # Not set when called from audit logs
        column_id           => $self->column && $self->column->id,
        column_name         => $self->column && $self->column->name,
    };
}

1;
