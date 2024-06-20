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

use Dancer2;
use Dancer2::Plugin::DBIC;
use Log::Report ();
use Dancer2::Plugin::LogReport mode => 'NORMAL';
use Data::Dumper;
use GADS::DB;
use GADS::Layout;
use GADS::Record;
use Text::CSV;
use Getopt::Long;
use List::MoreUtils 'first_index';

my (
    $take_first_enum,    $ignore_incomplete_dateranges,
    $dry_run,            $ignore_string_zeros,
    $force,              $invalid_csv,
    @invalid_report,     $instance_id,
    $update_unique,      $skip_existing_unique,
    $blank_invalid_enum, $no_change_unless_blank,
    $update_only,        $report_changes,
    @append,
);

GetOptions(
    'take-first-enum'              => \$take_first_enum,
    'ignore-incomplete-dateranges' => \$ignore_incomplete_dateranges,
    'dry-run'                      => \$dry_run,
    'ignore-string-zeros'          => \$ignore_string_zeros,
    'force=s'                      => \$force,
    'invalid-csv=s'                => \$invalid_csv,
    'invalid-report=s'             => \@invalid_report,
    'instance-id=s'                => \$instance_id,
    'update-unique=s'              => \$update_unique,
    'skip-existing-unique=s'       => \$skip_existing_unique,
    'update-only' => \$update_only,    # Do not write new version record
    'blank-invalid-enum'       => \$blank_invalid_enum,
    'no-change-unless-blank=s' =>
        \$no_change_unless_blank,      # =bork or =blank_new
    'report-changes' => \$report_changes,
    'append=s'       => \@append,
) or exit;

die "Invalid option '$force' supplied to --force"
    if $force && $force ne 'mandatory';

die
"Invalid option '$no_change_unless_blank' supplied to --no-change-unless-blank"
    if $no_change_unless_blank
    && $no_change_unless_blank !~ /^(skip_new|bork)$/;

die "Need --instance-id to be specified"
    unless $instance_id;

die "--skip-existing-unique and --update-unique are mutually exclusive"
    if $update_unique && $skip_existing_unique;

my ($file) = @ARGV;
$file or die "Usage: $0 [--take-first-enum] [--ignore-incomplete-dateranges]
    [--ignore-string-zeros] [--dry-run] [--force=mandatory] [--invalid-csv=failed.csv] filename";

GADS::DB->setup(schema);

GADS::Config->instance(config => config,);

my $site = schema->resultset('Site')->next;
schema->site_id($site->id);

my $csv = Text::CSV->new({ binary => 1 })    # should set binary attribute?
    or die "Cannot use CSV: " . Text::CSV->error_diag();

open my $fh, "<:encoding(utf8)", $file or die "$file: $!";

# Get first row for column headings
my $row = $csv->getline($fh);
my @f   = @$row;

my $layout = GADS::Layout->new(
    user                     => undef,
    schema                   => schema,
    config                   => GADS::Config->instance,
    instance_id              => $instance_id,
    user_permission_override => 1,
);

# First check if fields exist
my @fields;
my $selects;
my $selects_reverse;
my $dr;
my $update_unique_col;
my $skip_existing_unique_col;
my $multi_columns
    ;    # Fields that need more than one column of data (e.g. daterange).

