use Test::More; # tests => 1;
use strict;
use warnings;

use GADS::Filter;
use GADS::Records;
use Log::Report;

use lib 't/lib';
use Test::GADS::DataSheet;

foreach my $multivalue (0, 1)
{
    my $data = [
        {
            string1    => 'foo1',
            integer1   => 25,
            integer2   => 50,
            enum1      => $multivalue ? [1,2] : 1,
            person1    => 1,
        },
        {
            string1    => 'foo1',
            integer1   => 50,
            integer2   => 500,
            enum1      => 2,
            person1    => 1,
        },
        {
            string1    => 'foo2',
            integer1   => 60,
            integer2   => 60,
            enum1      => 2,
            person1    => 1,
        },
        {
            string1    => 'foo2',
            integer1   => 70,
            integer2   => 35,
            enum1      => 3,
            person1    => 1,
        },
    ];

    my $sheet   = Test::GADS::DataSheet->new(
        data         => $data,
        multivalue   => $multivalue,
        calc_code    => $multivalue
            ? "function evaluate (L1integer1, L1integer2) \n return (L1integer1[1] / L1integer2[1]) * 100 \n end"
            : "function evaluate (L1integer1, L1integer2) \n return (L1integer1 / L1integer2) * 100 \n end",
        column_count => { integer => 2 },
    );
    my $schema = $sheet->schema;
    my $layout  = $sheet->layout;
    $sheet->create_records;
    my $columns = $sheet->columns;

    my $string1  = $columns->{string1};
    my $integer1 = $columns->{integer1};
    my $integer2 = $columns->{integer2};
    my $calc1    = $columns->{calc1};
    my $enum1    = $columns->{enum1};
    my $person1  = $columns->{person1};

    my $records = GADS::Records->new(
        layout => $layout,
        user   => $sheet->user,
        schema => $schema,
    );

    my @results = @{$records->results};
    is(@results, 4, "Correct number of normal rows");

    is($records->aggregate_results, undef, "No aggregate results initially");

    $integer1->aggregate('sum');
    $integer1->write;
    $calc1->aggregate('sum');
    $calc1->write;
    $layout->clear;

    # Perform tests with and without filters
    foreach my $with_filter (0, 1)
    {
        my $rules = GADS::Filter->new(
            as_hash => {
                condition => 'OR',
                rules     => [
                    {
                        id       => $enum1->id,
                        type     => 'string',
                        value    => 'foo1',
                        operator => 'equal',
                    },
                    {
                        id       => $enum1->id,
                        type     => 'string',
                        value    => 'foo2',
                        operator => 'equal',
                    },
                ],
            },
        );
        my $view = GADS::View->new(
            name        => 'Aggregate view',
            columns     => [$string1->id, $integer1->id, $calc1->id, $person1->id],
            filter      => $with_filter && $rules,
            instance_id => $layout->instance_id,
            layout      => $layout,
            schema      => $schema,
            user        => $sheet->user,
        );
        $view->set_sorts({fields => [$enum1->id], types => ['asc']});
        $view->write;

        my $records = GADS::Records->new(
            view   => $view,
            layout => $layout,
            user   => $sheet->user,
            schema => $schema,
        );

        @results = @{$records->results};
        is(@results, $with_filter ? 3 : 4, "Correct number of normal rows");

        my $aggregate = $records->aggregate_results;

        is($aggregate->fields->{$integer1->id}->as_string, $with_filter ? 135 : 205, "Correct total of integer values");
        is($aggregate->fields->{$calc1->id}->as_string, $with_filter ? 160 : 360, "Correct total of calc values");

        # Test of recalc aggregate type, whereby calc values are recalculated based on
        # other aggregate fields. Do not include all required columns in the view -
        # this should still work
        {
            $calc1->aggregate('recalc');
            try { $calc1->write };
            my $e = qr/column integer2 does not have an aggregate defined/;
            like($@, $e, "Cannot set recalc without all required aggregate fields");
            $integer2->aggregate('sum');
            $integer2->write;
            $layout->clear;
            $calc1->aggregate('recalc');
            $calc1->write;
            $layout->clear;
            $integer2->aggregate('');
            try { $integer2->write };
            $e = qr/aggregate on this column cannot be removed/;
            like($@, $e, "Cannot remove aggregate with recalc in effect");

            $records = GADS::Records->new(
                view   => $view,
                layout => $layout,
                user   => $sheet->user,
                schema => $schema,
            );

            @results = @{$records->results};
            is(@results, $with_filter ? 3 : 4, "Correct number of normal rows");

            my $aggregate = $records->aggregate_results;

            is($aggregate->fields->{$integer1->id}->as_string, $with_filter ? 135 : 205, "Correct total of integer values");
            is($aggregate->fields->{$integer2->id}->as_string, $with_filter ? 610 : 645, "Correct total of integer values");
            is($aggregate->fields->{$calc1->id}->as_string, $with_filter ? 22 : 32, "Correct total of calc values");

            $calc1->aggregate('sum');
            $calc1->write;
            $integer2->aggregate('');
            $integer2->write;
            $layout->clear;
        }

        # Perform test for multivalue field within set of records that will be
        # aggregated, where the multivalue field is grouped. This checks for
        # double-counting of rows, which we do want for each group, but not for the
        # total aggregate
        {
            $view->set_groups([$enum1->id]);
            $view->write;
            $records->clear;

            @results = @{$records->results};
            is(@results, $with_filter ? 2 : 3, "Correct number of normal rows");

            # For the multivalue, the sum of the groups adds up to more than the
            # total aggregate. This is because one record appears in multiple
            # groups, but is only counted once for the overall aggregate
            is($results[0]->fields->{$integer1->id}->as_string, 25, "First grouping correct");
            is($results[1]->fields->{$integer1->id}->as_string, $multivalue ? 135 : 110, "Second grouping correct");
            is($results[2]->fields->{$integer1->id}->as_string, $with_filter ? 0 : 70, "Third grouping correct")
                if !$with_filter;

            my $aggregate = $records->aggregate_results;

            is($aggregate->fields->{$integer1->id}->as_string, $with_filter ? 135 : 205, "Correct total of integer values");
            is($aggregate->fields->{$calc1->id}->as_string, $with_filter ? 160 : 360, "Correct total of calc values");
        }
    }
}

