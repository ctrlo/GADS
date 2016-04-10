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
    $invalid_csv, @invalid_report, $instance_id,
    $update_unique, $blank_invalid_enum, $no_change_unless_blank,
    $update_only, $report_changes);

GetOptions (
    'take-first-enum'              => \$take_first_enum,
    'ignore-incomplete-dateranges' => \$ignore_incomplete_dateranges,
    'dry-run'                      => \$dry_run,
    'ignore-string-zeros'          => \$ignore_string_zeros,
    'force=s'                      => \$force,
    'invalid-csv=s'                => \$invalid_csv,
    'invalid-report=s'             => \@invalid_report,
    'instance-id=s'                => \$instance_id,
    'update-unique=s'              => \$update_unique,
    'update-only'                  => \$update_only, # Do not write new version record
    'blank-invalid-enum'           => \$blank_invalid_enum,
    'no-change-unless-blank'       => \$no_change_unless_blank,
    'report-changes'               => \$report_changes,
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

my $layout = GADS::Layout->new(
    user                     => undef,
    schema                   => schema,
    config                   => config,
    instance_id              => $instance_id,
    user_permission_override => 1
);

# First check if fields exist
my @fields; my $selects;
my $dr; my $update_unique_col;
foreach my $field (@f)
{
    my ($f) = rset('Layout')->search({ name => $field, instance_id => $layout->instance_id })->all;
    die "Field $field does not exist" unless $f;
    my $column = $layout->column($f->id);
    push @fields, $column;

    die "Daterange $field needs 2 columns" if ($dr && $f->type ne "daterange");

    # Convert update-unique to ID from name
    $update_unique_col = $column
        if $update_unique && $update_unique eq $f->name;

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

error "field $update_unique not found for update-unique"
    if $update_unique && !$update_unique_col;

my @all_bad;

# Open CSV to output bad lines in
my $fh_invalid;
if ($invalid_csv)
{
    #open $fh_invalid, ">", $invalid_csv or die "Failed to create $invalid_csv: $!";
    open $fh_invalid, ">:encoding(utf8)", $invalid_csv or die "Failed to create $invalid_csv: $!";
    my @field_names = map { $_->name } @fields;

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

my $count = {
    in      => 0,
    written => 0,
    errors  => 0,
};

while (my $row = $csv->getline($fh))
{
    my @row = @$row
        or next;
    next unless "@row"; # Skip blank lines

    $count->{in}++;

    my $col_count = 0;
    my $input; my @bad; my @bad_enum;
    my $previous_field;
    foreach my $col (@row)
    {
        my $f = $fields[$col_count];
        $col =~ s/\s+$//;
        #say STDOUT "Going to process $col into field $f->{name}";
        if ($f->type eq "enum" || $f->type eq "tree" || $f->type eq "person")
        {
            # Get enum ID value
            if ($col eq "")
            {
                # Blank value. Insertion will handle non-optional fields
                $input->{$f->field} = $col;
            }
            else {
                my $colname = $f->name;
                if (ref $selects->{$f->id}->{lc $col} eq "ARRAY")
                {
                    push @bad, qq(Multiple instances of enum value "$col" for "$colname");
                }
                elsif (exists $selects->{$f->id}->{lc $col})
                {
                    # okay
                    $input->{$f->field} = $selects->{$f->id}->{lc $col};
                }
                else {
                    push @bad_enum, qq(Invalid enum value "$col" for "$colname");
                    $input->{$f->field} = ''
                        if $blank_invalid_enum;
                }
            }
        }
        elsif ($f->type eq "daterange")
        {
            $col =~ s!/!-!g; # Change date delimiters from slash to hyphen
            if ($col =~ /([0-9]{1,2}).([0-9]{1,2}).([0-9]{4})/)
            {
                # Swap year and day if needed
                $col = "$3-$2-$1";
            }
            if (exists $input->{$f->field})
            {
                push @{$input->{$f->field}}, $col;
            }
            else {
                $input->{$f->field} = [$col];
            }
        }
        elsif ($f->type eq "string")
        {
            # Option to ignore zeros in text fields
            $input->{$f->field} = $ignore_string_zeros && $col eq '0' ? '' : $col;
        }
        elsif ($f->type eq "intgr")
        {
            if ($col =~ /^[\.0-9]+$/)
            {
                $input->{$f->field} = sprintf "%.0f", $col if $col;
            }
            elsif ($col) {
                my $colname = $f->name;
                push @bad, qq(Invalid item "$col" for integer field "$colname");
            }
        }
        else {
            $input->{$f->field} = $col;
        }

        my $previous_field = $f;
        $col_count++;
    }

    my $write = !@bad && (!@bad_enum || $blank_invalid_enum);
    if ($write)
    {
        # Insert record into DB. May still be problems
        my $record = GADS::Record->new(
            user   => undef,
            layout => $layout,
            schema => schema,
        );

        # Look for existing record?
        if ($update_unique)
        {
            my $unique_field = $update_unique_col->field;
            if ($input->{$unique_field})
            {
                if (my $existing = $record->find_unique($update_unique_col, $input->{$unique_field}))
                {
                    $record->find_current_id($existing->current_id);
                }
                else {
                    $record->initialise;
                }
            }
            else {
                $record->initialise;
                push @bad, qq(Missing unique identifier for "$update_unique". Data will be uploaded as new record. Full record follows: @row);
            }
        }
        else {
            $record->initialise;
        }

        my @changes;
        my @failed = update_fields(\@fields, $input, $record, \@changes);
        if ($report_changes && @changes)
        {
            say STDOUT "Changes for record ".$record->fields->{$update_unique_col->id}->as_string." are as follows:";
            say STDOUT $_ foreach @changes;
            say STDOUT "\n";
        }
        if (!@failed)
        {
            try { $record->write(no_alerts => 1, dry_run => $dry_run, force => $force, update_only => $update_only, no_change_unless_blank => $no_change_unless_blank) };
            if ($@)
            {
                my $exc = $@->died;
                my $message = ref $exc ? $@->died->message : $exc;
                push @failed, "$message";
            }
            else {
                $count->{written}++;
            }
        }
        push @bad, @failed;
    }

    push @bad, @bad_enum;

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

$count->{errors} = @all_bad;
say STDOUT Dumper $count;

sub update_fields
{   my ($fields, $input, $record, $changes) = @_;
    my @bad;
    foreach my $col (@$fields)
    {
        if ($col->userinput) # Not calculated fields
        {
            my $newv = $input->{$col->field};
            if (!$record->current_id || $newv)
            {
                if ($col->type eq "daterange" && $ignore_incomplete_dateranges)
                {
                    $newv = ['',''] if !($newv->[0] && $newv->[1]);
                }
                my $datum = $record->fields->{$col->id};
                my $old_value = $datum->as_string;
                my $was_blank = $datum->blank;
                try { $datum->set_value($newv) };
                if (my $exception = $@->wasFatal)
                {
                    push @bad, $exception->message->toString;
                }
                elsif ($report_changes && $record->current_id && $datum->changed && !$was_blank)
                {
                    my $colname = $col->name;
                    my $newvalue = $datum->as_string;
                    push @$changes, qq(Change value of "$colname" from "$old_value" to "$newvalue")
                        if  lc $old_value ne lc $newvalue; # Don't report change of case
                }
            }
        }
    }
    @bad;
}
