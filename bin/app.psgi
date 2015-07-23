#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use GADS;

use Plack::Builder;

builder {
#    enable SizeLimit => (
#        max_unshared_size_in_kb => '100000',
#        check_every_n_requests => 2
#    );
    GADS->to_app;
};

