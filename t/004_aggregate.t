use Test::More; # tests => 1;
use strict;
use warnings;

use GADS::Records;
use Log::Report;

use t::lib::DataSheet;

my $data = [
    {
        string1    => 'foo1',
        integer1   => 25,
        enum1      => [1,2],
    },
    {
        string1    => 'foo1',
        integer1   => 50,
        enum1      => 2,
    },
    {
        string1    => 'foo2',
        integer1   => 60,
        enum1      => 2,
    },
    {
        string1    => 'foo2',
        integer1   => 70,
        enum1      => 3,
    },
];

my $sheet   = t::lib::DataSheet->new(
    data       => $data,
    multivalue => 1,
    calc_code  => "function evaluate (L1integer1) \n return L1integer1 * 2 \n end",
);
my $schema = $sheet->schema;
my $layout  = $sheet->layout;
$sheet->create_records;
my $columns = $sheet->columns;

my $string1  = $columns->{string1};
my $integer1 = $columns->{integer1};
my $calc1    = $columns->{calc1};
my $enum1    = $columns->{enum1};

my $view = GADS::View->new(
    name        => 'Aggregate view',
    columns     => [$string1->id, $integer1->id, $calc1->id, $enum1->id],
    instance_id => $layout->instance_id,
    layout      => $layout,
    schema      => $schema,
    user        => $sheet->user,
);
$view->write;

my $records = GADS::Records->new(
    view   => $view,
    layout => $layout,
    user   => $sheet->user,
    schema => $schema,
);

my @results = @{$records->results};
is(@results, 4, "Correct number of normal rows");

is($records->aggregate_results, undef, "No aggregate results initially");

$integer1->aggregate('sum');
$integer1->write;
$calc1->aggregate('sum');
$calc1->write;
$layout->clear;

$records = GADS::Records->new(
    view   => $view,
    layout => $layout,
    user   => $sheet->user,
    schema => $schema,
);

@results = @{$records->results};
is(@results, 4, "Correct number of normal rows");

my $aggregate = $records->aggregate_results;

is($aggregate->fields->{$integer1->id}->as_string, "205", "Correct total of integer values");
is($aggregate->fields->{$calc1->id}->as_string, "410", "Correct total of calc values");

# Perform test for multivalue field within set of records that will be
# aggregated, where the multivalue field is grouped. This checks for
# double-counting of rows, which we do want for each group, but not for the
# total aggregate
{
    $view->set_groups([$enum1->id]);
    $records->clear;

    @results = @{$records->results};
    is(@results, 3, "Correct number of normal rows");

    # The sum of the groups adds up to more than the total aggregate. This is
    # because one record appears in multiple groups, but is only counted once
    # for the overall aggregate
    is($results[0]->fields->{$integer1->id}->as_string, 25, "First grouping correct");
    is($results[1]->fields->{$integer1->id}->as_string, 135, "Second grouping correct");
    is($results[2]->fields->{$integer1->id}->as_string, 70, "Third grouping correct");

    $aggregate = $records->aggregate_results;

    is($aggregate->fields->{$integer1->id}->as_string, "205", "Correct total of integer values");
    is($aggregate->fields->{$calc1->id}->as_string, "410", "Correct total of calc values");
}

done_testing();
