package GADS::Role::Purge::IntgrPurgable;

use strict;
use warnings;

use Moo::Role;

with 'GADS::Role::Purgeable';

sub _build_recordsource {'Intgr';}
sub _build_valuefield{'value';}

1;