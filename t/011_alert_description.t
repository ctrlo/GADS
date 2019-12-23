use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use GADS::Config;
use GADS::Group;
use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

my $config = GADS::Config->instance;
$config->config({ gads => { url => 'localhost' } });

my $sheet   = Test::GADS::DataSheet->new;
my $schema  = $sheet->schema;
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

# Create a group with read access of only one field
my $limited_group  = GADS::Group->new(schema => $schema);
$limited_group->name('Limited');
$limited_group->write;

my $string1 = $columns->{string1};
my $enum1 = $columns->{enum1};
$string1->set_permissions({
    $sheet->group->id  => $sheet->default_permissions,
    $limited_group->id => $sheet->default_permissions,
});
$string1->write;

my $user_normal1 = $sheet->user_normal1;
$user_normal1->groups($sheet->user, [$limited_group->id]);

my @tests = (
    {
        alert_columns => [$string1->id, $enum1->id],
        desc_limited  => 'Foo',
        desc_normal   => 'Foo, foo1',
        link_limited  => '<a href="localhost/record/1">Foo</a>',
        link_normal   => '<a href="localhost/record/1">Foo, foo1</a>',
        current_ids   => 1,
    },
    {
        alert_columns => [],
        desc_limited  => 'record ID 1',
        desc_normal   => 'record ID 1',
        link_limited  => 'record <a href="localhost/record/1">ID 1</a>',
        link_normal   => 'record <a href="localhost/record/1">ID 1</a>',
        current_ids   => 1,
    },
    {
        alert_columns => [$string1->id, $enum1->id],
        desc_limited  => 'Foo; Bar',
        desc_normal   => 'Foo, foo1; Bar, foo2',
        link_limited  => '<a href="localhost/record/1">Foo</a>; <a href="localhost/record/2">Bar</a>',
        link_normal   => '<a href="localhost/record/1">Foo, foo1</a>; <a href="localhost/record/2">Bar, foo2</a>',
        current_ids   => [1, 2],
    },
    {
        alert_columns => [],
        desc_limited  => 'record IDs 1, 2',
        desc_normal   => 'record IDs 1, 2',
        link_limited  => 'records <a href="localhost/record/1">ID 1</a>, <a href="localhost/record/2">ID 2</a>',
        link_normal   => 'records <a href="localhost/record/1">ID 1</a>, <a href="localhost/record/2">ID 2</a>',
        current_ids   => [1, 2],
    },
);

foreach my $test (@tests)
{
    my $alert_description = GADS::AlertDescription->new(
        schema => $schema,
    );

    $layout->set_alert_columns($test->{alert_columns});
    $layout->write;
    $layout->clear;

    my $desc = $alert_description->description(
        instance_id  => $layout->instance_id,
        current_ids  => $test->{current_ids},
        user         => $sheet->user,
    );

    is($desc, $test->{desc_normal}, "Alert description correct for normal user");

    my $link = $alert_description->link(
        instance_id  => $layout->instance_id,
        current_ids  => $test->{current_ids},
        user         => $sheet->user,
    );

    is($link, $test->{link_normal}, "Alert link correct for normal user");

    $desc = $alert_description->description(
        instance_id  => $layout->instance_id,
        current_ids  => $test->{current_ids},
        user         => $user_normal1,
    );

    is($desc, $test->{desc_limited}, "Alert description correct for limited user");

    $link = $alert_description->link(
        instance_id  => $layout->instance_id,
        current_ids  => $test->{current_ids},
        user         => $user_normal1,
    );

    is($link, $test->{link_limited}, "Alert link correct for limited user");
}

done_testing();
