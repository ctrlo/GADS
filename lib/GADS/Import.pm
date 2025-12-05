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
use File::BOM qw( open_bom );
use GADS::Record;
use List::MoreUtils 'first_index';
use Log::Report 'linkspace';
use Scope::Guard qw(guard);
use Text::CSV;
use Moo;
use MooX::Types::MooseLike::Base qw/Bool ArrayRef HashRef Int Bool/;

has schema => (
    is       => 'ro',
    required => 1,
);

has layout => (
    is       => 'ro',
    required => 1,
);

has user => (
    is       => 'ro',
    required => 1,
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

has split_multiple => (
    is  => 'ro',
    isa => Bool,
);

has short_names => (
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
    my $reverse = {};
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
    my $fh;
    # Use Open::BOM to deal with BOM files being imported
    try { open_bom($fh, $self->file) }; # Can raise various exceptions which would cause panic
    error __"Unable to open CSV file for reading: ".$@->wasFatal->message if $@; # Make any error user friendly
    $fh;
}

sub _reset_csv
{   my $self = shift;
    close $self->fh;
    $self->clear_csv;
    $self->clear_fh;
}

sub process
{   my ($self, %options) = @_;
    error __"skip_existing_unique and update_unique are mutually exclusive"
        if $self->update_unique && $self->skip_existing_unique;
    # XXX In the future this should probably reflect the user's permissions,
    # if/when importing is a separate permission
    local $GADS::Schema::IGNORE_PERMISSIONS = 1;
    # Build fields from first row before we start reading. This may error
    $self->fields;

    # We now need to close the fh and reset CSV. If we don't do this, we
    # end up with duplicated lines being read once the process forks.
    $self->_reset_csv;
    # Reopen the file, otherwise as it's a tmp file it will be deleted as soon
    # as the parent process exits (before the child has had a chance to open
    # it)
    my $fh = $self->fh;

    my $import_rs = $self->_import_status_rs;

    # We need to fork for the actual import, as it could take very long.
    # The import process writes the status to the database so that the
    # user can see the progress.
    if ($ENV{GADS_NO_FORK} || $options{no_fork})
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
                # Because we are forked, any messages caught here do not
                # actually go anywhere for the user to see (and do not appear
                # to go to syslogger either because we are inside another try
                # block). Therefore, record fatal errors to the status in the
                # database.
                $self->_import_status_rs->update->update({
                    result => $@->wasFatal->message,
                    completed => DateTime->now,
                }) if $@;
            }
        }
    }

    $import_rs;
}

