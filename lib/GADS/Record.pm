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

package GADS::Record;

use Dancer2 ':script';
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use GADS::Record;
use GADS::Util         qw(:all);
use String::CamelCase qw(camelize);
use Ouch;
use Safe;
use DateTime;
use DateTime::Format::Strptime qw( );
use POSIX qw(ceil);
schema->storage->debug(1);

use GADS::Schema;

sub _safe_eval;
sub _search_construct;

sub files
{
    my ($class, $item) = @_;
    my $record = $class->current({ current_id => $item });
    my %files;
    foreach my $col (@{GADS::View->columns({ files => 1 })})
    {
        my $f = $col->{field};
        $files{$f} = $record->$f ? $record->$f->value->name : '';
    }
    %files;
}


sub current($$)
{   my ($class, $item) = @_;

    my @join;     # Used for conditionals, which may not be shown in the view of choice
    my @prefetch; # Used for any field that we display the value for
    
    # So that we know how many times we've joined a table.
    # DBIC automatically suffixes additional joines _2 etc.
    my %joincount;
    # Keep a track of which we have joined at prefetch, so that we
    # add to this for the searches, otherwise use a join
    my %prefetch_used;

    # First, add all the columns in the view as a prefetch. During
    # this stage, we keep track of what we've added, so that we
    # can act accordingly during the filters
    my @columns;
    if (my $view_id = $item->{view_id})
    {
        @columns = @{GADS::View->columns({ view_id => $view_id })};
    }
    else {
        @columns = @{GADS::View->columns};
    }
    my %cache_cols; # Any column in the view that should be cached
    push @columns, @{$item->{additional}} if $item->{additional};
    foreach my $c (@columns)
    {
        # If it's a calculated/rag value, prefetch the columns in the calc
        if ($c->{type} eq 'rag' || $c->{type} eq 'calc')
        {
            push @columns, @{$c->{$c->{type}}->{columns}};
            $cache_cols{$c->{field}} = $c;
        } elsif ($c->{type} eq 'person')
        {
            # Still need to make sure we have cache of person's full name
            $cache_cols{$c->{field}} = $c;
        }

        # Value of enums are always "value" (joined table)
        push @prefetch, $c->{join};          # Add to prefetch list
        $prefetch_used{$c->{sprefix}} = 1;   # Tag that we've prefetched this value
        $joincount{$c->{sprefix}}++;         # Increment join counter to track _2 suffixes
    }

    my $search;
    if($item->{record_id}) {
        $search->{"me.id"} = $item->{record_id};
    }
    elsif ($item->{current_id})
    {
        $search->{"me.id"} = $item->{current_id};
        $search->{approval} = 0;
    }
    else {
        $search->{"record.record_id"} = undef;
        $search->{approval} = 0;
    }

    # First see if any calc or rag values are missing their cache values.
    # If so, insert them
    my %calcsearch = %{$search}; # Only update rows from current result
    my @cache_cols_join;         # The fields to join
    my @cache_cols_search;       # The search for undefined values
    my %cache_cols_done;         # Track whether we have already seen this field
    foreach my $csearch (values %cache_cols)
    {
        # Create the search parameter, looking for undef fields of the column
        my $sprefix = $csearch->{sprefix};
        next if $cache_cols_done{$sprefix}; # No need if same cached column already joined
        push @cache_cols_join, $csearch->{join};
        push @cache_cols_search, {"$sprefix.value" => undef };
        $cache_cols_done{$sprefix} = 1;
    }
    $calcsearch{'-or'} = \@cache_cols_search if @cache_cols_search;
    # Find them
    my @tocache;
    if ($item->{record_id})
    {
        @tocache = rset('Record')->search(
            \%calcsearch,
            {
                join => \@cache_cols_join,
            }
        )->all;
    }
    else {
        @tocache = rset('Current')->search(
            \%calcsearch,
            {
                join => {record => \@cache_cols_join},
            }
        )->all;
    }
    # For any that are found to be empty, update them with a value
    foreach my $rec (@tocache)
    {
        foreach my $col (values %cache_cols)
        {
            # Force creation of the cache value
            if ($item->{record_id})
            {
                item_value($col, $rec);
            }
            else {
                item_value($col, $rec->record);
            }
        }
    }

    # Now add all the filters as joins (we don't need to prefetch this data). However,
    # the filter might also be a column in the view from before, in which case add
    # it to, or use, the prefetch. We use the tracking variables from above.
    if (my $view_id = $item->{view_id})
    {
        foreach my $filter (@{GADS::View->filters($view_id)})
        {
            my $field = $filter->{column}->{field};
            my $fieldsearch;

            # As per the prefix, what we join depends on the type of field
            my $sprefix = $filter->{column}->{sprefix};
            my $joinv   = $filter->{column}->{join};
            if ($prefetch_used{$sprefix})
            {
                push @prefetch, $joinv;
            }
            else {
                push @join, $joinv;
            }
            $joincount{$sprefix}++;
            my $in = $joincount{$sprefix} == 1 ? '' : "_$joincount{$sprefix}"; # Join suffix
            $fieldsearch = "$sprefix$in.value";
            
            my $svalue = _search_construct $filter->{operator}, $filter->{value}
                or next;

            # Underscore in mysql is special for like
            $svalue->{'-like'} =~ s/\_/\\\_/g if $svalue->{'-like'};
            $search->{$fieldsearch} = $svalue;
        }
    }

    my @all;
    if ($item->{record_id})
    {
        unshift @prefetch, 'current'; # Add info about related current record

        my $select = {
            prefetch => \@prefetch,
            join     => \@join,
        };

        @all = rset('Record')->search(
            $search, $select
        )->all;
    }
    else {
        my $orderby = config->{gads}->{serial} eq "auto" ? 'me.id' : 'me.serial';

        # XXX Okay, this is a bit weird - we join current to record to current.
        # This is because we return records at the end, and it allows current
        # to be used when the record is used. Is there a better way?
        unshift @prefetch, 'current';

        my $select = {
            prefetch => {'record' => \@prefetch},
            join     => {'record' => \@join},
            order_by => $orderby,
        };

        # First count all values from result
        my $count = rset('Current')->search(
            $search, $select
        )->count;

        # Send page information back
        my $rows = $item->{rows};
        $item->{pages} = $rows ? ceil($count / $rows) : 1;

        # Now redo query but with just one page of results
        my $page = $item->{page}
                 ? $item->{page} > $item->{pages}
                 ? $item->{pages}
                 : $item->{page}
                 : undef;

        $select->{rows} = $rows if $rows;
        $select->{page} = $page if $page;
        my $result = rset('Current')->search(
            $search, $select
        );

        @all = map { $_->record } $result->all;
    }

    wantarray ? @all : pop(@all);
}

