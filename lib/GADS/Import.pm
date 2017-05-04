=pod
GADS - Globally Accessible Data Store
Copyright (C) 2016 Ctrl O Ltd

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

package GADS::Import;

use DateTime;
use GADS::Record;
use List::MoreUtils 'first_index';
use Log::Report 'linkspace';
use Scope::Guard qw(guard);
use Text::CSV;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

has schema => (
    is       => 'ro',
    required => 1,
);

has layout => (
    is       => 'ro',
    required => 1,
);

has user_id => (
    is  => 'ro',
    isa => Int,
);

has take_first_enum => (
    is  => 'ro',
    isa => Bool,
);

has dry_run => (
    is  => 'ro',
    isa => Bool,
);

has ignore_string_zeros => (
    is  => 'ro',
    isa => Bool,
);

has force_mandatory => (
    is  => 'ro',
    isa => Bool,
);

# Column IDs of values that should be appended on being updated, not overwritten
has append => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has _append_index => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build__append_index
{   my $self = shift;
    my %index = map { $_ => 1 } @{$self->append};
    \%index;
}

has no_change_unless_blank => (
    is      => 'ro',
    isa     => sub {
        my $value = shift;
        !$value || $value =~ /(skip_new|bork)/ or error __"Invalid option {option} for no_change_unless_blank", option => $value;
    },
    default => '',
);

has blank_invalid_enum => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has round_integers => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has report_changes => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has update_only => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

# ID of unique column to search for update
has update_unique => (
    is      => 'ro',
    isa     => Int,
);

has skip_existing_unique => (
    is      => 'ro',
    isa     => Int,
);

has csv => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_csv
{   my $self = shift;
    Text::CSV->new({ binary => 1 }) # should set binary attribute?
        or error __"Cannot use CSV: {error}", error => Text::CSV->error_diag;
}

has file => (
    is  => 'ro',
);

has selects => (
    is      => 'ro',
    isa     => HashRef,
    builder => sub { +{} },
);

has selects_reverse => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build_selects_reverse
{   my $self = shift;
    my $reverse;
    foreach my $col_id (keys %{$self->selects})
    {
        $reverse->{$col_id} = { reverse %{$self->selects->{$col_id}} };
    }
    $reverse;
}

has fields => (
    is  => 'lazy',
    isa => ArrayRef,
);

has fh => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_fh
{   my $self = shift;
    # Ideally we would use fault() for failure, but that would report OS errors to the end user
    open my $fh, "<:encoding(utf8)", $self->file or error __"Unable to open CSV file for reading";
    $fh;
}

sub _reset_csv
{   my $self = shift;
    close $self->fh;
    $self->clear_csv;
    $self->clear_fh;
}

sub process
{   my $self = shift;
    error __"skip_existing_unique and update_unique are mutually exclusive"
        if $self->update_unique && $self->skip_existing_unique;
    $self->layout->user_permission_override(1);
    # Build fields from first row before we start reading. This may error
    $self->fields;

    # We now need to close the fh and reset CSV. If we don't do this, we
    # end up with duplicated lines being read once the process forks.
    $self->_reset_csv;

    # We need to fork for the actual import, as it could take very long.
    # The import process writes the status to the database so that the
    # user can see the progress.
    if ($ENV{GADS_NO_FORK})
    {
        # Used in tests when we don't want to fork
        $self->_import_rows;
    }
    else {
        if (my $kid = fork)
        {
            waitpid($kid, 0); # wait for child to start grandchild and clean up
        }
        else {
            if (my $grandkid = fork) {
                POSIX::_exit(0); # the child dies here
            }
            else {
                # We must catch exceptions here, otherwise we will never
                # reap the process. Set up a guard to be doubly-sure this
                # happens.
                my $guard = guard { POSIX::_exit(0) };
                # Despite the guard, we still operate in a try block, so as to catch
                # the messages from any exceptions and report them accordingly
                try { $self->_import_rows } hide => 'ALL'; # This takes a long time
                $@->reportAll(is_fatal => 0);
            }
        }
    }
}

