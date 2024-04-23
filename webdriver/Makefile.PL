use strict;
use warnings;
use ExtUtils::MakeMaker;

our %prereq_pm = (
    'List::Util'            => '1.56',
    'Moo'                   => 0,
    'Test::More'            => 0,
    'Test2::API'            => 0,
    'Test2::Tools::Compare' => 0,
    'WebDriver::Tiny'       => '0.102',
);

return 1 if caller();

WriteMakefile(
    PREREQ_PM => \%prereq_pm,
);
