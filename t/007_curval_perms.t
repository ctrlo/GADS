use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use JSON qw(encode_json);
use Log::Report;
use GADS::Layout;
use GADS::Column::Calc;
use GADS::Filter;
use GADS::Record;
use GADS::Records;
use GADS::Schema;

use t::lib::DataSheet;

my $data = [
    {
        string1    => 'Foo',
        curval1    => 1,
    },
];

my $data2 = [
    {
        string1    => 'Foo',
        integer1   => 50,
        date1      => '2014-10-10',
        daterange1 => ['2012-02-10', '2013-06-15'],
        enum1      => 1,
    },
];

my $curval_sheet = t::lib::DataSheet->new(instance_id => 2, data => $data2, user_permission_override => 0);
$curval_sheet->create_records;
my $curval_columns = $curval_sheet->columns;
my $schema  = $curval_sheet->schema;
my $sheet   = t::lib::DataSheet->new(
    data                     => $data,
    schema                   => $schema,
    multivalue               => 1,
    curval                   => 2,
    curval_field_ids         => [ $curval_columns->{string1}->id, $curval_columns->{integer1}->id ],
    user_permission_override => 0,
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

# Permissions to all curval fields
my $records = GADS::Records->new(
    user   => $sheet->user_normal1,
    layout => $layout,
    schema => $schema,
);
is($records->single->fields->{$columns->{curval1}->id}->as_string, "Foo, 50", "Curval correct with full perms");

my $record = GADS::Record->new(
    user   => $sheet->user_normal1,
    layout => $layout,
    schema => $schema,
);
$record->find_current_id(2);
is($record->fields->{$columns->{curval1}->id}->as_string, "Foo, 50", "Curval correct with full perms");

# Now remove permission from one of the curval sub-fields
my $curval_int = $curval_columns->{integer1};
$curval_int->set_permissions({});
$curval_int->write;
$curval_sheet->layout->clear;
$layout->clear;

$records->clear;
is($records->single->fields->{$columns->{curval1}->id}->as_string, "Foo", "Curval correct with limited perms");
$record->clear;
$record->find_current_id(2);
is($record->fields->{$columns->{curval1}->id}->as_string, "Foo", "Curval correct with limited perms");

# Now check that user_permission_override on layout works
{
    my $layout = GADS::Layout->new(
        user                     => undef,
        user_permission_override => 1,
        schema                   => $schema,
        config                   => GADS::Config->instance,
        instance_id              => $layout->instance_id,
    );
    my $records = GADS::Records->new(
        user   => undef,
        layout => $layout,
        schema => $schema,
    );
    my $record = $records->single;
    is($record->fields->{$columns->{curval1}->id}->as_string, "Foo, 50", "Curval correct with full perms");

    # A record's GADS::Layout is cleared for a find_current_id. Therefore the
    # override needs to be set directly on GADS::Record
    $record = GADS::Record->new(
        user                     => undef,
        user_permission_override => 1,
        layout                   => $layout,
        schema                   => $schema,
    );
    $record->find_current_id(2);
    is($record->fields->{$columns->{curval1}->id}->as_string, "Foo, 50", "Curval correct with full perms");
}

# Now with override permission
$columns->{curval1}->override_permissions(1);
$columns->{curval1}->write;
$layout->clear;

$records->clear;
is($records->single->fields->{$columns->{curval1}->id}->as_string, "Foo, 50", "Curval correct with override");
$record->clear;
$record->find_current_id(2);
is($record->fields->{$columns->{curval1}->id}->as_string, "Foo, 50", "Curval correct with override");

done_testing();