sub _build_fields
{   my $self = shift;

    # Get first row for column headings
    my $fields_in = $self->csv->getline($self->fh);

    my @fields;

    foreach my $field (@$fields_in)
    {
        if (
            (
                ($self->update_unique && $self->update_unique == -11) ||
                ($self->skip_existing_unique && $self->skip_existing_unique == -11)
            ) &&
            $field eq 'ID'
        )
        {
            push @fields, $self->layout->column(-11); # Special case
        }
        elsif ($field =~ /^(Version Datetime|Version User ID)$/)
        {
            my $id = $self->layout->column_by_name($field)->id;
            push @fields, $self->layout->column($id);
        }
        else {
            my $f_rs = $self->schema->resultset('Layout')->search({
                name        => $field,
                instance_id => $self->layout->instance_id
            });
            error __x"Layout has more than one field named {name}", name => $field
                if $f_rs->count > 1;
            error __x"Field '{name}' in import headings not found in table", name => $field
                if $f_rs->count == 0;
            my $f = $f_rs->next;
            my $column = $self->layout->column($f->id);

            push @fields, $column;

            # Prefill select values
            if ($f->type eq "enum" || $f->type eq "tree")
            {
                foreach my $v (@{$column->enumvals})
                {
                    my $text = lc $v->{value};
                    # See if it already exists - possible multiple values
                    if (exists $self->selects->{$f->id}->{$text})
                    {
                        next if $self->take_first_enum;
                        my $existing = $self->selects->{$f->id}->{$text};
                        my @existing = ref $existing eq "ARRAY" ? @$existing : ($existing);
                        $self->selects->{$f->id}->{$text} = [@existing, $v->{id}];
                    }
                    else {
                        $self->selects->{$f->id}->{$text} = $v->{id};
                    }
                }
            }
            elsif ($f->type eq "person")
            {
                foreach my $v (@{$column->people})
                {
                    my $text = lc $v->value;
                    # See if it already exists - possible multiple values
                    if (exists $self->selects->{$f->id}->{$text})
                    {
                        my $existing = $self->selects->{$f->id}->{$text};
                        my @existing = ref $existing eq "ARRAY" ? @$existing : ($existing);
                        $self->selects->{$f->id}->{$text} = [@existing, $v->id];
                    }
                    else {
                        $self->selects->{$f->id}->{$text} = $v->id;
                    }
                }
            }
        }
    }

    \@fields;
}

