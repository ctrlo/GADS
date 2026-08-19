=comment
I _really_ don't like this - I have to work out some way to share the last chronology record between requests,
and this is the only way I can think of to do it without some sort of odd persistence somewhere.
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
