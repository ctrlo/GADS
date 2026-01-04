package GADS::Role::Presentation::Chronology::Curval;

use strict;
use warnings;

use Moo::Role;

use Data::Dump qw(pp);

around chronology => sub {
    my ( $orig, $self ) = @_;

    my $chronology = $self->$orig;

    for my $f (@{ $chronology->{html_form}}) {
        delete $f->{topics} if exists $f->{topics};
    }

    my $result = {$chronology->{column_name} => []};
    for my $l (@{ $chronology->{links}}) {
        $result->{$chronology->{column_name}} = [ map {+{$_->{data}->{column_name}=>$_->{data}->{value}}} @{$l->{presentation}->{columns}}];
    }

    $result;
};

1;
