package GADS::Role::Presentation::Column::Rag;

use Moo::Role;
use JSON qw(decode_json encode_json);
use URI::Escape qw/uri_escape_utf8/;

sub after_presentation
{   my ($self, $return) = @_;

    my $filter_values = [
        {
            id    => 'b_red',
            value => 'Red',
        },
        {
            id    => 'c_amber',
            value => 'Amber',
        },
        {
            id    => 'c_yellow',
            value => 'Yellow',
        },
        {
            id    => 'd_green',
            value => 'Green',
        },
        {
            id    => 'a_grey',
            value => 'Grey',
        },
        {
            id    => 'e_purple',
            value => 'Purple',
        }
    ];

    # Filter values normally only contains selected filters. For a RAG, because
    # there are only a few fixed options, we show them all regardless
    my $existing = decode_json($return->{filter_values});
    
    my %existing = map { $_->{id} => 1 } @$existing;

    $_->{checked} = $existing{$_->{id}} && \1
        foreach @$filter_values;

    $return->{filter_values} = encode_json $filter_values;
}

1;
