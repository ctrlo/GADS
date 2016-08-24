use Test::More; # tests => 1;
use strict;
use warnings;

use Log::Report;
use GADS::Import;

use t::lib::DataSheet;

# version tests
{
    my $sheet = t::lib::DataSheet->new(data => []);

    my $schema  = $sheet->schema;
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;
    $sheet->create_records;

    my $user1 = $schema->resultset('User')->create({
        username => 'test',
        password => 'test',
    });

    my $user2 = $schema->resultset('User')->create({
        username => 'test2',
        password => 'test2',
    });

    my $in = "string1,Version Datetime,Version User ID\nFoobar,2014-10-10 12:00,".$user2->id;
    my $import = GADS::Import->new(
        schema   => $schema,
        layout   => $layout,
        user_id  => $user1->id,
        file     => \$in,
    );

    $import->process;

    my $record = GADS::Record->new(
        user   => undef,
        layout => $layout,
        schema => $schema,
    );
    $record->find_current_id(1);
    is($record->createdby->id, $user2->id, "Record created by correct ID");
    is($record->created, '2014-10-10T12:00:00', "Record created datetime correct");
}

my @tests = (
    {
        data      => "string1\nString content",
        option    => undef,
        count_on  => 1,
        count_off => 1,
    },
    {
        data      => "string1\nString content",
        option    => 'dry_run',
        count_on  => 0,
        count_off => 1,
    },
    {
        data      => "string1,integer1\nString content,123\n,234",
        option    => 'force_mandatory',
        count_on  => 2,
        count_off => 1,
    },
    {
        data      => "enum1\nfoo1\nfoobar",
        option    => 'blank_invalid_enum',
        count_on  => 2,
        count_off => 1,
    },
    {
        data      => "enum1\nfoo1\nduplicate",
        option    => 'take_first_enum',
        count_on  => 2,
        count_off => 1,
    },
    {
        data      => "string1\nfoo\n0",
        option    => 'ignore_string_zeros',
        count_on  => 2,
        count_off => 2,
        written   => {
            String => {
                on  => 'foo',
                off => 'foo0',
            },
        },
    },
    {
        data      => "integer1\n100\n12.7",
        option    => 'round_integers',
        count_on  => 2,
        count_off => 1,
        written   => {
            Intgr => {
                on  => '10013',
                off => '100',
            },
        },
    },
);

foreach my $test (@tests)
{
    foreach my $status (qw/on off/)
    {
        my $sheet = t::lib::DataSheet->new(data => []);

        my $schema  = $sheet->schema;
        my $layout  = $sheet->layout;
        my $columns = $sheet->columns;
        $sheet->create_records;

        my $user = $schema->resultset('User')->create({
            username => 'test',
            password => 'test',
        });

        my %options;
        $options{$test->{option}} = $status eq 'on' ? 1 : 0
            if $test->{option};

        my $import = GADS::Import->new(
            schema   => $schema,
            layout   => $layout,
            user_id  => $user->id,
            file     => \($test->{data}),
            %options,
        );

        my $records = GADS::Records->new(
            user   => undef,
            layout => $layout,
            schema => $schema,
        );

        if ($test->{option} && $test->{option} eq 'force_mandatory')
        {
            my $string1 = $records->layout->column_by_name('string1');
            $string1->optional(0);
            $string1->write;
        }

        if ($test->{option} && $test->{option} eq 'take_first_enum')
        {
            my $enum1 = $records->layout->column_by_name('enum1');
            $enum1->enumvals([
                {
                    value => 'foo1',
                },
                {
                    value => 'duplicate',
                },
                {
                    value => 'duplicate',
                },
            ]);
            $enum1->write;
        }

        my $test_name = defined $test->{option} ? "with option $test->{option} set to $status" : "with no options";
        is($records->count, 0, "No records before import for test $test_name");
        $import->process;
        $records->clear;
        is($records->count, $test->{"count_$status"}, "Correct record count on import for test $test_name");

        if (my $written = $test->{written})
        {
            foreach my $table (keys %$written)
            {
                my $string = _table_as_string($schema, $table);
                my $expected = $written->{$table}->{$status};
                is($string, $expected, "Correct written value for $test_name");
            }
        }
    }
}

