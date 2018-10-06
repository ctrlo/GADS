use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Globe;

use t::lib::DataSheet;

my $simple_data = [
    {
        string1    => 'France',
        integer1   => 10,
        enum1      => 'foo2',
    },{
        string1    => 'Great Britain',
        integer1   => 15,
        enum1      => 'foo3',
    },
];

# Simple test first
{
    my $sheet = t::lib::DataSheet->new(
        data             => $simple_data,
        calc_code        => "function evaluate (L1string1) \n return L1string1 end",
        calc_return_type => 'globe',
    );

    $sheet->create_records;
    my $schema  = $sheet->schema;
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;

    my $records_options = {
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    };

    my $globe = GADS::Globe->new(
        records_options => $records_options,
    );

    my $trace = $globe->data->[0];
    my $items = _sort_items($trace);
    is_deeply($items->{locations}, ['France', 'Great Britain'], "Countries correct for simple view");
    like($items->{text}->[0], qr/foo2/, "Great Britain has correct enum value");
    like($items->{text}->[1], qr/foo3/, "France has correct enum value");
}

# Run with and without a view that doesn't contain a globe field (should be
# added automatically), and also no view
foreach my $withview (qw/none with without/)
{
    my @countries = qw(Albania Algeria Andorra Angola Australia
        Bahamas Bahrain Barbados Bermuda Bolivia);
    my @data;

    for my $i (1..500)
    {
        my $mod1 = $i % 10;
        my $mod2 = $i % 3;
        push @data, {
            string1  => $countries[$mod1],
            integer1 => 10,
            enum1    => "foo".($mod2+1),
        }
    }

    my $sheet = t::lib::DataSheet->new(
        data             => \@data,
        calc_code        => "function evaluate (L1string1) \n return L1string1 end",
        calc_return_type => 'globe',
    );

    $sheet->create_records;
    my $schema  = $sheet->schema;
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;

    my $records_options = {
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    };
    if ($withview =~ /with/)
    {
        my $cols = $withview eq 'with' ? [$columns->{calc1}->id] : [$columns->{string1}->id];
        my $view = GADS::View->new(
            name        => 'Test view',
            columns     => $cols,
            instance_id => $layout->instance_id,
            layout      => $layout,
            schema      => $schema,
            user        => $sheet->user,
        );
        $view->write;
        $records_options->{view} = $view;
    }

    foreach my $test (qw/group label color color_count group_numeric/)
    {
        my %options = $test eq 'group'
            ? (group_col_id => $columns->{enum1}->id)
            : $test eq 'color'
            ? (color_col_id => $columns->{integer1}->id)
            : $test eq 'color_count'
            ? (color_col_id => -1)
            : $test eq 'group_numeric'
            ? (group_col_id => $columns->{integer1}->id)
            : (label_col_id => $columns->{string1}->id);

        $options{records_options} = $records_options;

        my $globe = GADS::Globe->new(%options);

        if ($test eq 'group')
        {
            my $data = $globe->data->[0];
            foreach my $text (@{$data->{text}})
            {
                # foo1: 17<br>foo2: 16<br>foo3: 17
                $text =~ /foo.: ([0-9]+).*foo.: ([0-9]+).*foo.: ([0-9]+)/;
                my $total = $1 + $2 + $3;
                is($total, 50, "Total correct for all country items in group");
            }
        }
        elsif ($test eq 'group_numeric')
        {
            my $data = $globe->data->[0];
            my $exp = [ ('Total: 500') x 10 ];
            is($data->{hoverinfo}, 'text', "Show hover labels as text for group by numeric column");
            is_deeply($data->{text}, $exp, "Labels correct for group by numeric column");
        }
        elsif ($test eq 'label')
        {
            is(@{$globe->data}, 2, "Correct number of traces for label globe");
            my $text = [
                'Albania: 50',
                'Algeria: 50',
                'Andorra: 50',
                'Angola: 50',
                'Australia: 50',
                'Bahamas: 50',
                'Bahrain: 50',
                'Barbados: 50',
                'Bermuda: 50',
                'Bolivia: 50',
            ];
            my $trace1 = _sort_items($globe->data->[0]);
            is_deeply($trace1->{text}, $text, "Correct text for first trace in label");
            my $trace2 = _sort_items($globe->data->[1]);
            is_deeply($trace2->{hovertext}, $text, "Correct hovertext for second trace in label");
            is_deeply($trace2->{text}, $text, "Label of second trace is same as first trace");
        }
        elsif ($test eq 'color_count') {
            my $got = $globe->data->[0]->{z};
            my $expected = [ (50) x 10 ];
            is_deeply($got, $expected, "Z values correct for choropleth");
        }
        else {
            my $got = $globe->data->[0]->{z};
            my $expected = [ (500) x 10 ];
            is_deeply($got, $expected, "Z values correct for choropleth");
        }

        $globe->clear;
    }
}

