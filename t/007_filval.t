use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;
use GADS::Layout;
use GADS::Filter;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use lib 't/lib';
use Test::GADS::DataSheet;

my $data = [
    {
        string1    => 'Foo',
        integer1   => 40,
        date1      => '2014-10-10',
        daterange1 => ['2012-02-10', '2013-06-15'],
        enum1      => 1,
    },
    {
        string1    => 'Foo',
        integer1   => 50,
        date1      => '2014-10-10',
        daterange1 => ['2012-02-10', '2013-06-15'],
        enum1      => 1,
    },
    {
        string1    => 'Foo',
        integer1   => 55,
        date1      => '2014-10-10',
        daterange1 => ['2012-02-10', '2013-06-15'],
        enum1      => 1,
    },
    {
        string1    => 'Bar',
        integer1   => 99,
        date1      => '2009-01-02',
        daterange1 => ['2008-05-04', '2008-07-14'],
        enum1      => 2,
    },
    {
        string1    => 'Bar',
        integer1   => 200,
        date1      => '2009-01-02',
        daterange1 => ['2008-05-04', '2008-07-14'],
        enum1      => '',
    },
    {
        string1    => 'FooBar',
        integer1   => 150,
        date1      => '2000-01-02',
        daterange1 => ['2001-05-12', '2002-03-22'],
        enum1      => 3,
    },
];

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, data => $data);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;
my $sheet   = Test::GADS::DataSheet->new(
    data             => [],
    schema           => $schema,
    multivalue       => 1,
    curval           => 2,
    curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $curval = $columns->{curval1};

# Filter on curval tests
$curval->filter(GADS::Filter->new(
    as_hash => {
        rules => [{
            id       => $curval_sheet->columns->{string1}->id,
            type     => 'string',
            value    => '$L1string1',
            operator => 'equal',
        }],
    },
));
$curval->write;
$layout->clear;

my $filval = GADS::Column::Filval->new(
    schema                => $schema,
    user                  => $sheet->user,
    layout                => $layout,
    name                  => 'curval filter storage',
    type                  => 'filval',
    refers_to_instance_id => $curval_sheet->layout->instance_id,
    curval_field_ids      => [ $curval_sheet->columns->{integer1}->id ], # Purposefully different to previous tests
    related_field_id      => $curval->id,

);
$filval->set_permissions({$sheet->group->id => $sheet->default_permissions});
$filval->write;
$layout->clear;

my @tests = (
    {
        name         => 'new',
        new          => 1,
        string_value => 'Bar',
        count_values => 2,
        curval_value => 4,
        as_string    => '99; 200',
    },
    {
        name         => 'edit',
        string_value => 'Foo',
        count_values => 3,
        curval_value => 2,
        as_string    => '40; 50; 55',
    },
    # For the unchanged test, remove a record from the filtered curval, and
    # then change a value in the record that is unrelated to the filtered
    # curval. The values in the curval should not contain the deleted record,
    # but because the curval and its related fields are unchanged, the recorded
    # list of filtered values should remain the same
    {
        name         => 'unchanged, including curval',
        delete_value => 2,
        string_value => 'Foo',
        date_value   => '2017-01-01',
        count_values => 2,
        curval_value => 2,
        as_string    => '40; 50; 55',
    },
    # For this unchanged test, do the same as the previous one, but this time
    # change the curval. Unlike the previous test, this should re-evaluate the
    # list of stored values
        name         => 'unchanged sub-values, changed curval',
        delete_value => 2,
        string_value => 'Foo',
        date_value   => '2018-05-01',
        count_values => 2,
        curval_value => 1,
        as_string    => '40; 55',
    },
);

my $current_id;
foreach my $test (@tests)
{
    if (my $delete_value = $test->{delete_value})
    {
        my $record = GADS::Record->new(
            user   => $sheet->user,
            schema => $schema,
            layout => $layout,
        );
        $record->find_current_id($delete_value);
        $record->delete_current;
    }

    my $record = GADS::Record->new(
        user   => $sheet->user,
        schema => $schema,
        layout => $layout,
    );
    if ($test->{new})
    {
        $record->initialise;
    }
    else {
        $record->find_current_id($current_id);
    }

    my $string1 = $columns->{string1};
    $record->fields->{$string1->id}->set_value($test->{string_value});
    my $date1 = $columns->{date1};
    $record->fields->{$date1->id}->set_value($test->{date_value})
        if $test->{date_value};

    my $submission_token = $record->submission_token;

    my $cv = $layout->column($curval->id);
    my $count = $test->{count_values};
    is( scalar @{$layout->column($curval->id)->filtered_values($submission_token)}, $count, "Correct number of values for curval field with filter" );

    $record->fields->{$curval->id}->set_value([$test->{curval_value}]);
    $record->write(no_alerts => 1, submission_token => $submission_token);
    $current_id = $record->current_id;

    $record->clear;
    $record->find_current_id($current_id);

    my $as_string = $test->{as_string};
    is($record->fields->{$filval->id}->as_string, $as_string, "Filtered curval field correct");

    if (my $delete_value = $test->{delete_value})
    {
        my $record = GADS::Record->new(
            user   => $sheet->user,
            schema => $schema,
            layout => $layout,
        );
        $record->find_current_id($delete_value, deleted => 1);
        $record->restore;
    }

    $layout->clear;
}

done_testing();
