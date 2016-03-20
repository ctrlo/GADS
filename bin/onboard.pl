#!/usr/bin/perl -CS

=pod
GADS - Globally Accessible Data Store
Copyright (C) 2014 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use Log::Report ();
use Dancer2::Plugin::LogReport mode => 'NORMAL';
use Data::Dumper;
use GADS::DB;
use GADS::Layout;
use GADS::Record;
use Text::CSV;
use Getopt::Long qw(:config pass_through);
use List::MoreUtils 'first_index';

my ($take_first_enum, $ignore_incomplete_dateranges,
    $dry_run, $ignore_string_zeros, $force,
    $invalid_csv, @invalid_report, $instance_id);

GetOptions (
    'take-first-enum'              => \$take_first_enum,
    'ignore-imcomplete-dateranges' => \$ignore_incomplete_dateranges,
    'dry-run'                      => \$dry_run,
    'ignore-string-zeros'          => \$ignore_string_zeros,
    'force=s'                      => \$force,
    'invalid-csv=s'                => \$invalid_csv,
    'invalid-report=s'             => \@invalid_report,
    'instance-id=s'                => \$instance_id,
) or exit;


die "Invalid option '$force' supplied to --force"
    if $force && $force ne 'mandatory';

die "Need --instance-id to be specified"
    unless $instance_id;

my ($file) = @ARGV;
$file or die "Usage: $0 [--take-first-enum] [--ignore-incomplete-dateranges]
    [--ignore-string-zeros] [--dry-run] [--force=mandatory] [--invalid-csv=failed.csv] filename";

GADS::DB->setup(schema);

my $csv = Text::CSV->new({ binary => 1 }) # should set binary attribute?
    or die "Cannot use CSV: ".Text::CSV->error_diag ();

open my $fh, "<:encoding(utf8)", $file or die "$file: $!";

# Get first row for column headings
my $row = $csv->getline($fh);
my @f = @$row;

# First check if fields exist
my @fields; my $selects;
my $dr;
foreach my $field (@f)
{
    my ($f) = rset('Layout')->search({ name => $field })->all;
    die "Field $field does not exist" unless $f;
    push @fields, {
        field => "field".$f->id,
        id    => $f->id,
        type  => $f->type,
        name  => $f->name,
    };

    die "Daterange $field needs 2 columns" if ($dr && $f->type ne "daterange");

    # Prefill select values
    if ($f->type eq "enum" || $f->type eq "tree")
    {
        my @vals = rset('Enumval')->search({ layout_id => $f->id, deleted => 0 })->all;
        foreach my $v (@vals)
        {
            my $text = lc $v->value;
            # See if it already exists - possible multiple values
            if (exists $selects->{$f->id}->{$text})
            {
                next if $take_first_enum;
                my $existing = $selects->{$f->id}->{$text};
                my @existing = ref $existing eq "ARRAY" ? @$existing : ($existing);
                $selects->{$f->id}->{$text} = [@existing, $v->id];
            }
            else {
                $selects->{$f->id}->{$text} = $v->id;
            }
        }
    }
    elsif ($f->type eq "person")
    {
        my @vals = rset('User')->search({ deleted => undef, account_request => 0 })->all;
        foreach my $v (@vals)
        {
            my $text = lc $v->value;
            # See if it already exists - possible multiple values
            if (exists $selects->{$f->id}->{$text})
            {
                my $existing = $selects->{$f->id}->{$text};
                my @existing = ref $existing eq "ARRAY" ? @$existing : ($existing);
                $selects->{$f->id}->{$text} = [@existing, $v->id];
            }
            else {
                $selects->{$f->id}->{$text} = $v->id;
            }
        }
    }
    elsif ($f->type eq "daterange")
    {
        # Expect a second daterange column immediately after
        $dr = $dr ? 0 : 1;
    }
}

my @all_bad;

my $layout = GADS::Layout->new(
    user                     => undef,
    schema                   => schema,
    config                   => config,
    instance_id              => $instance_id,
    user_permission_override => 1
);

