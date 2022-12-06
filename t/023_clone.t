use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

my $curval_sheet = Test::GADS::DataSheet->new(instance_id => 2);
$curval_sheet->create_records;
my $schema  = $curval_sheet->schema;

my $data = [
    {
        integer1   => 150,
        string1    => 'Foobar',
        curval1    => 1,
        date1      => '2010-01-01',
        daterange1 => ['2011-02-02', '2012-02-02'],
        enum1      => 'foo1',
        tree1      => 'tree1',
    },
];

my $sheet   = Test::GADS::DataSheet->new(
    data             => $data,
    schema           => $schema,
    curval           => 2,
    curval_field_ids => [ $curval_sheet->columns->{string1}->id ],
);
my $layout  = $sheet->layout;
my $columns = $sheet->columns;
$sheet->create_records;

$curval_sheet->add_autocur(
    refers_to_instance_id => 1,
    related_field_id      => $columns->{curval1}->id,
    curval_field_ids      => [$columns->{string1}->id],
);

my @colnames = keys %{$data->[0]};
my $curval = $columns->{curval1};
my $string = $columns->{string1};

my $record = GADS::Record->new(
    user   => $sheet->user_normal1,
    layout => $layout,
    schema => $schema,
);
$record->find_current_id(3);
is($record->fields->{$string->id}->as_string, "Foobar", "String correct to begin with");
is($record->fields->{$curval->id}->as_string, 'Foo', "Curval correct to begin with");
my $ids = join '', @{$record->fields->{$curval->id}->ids};

# Standard clone first
for my $reload (0..1)
{
    my $record = GADS::Record->new(
        user   => $sheet->user_normal1,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id(3);
    my $cloned = $record->clone;

    my %expected = map { $_ => $data->[0]->{$_} } @colnames;
    $expected{daterange1} = "2011-02-02 to 2012-02-02";
    $expected{curval1} = "Foo";

    # Check after initial clone (before write) to see whether this is correct
    # for use in the HTML form
    foreach my $colname (@colnames)
    {
        is($cloned->fields->{$columns->{$colname}->id}->as_string, $expected{$colname}, "$colname correct after cloning (pre-write)");
        my ($textall) = @{$cloned->fields->{$columns->{$colname}->id}->text_all};
        is($textall, $expected{$colname}, "Textall for $colname correct after cloning (pre-write)");
    }

    my %vals = map {
        $columns->{$_}->id => $cloned->fields->{$columns->{$_}->id}->html_form
    } @colnames;

    if ($reload)
    {
        $cloned = GADS::Record->new(
            user   => $sheet->user_normal1,
            layout => $layout,
            schema => $schema,
        );
        $cloned->initialise(instance_id => 1);
        $cloned->fields->{$_}->set_value($vals{$_})
            foreach keys %vals;
    }

    # Check after write, to see whether that is correct too
    $cloned->write(no_alerts => 1);
    my $cloned_id = $cloned->current_id;
    $cloned->clear;
    $cloned->find_current_id($cloned_id);
    foreach my $colname (@colnames)
    {
        if ($colname eq 'curval1')
        {
            #is($cloned->fields->{$curval->id}->as_string, "Foo", "Curval correct after cloning");
            my $ids_new = join '', @{$cloned->fields->{$curval->id}->ids};
            is($ids_new, $ids, "ID of newly written field same");
        }
        is($cloned->fields->{$columns->{$colname}->id}->as_string, $expected{$colname}, "$colname correct after cloning");
        is($_, $expected{$colname}, "Textall for $colname correct after cloning")
            foreach @{$cloned->fields->{$columns->{$colname}->id}->text_all};
    }
}

# Set up curval to be allow adding and removal
$curval->show_add(1);
$curval->value_selector('noshow');
$curval->write(no_alerts => 1);

$record->clear;
$record->find_current_id(3);

# Clone the record and write with no updates
my $cloned = $record->clone;
$cloned->write(no_alerts => 1);
my $cloned_id = $cloned->current_id;
$cloned->clear;
$cloned->find_current_id($cloned_id);
is($cloned->fields->{$string->id}->as_string, "Foobar", "String correct after cloning");
is($cloned->fields->{$curval->id}->as_string, "Foo", "Curval correct after cloning");
my $ids_new = join '', @{$cloned->fields->{$curval->id}->ids};
isnt($ids, $ids_new, "ID of newly written field different");

# Clone the record and update with no changes (as for HTML form submission)
for my $reload (0..1)
{
    my $record = GADS::Record->new(
        user   => $sheet->user_normal1,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id(3);
    $cloned = $record->clone;
    my $curval_datum = $cloned->fields->{$curval->id};
    my @vals = map { $_->{as_query} } @{$curval_datum->html_form};
    ok("@vals", "HTML form has record as query");
    is(@vals, 1, "One record in form value");
    if ($reload) # Start writing to virgin record, as per new record submission
    {
        $cloned = GADS::Record->new(
            user   => $sheet->user_normal1,
            layout => $layout,
            schema => $schema,
        );
        $cloned->initialise(instance_id => 1);
        $curval_datum = $cloned->fields->{$curval->id};
        $cloned->fields->{$string->id}->set_value('Foobar');
    }
    $curval_datum->set_value([@vals]);
    $cloned->write(no_alerts => 1);
    $cloned_id = $cloned->current_id;
    $cloned->clear;
    $cloned->find_current_id($cloned_id);
    is($cloned->fields->{$string->id}->as_string, "Foobar", "String correct after cloning");
    is($cloned->fields->{$curval->id}->as_string, "Foo", "Curval correct after cloning");
    $ids_new = join '', @{$cloned->fields->{$curval->id}->ids};
    isnt($ids, $ids_new, "ID of newly written field different");
}

# Clone the record and update with changes (as for HTML form submission edit)
foreach my $reload (0..1)
{
    my $record = GADS::Record->new(
        user   => $sheet->user_normal1,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id(3);
    $cloned = $record->clone;
    my $curval_datum = $cloned->fields->{$curval->id};
    my @vals = map { $_->{as_query} } @{$curval_datum->html_form};
    s/Foo/Foo2/ foreach @vals;
    if ($reload)
    {
        $cloned = GADS::Record->new(
            user   => $sheet->user_normal1,
            layout => $layout,
            schema => $schema,
        );
        $cloned->initialise(instance_id => 1);
        $curval_datum = $cloned->fields->{$curval->id};
        $cloned->fields->{$string->id}->set_value('Foobar');
    }
    $curval_datum->set_value([@vals]);
    $cloned->write(no_alerts => 1);
    $cloned_id = $cloned->current_id;
    $cloned->clear;
    $cloned->find_current_id($cloned_id);
    is($cloned->fields->{$string->id}->as_string, "Foobar", "String correct after cloning");
    is($cloned->fields->{$curval->id}->as_string, "Foo2", "Curval correct after cloning");
    $ids_new = join '', @{$cloned->fields->{$curval->id}->ids};
    isnt($ids, $ids_new, "ID of newly written field different");
}

done_testing();
