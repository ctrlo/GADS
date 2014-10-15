#!/usr/bin/perl

=pod
GADS - Globally Accessible Data Store
Copyright (C) 2014 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use GADS::Schema;
use File::Slurp;
use File::MimeInfo;
use File::Basename;

my ($file) = @ARGV;

$file or die "Usage: $0 filename";

my $filename  = fileparse($file);
my $mime_type = mimetype($file);
my $bin_data  = read_file($file, binmode => ':raw');

my $f = rset('Fileval')->create({
    name     => $filename,
    mimetype => $mime_type,
    content  => $bin_data,
});

my $fid = $f->id;

print "File uploaded as ID $fid\n";