sub _filter
{   my ($search, $value) = @_;

    my ($operator) = keys $search;
    my ($sval)     = values $search;

    if ($operator eq '-like')
    {
        $sval =~ s/%(.*)%/$1/;
        return 1 if ($value =~ /$sval/i);
    }
    elsif ($operator eq '=')
    {
        return 1 if lc $value eq lc $sval;
    }
    return 0;
}

sub _search_construct
{   my ($operator, $value) = @_;

    if ($operator eq "equal")
    {
        { '=', $value};
    }
    elsif ($operator eq "gt")
    {
        { '>', $value};
    }
    elsif ($operator eq "lt")
    {
        { '<', $value};
    }
    elsif ($operator eq "contains")
    {
        { '-like', "%$value%"};
    }
}

sub csv
{
    my ($class, $colnames, $data) = @_;

    my @colnames = @$colnames;
    my $csv = Text::CSV->new;
    $csv->combine(@colnames)
        or ouch 'csvfail', "An error occurred producing the CSV headings: ".$csv->error_input;
    my $csvout = $csv->string."\n";
    my $numcols = $#colnames + 1;
    foreach my $line (@$data)
    {
        $csv->combine(@$line[1 .. $numcols])
            or ouch 'csvfail', "An error occurred producing a line of CSV: ".$csv->error_input;
        $csvout .= $csv->string."\n";
    }
    $csvout;
}

