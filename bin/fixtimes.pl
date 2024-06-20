#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use GADS::DB;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport mode => 'NORMAL';

GADS::DB->setup(schema);

GADS::Config->instance(config => config,);

# No site ID configuration and selection, as Record resultset does not contain site_id field
my $records_rs = schema->resultset('Record')->search(
    {
        'me.created'           => { '>=' => '2020-03-29 02:00' },
        'record_earlier_id.id' => undef,
    },
    {
        join => 'record_earlier_id',
    },
);

foreach my $record ($records_rs->all)
{
    $record->update({
        created => $record->created->clone->subtract(hours => 1),
    });
}
