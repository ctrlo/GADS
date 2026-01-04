package GADS::Role::Presentation::Chronology::Person;

use Moo::Role;

around chronology => sub {
    my ($orig, $self) = @_;
    
    my $chronology = $self->$orig;

    return {
        name    => $chronology->{column_name},
        text    => $chronology->{text},
        details => $chronology->{details},
    };
};

1;