sub data
{
    my ($class, $view_id, $records, $options) = @_;
    my @output;

    my $columns = GADS::View->columns({ view_id => $view_id });

    RECORD:
    foreach my $record (@$records)
    {
        my $serial = config->{gads}->{serial} eq "auto" ? $record->current->id : $record->current->serial;
        my @rec = ($record->id, $serial);

        foreach my $column (@$columns)
        {
            my $field = 'field'.$column->{id};
            # Check for RAG/calc filters. These can't be done at record retrieval
            # time, as the other filters are
            my $value = item_value($column, $record, $options);
            push @rec, $value;
        }
        push @output, \@rec;
    }
    @output;
}

sub rag
{   my ($class, $column, $record) = @_;

    my $rag   = $column->{rag};
    my $field = $column->{field};
    my $item  = $record->$field;
    if (defined $item)
    {
        return $item->value;
    }
    else {
        my $green = $rag->{green};
        my $amber = $rag->{amber};
        my $red   = $rag->{red};

        foreach my $col (@{$rag->{columns}})
        {
            my $name = $col->{name};
            my $value = item_value($col, $record, {epoch => 1});
            $green =~ s/\[$name\]/$value/gi;
            $amber =~ s/\[$name\]/$value/gi;
            $red   =~ s/\[$name\]/$value/gi;
        }

        # Insert current date if required
        my $now = time;
        $green =~ s/CURDATE/$now/g;
        $amber =~ s/CURDATE/$now/g;
        $red   =~ s/CURDATE/$now/g;

        my $okaycount;
        foreach my $code ($green, $amber, $red)
        {
            $_ = $code;
            last unless /^[ \S]+$/; # Only allow normal spaces
            last if /[\[\]]+/; # Do not allow any remaining brackets
            last if /\\/; # No escapes please
            s/"[^"]+"//g;
            m!^([-()*+/0-9<> ]|&&|eq|==)+$! or last;
            $okaycount++;
        }

        my $ragvalue;
        if ($okaycount == 3)
        {
            if (_safe_eval "($red)")
            {
                $ragvalue = 'red';
            }
            elsif (_safe_eval "($amber)")
            {
                $ragvalue = 'amber';
            }
            elsif (_safe_eval "($green)")
            {
                $ragvalue = 'green';
            }
            else {
                $ragvalue = 'grey';
            }
        }
        else {
            $ragvalue = 'grey';
        }
        rset('Ragval')->create({
            record_id => $record->id,
            layout_id => $column->{id},
            value     => $ragvalue,
        });
        $ragvalue;
    }
}

sub calc
{   my ($class, $column, $record) = @_;

    my $calc  = $column->{calc};
    my $field = $column->{field};
    my $item  = $record->$field;
    if (defined $item)
    {
        return $item->value;
    }
    else {
        my $code = $calc->{calc};
        foreach my $col (@{$calc->{columns}})
        {
            my $name = $col->{name};
            next unless $code =~ /\[$name\]/i;

            my $value = item_value($col, $record, {epoch => 1});
            $value = "\"$value\"" unless $value =~ /^[0-9]+$/;
            $code =~ s/\[$name\]/$value/gi;
        }
        # Insert current date if required
        my $now = time;
        $code =~ s/CURDATE/$now/g;

        my $value = _safe_eval "$code";
        rset('Calcval')->create({
            record_id => $record->id,
            layout_id => $column->{id},
            value     => $value,
        });
        $value;
    }
}

sub person
{   my ($class, $column, $record) = @_;

    my $calc  = $column->{calc};
    my $field = $column->{field};
    my $item  = $record->$field;

    return undef unless $item; # Missing value

    if (defined $item->value->value)
    {
        return $item->value->value;
    }
    else {
        my $firstname = $record->$field ? $record->$field->value->firstname : '';
        my $surname   = $record->$field ? $record->$field->value->surname : '';
        my $value     = "$surname, $firstname";

        $item->value->update({
            value     => $value,
        });
        $value;
    }
}

