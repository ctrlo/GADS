package GADS::Role::Presentation::Column::Rag;

use Moo::Role;
use JSON qw(decode_json encode_json);
use URI::Escape qw/uri_escape_utf8/;

sub after_presentation
{   my ($self, $return) = @_;

    # Currently not in use
}

1;
