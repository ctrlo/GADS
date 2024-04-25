package GADS::Role::Purge::RagPurgable;

use strict;
use warnings;

use Moo::Role;

with 'GADS::Role::Purgeable';

sub _build_recordsource {'Ragval';}
sub _build_valuefield{'value';}

1;