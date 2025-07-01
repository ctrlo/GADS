use Test::More;    # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;
use GADS::Record;

use lib 't/lib';
use Test::GADS::DataSheet;

use Test::Simple tests => 384;

my $sheet = Test::GADS::DataSheet->new(
    column_count => {
        string => 2,
    },
    data => [ {
        string1      => 'Foo',
        string2      => 'Keep',
        integer1     => 50,
        date1        => '2014-10-10',
        enum1        => 1,
        daterange1   => [ '2012-02-10', '2013-06-15' ],
        person1      => 1,
        tree1        => 'tree1',
        file1        => {
            name     => 'file1.txt',
            mimetype => 'text/plain',
            content  => 'Text file1',
        },
    } ],
);
my $schema  = $sheet->schema;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $record = GADS::Record->new(
    user   => $sheet->user,
    schema => $schema,
    layout => $layout,
);

my @cols = (
    {
        name      => "tree1",
        type      => "Enum",
        new       => undef,
        as_string => 'tree1'
    },
    {
        name => "string1",
        type => "String",
        new  => "Foo2",
    },
    {
        name => "integer1",
        type => "Intgr",
        new  => 72,
    },
    {
        name => "date1",
        type => "Date",
        new  => "2024-10-11",
    },
    {
        name      => "enum1",
        type      => "Enum",
        new       => 2,
        as_string => "foo2",
    },
    {
        name      => "daterange1",
        type      => "Daterange",
        new       => [ '2010-02-11', '2015-06-16' ],
        as_string => '2010-02-11 to 2015-06-16',
    },
    {
        name      => "person1",
        type      => "Person",
        new       => 2,
        as_string => "User2, User2",
    },
    {
        name => "file1",
        type => "File",
        new  => {
            name     => 'file2.txt',
            mimetype => 'text/plain',
            content  => 'Text file2',
        },
        as_string => "file2.txt",
    },
);

foreach my $col (@cols)
{
    my $test_col = $columns->{ $col->{name} };
    ok($test_col, "Column found");

    $record->find_current_id(1);

    
    if($col->{new}) {
        $record->fields->{ $test_col->id }->set_value($col->{new});
        $record->write(no_alerts => 1);
    }

    my $newval = $col->{as_string} || $col->{new};

    is(
        $record->fields->{ $test_col->id }->as_string,
        $newval, "Intial value correct",
    );

    my $current = $schema->resultset('Current')->find(1);

    foreach my $rec_rs ($current->records)
    {
        my $datum = $schema->resultset($col->{type})->search({
            record_id => $rec_rs->id,
            layout_id => $test_col->id,
        })->next;
        ok($datum,        "Datum found");
        ok($datum->value, "Datum is not blank to begin");
    }

    $current->historic_purge($sheet->user, ($test_col->id));

    $record->find_current_id(1);

    ok(!$record->fields->{ $test_col->id }->as_string, "Value now blanked")
        unless $col->{type} eq 'File';
    is(
        $record->fields->{ $test_col->id }->as_string,
        'Purged', "Value now blanked",
    ) if $col->{type} eq 'File';

    foreach my $rec_rs ($current->records)
    {
        my $datum = $schema->resultset($col->{type})->search({
            record_id => $rec_rs->id,
            layout_id => $test_col->id,
        })->next;
        ok(!$datum->value, "Datum is now blank");
        ok($datum->purged_by, "Purged by is set");
        ok($datum->purged_on, "Purged on is set");
        ok($datum->is_purged, "Is purged is set");

        $datum=$schema->resultset('String')->search({
            record_id => $rec_rs->id,
            layout_id => $columns->{string2}->id,
        })->next;
        ok($datum->value, "String2 is not blank");
        ok(!$datum->purged_by, "String2 purged by is not set");
        ok(!$datum->purged_on, "String2 purged on is not set");
        ok(!$datum->is_purged, "String2 is purged is not set");
    }
}

done_testing();