sub _import_rows
{   my $self = shift;

    my $count = {
        in      => 0,
        written => 0,
        errors  => 0,
        skipped => 0,
    };

    my $parser_yymd = DateTime::Format::Strptime->new(
        pattern  => '%Y-%m-%d %R',
    );

    # Make sure fields is built from first row before we start reading
    $self->fields;

    # Used to retrieve all columns when searching unique field
    my @all_column_ids = map { $_->id } $self->layout->all;

    my $import = $self->schema->resultset('Import')->create({
        user_id => $self->user_id,
        type    => 'data',
        started => DateTime->now,
    });

    $self->csv->getline($self->fh); # Slurp off the header row

    while (my $row = $self->csv->getline($self->fh))
    {
        my @row = @$row
            or next;
        next if "@row" eq ''; # Skip blank lines, including zero

        # For the status report
        my $import_row = $self->schema->resultset('ImportRow')->new({
            import_id => $import->id,
        });

        $count->{in}++;

        my $col_count = 0;
        my $input; my @bad; my @bad_enum;
        my %options;
        foreach my $value (@row)
        {
            # Trim value
            $value =~ s/\h+$//;
            $value =~ s/^\h+//;

            my $col = $self->fields->[$col_count];

            if (!$col)
            {
                push @bad, qq(Extraneous value found on row: "$value");
            }
            elsif ($col->id == -11) # ID column
            {
                $input->{-11} = $value;
                $col_count++;
                next;
            }
            elsif ($col->name eq 'Version Datetime')
            {
                $options{version_datetime} = $parser_yymd->parse_datetime($value)
                    or push @bad, qq(Invalid version_datetime "$value");
            }
            elsif ($col->name eq 'Version User ID')
            {
                $options{version_userid} = $value;
            }
            elsif ($col->type eq "enum" || $col->type eq "tree" || $col->type eq "person")
            {
                # Get enum ID value
                if ($value eq "")
                {
                    # Blank value. Insertion will handle non-optional fields
                    $input->{$col->id} = $value;
                }
                else {
                    if (ref $self->selects->{$col->id}->{lc $value} eq "ARRAY")
                    {
                        push @bad, __x"Multiple instances of enum value '{value}' for '{colname}'",
                            value => $value, colname => $col->name;
                    }
                    elsif (exists $self->selects->{$col->id}->{lc $value})
                    {
                        # okay
                        $input->{$col->id} = $self->selects->{$col->id}->{lc $value};
                    }
                    else {
                        push @bad_enum, __x"Invalid enum value '{value}' for '{colname}'",
                            value => $value, colname => $col->name;
                        $input->{$col->id} = ''
                            if $self->blank_invalid_enum;
                    }
                }
            }
            elsif ($col->type eq "daterange")
            {
                if ($value =~ /^(\H+)\h*(-|to)\h*(\H+)$/)
                {
                    $input->{$col->id} = [$1,$3];
                }
                elsif ($value) {
                    push @bad, __x"Invalid daterange value '{value}' for '{colname}'",
                        value => $value, colname => $col->name;
                }
            }
            elsif ($col->type eq "string")
            {
                # Option to ignore zeros in text fields
                $input->{$col->id} = $self->ignore_string_zeros && $value eq '0' ? '' : $value;
            }
            elsif ($col->type eq "intgr")
            {
                my $qr = $self->round_integers ? qr/^[\.0-9]+$/ : qr/^[0-9]+$/;
                if ($value =~ $qr)
                {
                    # Round decimals if needed
                    $input->{$col->id} = $value && $self->round_integers ? sprintf("%.0f", $value) : $value;
                }
                elsif ($value) {
                    push @bad, __x"Invalid value '{value}' for integer field '{colname}'",
                        value => $value, colname => $col->name;
                }
            }
            else {
                $input->{$col->id} = $value;
            }

            $col_count++;
        }

        my $skip;
        my $write = !@bad && (!@bad_enum || $self->blank_invalid_enum);
        if ($write)
        {
            # Insert record into DB. May still be problems
            my $record = GADS::Record->new(
                user   => undef, # Write user has blank for imports, not logged-in user
                layout => $self->layout,
                schema => $self->schema,
            );

            # Look for existing record?

            my @changes;
            if ($self->update_unique)
            {
                if (my $unique_value = $input->{$self->update_unique})
                {
                    if ($self->update_unique == -11) # ID
                    {
                        try { $record->find_current_id($unique_value) };
                        if ($@)
                        {
                            push @bad, qq(Failed to retrieve record ID $unique_value ($@). Data will not be uploaded.);
                            $skip = 1;
                        }
                    }
                    elsif (my $existing = $record->find_unique($self->layout->column($self->update_unique), $unique_value, @all_column_ids))
                    {
                        $record = $existing;
                    }
                    else {
                        $record->initialise;
                    }
                }
                else {
                    $record->initialise;
                    my $full = "@row";
                    $full =~ s/\n//g;
                    push @changes, __x"Missing unique identifier for '{unique_field}'. Data will be uploaded as new record.",
                        unique_field => $self->layout->column($self->update_unique)->name;
                }
            }
            elsif (my $unique_id = $self->skip_existing_unique)
            {
                if (defined $input->{$unique_id})
                {
                    my $unique_field = $self->layout->column($unique_id);
                    if (my $existing = $record->find_unique($unique_field, $input->{$unique_id}))
                    {
                        push @bad, __x"Skipping: unique identifier '{value}' already exists for '{unique_field}'",
                            value => $input->{$unique_id}, unique_field => $unique_field->name;
                        $skip = 1;
                    }
                    else {
                        $record->initialise;
                    }
                }
                else {
                    $record->initialise;
                    my $full = "@row";
                    $full =~ s/\n//g;
                    push @bad, qq(Missing unique identifier for "$input->{$unique_id}". Data will be uploaded as new record.);
                }
            }
            else {
                $record->initialise;
            }

            if ($skip)
            {
                $count->{skipped}++;
            }
            else {
                my @failed = $self->update_fields($input, $record, \@changes);

                if ($self->report_changes && @changes)
                {
                    $import_row->changes(join ', ', @changes);
                }

                if (!@failed)
                {
                    try { $record->write(
                        no_alerts              => 1,
                        dry_run                => $self->dry_run,
                        force_mandatory        => $self->force_mandatory,
                        update_only            => $self->update_only,
                        no_change_unless_blank => $self->no_change_unless_blank,
                        allow_update           => $self->append,
                        %options
                    ) };
                    if ($@)
                    {
                        my $exc = $@->died;
                        my $message = ref $exc ? $@->died->message : $exc;
                        push @failed, "$message";
                        $write = 0;
                    }
                    else {
                        $count->{written}++;
                    }
                }
                else {
                    $write = 0;
                }
                push @bad, @failed;
            }
        }

        push @bad, @bad_enum;

        $self->csv->combine(@row);
        $import_row->content($self->csv->string);
        $import_row->status($write ? 'Record written' : 'Record not written');

        if (@bad)
        {
            $count->{errors}++ unless $skip; # already counted in skip
            $import_row->errors(join ', ', @bad);
        }

        $import_row->insert;
        
        $import->update({
            row_count => $count->{in},
        });
    }

    my $result = "Rows in: $count->{in}, rows written: $count->{written}, errors: $count->{errors}";
    $import->update({
        completed     => DateTime->now,
        result        => $result,
        written_count => $count->{written},
        error_count   => $count->{errors},
        skipped_count => $count->{skipped},
    });
}

