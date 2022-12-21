use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# A test for checking use of all types of field within a calc's curval

my $cdata = [{
    string1    => 'foobar',
    person1    => 1,
    integer1   => 999,
    date1      => '2020-03-03',
    daterange1 => ['2019-01-02', '2019-02-01'],
    enum1      => 1,
    tree1      => 4,
}];

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, site_id => 1, data => $cdata);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;

my $cperson = $curval_sheet->columns->{person1};
$cperson->name_short('L2person1');
$cperson->write;
$curval_sheet->layout->clear;

my $data = [{
    string1 => 'Foobar',
    curval1 => 1,
}];

my $sheet   = Test::GADS::DataSheet->new(
    data             => $data,
    schema           => $schema,
    curval           => 2,
    curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
    calc_return_type => 'string',
    calc_code        => qq{function evaluate (L1curval1)
        if L1curval1 == nil then
            return "test"
        end
        return L1curval1.field_values.L2string1
            .. L1curval1.field_values.L2integer1
            .. L1curval1.field_values.L2person1.surname
            .. L1curval1.field_values.L2date1.ymd
            .. L1curval1.field_values.L2daterange1.to.ymd
            .. L1curval1.field_values.L2enum1
            .. L1curval1.field_values.L2tree1.value
    end},
);

my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

my $calc = $columns->{calc1};

my $record = GADS::Record->new(
    user   => $sheet->user_normal1,
    layout => $layout,
    schema => $schema,
);
$record->find_current_id(2);
is($record->fields->{$calc->id}->as_string, "foobar999User12020-03-032019-02-01foo1tree1", "Main calc correct");

done_testing();
