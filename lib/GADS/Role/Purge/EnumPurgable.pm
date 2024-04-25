package GADS::Role::Purge::EnumPurgable;

use strict;
use warnings;

use Moo::Role;

with 'GADS::Role::Purgeable';

sub _build_recordsource {'Enum';}
sub _build_valuefield{'value';}

1;