# update tests
my @update_tests = (
    {
        option  => 'update_unique',
        data    => "string1,integer1\nFoo,100\nFoo2,150",
        count   => 3,
        string  => 'Foo Bar Foo2',
        intgr   => '100 99 150',
        written => 2,
        errors  => 0,
        skipped => 0,
    },
    {
        option  => 'skip_existing_unique',
        data    => "string1,integer1\nFoo,100\nFoo2,150",
        count   => 3,
        string  => 'Foo Bar Foo2',
        intgr   => '50 99 150',
        written => 1,
        errors  => 0,
        skipped => 1,
    },
    {
        option  => 'no_change_unless_blank',
        data    => "string1,integer1,date1\nFoo,200,2010-10-10\nBar,300,2011-10-10",
        count   => 2,
        string  => 'Foo Bar',
        intgr   => '50 300',
        date    => '2010-10-10 2011-10-10',
        written => 2,
        errors  => 0,
        skipped => 0,
        existing_data => [
            {
                string1    => 'Foo',
                integer1   => 50,
                date1      => '',
            },
            {
                string1    => 'Bar',
                integer1   => '',
                date1      => '',
            },
        ],
    },
);

foreach my $test (@update_tests)
{
    my $sheet = t::lib::DataSheet->new;
    $sheet->data($test->{existing_data}) if $test->{existing_data};

    my $schema  = $sheet->schema;
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;
    $sheet->create_records;

    my $user = $schema->resultset('User')->create({
        username => 'test',
        password => 'test',
    });

    my $string1 = $layout->column_by_name('string1');
    $string1->isunique(1);
    $string1->write;

    my %options;
    if ($test->{option} eq 'update_unique')
    {
        $options{update_unique} = $string1->id;
    }
    if ($test->{option} eq 'skip_existing_unique')
    {
        $options{skip_existing_unique} = $string1->id;
    }
    if ($test->{option} eq 'no_change_unless_blank')
    {
        $options{update_unique} = $string1->id;
        $options{no_change_unless_blank} = 'skip_new';
    }

    my $import = GADS::Import->new(
        schema        => $schema,
        layout        => $layout,
        user_id       => $user->id,
        file          => \$test->{data},
        %options,
    );

    $import->process;

    my $records = GADS::Records->new(
        user   => undef,
        layout => $layout,
        schema => $schema,
    );

    is($records->count, $test->{count}, "Correct record count after import test $test->{option}");
    my @got_string = map { $_->fields->{$string1->id}->as_string } @{$records->results};
    is("@got_string", $test->{string}, "Correct data written to string table for test $test->{option}");
    my $integer1 = $layout->column_by_name('integer1');
    my @got_integer = map { $_->fields->{$integer1->id}->as_string } @{$records->results};
    is("@got_integer", $test->{intgr}, "Correct data written to intgr table for test $test->{option}");
    if ($test->{date})
    {
        my $date1 = $layout->column_by_name('date1');
        my @got_date = map { $_->fields->{$date1->id}->as_string } @{$records->results};
        is("@got_date", $test->{date}, "Correct data written to date table for test $test->{option}");
    }

    my $imp = $schema->resultset('Import')->next;
    is($imp->written_count, $test->{written}, "Correct count of written lines for test $test->{option}");
    is($imp->error_count, $test->{errors}, "Correct count of error lines for test $test->{option}");
    is($imp->skipped_count, $test->{skipped}, "Correct count of skipped lines for test $test->{option}");
}

done_testing();

sub _table_as_string
{   my ($schema, $table) = @_;
    join '', $schema->resultset($table)->search({},{ order_by => 'id' })->get_column('value')->all;
}