# Count of curval numeric field
{
    my $data = [
        {
            string1  => 'Foo',
            integer1 => 25,
            enum1    => [qw/foo1 foo2/],
        },
        {
            string1  => 'FooBar',
            integer1 => 25,
            enum1    => [qw/foo2 foo3/],
        },
        {
            string1  => 'Bar',
            integer1 => 25,
            enum1    => [qw/foo1/],
        },
        {
            string1  => 'Foo',
            integer1 => 25,
            enum1    => [qw/foo2/],
        },
    ];
    my $curval_sheet = t::lib::DataSheet->new(
        data        => $data,
        multivalue  => 1,
        instance_id => 2,
    );
    $curval_sheet->create_records;
    my $schema = $curval_sheet->schema;
    my $curval_columns = $curval_sheet->columns;

    $data = [
        {
            string1 => 'France',
            curval1 => [1, 2],
        },
        {
            string1 => 'Germany',
            curval1 => 3,
        },
        {
            string1 => 'Spain',
            curval1 => 4,
        },
    ];
    my $sheet = t::lib::DataSheet->new(
        data             => $data,
        curval           => $curval_sheet->instance_id,
        schema           => $schema,
        multivalue       => 1,
        calc_code        => "function evaluate (L1string1) \n return L1string1 end",
        calc_return_type => 'globe',
    );
    $sheet->create_records;
    my $columns = $sheet->columns;
    my $layout  = $sheet->layout;

    my $globe = GADS::Globe->new(
        color_col_id => $columns->{curval1}->id.'_'.$curval_columns->{integer1}->id,
        records_options => {
            user   => $sheet->user,
            layout => $layout,
            schema => $schema,
        },
    );

    my $z = [
        50,
        25,
        25
    ];
    my $locations = [qw/
        France
        Germany
        Spain
    /];
    my $text = [ map { "Total: $_" } @$z ];

    my $out = $globe->data->[0];
    my @results = map {
        +{
            location => $_,
            text     => shift @{$out->{text}},
            z        => shift @{$out->{z}},
        },
    } @{$out->{locations}};
    @results = sort { $a->{location} cmp $b->{location} } @results;
    is_deeply([map { $_->{z} } @results], $z, "Choropleth values correct for curval field");
    is_deeply([map { $_->{location} } @results], $locations, "Location values correct for curval field");
    is_deeply([map { $_->{text} } @results], $text, "Text values correct for curval field");
}

# Invalid columns
{
    my $sheet = t::lib::DataSheet->new(
        data             => $simple_data,
        calc_code        => "function evaluate (L1string1) \n return L1string1 end",
        calc_return_type => 'globe',
    );

    $sheet->create_records;
    my $schema  = $sheet->schema;
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;

    my $records_options = {
        user   => $sheet->user,
        layout => $layout,
        schema => $schema,
    };

    foreach my $test (qw/group_col_id label_col_id color_col_id/)
    {
        my $globe = GADS::Globe->new(
            $test           => 999,
            records_options => $records_options,
        );

        my $trace = $globe->data->[0];
        is(@{$trace->{locations}}, 2, "Country count correct for invalid column");
    }
}

done_testing();

sub _sort_items
{   my $items = shift;
    my @items;

    push @items, {
        location  => $items->{locations}->[$_],
        text      => $items->{text}->[$_],
        hovertext => $items->{hovertext}->[$_],
    } foreach (0..(scalar @{$items->{locations}} - 1));

    @items = sort { $a->{location} cmp $b->{location} } @items;
    +{
        locations => [ map { $_->{location} } @items ],
        text      => [ map { $_->{text} } @items ],
        hovertext => [ map { $_->{hovertext} } @items ],
    }
}
