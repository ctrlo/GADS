use Test::More; # tests => 1;
use strict;
use warnings;

use DateTime;
use JSON qw(encode_json);
use Log::Report;
use GADS::Graph;
use GADS::Graph::Data;
use GADS::Records;
use GADS::RecordsGroup;

use t::lib::DataSheet;

my $data = [
    {
        string1    => 'Foo',
        date1      => '2013-10-10',
        daterange1 => ['2014-03-21', '2015-03-01'],
        integer1   => 10,
        enum1      => 'foo1',
        curval1    => 1,
    },{
        string1    => 'Bar',
        date1      => '2014-10-10',
        daterange1 => ['2010-01-04', '2011-06-03'],
        integer1   => 15,
        enum1      => 'foo1',
        curval1    => 2,
    },
];

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema = $curval_sheet->schema;
my $sheet = t::lib::DataSheet->new(data => $data, curval => 2, schema => $schema);

my $layout = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $records = GADS::Records->new(
    user                 => undef,
    layout               => $layout,
    schema               => $schema,
);

# 4 for all main sheet1 values, plus 4 for referenced curval fields
is( @{$records->data_calendar}, 8, "Retrieving all data returns correct number of points to plot for calendar" );
$records->clear;
is( @{$records->data_timeline->{items}}, 8, "Retrieving all data returns correct number of points to plot for timeline" );

# Add a filter and only retrieve one column
my $rules = encode_json({
    rules     => [{
        id       => $columns->{string1}->id,
        type     => 'string',
        value    => 'Foo',
        operator => 'equal',
    }],
    # condition => 'AND', # Default
});

my $view = GADS::View->new(
    name        => 'Test view',
    columns     => [$columns->{date1}->id],
    filter      => $rules,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => undef,
);
$view->write;

$records = GADS::Records->new(
    user   => undef,
    layout => $layout,
    schema => $schema,
    view   => $view,
);

is( @{$records->data_calendar}, 1, "Filter and single column returns correct number of points to plot for calendar" );
$records->clear;
is( @{$records->data_timeline->{items}}, 1, "Filter and single column returns correct number of points to plot for timeline" );

# When a timeline includes a label, that column should be automatically
# included even if it's not part of the view
$records->clear;
my $items = $records->data_timeline(label => $columns->{string1}->id)->{items};
like( $items->[0]->{content}, qr/Foo/, "Label included in output even if not in view" );

# Now use the same filter and restrict by date
my $fromdt = DateTime->new(
    year       => 2010,
    month      => 01,
    day        => 01,
);
my $todt = DateTime->new(
    year       => 2020,
    month      => 01,
    day        => 01,
);

$records = GADS::Records->new(
    user   => undef,
    layout => $layout,
    schema => $schema,
    view   => $view,
    from   => $fromdt,
    to     => $todt,
);

is( @{$records->data_calendar}, 1, "Filter, single column and limited range returns correct number of points to plot for calendar" );
$records->clear;
is( @{$records->data_timeline->{items}}, 1, "Filter, single column and limited range returns correct number of points to plot for timeline" );

done_testing();
