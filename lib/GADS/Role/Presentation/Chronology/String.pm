package GADS::Role::Presentation::Chronology::String;

use Moo::Role;

around chronology => sub {
    my ( $orig, $self ) = @_;

    my $chronology = $self->$orig;

    return { $chronology->{column_name} => $chronology->{value} };
};

1;
