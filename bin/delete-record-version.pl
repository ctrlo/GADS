#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use 5.10.0;
use GADS::DB;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport mode => 'NORMAL';
use Getopt::Long;

dispatcher close => 'error_handler';

GADS::DB->setup(schema);

GADS::Config->instance(config => config,);

my ($record_id);

GetOptions('record-id=s' => \$record_id,)
    or exit;

$record_id
    or error __ "Please provide the record version ID with --record-id";

my $record = schema->resultset('Record')->find($record_id)
    or error __ "Record ID not found";

say __x
"This will purge the version {rid} from record {cid} created by {user} at {date}. Press any key to continue.",
    rid  => $record_id,
    cid  => $record->current_id,
    user => $record->createdby->value,
    date => $record->created;

<STDIN>;

my $guard = schema->txn_scope_guard;

$record->calcvals->delete;
$record->curvals->delete;
$record->dateranges->delete;
$record->dates->delete;
$record->enums->delete;
$record->files->delete;
$record->intgrs->delete;
$record->people->delete;
$record->ragvals->delete;
$record->strings->delete;
$record->user_lastrecords->delete;
$record->delete;

$guard->commit;