foreach my $field (@f)
{
    if ($update_unique && $update_unique eq 'ID' && $field eq 'ID')
    {
        # Check that there is not an ID field in the layout
        die "ID is present in the layout but is a special name"
            if grep { $_->name eq 'ID' } $layout->all;
        push @fields,
            undef; # Special case. XXX maybe need a special GADS::Column for ID?
    }
    elsif ($field =~ /^(__version_datetime|__version_userid)$/)
    {
        push @fields, $1;
        next;
    }
    else
    {
        my ($f) =
            rset('Layout')
            ->search({ name => $field, instance_id => $layout->instance_id })
            ->all;
        die "Field $field does not exist" unless $f;
        my $column = $layout->column($f->id);
        die "Field $field exists twice"
            if (grep { ref $_ && $_->name eq $field } @fields)
            && $column->type ne "daterange";
        push @fields, $column unless $dr && $f->type eq "daterange";

        $multi_columns->{ $column->id } = 1 if $dr && $f->type eq "daterange";

        # Convert update-unique to ID from name
        $update_unique_col = $column
            if $update_unique
            && $update_unique ne 'ID'
            && $update_unique eq $f->name;

        # Convert skip-existing-unique to ID from name
        $skip_existing_unique_col = $column
            if $skip_existing_unique && $skip_existing_unique eq $f->name;

        # Prefill select values
        if ($f->type eq "enum" || $f->type eq "tree")
        {
            my @vals =
                rset('Enumval')->search({ layout_id => $f->id, deleted => 0 })
                ->all;
            foreach my $v (@vals)
            {
                my $text = _trim(lc $v->value);

                # See if it already exists - possible multiple values
                if (exists $selects->{ $f->id }->{$text})
                {
                    next if $take_first_enum;
                    my $existing = $selects->{ $f->id }->{$text};
                    my @existing =
                        ref $existing eq "ARRAY" ? @$existing : ($existing);
                    $selects->{ $f->id }->{$text} = [ @existing, $v->id ];
                }
                else
                {
                    $selects->{ $f->id }->{$text} = $v->id;
                }
                $selects_reverse->{ $f->id }->{ $v->id } = $text;
            }
        }
        elsif ($f->type eq "person")
        {
            my @vals = rset('User')
                ->search({ deleted => undef, account_request => 0 })->all;
            foreach my $v (@vals)
            {
                my $text = lc $v->value;

                # See if it already exists - possible multiple values
                if (exists $selects->{ $f->id }->{$text})
                {
                    my $existing = $selects->{ $f->id }->{$text};
                    my @existing =
                        ref $existing eq "ARRAY" ? @$existing : ($existing);
                    $selects->{ $f->id }->{$text} = [ @existing, $v->id ];
                }
                else
                {
                    $selects->{ $f->id }->{$text} = $v->id;
                }
                $selects_reverse->{ $f->id }->{ $v->id } = $text;
            }
        }
        elsif ($f->type eq "daterange")
        {
            # Expect a second daterange column immediately after
            $dr = $dr ? 0 : 1;
        }
    }
}

error "field $update_unique not found for update-unique"
    if $update_unique && $update_unique ne 'ID' && !$update_unique_col;

error "field $skip_existing_unique not found for skip-existing-unique"
    if $skip_existing_unique && !$skip_existing_unique_col;

my @all_bad;

# Open CSV to output bad lines in
my $fh_invalid;
if ($invalid_csv)
{
#open $fh_invalid, ">", $invalid_csv or die "Failed to create $invalid_csv: $!";
    open $fh_invalid, ">:encoding(utf8)", $invalid_csv
        or die "Failed to create $invalid_csv: $!";
    my @field_names = map { ref $_ ? $_->name : $_ } @fields;

    my @headings = @invalid_report ? @invalid_report : @field_names;
    $csv->print($fh_invalid, [ 'Status', @headings, 'Errors' ]);
    print $fh_invalid "\n";

    # If invalid-report has been specified, convert field names into
    # indexes of CSV file
    @invalid_report = map {
        my $name  = $_;
        my $index = first_index { /^$name$/ } @field_names;
        error "Field $_ invalid for invalid-report" if $index == -1;
        $index;
    } @invalid_report;
}

my %append;
foreach my $append (@append)
{
    my ($col) = grep { $_ && $_->name eq $append } @fields;
    error "Field $append invalid for append" unless $col;
    $append{ $col->id } = 1;
}

my $count = {
    in      => 0,
    written => 0,
    errors  => 0,
};

my $parser_yymd = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d',);

# Used to retrieve all columns when searching unique field
my @all_column_ids = map { $_->id } $layout->all;

