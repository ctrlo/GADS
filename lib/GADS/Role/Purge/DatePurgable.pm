package GADS::Role::Purge::DatePurgable;

use strict;
use warnings;

use Moo::Role;

with 'GADS::Role::Purgeable';

sub _build_recordsource {'Date';}
sub _build_valuefield{'value';}

1;