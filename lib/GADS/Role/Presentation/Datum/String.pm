package GADS::Role::Presentation::Datum::String;

use Moo::Role;
use HTML::FromText qw(text2html);

sub presentation {
    my $self = shift;

    my $base = $self->presentation_base;

    my $raw = $base->{value};

    my $html = [map {text2html(
        $_,
        lines     => 1,
        urls      => 1,
        email     => 1,
        metachars => 1,
    ) } @{$base->{html_form}}];

    $base->{visible} = $self->visible;
    $base->{raw}  = $raw;
    $base->{html} = $html;

    return $base;
}

1;