while (my $row = $csv->getline($fh))
{
    my @row = @$row
        or next;
    next unless "@row";    # Skip blank lines

    $count->{in}++;

    my $col_count = 0;
    my $input;
    my @bad;
    my @bad_enum;
    my $drf;               # last loop was a daterange, may be another
    my $previous_field;
    my %options;
    foreach my $col (@row)
    {
        $col = _trim($col);

        my $f = $fields[$col_count];

        if (!$f)    # Will be undef for ID column
        {
            $input->{ID} = $col;
            $col_count++;
            next;
        }
        elsif ($f eq '__version_datetime')
        {
            $options{version_datetime} = $parser_yymd->parse_datetime($col)
                or push @bad, qq(Invalid version_datetime "$col");
        }
        elsif ($f eq '__version_userid')
        {
            $options{version_userid} = $col;
        }
        elsif ($f->type eq "enum" || $f->type eq "tree" || $f->type eq "person")
        {
            # Get enum ID value
            if ($col eq "")
            {
                # Blank value. Insertion will handle non-optional fields
                $input->{ $f->field } = $col;
            }
            else
            {
                my $colname = $f->name;
                if (ref $selects->{ $f->id }->{ lc $col } eq "ARRAY")
                {
                    push @bad,
qq(Multiple instances of enum value "$col" for "$colname");
                }
                elsif (exists $selects->{ $f->id }->{ lc $col })
                {
                    # okay
                    $input->{ $f->field } = $selects->{ $f->id }->{ lc $col };
                }
                else
                {
                    push @bad_enum,
                        qq(Invalid enum value "$col" for "$colname");
                    $input->{ $f->field } = ''
                        if $blank_invalid_enum;
                }
            }
        }
        elsif ($f->type eq "daterange")
        {
            # Daterange can be either 2 date columns or textual date range
            $col =~ s!/!-!g;    # Change date delimiters from slash to hyphen
            $col =~ s!^([0-9]{1,2})-([0-9]{1,2})-([0-9]{4})$!$3-$2-$1!
                ;               # Allow wrong way round
            $col =~ s/^([0-9]{4})([0-9]{2})([0-9]{2})$/$1-$2-$3/
                ;               # Allow no delimter. Assume yyyymmdd
            if ($multi_columns->{ $f->id })
            {
                if (exists $input->{ $f->field })
                {
                    push @{ $input->{ $f->field } }, $col;
                    $drf = 0;
                }
                else
                {
                    $input->{ $f->field } = [$col];
                    $drf = 1;
                }
            }
            elsif ($col =~
/^([0-9]{4}-[0-9]{1,2}-[0-9]{1,2})\h*(-|to)\h*([0-9]{4}-[0-9]{1,2}-[0-9]{1,2})$/
                )
            {
                $input->{ $f->field } = [ $1, $3 ];
            }
            else
            {
                my $colname = $f->name;
                push @bad, qq(Invalid daterange value "$col" for "$colname");
            }
        }
        elsif ($f->type eq "string")
        {
            # Option to ignore zeros in text fields
            $input->{ $f->field } =
                $ignore_string_zeros && $col eq '0' ? '' : $col;
        }
        elsif ($f->type eq "intgr")
        {
            if ($col =~ /^[\.0-9]+$/)
            {
                $input->{ $f->field } = sprintf "%.0f", $col if $col;
            }
            elsif ($col)
            {
                my $colname = $f->name;
                push @bad, qq(Invalid item "$col" for integer field "$colname");
            }
        }
        else
        {
            $input->{ $f->field } = $col;
        }

        my $previous_field = $f;
        $col_count++ unless $drf;
    }

    my $write = !@bad && (!@bad_enum || $blank_invalid_enum);
    if ($write)
    {
        my $skip;

        # Insert record into DB. May still be problems
        my $record = GADS::Record->new(
            user   => undef,
            layout => $layout,
            schema => schema,
        );

        # Look for existing record?
        if ($update_unique)
        {
            my $unique_field =
                $update_unique eq 'ID' ? 'ID' : $update_unique_col->field;
            if ($input->{$unique_field})
            {
                if ($unique_field eq 'ID')
                {
                    try { $record->find_current_id($input->{ID}) };
                    if ($@)
                    {
                        push @bad,
qq(Failed to retrieve record ID $input->{ID} ($@). Data will not be uploaded.);
                        $skip = 1;
                    }
                }
                elsif (
                    my $existing = $record->find_unique(
                        $update_unique_col,
                        $input->{$unique_field},
                        retrieve_columns => \@all_column_ids
                    )
                    )
                {
                    $record = $existing;
                }
                else
                {
                    $record->initialise;
                }
            }
            else
            {
                $record->initialise;
                my $full = "@row";
                $full =~ s/\n//g;
                push @bad,
qq(Missing unique identifier for "$update_unique". Data will be uploaded as new record. Full record follows: $full);
            }
        }
        elsif ($skip_existing_unique)
        {
            my $unique_field = $skip_existing_unique_col->field;
            if (defined $input->{$unique_field})
            {
                if (
                    my $existing = $record->find_unique(
                        $skip_existing_unique_col, $input->{$unique_field}
                    )
                    )
                {
                    push @bad,
qq(Skipping: unique identifier "$input->{$unique_field}" already exists for "$skip_existing_unique");
                    $skip = 1;
                }
                else
                {
                    $record->initialise;
                }
            }
            else
            {
                $record->initialise;
                my $full = "@row";
                $full =~ s/\n//g;
                push @bad,
qq(Missing unique identifier for "$update_unique". Data will be uploaded as new record. Full record follows: $full);
            }
        }
        else
        {
            $record->initialise;
        }

        unless ($skip)
        {
            my @changes;
            my @failed = update_fields(\@fields, $input, $record, \@changes);
            if ($report_changes && @changes)
            {
                my $ident =
                      $update_unique eq 'ID'
                    ? $record->current_id
                    : $record->fields->{ $update_unique_col->id }->as_string;
                say STDOUT "Changes for record $ident are as follows:";
                say STDOUT $_ foreach @changes;
                say STDOUT "\n";
            }
            if (!@failed)
            {
                my $allow_update = [ keys %append ];
                try
                {
                    $record->write(
                        no_alerts              => 1,
                        dry_run                => $dry_run,
                        force                  => $force,
                        update_only            => $update_only,
                        no_change_unless_blank => $no_change_unless_blank,
                        allow_update           => $allow_update,
                        %options,
                    )
                };
                if ($@)
                {
                    my $exc     = $@->died;
                    my $message = ref $exc ? $@->died->message : $exc;
                    push @failed, "$message";
                    $write = 0;
                }
                else
                {
                    $count->{written}++;
                }
            }
            else
            {
                $write = 0;
            }
            push @bad, @failed;
        }
    }

    push @bad, @bad_enum;

    if (@bad)
    {
        push @all_bad,
            {
                problems => \@bad,
                row      => "@row",
            };
        if ($invalid_csv)
        {
            if (@invalid_report)
            {
                my @row2;
                push @row2, $row->[$_] foreach @invalid_report;
                $row = \@row2;
            }
            unshift @$row, $write ? 'Record written' : 'Record not written';
            push @$row, @bad;
            $csv->print($fh_invalid, $row);
            print $fh_invalid "\n";
        }
    }
}

