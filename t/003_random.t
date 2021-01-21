use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Test random sorting functionality of a view

my @data;
for my $count (1..1000)
{
    push @data, {
        string1 => "Foo $count",
        enum1   => ($count % 3) + 1,
    };
}
my $sheet = Test::GADS::DataSheet->new(data => \@data);
$sheet->create_records;

my $schema = $sheet->schema;
my $layout = $sheet->layout;
my $columns = $sheet->columns;

my $view = GADS::View->new(
    name        => 'Random view',
    columns     => [$columns->{string1}->id, $columns->{enum1}->id],
    instance_id => $layout->instance_id,
    layout      => $layout,
    schema      => $schema,
    user        => $sheet->user,
);
$view->set_sorts({fields => [$sheet->columns->{string1}->id], types => ['random']});
$view->write;

# Retrieve the set of results 10 times, and assume that at some point the
# randomness is such that a different record will be retrieved one of those
# times
my %strings;
for my $loop (1..10)
{
    my $records = GADS::Records->new(
        view    => $view,
        user    => $sheet->user,
        layout  => $layout,
        schema  => $schema,
    );
    my $record = $records->single;
    my $string = $record->fields->{$columns->{string1}->id}->as_string;
    $strings{$string} = 1;
}

ok(keys %strings > 1, "More than one different random record");

# Sanity check of normal sort
$view->set_sorts({fields => [$sheet->columns->{string1}->id], types => ['asc']});
$view->write;

%strings = ();
for my $loop (1..10)
{
    my $records = GADS::Records->new(
        view    => $view,
        user    => $sheet->user,
        layout  => $layout,
        schema  => $schema,
    );
    my $record = $records->single;
    my $string = $record->fields->{$columns->{string1}->id}->as_string;
    $strings{$string} = 1;
}

ok(keys %strings == 1, "Same record retrieved for fixed sort");

$view->set_sorts({fields => [$sheet->columns->{enum1}->id, $sheet->columns->{string1}->id], types => ['asc', 'random']});
$view->write;

my %enums;
for my $loop (1..10)
{
    my $records = GADS::Records->new(
        view    => $view,
        user    => $sheet->user,
        layout  => $layout,
        schema  => $schema,
    );
    my $record = $records->single;
    my $string = $record->fields->{$columns->{string1}->id}->as_string;
    $strings{$string} = 1;
    my $enum   = $record->fields->{$columns->{enum1}->id}->as_string;
    $enums{$enum} = 1;
}

ok(keys %strings > 1, "Random records retrieved for random part of search");
ok(keys %enums == 1, "Same record retrieved for fixed part of search");
my ($enum) = keys %enums;
is($enum, "foo1", "Correct sorted value for fixed sort");

done_testing();
