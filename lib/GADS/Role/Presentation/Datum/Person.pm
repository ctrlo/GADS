package GADS::Role::Presentation::Datum::Person;

use Moo::Role;

sub _presentation_details {
    my $self = shift;

    return [] unless $self->id;

    my $site = $self->column->layout->instance->site;

    my @details;

    if (my $email = $self->email) {
        push @details, {
            value => $self->email,
            type  => 'email'
        };
    }

    for (
        [$self->freetext1, $site->register_freetext1_name],
        [$self->freetext2, $site->register_freetext2_name]
    ) {
        next unless $_->[0];

        push @details, {
            definition => $_->[1],
            value      => $_->[0],
            type       => 'text'
        };
    }

    return \@details;
}

sub presentation {
    my $self = shift;

    return {
        type    => $self->column->type,
        text    => $self->text,
        details => $self->_presentation_details
    };
}

1;
