use Test::More;
use strict;
use warnings;

use lib 't/lib';

use Test::Compile;

my $test = Test::Compile->new;
$test->ok($test->pl_file_compiles('./lib/GADS.pm'), 'GADS compiles');
$test->done_testing();
