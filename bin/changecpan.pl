#!/bin/perl

use strict;
use warnings;

use feature 'say';

unlink "install.sh" if -e "install.sh";

open (IN, "<cpanfile") or die "Can't open cpanfile: $!";
open (OUT, ">install.sh") or die "Can't open install.sh: $!";

print OUT "#!/bin/bash\n\n";

print OUT "for i in ";

my $line;

while (<IN>) {
    chomp;
    $line = $_;
    $line = lc $line;
    $line =~ s/requires \"//g;
    $line =~ s/, '[\d\.]+'//g;
    $line =~ s/\";//g;
    $line =~ s/^/lib/g;
    $line =~ s/$/::perl/g;
    $line =~ s/::/-/g;
    print OUT "$line ";
}

print OUT "\n";
print OUT "do\n";
print OUT '    apt-get install -y $i';
print OUT "\n";
print OUT "done\n";