# Open CSV to output bad lines in
my $fh_invalid;
if ($invalid_csv)
{
    open $fh_invalid, ">", $invalid_csv or die "Failed to create $invalid_csv: $!";
    # open $fh_invalid, ">:encoding(utf8)", $invalid_csv or die "Failed to create $invalid_csv: $!";
    my @field_names = map { $_->{name} } @fields;

    my @headings = @invalid_report ? @invalid_report : @field_names;
    $csv->print($fh_invalid, [@headings, 'Errors']);
    print $fh_invalid "\n";

    # If invalid-report has been specified, convert field names into
    # indexes of CSV file
    @invalid_report = map {
        my $name = $_;
        my $index = first_index { /^$name$/ } @field_names;
        error "Field $_ invalid for invalid-report" if $index == -1;
        $index;
    } @invalid_report;
}

while (my $row = $csv->getline($fh))
{
    my @row = @$row
        or next;
    next unless "@row"; # Skip blank lines

    my $count = 0;
    my $input; my @bad;
    my $previous_field;
    foreach my $col (@row)
    {
        my $f = $fields[$count];
        $col =~ s/\s+$//;
        say STDOUT "Going to process $col into field $f->{name}";
        if ($f->{id} == 118) {
            # IDT course name. Exists in act type?
            if ($selects->{36}->{lc $col})
            {
                push @bad, qq(IDT Tier 3 course name "$col" exists as sub activity type);
            }
        }
        if ($f->{type} eq "enum" || $f->{type} eq "tree" || $f->{type} eq "person")
        {
            # Get enum ID value
            if ($col eq "")
            {
                # Blank value. Insertion will handle non-optional fields
                $input->{$f->{field}} = $col;
            }
            else {
                if (ref $selects->{$f->{id}}->{lc $col} eq "ARRAY")
                {
                    push @bad, qq(Multiple instances of enum value "$col" for "$f->{name}");
                }
                elsif (exists $selects->{$f->{id}}->{lc $col})
                {
                    # okay
                    $input->{$f->{field}} = $selects->{$f->{id}}->{lc $col};
                }
                else {
                    push @bad, qq(Invalid enum value "$col" for "$f->{name}");
                }
            }
        }
        elsif ($f->{type} eq "daterange")
        {
            $col =~ s!/!-!g; # Change date delimiters from slash to hyphen
            if ($col =~ /([0-9]{1,2}).([0-9]{1,2}).([0-9]{4})/)
            {
                # Swap year and day if needed
                $col = "$3-$2-$1";
            }
            if (exists $input->{$f->{field}})
            {
                push @{$input->{$f->{field}}}, $col;
            }
            else {
                $input->{$f->{field}} = [$col];
            }
        }
        elsif ($f->{type} eq "string")
        {
            # Option to ignore zeros in text fields
            $input->{$f->{field}} = $ignore_string_zeros && $col eq '0' ? '' : $col;
        }
        elsif ($f->{type} eq "intgr")
        {
            $input->{$f->{field}} = sprintf "%.0f", $col if $col;
        }
        else {
            $input->{$f->{field}} = $col;
        }

        my $previous_field = $f;
        $count++;
    }

    unless (@bad)
    {
        # Insert record into DB. May still be problems
        my $record = GADS::Record->new(
            user   => undef,
            layout => $layout,
            schema => schema,
        );
        $record->initialise;
        my $failed;
        foreach my $col ($layout->all)
        {
            if ($col->userinput) # Not calculated fields
            {
                my $newv = $input->{$col->field};
                if ($col->type eq "daterange" && $ignore_incomplete_dateranges)
                {
                    $newv = ['',''] if !($newv->[0] && $newv->[1]);
                }
                try { $record->fields->{$col->id}->set_value($newv) };
                if (my $exception = $@->wasFatal)
                {
                    push @bad, $exception->message->toString;
                    $failed = 1;
                }
            }
        }
        if (!$failed)
        {
            try { $record->write(no_alerts => 1, dry_run => $dry_run, force => $force) };
            push @bad, "$@" if $@;
        }
    }

    if (@bad)
    {
        push @all_bad, {
            problems => \@bad,
            row      => "@row",
        };
        if ($invalid_csv)
        {
            if (@invalid_report)
            {
                my @row2;
                push @row2, $row->[$_]
                    foreach @invalid_report;
                $row = \@row2;
            }
            push @$row, @bad;
            $csv->print($fh_invalid, $row);
            print $fh_invalid "\n";
        }
    }
}

$csv->eof or $csv->error_diag();
close $fh;
if ($invalid_csv) {
    close $fh_invalid or die "$invalid_csv: $!";
}

say STDERR Dumper \@all_bad;
