#!/usr/bin/env perl

use Data::Dump qw(pp);

use FindBin qw($Bin);
use lib "$Bin/../lib";

use GADS::Datum::Calc;

print pp(GADS::Datum::Calc->meta->get_all_attributes);