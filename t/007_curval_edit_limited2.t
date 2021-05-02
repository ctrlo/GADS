use Test::More; # tests => 1;
use strict;
use warnings;
use utf8;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

# Tests for curval edit values that are within a curval table that is limited
# by a view. The view limit on the curval table depends on both values in the
# main table and values in the curval table. These tests ensure that:
# - Values not visible by the user are unchanged
# - Values that are no longer visible by the user after being edited can still
#   be removed (i.e. if as a result of the user removing the curval value they no
#   longer have access to it, the removal can still take place)

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

# Tests:
# 1. Deletion of records in the curval table once they are removed from the main record
# 2. Normal removal of curval values which the user then no longer has access to
# 3. Resave of curval value, ensuring that other records the user never had access to are unchanged
# 4. Same as (3) but with the user changing a curval value

foreach my $test (qw/delete_not_used normal noaccess noaccess_changed/)
{
    # Set up tables

    my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2, data => $data);
    $curval_sheet->create_records;
    my $schema = $curval_sheet->schema;

    my $sheet = Test::GADS::DataSheet->new(
        multivalue       => 1,
        schema           => $schema,
        instance_id      => 1,
        data             => [],
        curval           => 2,
        curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
    );
    $sheet->create_records;
    my $columns = $sheet->columns;

    my $curval = $sheet->columns->{curval1};
    $curval->delete_not_used($test eq 'normal' ? 0 : 1);
    $curval->show_add(1);
    $curval->value_selector('noshow');
    $curval->write(no_alerts => 1);

    # Add autocur, this will be used in the limited view filter
    my $autocur = $curval_sheet->add_autocur(
        refers_to_instance_id => 1,
        related_field_id      => $curval->id,
        curval_field_ids      => [$sheet->columns->{string1}->id],
    );

    # The limited view for the user
    my $rules = GADS::Filter->new(
        as_hash => {
            rules     => [
                {
                    id       => $autocur->id."_".$columns->{string1}->id,
                    type     => 'string',
                    value    => 'Apples',
                    operator => 'equal',
                },
                {
                    id       => $curval_sheet->columns->{string1}->id,
                    type     => 'string',
                    value    => 'Access',
                    operator => 'begins_with',
                },
            ],
            condition => 'OR',
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

    # Create record as administrator with various data in its curval field
    my $record = GADS::Record->new(
        user   => $sheet->user,
        layout => $sheet->layout,
        schema => $schema,
    );
    $record->initialise;
    $record->fields->{$columns->{string1}->id}->set_value($test =~ /noaccess/ ? 'Bananas' : 'Apples');
    $record->fields->{$curval->id}->set_value([
        $curval_sheet->columns->{string1}->field."=Brown&"
        .$curval_sheet->columns->{integer1}->field."=65",
        $curval_sheet->columns->{string1}->field."=Smith&"
        .$curval_sheet->columns->{integer1}->field."=32",
        $curval_sheet->columns->{string1}->field."=Access&"
        .$curval_sheet->columns->{integer1}->field."=93",
        $curval_sheet->columns->{string1}->field."=Access2&"
        .$curval_sheet->columns->{integer1}->field."=44",
    ]);
    $record->write(no_alerts => 1);
    my $cid = $record->current_id;

    # Check the written values as a normal user
    $record = GADS::Record->new(
        user   => $normal_user,
        layout => $sheet->layout,
        schema => $schema,
    );
    $record->find_current_id($cid);
    my $curval_value = $record->fields->{$curval->id};
    is($curval_value->as_string, $test =~ /noaccess/ ? "Access; Access2" : "Access; Access2; Brown; Smith", "Correct curval as normal user");

    # Now remove one of the curval values as a normal user. Once the curval
    # values is removed the record will no longer be visible to the user
    # writing, but that should not prevent the write taking place
    my @values = @{$curval_value->values};
    my $regex = $test eq 'noaccess'
        ? qr/access/i
        : $test eq 'noaccess_changed'
        ? qr/^access$/i
        : qr/(access|brown)/i;
    my @ids = map $_->{id}, grep $_->{value} =~ $regex, @values;
    $record->fields->{$columns->{integer1}->id}->set_value('1234'); # Ensure change in record
    $curval_value->set_value(\@ids);
    $record->write(no_alerts => 1);

    # Check the value as the normal user
    $record->clear;
    $record->find_current_id($cid);
    $curval_value = $record->fields->{$curval->id};
    my $expected = $test eq 'noaccess'
        ? "Access; Access2"
        : $test eq 'noaccess_changed'
        ? "Access"
        : "Access; Access2; Brown";
    is($curval_value->as_string, $expected, "Correct curval value to normal user after edit");

    # If the test means that the user never had access to one of the curval
    # values then check that is still there as an administrator
    if ($test =~ /noaccess/)
    {
        my $layout = $sheet->layout;
        $layout->user($sheet->user);
        $layout->clear;
        $record = GADS::Record->new(
            user   => $sheet->user,
            layout => $layout,
            schema => $schema,
        );
        $record->find_current_id($cid);
        my $curval_value = $record->fields->{$curval->id};
        is($curval_value->as_string, $test eq 'noaccess' ? "Access; Access2; Brown; Smith" : "Access; Brown; Smith", "Correct age");
    }
}

done_testing();
