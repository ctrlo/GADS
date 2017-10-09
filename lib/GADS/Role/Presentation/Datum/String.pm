package GADS::Role::Presentation::Datum::String;

use Moo::Role;
use HTML::FromText qw(text2html);

sub presentation {
    my $self = shift;

    my $raw = $self->as_string;

    my $html = text2html(
        $raw,
        urls      => 1,
        email     => 1,
        metachars => 1,
    );

    return {
        type => $self->column->type,
        raw  => $raw,
        html => $html
    };
}

1;
