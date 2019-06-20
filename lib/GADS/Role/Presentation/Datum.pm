package GADS::Role::Presentation::Datum;

use Moo::Role;

sub presentation { shift->presentation_base } # Default, overridden

sub presentation_base {
    my $self = shift;
    return {
        type                => $self->column->type,
        value               => $self->as_string,
        filter_value        => $self->filter_value,
        blank               => $self->blank,
        dependent_not_shown => $self->dependent_not_shown,
    };
}

1;