$csv->eof or $csv->error_diag();
close $fh;
if ($invalid_csv)
{
    close $fh_invalid or die "$invalid_csv: $!";
}

$count->{errors} = @all_bad;
say STDOUT Dumper $count;

sub update_fields
{   my ($fields, $input, $record, $changes) = @_;
    my @bad;
    foreach my $col (@$fields)
    {
        next unless $col;                   # undef for ID column
        if (ref $col && $col->userinput)    # Not calculated fields
        {
            my $newv = $input->{ $col->field };
            if (!$record->current_id || defined $newv)
            {
                if ($col->type eq "daterange" && $ignore_incomplete_dateranges)
                {
                    $newv = [ '', '' ] if !($newv->[0] && $newv->[1]);
                }
                my $datum     = $record->fields->{ $col->id };
                my $old_value = $datum->as_string;
                my $was_blank = $datum->blank;
                if ($append{ $col->id })
                {
                    $newv =~ s/^\s+//
                        if !$old_value
                        ; # Trim preceding line returns if no value to append to
                          # Make sure CR at end of old value if applicable
                    $old_value =~ s/\s+$//;
                    $old_value = "$old_value\n"     if $old_value;
                    $newv      = $old_value . $newv if $append{ $col->id };
                }

           # Don't update existing value if no_change_unless_blank is "skip_new"
                if (   $no_change_unless_blank
                    && $no_change_unless_blank eq 'skip_new'
                    && $record->current_id
                    && !$was_blank
                    && !$append{ $col->id })
                {
                    my $colname = $col->name;
                    my $newvalue =
                          $col->fixedvals
                        ? $selects_reverse->{ $col->id }->{$newv}
                        : $newv;
                    if (lc $old_value ne lc $newvalue)
                    {
                        push @$changes,
qq(Not going to change value of "$colname" from "$old_value" to "$newvalue");
                    }
                    elsif ($old_value ne $newvalue)
                    {
                        push @$changes,
qq(Not going to change case of "$colname" from "$old_value" to "$newvalue")
                            unless $col->fixedvals;
                    }
                }
                else
                {
                    try { $datum->set_value($newv) };
                    if (my $exception = $@->wasFatal)
                    {
                        push @bad, $exception->message->toString;
                    }
                    elsif ($report_changes
                        && $record->current_id
                        && $datum->changed
                        && !$was_blank
                        && !$append{ $col->id })
                    {
                        my $colname  = $col->name;
                        my $newvalue = $datum->as_string;
                        push @$changes,
qq(Change value of "$colname" from "$old_value" to "$newvalue")
                            if lc $old_value ne
                            lc $newvalue;    # Don't report change of case
                    }
                }
            }
        }
    }
    @bad;
}

sub _trim
{   my $in = shift;
    $in =~ s/\h+$//;
    $in =~ s/^\h+//;
    $in;
}
