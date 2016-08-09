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

# Example script for updating values across all records based on another
# field's value

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2;
use Dancer2::Plugin::DBIC;
use Data::Dumper;
use GADS::DB;
use GADS::Layout;
use GADS::Record;
use Log::Report;
use Text::CSV;
use Getopt::Long qw(:config pass_through);

GADS::DB->setup(schema);

# All valid values
my @valid = rset('Enumval')->search({ layout_id => 42 })->all;

my @text = rset('String')->search({ layout_id => 74 })->all;

foreach my $text (@text)
{
    next unless $text->value;
    $text->value =~ /([a-z][0-9]{4}[a-z])/i;
    my $v = $1 or next;
    if (my @exists = (grep { $_->value =~ /$v/i } @valid))
    {
        next if @exists > 1;
        my $u = pop @exists;
        my $record_id = $text->record_id;
        say STDOUT "Going to change https://xxxx/history/$record_id to ".$u->id." (".$u->value.")";
        my $update = rset('Enum')->search({ record_id => $record_id, layout_id => 42 });
        say STDOUT "This will update ".$update->count." records";
        $update->update({ value => $u->id });
        say STDOUT "Going to clear value from https://xxxx/history/$record_id";
        $update = rset('String')->search({ record_id => $record_id, layout_id => 74 });
        say STDOUT "This will update ".$update->count." records";
        $update->update({ value => undef });
    }
}
