#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use GADS;
use Dancer2;

set port => ($ENV{PORT} || 3000);

GADS->dance;
