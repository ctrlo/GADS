package GADS::Role::Presentation::Datum::Person;

use Moo::Role;

sub _presentation_details
{   my ($self, $person, %options) = @_;

    my $site = $options{site} || $self->column->layout->site;

    my @details;

    if (my $email = $person->{email})
    {
        push @details,
            {
                value => $person->{email},
                type  => 'email',
            };
    }

    for (
        [ $person->{freetext1}, $site->register_freetext1_name ],
        [ $person->{freetext2}, $site->register_freetext2_name ],
        )
    {
        next unless $_->[0];

        push @details,
            {
                definition => $_->[1],
                value      => $_->[0],
                type       => 'text',
            };
    }

    return {
        id      => $person->{id},
        text    => $person->{value},
        details => \@details,
    };
}

sub presentation
{   my ($self, %options) = @_;

    my $base = $self->presentation_base(%options);
    delete $base->{value};

    $base->{text}    = $self->as_string;
    $base->{value}   = $self->as_string;
    $base->{details} = [
        map $self->_presentation_details($_, %options),
        @{ $self->value_hash }
    ];
    $base->{ids} = $self->ids;

    return $base;
}

1;
