use Test::More; # tests => 1;
use strict;
use warnings;

use GADS::Records;
use Log::Report;

use t::lib::DataSheet;

foreach my $multivalue (0..1)
{
    # It doesn't make a lot of sense to test a lot of these values, as the grouping
    # of text fields is not really possible (instead, the max value is used).
    # However, add them to the tests, to check that if a user does add them to a
    # grouping view that something unexpected doesn't happen
    my $data = [
        {
            string1    => 'foo1',
            integer1   => 25,
            date1      => '2011-10-10',
            daterange1 => ['2000-01-02', '2001-03-03'],
            enum1      => 7,
            tree1      => 12,
            curval1    => 1,
        },
        {
            string1    => 'foo1',
            integer1   => 50,
            date1      => '2012-10-10',
            daterange1 => ['2004-01-02', '2005-03-03'],
            enum1      => $multivalue ? [7,9] : 7,
            tree1      => 12,
            curval1    => 1,
        },
        {
            string1    => 'foo2',
            integer1   => 60,
            date1      => '2009-10-10',
            daterange1 => ['2007-01-02', '2007-03-03'],
            enum1      => 8,
            tree1      => 11,
            curval1    => 2,
        },
        {
            string1    => 'foo2',
            integer1   => 70,
            date1      => '2008-10-10',
            daterange1 => ['2001-01-02', '2001-03-03'],
            enum1      => 8,
            tree1      => 11,
            curval1    => 2,
        },
    ];

    my $expected = [
        {
            string1    => 'foo1',
            integer1   => 75,
            calc1      => 150,
            date1      => '2012-10-10',
            daterange1 => '2004-01-02 to 2005-03-03',
            enum1      => $multivalue ? 'foo3' : 'foo1',
            tree1      => 'tree3',
            curval1    => 'Foo',
        },
        {
            string1    => 'foo2',
            integer1   => 130,
            calc1      => 260,
            date1      => '2009-10-10',
            daterange1 => '2007-01-02 to 2007-03-03',
            enum1      => 'foo2',
            tree1      => 'tree2',
            curval1    => 'Bar',
        },
    ];

    my $curval_sheet = t::lib::DataSheet->new(instance_id => 2);
    $curval_sheet->create_records;
    my $schema = $curval_sheet->schema;

    my $sheet   = t::lib::DataSheet->new(
        data             => $data,
        calc_code        => "function evaluate (L1integer1) \n return L1integer1 * 2 \n end",
        schema           => $schema,
        curval           => 2,
        curval_field_ids => [$curval_sheet->columns->{string1}->id],
        multivalue       => $multivalue,
        multivalue_columns => {enum => 1},
    );

    my $layout  = $sheet->layout;
    $sheet->create_records;
    my $columns = $sheet->columns;

    my $autocur = $curval_sheet->add_autocur(
        refers_to_instance_id => 1,
        related_field_id      => $columns->{curval1}->id,
        curval_field_ids      => [$columns->{string1}->id],
    );

    my $string1    = $columns->{string1};
    my $integer1   = $columns->{integer1};
    my $calc1      = $columns->{calc1};
    my $date1      = $columns->{date1};
    my $daterange1 = $columns->{daterange1};
    my $enum1      = $columns->{enum1};
    my $tree1      = $columns->{tree1};
    my $curval1    = $columns->{curval1};

    my $view = GADS::View->new(
        name        => 'Group view',
        columns     => [$string1->id, $integer1->id, $calc1->id, $date1->id, $daterange1->id, $enum1->id, $tree1->id, $curval1->id],
        instance_id => $layout->instance_id,
        layout      => $layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view->write;
    $view->set_groups([$string1->id]);
    # Also add a sort, to check that doesn't result in unwanted multi-value
    # field joins
    $view->set_sorts([$enum1->id], ['asc']);

    my $records = GADS::Records->new(
        view   => $view,
        layout => $layout,
        user   => $sheet->user,
        schema => $schema,
    );

    my @results = @{$records->results};
    is(@results, 2, "Correct number of rows for group by string");

    my @expected = (@$expected);
    foreach my $row (@results)
    {
        my $expected = shift @expected;
        is($row->fields->{$string1->id}, $expected->{string1}, "Group text correct");
        is($row->fields->{$integer1->id}, $expected->{integer1}, "Group integer correct");
        is($row->fields->{$calc1->id}, $expected->{calc1}, "Group calc correct");
        is($row->fields->{$date1->id}, $expected->{date1}, "Group date correct");
        is($row->fields->{$daterange1->id}, $expected->{daterange1}, "Group daterange correct");
        is($row->fields->{$enum1->id}, $expected->{enum1}, "Group enum correct");
        is($row->fields->{$tree1->id}, $expected->{tree1}, "Group tree correct");
        is($row->fields->{$curval1->id}, $expected->{curval1}, "Group curval correct");
        is($row->id_count, 2, "ID count correct");
    }

    # Remove grouped column from view and check still gets added as required
    $view->columns([$integer1->id]);
    $view->write;

    @expected = (@$expected);
    $records->clear;
    $records = GADS::Records->new(
        view   => $view,
        layout => $layout,
        user   => $sheet->user,
        schema => $schema,
    );
    @results = @{$records->results};
    is(@results, 2, "Correct number of rows for group by string");
    foreach my $row (@results)
    {
        my $expected = shift @expected;
        is($row->fields->{$string1->id}, $expected->{string1}, "Group text correct");
        is($row->fields->{$integer1->id}, $expected->{integer1}, "Group integer correct");
    }

    # Test autocur
    $view = GADS::View->new(
        name        => 'Group view autocur',
        columns     => [$autocur->id],
        instance_id => $curval_sheet->layout->instance_id,
        layout      => $curval_sheet->layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view->write;
    $view->set_groups([$curval_sheet->columns->{string1}->id]);

    $records = GADS::Records->new(
        view   => $view,
        layout => $curval_sheet->layout,
        user   => $sheet->user,
        schema => $schema,
    );

    @results = @{$records->results};
    is(@results, 2, "Correct number of rows for group by string with autocur");
    @expected = qw/foo2 foo1/; # Sorting does not currently work in group views
    foreach my $row (@results)
    {
        my $exp = shift @expected;
        is($row->fields->{$autocur->id}, $exp, "Group text correct");
    }

}

# Large number of records (greater than default number of rows in table). Check
# that paging does not affect results
{
    my @data;
    my %group_values;
    for my $count (1..300)
    {
        my $id = substr $count, -1;
        push @data, {
            string1  => "Foo$id",
            integer1 => $id * 10,
        };
    }

    my $sheet = t::lib::DataSheet->new(data => \@data);
    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $columns  = $sheet->columns;
    my $string1  = $columns->{string1};
    my $integer1 = $columns->{integer1};

    my $view = GADS::View->new(
        name        => 'Group view large',
        columns     => [$string1->id, $integer1->id],
        instance_id => $layout->instance_id,
        layout      => $layout,
        schema      => $schema,
        user        => $sheet->user,
    );
    $view->write;
    $view->set_groups([$string1->id]);

    my $records = GADS::Records->new(
        # Specify rows parameter to simulate default used for table view. This
        # should be ignored
        rows   => 50,
        page   => 1,
        view   => $view,
        layout => $layout,
        user   => $sheet->user,
        schema => $schema,
    );

    my @results = @{$records->results};
    is(@results, 10, "Correct number of rows for group of large number of records");
    is($records->pages, 1, "Correct number of pages for large number of records");

    my @expected = (
        {
            string1  => 'Foo0',
            integer1 => 0,
        },
        {
            string1  => 'Foo1',
            integer1 => 300,
        },
        {
            string1  => 'Foo2',
            integer1 => 600,
        },
        {
            string1  => 'Foo3',
            integer1 => 900,
        },
        {
            string1  => 'Foo4',
            integer1 => 1200,
        },
        {
            string1  => 'Foo5',
            integer1 => 1500,
        },
        {
            string1  => 'Foo6',
            integer1 => 1800,
        },
        {
            string1  => 'Foo7',
            integer1 => 2100,
        },
        {
            string1  => 'Foo8',
            integer1 => 2400,
        },
        {
            string1  => 'Foo9',
            integer1 => 2700,
        },
    );
    foreach my $row (@results)
    {
        my $expected = shift @expected;
        is($row->fields->{$string1->id}, $expected->{string1}, "Group text correct");
        is($row->fields->{$integer1->id}, $expected->{integer1}, "Group integer correct");
        is($row->id_count, 30, "ID count correct for large records group");
    }

}

done_testing();
