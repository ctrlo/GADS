#!/usr/bin/perl
use strict;
use warnings;

use feature ':5.37';

use FindBin;
use lib "$FindBin::Bin/../lib";

use Encode 'encode';

use Dancer2;
use Dancer2::Plugin::DBIC;

sub purge {
    my $value = shift;
    if(ref $value eq 'GADS::Schema::Result::Calcval') {
        purge_calc $value;
    }elsif(ref $value eq 'GADS::Schema::Result::Date') {
        purge_value ($value, 'Date', 'value');
    }elsif(ref $value eq 'GADS::Schema::Result::Daterange') {
        purge_date_range $value;
    }elsif(ref $value eq 'GADS::Schema::Result::Enum') {
        purge_value ($value, 'Enum', 'value');
    }elsif(ref $value eq 'GADS::Schema::Result::File') {
        purge_file $value;
    }elsif(ref $value eq 'GADS::Schema::Result::Intgr') {
        purge_value ($value, 'Intgr', 'value');
    }elsif(ref $value eq 'GADS::Schema::Result::Person') {
        purge_value($value, 'Person', 'value');
    }elsif(ref $value eq 'GADS::Schema::Result::Ragval') {
        purge_value ($value, 'Ragval', 'value');
    }elsif(ref $value eq 'GADS::Schema::Result::String') {
        purge_value ($value,'String', 'value');
    }else{
        say "Unknown type: " . ref $value;
        exit(2);
    }
    say "Deleted $value";
}

sub purge_value {
    my ($value, $value_source, $value_column) = @_;

    schema->txn_do(sub {
        my $source=schema->resultset($value_source)->find($value->id);
        $source->update({$value_column => undef});
    });
}

sub purge_calc {
    my $calc = shift;
    my @fields = ('value_text', 'value_int', 'value_date', 'value_numeric', 'value_datetime');

    schema->txn_do(sub {
        $calc->update({ $_ => undef }) foreach @fields;
    });
}

sub purge_date_range {
    my $daterange = shift;

    schema->txn_do(sub {
        $daterange->update({ from => undef, to => undef });
    });
}

sub purge_file {
    my $file = shift;

    schema->txn_do(sub {
        my $value = $file->value;
        $value->update({
            name=>'purged',
            mimetype=>'text/plain',
            content=>encode('utf-8', 'purged'),
        });
    });
}

say "Usage: ./delete-file.pl <current_id> <layout_id> [<layout id>...]" unless @ARGV > 1;
exit(1) unless @ARGV > 1;

my $current_id = shift(@ARGV);

my $total = 0;

my $current = schema->resultset('Current')->find($current_id);
my @records = $current->records->all;
my @values;

foreach my $layout (@ARGV) {
    push @values, $_->calcvals->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->dateranges->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->dates->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->enums->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->files->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->intgrs->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->people->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->ragvals->search({ layout_id => $layout })->all foreach @records;
    push @values, $_->strings->search({ layout_id => $layout })->all foreach @records;
}

foreach my $value (@values) {
    purge $value;
    $total++;
}

say "Purged $total records";
exit(0);