sub update_fields
{   my ($self, $input, $record, $changes) = @_;
    my @bad;
    foreach my $col (@{$self->fields})
    {
        if ($col->userinput && !$col->internal) # Not calculated fields
        {
            my $newv = $input->{$col->id};
            if (!$record->current_id || $newv ne '')
            {
                my $datum = $record->fields->{$col->id};
                my $old_value = $datum->as_string;
                my $was_blank = $datum->blank;

                if ($self->_append_index->{$col->id})
                {
                    $newv =~ s/^\s+// if !$old_value; # Trim preceding line returns if no value to append to
                    # Make sure CR at end of old value if applicable
                    $old_value =~ s/\s+$//;
                    $old_value = "$old_value\n" if $old_value;
                    $newv = $old_value.$newv if $self->_append_index->{$col->id};
                }

                # Don't update existing value if no_change_unless_blank is "skip_new"
                if ($self->no_change_unless_blank eq 'skip_new' && $record->current_id && !$was_blank && !$self->_append_index->{$col->id})
                {
                    my $colname = $col->name;
                    my $newvalue = $col->fixedvals
                        ? $self->selects_reverse->{$col->id}->{$newv}
                        : $col->type eq 'daterange'
                        ? "$newv->[0] to $newv->[1]"
                        : $newv;
                    if (lc $old_value ne lc $newvalue)
                    {
                        push @$changes, qq(Not going to change value of "$colname" from "$old_value" to "$newvalue")
                    }
                    elsif ($old_value ne $newvalue)
                    {
                        push @$changes, qq(Not going to change case of "$colname" from "$old_value" to "$newvalue")
                            unless $col->fixedvals;
                    }
                }
                else {
                    try { $datum->set_value($newv) };
                    if (my $exception = $@->wasFatal)
                    {
                        push @bad, $exception->message->toString;
                    }
                    elsif ($self->report_changes && $record->current_id && $datum->changed && !$was_blank && !$self->_append_index->{$col->id})
                    {
                        my $colname = $col->name;
                        my $newvalue = $datum->as_string;
                        push @$changes, qq(Change value of "$colname" from "$old_value" to "$newvalue")
                            if  lc $old_value ne lc $newvalue; # Don't report change of case
                    }
                }
            }
        }
    }
    @bad;
}

1;
