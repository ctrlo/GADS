package GADS::Role::Presentation::Datum::Curval;

use Moo::Role;

sub _presentation_details {
    my $self = shift;

    return [] unless $self->as_string;

    my $rti = $self->column->refers_to_instance;

    my @links = map +{
        id   => $_->{id},
        href => $_->{value},
        refers_to_instance => $rti,
    }, @{$self->_text_all};

    return \@links;
}

sub presentation {
    my $self = shift;

    my $multivalue = $self->column->multivalue;

    my %presentation = (
        type => $self->column->type,
        text => $self->as_string
    );

    if ($multivalue) {
        $presentation{links} = $self->_presentation_details;
    }

    return \%presentation;
}

1;
