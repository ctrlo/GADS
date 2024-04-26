package GADS::Role::Purge::StringPurgable;

use strict;
use warnings;

use Moo::Role;

with 'GADS::Role::Purgeable';

sub _build_recordsource {'String';}
sub _build_valuefield{'value';}

1;