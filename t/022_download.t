use Test::More; # tests => 1;
use strict;
use warnings;

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime

use JSON qw(encode_json);
use Log::Report;
use GADS::Graph;
use GADS::Graph::Data;
use GADS::Records;

use lib 't/lib';
use Test::GADS::DataSheet;

set_fixed_time('01/10/2024 14:00:00', '%m/%d/%Y %H:%M:%S');

my @data;
push @data, {
    string1  => 'foobar',
    integer1 => $_,
} for (1..1000);

my $sheet = Test::GADS::DataSheet->new(data => \@data);
$sheet->create_records;
my $columns = $sheet->columns;
my $layout  = $sheet->layout;

my $edited_time = $layout->column_by_name_short('_version_datetime');
my $edited_user = $layout->column_by_name_short('_version_user');

my $view = GADS::View->new(
    name        => "Test",
    instance_id => $layout->instance_id,
    layout      => $layout,
    schema      => $sheet->schema,
    user        => $sheet->user,
    columns     => [$sheet->columns->{string1}->id, $sheet->columns->{integer1}->id, $edited_time->id, $edited_user->id],
);
$view->set_sorts({fields => [$sheet->columns->{integer1}->id], types => ['asc']});
$view->write;

my $records = GADS::Records->new(
    user   => $sheet->user,
    layout => $layout,
    schema => $sheet->schema,
    view   => $view,
);

is($records->csv_header, qq(ID,"Last edited time","Last edited by",string1,integer1\n));

my $edittime = '2024-01-10 14:00:00';
my $i;
while (my $line = $records->csv_line)
{
    $i++;
    is($line, qq($i,"$edittime","User1, User1",foobar,$i\n));

    # Add a record part way through the download - this should have no impact
    # on the download currently in progress
    if ($i == 500)
    {
        my $record = GADS::Record->new(
            user   => $sheet->user,
            layout => $layout,
            schema => $sheet->schema,
        );
        $record->initialise;
        $record->fields->{$columns->{string1}->id}->set_value('foobar');
        $record->fields->{$columns->{integer1}->id}->set_value(800);
        $record->write(no_alerts => 1);
    }
}

done_testing();