# Large number of records (greater than default number of rows in table). Check
# that paging does not affect results
{
    my @data;
    for my $count (1..300)
    {
        push @data, {
            string1  => "Foo",
            integer1 => 10,
            integer2 => 10,
        };
    }

    my $sheet = Test::GADS::DataSheet->new(
        data         => \@data,
        calc_code    => "function evaluate (L1integer1, L1integer2) \n return (L1integer1 / L1integer2) * 100 \n end",
        column_count => { integer => 2 },
    );
    $sheet->create_records;
    my $schema   = $sheet->schema;
    my $layout   = $sheet->layout;
    my $columns  = $sheet->columns;
    my $integer1 = $columns->{integer1};
    my $calc1    = $columns->{calc1};

    $integer1->aggregate('sum');
    $integer1->write;
    $calc1->aggregate('sum');
    $calc1->write;
    $layout->clear;

    my $records = GADS::Records->new(
        # Specify rows parameter to simulate default used for table view. This
        # should be ignored for the aggregate
        rows   => 50,
        page   => 1,
        layout => $layout,
        user   => $sheet->user,
        schema => $schema,
    );

    my @results = @{$records->results};
    is(@results, 50, "Correct number of normal rows");
    is($records->pages, 6, "Correct number of pages for large number of records");

    my $aggregate = $records->aggregate_results;

    is($aggregate->fields->{$integer1->id}->as_string, "3000", "Group integer correct for large amount of results");
    is($aggregate->fields->{$calc1->id}->as_string, "30000", "Group integer correct for large amount of results");
}

done_testing();
