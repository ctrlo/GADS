package GADS::Role::Purge::PersonPurgable;

use strict;
use warnings;

use Moo::Role;

with 'GADS::Role::Purgeable';

sub _build_recordsource {'Person';}
sub _build_valuefield{'value';}

1;