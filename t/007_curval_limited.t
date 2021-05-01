use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Tests for curval fields that contain values from a table which the user only
# has limited access to.
#
# The user in these tests only has access to values in the curval field that
# are "foo1".
#
# Expected behaviour: if the curval field is single value, then the change they
# make will overwrite the current value. If the curval field is a multivalue
# field, then do not show the user the value they do not have access to and
# also do not remove it when they update it.

foreach my $multivalue (0..1)
{
    my $data = [
        {
            string1 => 'Newcastle',
            enum1   => 'foo1',
        },
        {
            string1 => 'Liverpool',
            enum1   => 'foo2',
        },
        {
            string1 => 'York',
            enum1   => 'foo1',
        },
    ];
    my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, data => $data);
    $curval_sheet->create_records;
    my $curval_columns = $curval_sheet->columns;
    my $curval_layout  = $curval_sheet->layout;
    $curval_layout->sort_layout_id($curval_columns->{string1}->id);
    $curval_layout->write;
    my $schema = $curval_sheet->schema;

    # The main record always contains "Liverpool" which the user does not have
    # access to
    my $sheet = Test::GADS::DataSheet->new(
        multivalue       => $multivalue,
        schema           => $schema,
        instance_id      => 1,
        data             => [
            {
                string1 => 'Project 1',
                curval1 => $multivalue ? [2,3] : [2],
            }
        ],
        curval           => 2,
        curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
    );
    $sheet->create_records;
    my $curval = $sheet->columns->{curval1};

    # Set up limited view, only allowing user to see enum value "foo1"
    my $rules = GADS::Filter->new(
        as_hash => {
            rules     => [{
                id       => $curval_sheet->columns->{enum1}->id,
                type     => 'string',
                value    => 'foo1',
                operator => 'equal',
            }],
        },
    );

    my $view_limit = GADS::View->new(
        name        => 'Limit to view',
        filter      => $rules,
        instance_id => $curval_sheet->layout->instance_id,
        layout      => $curval_sheet->layout,
        schema      => $schema,
        user        => $sheet->user,
        is_admin    => 1,
    );
    $view_limit->write;

    my $normal_user = $sheet->user_normal1;
    $normal_user->set_view_limits([$view_limit->id]);

    $sheet->layout->user($normal_user);
    $sheet->layout->clear;

    # When viewing the initial record the user never sees Liverpool, but does
    # see York for the multivalue
    my $record = GADS::Record->new(
        user   => $normal_user,
        layout => $sheet->layout,
        schema => $schema,
    );
    $record->find_current_id(4);
    is($record->fields->{$curval->id}->as_string, $multivalue ? "York" : '', "Correct age");

    # Make an edit
    $record->fields->{$curval->id}->set_value([1]); # Newcastle
    $record->write(no_alerts => 1);

    # Check value again as normal user, no access to York
    $record = GADS::Record->new(
        user   => $normal_user,
        layout => $sheet->layout,
        schema => $schema,
    );
    $record->find_current_id(4);
    is($record->fields->{$curval->id}->as_string, "Newcastle", "Correct age");

    # As admin user should see all curval values
    $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $sheet->layout,
        schema => $schema,
    );
    $record->find_current_id(4);
    # Liverpool overwritten for single value
    my $expected = $multivalue ? 'Liverpool; Newcastle' : 'Newcastle';
    is($record->fields->{$curval->id}->as_string, $expected, "Correct age");
}

done_testing();