sub approve
{   my ($class, $id, $values, $uploads) = @_;

    # Search for records requiring approval
    my $search->{approval} = 1;
    $search->{id} = $id if $id; # with ID if required
    my @r = rset('Record')->search($search)->all;

    return \@r unless $values; # Summary only required

    my $r = shift @r; # Just the first please
    my $previous;
    $previous = $r->record if $r->record; # Its related record

    my $columns = GADS::View->columns; # All fields

    foreach my $col (@$columns)
    {
        next if $col->{type} eq "rag" || $col->{type} eq "calc";
        my $fn = "field".$col->{id};

        my $v;
        if ($col->{type} eq 'file')
        {
            # If a new file has been uploaded, use that instead
            if (my $upload = $uploads->{"file$col->{id}"})
            {
                my $upload = {
                    name     => $upload->filename,
                    mimetype => $upload->type,
                    content  => $upload->content,
                };
                $values->{$fn} = $r->$fn->value->update($upload)->id;
            }
            else {
                $values->{$fn} = $r->$fn->value->id; # Delete hidden value from submitted form
            }
        }
        if (defined $values->{$fn})
        {
            # Field was submitted in form
            $v = $values->{$fn};
            !$v && !$col->{optional}
                and ouch 'missing', "Field $col->{name} is not optional. Please enter a value.";
        } elsif($previous && $previous->$fn)
        {
            # No field submitted - not part of approval. Use previous value if existing
            $v = $previous->$fn->value;
        } elsif (!$col->{optional} && $previous->$fn)
        {
            ouch 'missing', "Field $col->{name} is not optional. Please enter a value.";
        }

        next unless defined $v;

        # Does a value exist to update?
        if ($r->$fn)
        {
            $r->$fn->update({ value => $v })
                or ouch 'dbfail', "Database error updating new approved values";
        }
        else {
            my $type = $col->{type} eq 'tree' ? 'enum' : $col->{type};
            my $table = camelize $type;
            rset($table)->create({
                record_id => $r->id,
                layout_id => $col->{id},
                value     => $v,
            }) or ouch 'dbfail', "Failed to create database entry for appproved field ".$col->{name};
        }
    }
    $r->update({ approval => 0, record_id => undef, created => \"NOW()" })
        or ouch 'dbfail', "Database error when removing approval status from updated record";
    rset('Current')->find($r->current_id)->update({ record_id => $r->id })
        or ouch 'dbfail', "Database error when updating current record tracking";
}
    
sub versions($$)
{   my ($class, $id) = @_;
    my @records = rset('Record')->search({
        'current_id' => $id,
        approval     => 0,
        record_id    => undef
    },{
        order_by => { -desc => 'created' }
    })->all;
    \@records;
}

