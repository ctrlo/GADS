use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Graph;
use GADS::Graph::Data;
use GADS::Records;

use t::lib::DataSheet;

my @data;
push @data, {
    string1  => 'foobar',
    integer1 => $_,
} for (1..1000);

my $sheet = t::lib::DataSheet->new(data => \@data);
$sheet->create_records;
my $columns = $sheet->columns;

my $view = GADS::View->new(
    name        => "Test",
    instance_id => $sheet->layout->instance_id,
    layout      => $sheet->layout,
    schema      => $sheet->schema,
    user        => $sheet->user,
    columns     => [$sheet->columns->{string1}->id, $sheet->columns->{integer1}->id],
);
$view->write;
$view->set_sorts([$sheet->columns->{integer1}->id], ['asc']);

my $records = GADS::Records->new(
    user   => $sheet->user,
    layout => $sheet->layout,
    schema => $sheet->schema,
    view   => $view,
);

is($records->csv_header, "ID,string1,integer1\n");

my $i;
while (my $line = $records->csv_line)
{
    $i++;
    is($line, "$i,foobar,$i\n");

    # Add a record part way through the download - this should have no impact
    # on the download currently in progress
    if ($i == 500)
    {
        my $record = GADS::Record->new(
            user   => $sheet->user,
            layout => $sheet->layout,
            schema => $sheet->schema,
        );
        $record->initialise;
        $record->fields->{$columns->{string1}->id}->set_value('foobar');
        $record->fields->{$columns->{integer1}->id}->set_value(800);
        $record->write(no_alerts => 1);
    }
}

done_testing();
