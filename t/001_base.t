use Test::More;
use strict;
use warnings;

if ( ! -f 'config.yml' ) {
    plan skip_all => 'No application configuration in config.yml';
}
else {
    plan tests => 1;
}

use_ok 'GADS';
