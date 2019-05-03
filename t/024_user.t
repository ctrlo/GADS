use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;

use t::lib::DataSheet;

my $sheet = t::lib::DataSheet->new(site_id => 1);
$sheet->create_records;
my $schema = $sheet->schema;
my $site   = $sheet->site;

my %template = (
    current_user     => $sheet->user,
    no_welcome_email => 1,
    surname          => 'Bloggs',
    firstname        => 'Joe',
    email            => 'joe@example.com',
    username         => 'joe@example.com',
);

my $user = $schema->resultset('User')->create_user(%template);

my $user_id = $user->id;

my $u = $schema->resultset('User')->find($user_id);

is($u->value, "Bloggs, Joe", "User created successfully");

$site->update({ register_organisation_mandatory => 1 });
try { $schema->resultset('User')->create_user(%template, email => 'joe1@example.com') };
like($@, qr/Please select a Organisation/, "Failed to create user missing org");

my $org = $schema->resultset('Organisation')->create({ name => 'Org' });
$site->update({ register_team_mandatory => 1 });
try { $schema->resultset('User')->create_user(%template, email => 'joe1@example.com', organisation => $org->id) };
like($@, qr/Please select a Team/, "Failed to create user missing team");

my $team = $schema->resultset('Team')->create({ name => 'Team' });
$site->update({ register_department_mandatory => 1 });
try { $schema->resultset('User')->create_user(%template, email => 'joe1@example.com', organisation => $org->id, team_id => $team->id) };
like($@, qr/Please select a Department/, "Failed to create user missing department");

done_testing();
