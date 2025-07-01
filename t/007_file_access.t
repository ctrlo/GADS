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

use lib 't/lib';
use Test::GADS::DataSheet;

my $data = [
    {
        string1    => 'Foo',
        integer1   => '100',
        enum1      => 1,
        file1      => undef, # Add random file
    },
    {
        string1    => 'Bar',
        integer1   => '200',
        enum1      => 2,
        file1      => undef,
    },
];

my $sheet   = Test::GADS::DataSheet->new(
    data => $data,
);
$sheet->create_records;
my $schema       = $sheet->schema;
my $layout       = $sheet->layout;
my $columns      = $sheet->columns;
my $user         = $sheet->user;
my $limited_user = $sheet->user_normal1;

# Add a view limit
my $rules = GADS::Filter->new(
    as_hash => {
        rules     => [{
            id       => $columns->{enum1}->id,
            type     => 'string',
            value    => 'foo1',
            operator => 'equal',
        }],
    },
);

my $view_limit = GADS::View->new(
    name        => 'Limit to view',
    filter      => $rules,
    global      => 1,
    instance_id => 1,
    layout      => $layout,
    schema      => $schema,
    user        => $user,
);
$view_limit->write;

$limited_user->set_view_limits([$view_limit->id]);

$layout->clear;

# Test for get file from record which has limited view
{
    my $record = GADS::Record->new(
        user   => $limited_user,
        schema => $schema,
        layout => $layout,
    );

    # Check access to normal record
    $record->find_current_id(1);
    ok($record, "Retrieved record successfully");

    # Check record is limited normally
    my $current_id = 2;
    $record->clear;
    try { $record->find_current_id($current_id) };
    like($@, qr/not found/, "Cannot access limited record");

    # Check direct access to file is limited
    my $fileval_id = $schema->resultset('Fileval')->search({
        'record.current_id' => $current_id,
    },{
        join => {
            files => 'record',
        },
    })->next->id;

    try { $schema->resultset('Fileval')->find_with_permission($fileval_id, $limited_user) };
    like($@, qr/not found/, "Unable to retrieve limited file");
}

# Test for file inaccessible due to field permissions
{
    my $fileval_id = $schema->resultset('Fileval')->search({
        'record.current_id' => 1,
    },{
        join => {
            files => 'record',
        },
    })->next->id;

    # Check normal access first
    try { $schema->resultset('Fileval')->find_with_permission($fileval_id, $limited_user) };
    ok(!$@, "Can retrieve accessible file");

    my $filecol = $columns->{file1};
    # Remove all permissions
    $filecol->set_permissions({$sheet->group->id => []});
    $filecol->write;
    try { $schema->resultset('Fileval')->find_with_permission($fileval_id, $limited_user) };
    like($@, qr/not have access/, "Unable to retrieve limited file");
}

done_testing();