sub _build_fields
{   my $self = shift;

    # Get first row for column headings
    my $fields_in = $self->csv->getline($self->fh);

    my @fields;
    my $column_id = $self->layout->column_id;

    foreach my $field (@$fields_in)
    {
        if (
            (
                ($self->update_unique && $self->update_unique == $column_id->id) ||
                ($self->skip_existing_unique && $self->skip_existing_unique == $column_id->id)
            ) &&
            $field eq ($self->short_names ? '_id' : 'ID')
        )
        {
            push @fields, $self->layout->column($column_id->id); # Special case
        }
        # Short name internal fields
        elsif ($self->short_names && $field =~ /^(_version_datetime|_version_user)$/)
        {
            my $id = $self->layout->column_by_name_short($field)->id;
            push @fields, $self->layout->column($id);
        }
        # Full name internal fields
        elsif ($field =~ /^(Last edited time|Last edited by)$/)
        {
            my $id = $self->layout->column_by_name($field)->id;
            push @fields, $self->layout->column($id);
        }
        else {
            my $search = {
                instance_id => $self->layout->instance_id,
            };
            $search->{name} = $field if !$self->short_names;
            $search->{name_short} = $field if $self->short_names;
            my $f_rs = $self->schema->resultset('Layout')->search($search);
            error __x"Layout has more than one field named {name}", name => $field
                if $f_rs->count > 1;
            error __x"Field '{name}' in import headings not found in table", name => $field
                if $f_rs->count == 0;
            my $f = $f_rs->next;
            my $column = $self->layout->column($f->id);

            error __x"Field '{name}' is not a user-input field", name => $field
                if !$column->userinput && (!$self->update_unique || $column->id != $self->update_unique);

            push @fields, $column;

            # Prefill select values
            if ($f->type eq "enum" || $f->type eq "tree")
            {
                foreach my $v (@{$column->enumvals})
                {
                    next if $v->{deleted};
                    my $text = _trim(lc $v->{value});
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

has _import_status_rs => (
    is => 'lazy',
);

sub _build__import_status_rs
{   my $self = shift;
    $self->schema->resultset('Import')->create({
        user_id     => $self->user->id,
        type        => 'data',
        started     => DateTime->now,
        instance_id => $self->layout->instance_id,
    });
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

    my $import = $self->_import_status_rs;

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
        foreach my $cell (@row)
        {
            my $col = $self->fields->[$col_count];

            if (!$col)
            {
                push @bad, qq(Extraneous value found on row: "$cell");
                next;
            }
            elsif ($col->id == $self->layout->column_id->id) # ID column
            {
                push @{$input->{$col->id}}, $cell;
                $col_count++;
                next;
            }

            $input->{$col->id} = [];

            my @values;
            if ($self->split_multiple && $col->multivalue)
            {
                @values = split /,/, $cell;
            }
            else {
                @values = ($cell);
            }

            foreach my $value (@values)
            {
                # Trim value
                $value = _trim($value);

                if ($col->name eq ($self->short_names ? '_version_datetime' : 'Last edited time'))
                {
                    $options{version_datetime} = $parser_yymd->parse_datetime($value)
                        or push @bad, qq(Invalid version_datetime "$value");
                }
                elsif ($col->name eq ($self->short_names ? '_version_user' : 'Last edited by'))
                {
                    $options{version_userid} = $value;
                }
                elsif ($col->type eq "enum" || $col->type eq "tree")
                {
                    # Get enum ID value
                    if ($value eq "")
                    {
                        # Blank value. Insertion will handle non-optional fields
                        push @{$input->{$col->id}}, $value;
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
                            push @{$input->{$col->id}}, $self->selects->{$col->id}->{lc $value};
                        }
                        else {
                            push @bad_enum, __x"Invalid enum value '{value}' for '{colname}'",
                                value => $value, colname => $col->name;
                            push @{$input->{$col->id}}, ''
                                if $self->blank_invalid_enum;
                        }
                    }
                }
                elsif ($col->type eq "daterange")
                {
                    if (!$value)
                    {
                        push @{$input->{$col->id}}, ['',''];
                    }
                    elsif ($value =~ /^(\H+)\h*(-|to)\h*(\H+)$/)
                    {
                        push @{$input->{$col->id}}, [$1,$3];
                    }
                    elsif ($value) {
                        push @bad, __x"Invalid daterange value '{value}' for '{colname}'",
                            value => $value, colname => $col->name;
                    }
                }
                elsif ($col->type eq "string")
                {
                    # Option to ignore zeros in text fields
                    push @{$input->{$col->id}}, $self->ignore_string_zeros && $value eq '0' ? '' : $value;
                }
                elsif ($col->type eq "intgr")
                {
                    if ($value)
                    {
                        my $qr = $self->round_integers ? qr/^[\.0-9]+$/ : qr/^[0-9]+$/;
                        if ($value =~ $qr)
                        {
                            # Round decimals if needed
                            $value = $value && $self->round_integers ? sprintf("%.0f", $value) : $value;
                            push @{$input->{$col->id}}, $value;
                        }
                        elsif ($value) {
                            push @bad, __x"Invalid value '{value}' for integer field '{colname}'",
                                value => $value, colname => $col->name;
                        }
                    }
                }
                else {
                    push @{$input->{$col->id}}, $value;
                }
            }

            $col_count++;
        }

        my $skip;
        my $write = !@bad && (!@bad_enum || $self->blank_invalid_enum);
        if ($write)
        {
            # Insert record into DB. May still be problems
            my $record = GADS::Record->new(
                user   => $self->user,
                layout => $self->layout,
                schema => $self->schema,
            );

            # Look for existing record?

            my @changes;
            if ($self->update_unique)
            {
                my @values = $input->{$self->update_unique} && @{$input->{$self->update_unique}};
                if (!$input->{$self->update_unique})
                {
                    push @bad, qq(Specified unique field to update not found in import);
                    $skip = 1;
                }
                elsif (@values > 1)
                {
                    push @bad, qq(Multiple values specified for unique field to update);
                    $skip = 1;
                }
                elsif (@values == 1)
                {
                    my $unique_value = pop @values;
                    if ($self->update_unique == $self->layout->column_id->id) # ID
                    {
                        if ($unique_value)
                        {
                            try { $record->find_current_id($unique_value, instance_id => $self->layout->instance_id) };
                            if ($@)
                            {
                                push @bad, qq(Failed to retrieve record ID $unique_value ($@). Data will not be uploaded.);
                                $skip = 1;
                            }
                        }
                        else {
                            push @changes, __x"Unique identifier ID blank, data will be uploaded as new record.";
                            $record->initialise;
                        }
                    }
                    elsif (my $existing = $record->find_unique($self->layout->column($self->update_unique), $unique_value, retrieve_columns => \@all_column_ids))
                    {
                        $record = $existing;
                    }
                    else {
                        push @changes, __x"Unique identifier '{unique_value}' does not exist. Data will be uploaded as new record.",
                            unique_value => $unique_value;
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
                my @values = @{$input->{$unique_id}};
                if (@values > 1)
                {
                    push @bad, qq(Multiple values specified for unique field);
                    $skip = 1;
                }
                elsif (defined $values[0])
                {
                    my $unique_field = $self->layout->column($unique_id);
                    if (my $existing = $record->find_unique($unique_field, $values[0]))
                    {
                        push @bad, __x"Skipping: unique identifier '{value}' already exists for '{unique_field}'",
                            value => $values[0], unique_field => $unique_field->name;
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
                    push @bad, qq(Missing unique identifier. Data will be uploaded as new record.);
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

    my $result = "Rows in: $count->{in}, rows written: $count->{written}, errors: $count->{errors}, skipped: $count->{skipped}";
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
            my $datum = $record->fields->{$col->id};
            my $old_value = $datum->as_string;
            my $was_blank = $datum->blank;

            if ($self->_append_index->{$col->id})
            {
                if ($col->multivalue)
                {
                    push @$newv, @{$datum->set_values};
                }
                else {
                    $newv = pop @$newv;
                    $newv =~ s/^\s+// if !$old_value; # Trim preceding line returns if no value to append to
                    # Make sure CR at end of old value if applicable
                    $old_value =~ s/\s+$//;
                    $old_value = "$old_value\n" if $old_value;
                    $newv = $old_value.$newv if $self->_append_index->{$col->id};
                }
            }

            # Don't update existing value if no_change_unless_blank is "skip_new"
            if ($self->no_change_unless_blank eq 'skip_new' && $record->current_id && !$was_blank && !$self->_append_index->{$col->id})
            {
                my $colname = $col->name;
                my $newvalue = join ', ', map {
                    $col->fixedvals
                        ? $self->selects_reverse->{$col->id}->{$_}
                        : $col->type eq 'daterange'
                        ? "$_->[0] to $_->[1]"
                        : $_;
                    } @$newv;
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
    @bad;
}

sub _trim
{   my $in = shift;
    $in =~ s/\h+$//;
    $in =~ s/^\h+//;
    $in;
}

1;
