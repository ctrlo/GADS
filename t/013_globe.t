use Test::More; # tests => 1;
use strict;
use warnings;

use JSON qw(encode_json);
use Log::Report;
use GADS::Globe;

use t::lib::DataSheet;

# Simple test first
{
    my $data = [
        {
            string1    => 'FRA',
            integer1   => 10,
            enum1      => 'foo2',
        },{
            string1    => 'GBR',
            integer1   => 15,
            enum1      => 'foo3',
        },
    ];

    my $sheet = t::lib::DataSheet->new(
        data             => $data,
        calc_code        => "function evaluate (L1string1) \n return L1string1 end",
        calc_return_type => 'globe',
    );

    $sheet->create_records;
    my $schema  = $sheet->schema;
    my $layout  = $sheet->layout;
    my $columns = $sheet->columns;

    my $records_options = {
        user                 => $sheet->user,
        layout               => $layout,
        schema               => $schema,
        interpolate_children => 0,
    };

    my $globe = GADS::Globe->new(
        records_options => $records_options,
    );

    my $trace = $globe->data->[0];
    my $items = _sort_items($trace);
    is_deeply($items->{locations}, ['FRA', 'GBR'], "Countries correct for simple view");
    like($items->{text}->[0], qr/foo2/, "Great Britain has correct enum value");
    like($items->{text}->[1], qr/foo3/, "France has correct enum value");
}

{
    my @countries = qw(ABW AFG AGO AIA ALA ALB AND ANT ARE ARG);
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
        user                 => $sheet->user,
        layout               => $layout,
        schema               => $schema,
        interpolate_children => 0,
    };

    foreach my $test (qw/group label color/)
    {
        my %options = $test eq 'group'
            ? (group_col_id => $columns->{enum1}->id)
            : $test eq 'color'
            ? (color_col_id => $columns->{integer1}->id)
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
        elsif ($test eq 'label')
        {
            is(@{$globe->data}, 2, "Correct number of traces for label globe");
            my $text = [
                'ABW: 50',
                'AFG: 50',
                'AGO: 50',
                'AIA: 50',
                'ALA: 50',
                'ALB: 50',
                'AND: 50',
                'ANT: 50',
                'ARE: 50',
                'ARG: 50',
            ];
            my $trace1 = _sort_items($globe->data->[0]);
            is_deeply($trace1->{text}, $text, "Correct text for first trace in label");
            my $trace2 = _sort_items($globe->data->[1]);
            is_deeply($trace2->{hovertext}, $text, "Correct hovertext for second trace in label");
            is_deeply($trace2->{text}, \@countries, "Correct text for second trace in label");
        }
        else {
            my $got = $globe->data->[0]->{z};
            my $expected = [ (500) x 10 ];
            is_deeply($got, $expected, "Z values correct for choropleth");
        }

        $globe->clear;
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
