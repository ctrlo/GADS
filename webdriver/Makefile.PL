use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    PREREQ_PM => {
        'List::Util'            => '1.56',
        'Moo'                   => 0,
        'Test::More'            => 0,
        'Test2::API'            => 0,
        'Test2::Tools::Compare' => 0,
        'WebDriver::Tiny'       => '0.102',
    },
);
