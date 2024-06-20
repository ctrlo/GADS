#!/usr/bin/perl

=pod
GADS - Globally Accessible Data Store
Copyright (C) 2017 Ctrl O Ltd

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

use Dancer2;
use Dancer2::Plugin::DBIC;
use GADS::Schema;
use Text::CSV;

my ($file) = @ARGV;

$file or die "Usage: $0 filename";

my $csv = Text::CSV->new({ binary => 1 })
    or die "Cannot use CSV: " . Text::CSV->error_diag();

open my $fh, "<:encoding(utf8)", $file or die "$file: $!";

# Index all names
my %titles        = map { $_->name => $_->id } rset('Title')->all;
my %organisations = map { $_->name => $_->id } rset('Organisation')->all;
my %groups        = map { $_->name => $_->id } rset('Group')->all;

my $guard = schema->txn_scope_guard;

while (my $row = $csv->getline($fh))
{
    my ($firstname, $surname, $email, $freetext1, $freetext2, $title,
        $organisation, $group)
        = @$row;

    my $title_id        = $titles{$title} or die qq(Title "$title" not found);
    my $organisation_id = $organisations{$organisation}
        or die qq(Organisation "$organisation" not found);
    my $group_id = $groups{$group} or die qq(Group "$group" not found);
    my $user     = rset('User')->create({
        firstname    => $firstname,
        surname      => $surname,
        email        => $email,
        username     => $email,
        freetext1    => $freetext1,
        freetext2    => $freetext2,
        title        => $title_id,
        organisation => $organisation_id,
    });
    rset('UserGroup')->create({
        user_id  => $user->id,
        group_id => $group_id,
    });
}

$guard->commit;

say STDERR "Finished";
