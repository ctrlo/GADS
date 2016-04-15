use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use t::lib::DataSheet;

my $sheet1 = t::lib::DataSheet->new(data => [], instance_id => 1);
my $schema = $sheet1->schema;
my $sheet2 = t::lib::DataSheet->new(data => [], instance_id => 2, schema => $schema);

my $layout1 = $sheet1->layout;
my $layout2 = $sheet2->layout;
my $columns1 = $sheet1->columns;
my $columns2 = $sheet2->columns;

# Set link field of second sheet daterange to daterange of first sheet
$columns2->{daterange1}->link_parent_id($columns1->{daterange1}->id);
$columns2->{daterange1}->write;
$layout2->clear; # Need to rebuild columns to get link_parent built

my $record1 = GADS::Record->new(
    user     => undef,
    layout   => $layout1,
    schema   => $schema,
    base_url => undef,
);

$record1->initialise;
$record1->fields->{$columns1->{daterange1}->id}->set_value(['2010-10-10', '2012-10-10']);
$record1->write(no_alerts => 1);

my $record2 = GADS::Record->new(
    user     => undef,
    layout   => $layout2,
    schema   => $schema,
    base_url => undef,
);

$record2->initialise;
$record2->fields->{$columns2->{daterange1}->id}->set_value(['2010-10-10', '2012-10-10']);
$record2->write(no_alerts => 1);

$record2->clear;

$record2->linked_id($record1->current_id);
$record2->initialise;
$record2->fields->{$columns2->{string1}->id}->set_value('Foo');
$record2->write(no_alerts => 1);
$record2->write_linked_id;

my @filters = (
    {
        rules => [{
            id       => $columns2->{daterange1}->id,
            type     => 'daterange',
            value    => '2011-10-10',
            operator => 'contains',
        }],
        count => 2,
    },
);

foreach my $filter (@filters)
{
    my $rules = encode_json({
        rules     => $filter->{rules},
        condition => $filter->{condition},
    });

    my $view = GADS::View->new(
        filter      => $rules,
        instance_id => 2,
        layout      => $layout2,
        schema      => $schema,
        user        => undef,
    );

    my $records = GADS::Records->new(
        user    => undef,
        view    => $view,
        layout  => $layout2,
        schema  => $schema,
    );

    ok( $records->count == $filter->{count}, "Searching for record count $filter->{count}");
}

done_testing();