sub update
{   my ($class, $params, $user, $uploads) = @_;

    my $current_id = $params->{current_id} || 0;

    # Create a new overall record if it's new, otherwise
    # load the old values
    my $old;
    if ($current_id)
    {
        ouch 'nopermission', "No permissions to update an entry"
            if !$user->{permissions}->{update};
        $old = GADS::Record->current({ current_id => $current_id });
    }
    else
    {
        ouch 'nopermission', "No permissions to add a new entry"
            if !$user->{permissions}->{create};
    }

    # Set up a date parser
    my $format = DateTime::Format::Strptime->new(
         pattern   => '%Y-%m-%d',
         time_zone => 'local',
    );

    my $noapproval = $user->{permissions}->{update_noneed_approval} || $user->{permissions}->{approver};

    # First loop round: sanitise and see which if any have changed
    my $layout_rs = rset('Layout');
    my $newvalue; my $changed; my $oldvalue;
    my %appfields; # Any fields that need approval
    my ($need_app, $need_rec); # Whether a new approval_rs or record_rs needs to be created
    foreach my $fn (keys %$params)
    {
        # All data fields will be "field" with an integer key
        next unless $fn =~ /^field(\d+)$/;
        my $fieldid = $1;

        # Keep a record of all the old values so that we can compare
        $oldvalue->{$fieldid} = ($old && $old->$fn) ? $old->$fn->value : undef;

        my $field = $layout_rs->find($fieldid);
        my $value = $params->{$fn};

        if (!$value && !$field->optional && (!$old || ($old && $oldvalue->{$fieldid})))
        {
            # Only if a value was set previously, otherwise a field that had no
            # value might be made mandatory, but if it's read-only then that will
            # stop users updating other fields of the record
            ouch 'missing', '"'.$field->name.'" is not optional. Please enter a value.';
        }
        elsif ($field->type eq 'date')
        {
            # Convert to DateTime object if required
            $newvalue->{$fieldid} = $format->parse_datetime($value);
            $newvalue->{$fieldid} or ouch 'invaliddate', "Invalid date \"$value\"";
        }
        elsif ($field->type eq 'file')
        {
            # Find the file upload and store for later
            if (my $upload = $uploads->{"file$fieldid"})
            {
                $newvalue->{$fieldid} = {
                    name     => $upload->filename,
                    mimetype => $upload->type,
                    content  => $upload->content,
                };
            }
            else {
                $newvalue->{$fieldid} = $oldvalue->{$fieldid}; # DB ID of existing filename
            }
        }
        else
        {
            $newvalue->{$fieldid} = $value;
        }

        # Keep a track as to whether a value has changed. Keep it undef for new values
        $changed->{$fieldid} = $old ? _changed($field, $oldvalue->{$fieldid}, $newvalue->{$fieldid}) : undef;

        ouch 'nopermission', "Field ID $fieldid is read only"
            if $changed->{$fieldid} &&
            $field->permission == READONLY &&
            !$noapproval;

        if ($old && $changed->{$fieldid})
        {
            # Update to record and the field has changed
            if ($field->permission == APPROVE)
            {
                # Field needs approval
                if ($noapproval)
                {
                    # User has permission to not need approval
                    $need_rec = 1;
                }
                else {
                    # This needs an approval record
                    $need_app = 1;
                    $appfields{$fieldid} = 1;
                }
            }
            else {
                # Field can be updated openly (OPEN)
                $need_rec = 1;
            }
        }
        if (!$old)
        {
            # New record
            if ($noapproval)
            {
                # User has permission to create new without approval
                if (($field->permission == APPROVE || $field->permission == READONLY)
                    && !$noapproval)
                {
                    # But field needs permission
                    $need_app = 1;
                    $appfields{$fieldid} = 1;
                }
                else {
                    $need_rec = 1;
                }
            }
            else {
                # Whole record creation needs approval
                $need_app = 1;
                $appfields{$fieldid} = 1;
            }
        }
    }

    # Anything to update?
    return unless $need_app || $need_rec;

    # New record?
    unless ($current_id)
    {
        my $serial;
        if (config->{gads}->{serial} ne "auto")
        {
            $serial = $params->{serial}
                or ouch 'noserial', "No serial number was supplied";
        }
        $current_id = rset('Current')->create({serial => $serial})->id;
    }

    my $record_rs   = record_rs($current_id, $user) if $need_rec;

    my $rid = $record_rs ? $record_rs->id
                         : $old ? $old->id : undef;
    my $approval_rs = approval_rs($current_id, $rid) if $need_app;

    unless ($old)
    {
        # New entry, so save record ID to user for retrieval of previous
        # values if needed for another new entry. Use the approval ID id
        # it exists, otherwise the record ID.
        my $id = $approval_rs ? $approval_rs->id : $record_rs->id;
        rset('User')->find($user->{id})->update({ lastrecord => $id });
    }

    # Write all the values
    foreach my $fieldid (keys %$newvalue)
    {
        my $field = $layout_rs->find($fieldid);
        my $value = $newvalue->{$fieldid} or next;

        # If new file, store it
        if (!$old || ($field->type eq 'file' && $changed->{$fieldid}))
        {
            # Okay, this is probably bad programming practice, but it seems
            # the tidyiest way to do it. $newvalue contains the file hash
            # if it's a new file, but an integer of the existing filename ID
            # if it's not been updated. Either way, on exit from here, it
            # contains the ID of the file
            my $file = rset('Fileval')->create($newvalue->{$fieldid});
            $newvalue->{$fieldid} = $file->id;
        }
        my $table = camelize $field->type eq 'tree' ? 'enum' : $field->type;
        if ($record_rs) # For new records, only set if user has create permissions without approval
        {
            my $v;
            # Need to write all values regardless
            if ($field->permission == OPEN || $noapproval)
            {
                # Write new value
                $v = $newvalue->{$fieldid};
            }
            else {
                # Write old value
                $v = $oldvalue->{$fieldid};
            }
            if ($v)
            {
                # Don't create a record for blank values. Doesn't work for
                # enums and other fields that reference others
                rset($table)->create({
                    record_id => $record_rs->id,
                    layout_id => $field->id,
                    value     => $v,
                }) or ouch 'dbfail', "Failed to create database entry for field ".$field->name;
            }
        }
        if ($approval_rs)
        {
            # Only need to write values that need approval
            next unless $appfields{$fieldid};
            rset($table)->create({
                record_id => $approval_rs->id,
                layout_id => $field->id,
                value     => $newvalue->{$fieldid},
            }) or ouch 'dbfail', "Failed to create approval database entry for field ".$field->name;
        }

    }

    # Finally update the current record tracking, if we've created a new
    # permanent record
    if ($need_rec)
    {
        rset('Current')->find($current_id)->update({ record_id => $record_rs->id })
            or ouch 'dbfail', "Database error updating current record tracking";
    }
    1;
}

