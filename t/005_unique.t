use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Record;

use lib 't/lib';
use Test::GADS::DataSheet;

my $data = {
    string1    => 'Bar',
    integer1   => 99,
    date1      => '2009-01-02',
    enum1      => 1,
    tree1      => 4,
    daterange1 => ['2008-05-04', '2008-07-14'],
    person1    => 1,
    file1 => {
        name     => 'file1.txt',
        mimetype => 'text/plain',
        content  => 'Text file1',
    },
};

my $sheet = Test::GADS::DataSheet->new(
    data => [$data],
    calc_code => 'function evaluate (L1string1)
        return L1string1
    end',
    calc_return_type => 'string',
);
$sheet->create_records;
my $columns = $sheet->columns;
my $layout  = $sheet->layout;

my $record = GADS::Record->new(
    user     => $sheet->user,
    layout   => $sheet->layout,
    schema   => $sheet->schema,
);
$record->initialise;

foreach my $col ($layout->all(userinput => 1))
{
    $col->isunique(1);
    $col->write;
    $layout->clear;
    $record->fields->{$col->id}->set_value($data->{$col->name});
    try { $record->write(no_alerts => 1) };
    like($@, qr/must be unique but value .* already exists/, "Failed to write unique existing value for ".$col->name);
    $col->isunique(0);
    $col->write;
}

# Now calc unique values
{
    my $calc = $columns->{calc1};
    $calc->isunique(1);
    $calc->write;
    $layout->clear;
    $record->fields->{$calc->id}->set_value($data->{string1});
    try { $record->write(no_alerts => 1) };
    like($@, qr/must be unique but value .* already exists/, "Failed to write unique existing value for calc value");
    $record->clear;
    $record->initialise(instance_id => 1);
    $calc->isunique(0);
    $calc->write;
}

# Calc with child unique
{
    # Make calc column unique
    my $calc = $columns->{calc1};
    $calc->isunique(1);
    $calc->write;
    $layout->clear;

    # First a write that will fail, which is the string value that will cause
    # the calc value to be a duplicate. This will cause a unique error as the
    # string is field in the calc and therefore the calc needs to be unique
    my $string1 = $columns->{string1};
    $string1->set_can_child(1);
    $string1->write;
    $layout->clear;

    # Create child
    my $child = GADS::Record->new(
        user   => $sheet->user,
        layout => $layout,
        schema => $sheet->schema,
    );
    $child->parent_id(1);
    $child->initialise;

    $child->fields->{$string1->id}->set_value($data->{string1});
    try { $child->write(no_alerts => 1) };
    like($@, qr/must be unique but value .* already exists/, "Failed to write unique existing value for calc-dependent value");

    # Now make string value not a child value, which will mean that the even
    # though the child calc value is the same, it will be accepted as it is
    # copied from the parent.
    #
    # Make date field the child field instead
    my $date1 = $columns->{date1};
    $date1->set_can_child(1);
    $date1->write;
    $string1->set_can_child(0);
    $string1->write;
    $layout->clear;

    # Restart child record
    $child->clear;
    $child->parent_id(1);
    $child->initialise(instance_id => 1);
    $child->fields->{$date1->id}->set_value('2013-10-10');
    try { $child->write(no_alerts => 1) };
    ok(!$@, "Wrote child with duplicate calc value");
    is($child->fields->{$calc->id}->as_string, $data->{string1}, "Duplicated child calc written");
}

# Calc unique value that the user does not have access to
{
    my $calc = $columns->{calc1};
    $calc->isunique(1);
    $calc->set_permissions({$sheet->group->id => []});
    $calc->write;
    $layout->clear;

    my $string1 = $columns->{string1};

    # First value that already exists
    $record->fields->{$string1->id}->set_value($data->{string1});
    try { $record->write(no_alerts => 1) };
    like($@, qr/must be unique but value .* already exists/, "Failed to write unique existing value for calc value");

    # Then value that does not exist
    $record->clear;
    $record->initialise(instance_id => 1);
    $record->fields->{$string1->id}->set_value('XXX');
    $record->write(no_alerts => 1);
    my $cid = $record->current_id;
    $record->clear;
    $record->find_current_id($cid);
    is($record->fields->{$string1->id}->as_string, "XXX");

    $calc->isunique(0);
    $calc->write;
}

done_testing();
