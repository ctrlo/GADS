=comment
It's a singleton object that just holds the last chronology record, and the API can set it when it finds a chronology,
and the Record class can get it when it needs to find the next page of a chronology.
=cut
package GADS::Chronology;

use strict;
use warnings;

use Moo;

with 'MooX::Singleton';

has last_record => (
    is => 'rw',
);

sub clear {
    shift->last_record(undef);
}

1;