sub _changed
{
    my ($field, $old, $new) = @_;

    # Return true if no old value
    return 1 if !$old && $new;

    # Return false if both undefined (prevent undefined warnings below)
    return 0 if !$old && !$new;

    if ($field->type eq 'string')
    {
        return $old ne $new;
    }
    elsif($field->type eq 'intgr')
    {
        return $old != $new;
    }
    elsif($field->type eq 'file')
    {
        return ref $new eq 'HASH' ? 1 : 0;
    }
    elsif($field->type eq 'enum' || $field->type eq 'tree' || $field->type eq 'person')
    {
        return $old->id != $new;
    }
    elsif($field->type eq 'date')
    {
        return DateTime->compare($old, $new);
    }
}

sub record_rs
{
    my ($current_id, $user) = @_;
    my $record;
    $record->{current_id} = $current_id;
    $record->{created} = \"NOW()";
    $record->{createdby} = $user->{id};
    rset('Record')->create($record)
        or ouch 'dbfail', "Failed to create a database record for this update";
}

sub approval_rs
{
    my ($current_id, $record_id) = @_;
    my $record;
    $record->{current_id} = $current_id;
    $record->{created} = \"NOW()";
    $record->{record_id} = $record_id;
    $record->{approval} = 1;
    rset('Record')->create($record)
        or ouch 'dbfail', "Failed to create a database record for the approval request";
}

sub _safe_eval
{
    my($expr) = @_;
    my($cpt) = new Safe;

    #Basic variable IO and traversal
    $cpt->permit_only(qw(null scalar const padany lineseq leaveeval rv2sv pushmark list return enter));
    
    #Comparators
    $cpt->permit(qw(lt i_lt gt i_gt le i_le ge i_ge eq i_eq ne i_ne ncmp i_ncmp slt sgt sle sge seq sne scmp));

    # XXX fix later? See https://rt.cpan.org/Public/Bug/Display.html?id=89437
    $cpt->permit(qw(rv2gv));

    #Base math
    #$cpt->permit(qw(preinc i_preinc predec i_predec postinc i_postinc postdec i_postdec int hex oct abs pow multiply i_multiply divide i_divide modulo i_modulo add i_add subtract i_subtract));

    #Conditionals
    $cpt->permit(qw(cond_expr flip flop andassign orassign and or xor));

    #Advanced math
    #$cpt->permit(qw(atan2 sin cos exp log sqrt rand srand));

    my($ret) = $cpt->reval($expr);

    if($@)
    {
        return $@;
    }
    else {
        return $ret;
    }
}

1;

