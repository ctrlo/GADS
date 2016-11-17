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

# Clear the record object and write a new one, this time with the
# date blank but linked to the first sheet with a date value
$record2->clear;

$record2->linked_id($record1->current_id);
$record2->initialise;
$record2->fields->{$columns2->{string1}->id}->set_value('Foo');
$record2->write(no_alerts => 1);
$record2->write_linked_id;

my @filters = (
    {
        name  => 'Basic',
        rules => [{
            id       => $columns2->{daterange1}->id,
            type     => 'daterange',
            value    => '2011-10-10',
            operator => 'contains',
        }],
        values => [
            'string1: ,integer1: ,enum1: ,tree1: ,date1: ,daterange1: 2010-10-10 to 2012-10-10,file1: ,person1: ,rag1: b_red,calc1: 2010,',
            'string1: Foo,integer1: ,enum1: ,tree1: ,date1: ,daterange1: 2010-10-10 to 2012-10-10,file1: ,person1: ,rag1: b_red,calc1: 2010,',
        ],
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
        name        => $filter->{name},
        filter      => $rules,
        columns     => [map { $_->id } values %$columns2],
        instance_id => 2,
        layout      => $layout2,
        schema      => $schema,
        user        => undef,
    );
    $view->write;

    my $records = GADS::Records->new(
        user    => undef,
        view    => $view,
        layout  => $layout2,
        schema  => $schema,
    );

    is( $records->count, $filter->{count}, "Correct record count for filter $filter->{name}");

    foreach my $expected (@{$filter->{values}})
    {
        my $retrieved = $records->single;
        my $got = '';
        $got .= $_->name.': ' . $retrieved->fields->{$_->id} . ','
            foreach sort { $a->id <=> $b->id } values %$columns2;
        is( $got, $expected, "Retrieved data correct for test $filter->{name} ID ".$retrieved->current_id );
    }
}

done_testing();
