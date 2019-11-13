use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;

use Test::MockTime qw(set_fixed_time restore_time); # Load before DateTime

use lib 't/lib';
use Test::GADS::DataSheet;

# Test search of values that have changed in time period

my $sheet = Test::GADS::DataSheet->new;
$sheet->create_records;

my $schema = $sheet->schema;
my $layout = $sheet->layout;
my $columns = $sheet->columns;

my @to_write = (
    {
        string1    => 'foo1',
        enum1      => 1,
        version_dt => '01/01/2014 12:00',
    },
    {
        string1    => 'foo1',
        enum1      => 1,
        version_dt => '02/01/2014 12:00',
    },
    {
        string1    => 'foo1',
        enum1      => 1,
        version_dt => '03/01/2014 12:00',
    },
    {
        string1    => 'foo2',
        enum1      => 2,
        version_dt => '04/01/2014 12:00',
    },
    {
        string1    => 'foo2',
        enum1      => 2,
        version_dt => '05/01/2014 12:00',
    },
    {
        string1    => 'foo2',
        enum1      => 2,
        version_dt => '06/01/2014 12:00',
    },
    {
        string1    => 'foo3',
        enum1      => 3,
        version_dt => '07/01/2014 12:00',
    },
    {
        string1    => 'foo3',
        enum1      => 3,
        version_dt => '08/01/2014 12:00',
    },
    {
        string1    => 'foo3',
        enum1      => 3,
        version_dt => '09/01/2014 12:00',
    },
);

# Create records over a period of time
my $write_id;
foreach my $write (@to_write)
{
    my $version_dt = delete $write->{version_dt};
    set_fixed_time($version_dt, '%m/%d/%Y %H:%M:%S');
    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    );
    $record->initialise if !$write_id;
    $record->find_current_id($write_id) if $write_id;
    $record->fields->{$columns->{enum1}->id}->set_value($write->{enum1});
    $record->fields->{$columns->{string1}->id}->set_value($write->{string1});
    $record->write(no_alerts => 1);
    $write_id = $record->current_id;
}

my @tests = (
    {
        changed_date => '2014-09-15',
        count        => 0,
    },
    {
        changed_date => '2014-08-15',
        count        => 0,
    },
    {
        changed_date => '2014-07-15',
        count        => 0,
    },
    {
        changed_date => '2014-06-15',
        count        => 1,
    },
    {
        changed_date => '2014-05-15',
        count        => 1,
    },
    {
        changed_date => '2014-01-15',
        count        => 1,
    },
    {
        changed_date => '2013-12-15',
        count        => 1,
    },
);

foreach my $test (@tests)
{
    foreach my $type (qw/enum1 string1/) # XXX Add other field types
    {
        my $rules = GADS::Filter->new(
            as_hash => {
                rules     => [{
                    id       => $columns->{$type}->id,
                    type     => 'date',
                    value    => $test->{changed_date},
                    operator => 'changed_after',
                }],
            },
        );
        my $view = GADS::View->new(
            name        => 'Test view',
            filter      => $rules,
            columns     => [$columns->{string1}->id, $columns->{$type}->id],
            instance_id => $layout->instance_id,
            layout      => $layout,
            schema      => $schema,
            user        => $sheet->user,
        );
        $view->write;

        my $records = GADS::Records->new(
            view    => $view,
            user    => $sheet->user,
            layout  => $layout,
            schema  => $schema,
        );
        my $count = $records->count;
        is($count, $test->{count}, "Correct count for changed since $test->{changed_date} for $type");
        is(@{$records->results}, $test->{count}, "Correct number of records for changed since $test->{changed_date} for $type");
    }
}

done_testing();
