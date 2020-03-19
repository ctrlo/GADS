use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    PREREQ_PM => {
        'List::MoreUtils'       => 0,
        'Test2::API'            => 0,
        'Test2::Tools::Compare' => 0,
        'WebDriver::Tiny'       => 0,
    },
);
