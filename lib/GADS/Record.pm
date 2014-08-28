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
use Data::Compare;
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
        $files{$f} = $record->$f && $record->$f->value ? $record->$f->value->name : '';
    }
    %files;
}

sub _add_jp
{
    my ($toadd, $prefetches, $joins, $type) = @_;

    # Process a join or prefetch. We see if we've already done
    # it first before adding. If the join criteria is a hash
    # (ie joining a field and then a value table), then we count
    # the number of value joins, as these will subsequntyly be
    # labelled _2 etc. In this case, we return index number.
    my %found; my $key;
    ($key) = keys %$toadd if ref $toadd eq 'HASH';
    foreach my $j (@$prefetches, @$joins)
    {
        if ($key && ref $j eq 'HASH')
        {
            $found{$key}++;
            return $found{$key} if Compare $toadd, $j;
        }
    }
    if ($type eq 'join')
    {
        push @$joins, $toadd;
    }
    elsif ($type eq 'prefetch')
    {
        push @$prefetches, $toadd;
    }
    return $key ? $found{$key} : 1;
}

sub _add_prefetch
{
    _add_jp @_, 'prefetch';
}

sub _add_join
{
    _add_jp @_, 'join';
}

sub current($$)
{   my ($class, $item) = @_;

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
    my @filters; # All the filters for this query
    my $prefetches = []; my $joins = [];
    foreach my $c (@columns)
    {
        # If it's a calculated/rag value, prefetch the columns in the calc
        if (($c->{type} eq 'rag' || $c->{type} eq 'calc') && $c->{$c->{type}})
        {
            push @columns, @{$c->{$c->{type}}->{columns}};
        }
        elsif ($c->{type} eq "date" || $c->{type} eq "daterange")
        {
            # Apply any date filters if required
            my @f;
            if (my $to = $item->{to})
            {
                my $f = {
                    column   => $c,
                    operator => 'lt',
                    value    => $to->ymd,
                    type     => 'and',
                };
                push @f, $f;
            }
            if (my $from = $item->{from})
            {
                my $f = {
                    column   => $c,
                    operator => 'gt',
                    value    => $from->ymd,
                    type     => 'and',
                };
                push @f, $f;
            }
            push @filters, {value => \@f, type => 'and'} if @f;
        }
        # Flag cache if need be - may need updating
        $cache_cols{$c->{field}} = $c
            if $c->{hascache};

        # Add to the prefetch array. This tracks what's been added
        # and only adds additional fields as required
        _add_prefetch ($c->{join}, $prefetches, $joins);
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

    # First see if any cachable fields are missing their cache values.
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

    # Add all the view's filters onto any existing ones
    push @filters, @{GADS::View->filters($item->{view_id})} if $item->{view_id};
    # Any filters to OR to the overall query. These will probably be date
    # filters specified above for a subset of results
    my @or_filters;
    foreach my $filter (@filters)
    {
        my $field = $filter->{column}->{field};

        # As per the prefix, what we join depends on the type of field
        my $sprefix = $filter->{column}->{sprefix};

        my @searches = _search_construct $filter, $prefetches, $joins;

        while (@searches)
        {
            my $sfield = shift @searches;
            my $svalue = shift @searches;
            $sfield && $svalue or next;

            # Underscore in mysql is special for like
            $svalue->{'-like'} =~ s/\_/\\\_/g if $svalue->{'-like'};

            if ($sfield eq 'multi')
            {
                push @or_filters, $svalue;
            }
            else {
                if (ref $search->{$sfield} eq 'ARRAY')
                {
                    push @{$search->{$sfield}}, $svalue;
                }
                elsif ($search->{$sfield})
                {
                    $search->{$sfield} = [ -and => $search->{$sfield}, $svalue ];
                }
                else {
                    $search->{$sfield} = $svalue;
                }
            }
        }
    }

    $search->{'-or'} = \@or_filters if @or_filters;

    my @all;
    if ($item->{record_id})
    {
        unshift @$prefetches, 'current'; # Add info about related current record

        my $select = {
            prefetch => $prefetches,
            join     => $joins,
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
        unshift @$prefetches, 'current';

        my $select = {
            prefetch => {'record' => $prefetches},
            join     => {'record' => $joins},
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
{   my ($filter, $prefetches, $joins) = @_;

    my $operator = $filter->{operator};
    my $value    = $filter->{value};
    my $column   = $filter->{column};
    my $type     = $filter->{type};

    if (ref $value eq 'ARRAY')
    {
        my @v = map { _search_construct $_, $prefetches, $joins } @$value;
        my $t = $type eq 'or' ? '-or' : '-and';
        # Use a hash structure with operator rather than only an array
        # ref, otherwise the same field with different search values
        # will get overwritten
        return ('multi', { $t => \@v });
    }

    my $jn = _add_join ($column->{join}, $prefetches, $joins);
    my $index = $jn > 1 ? "_$jn" : '';
    my $sfield   = $column->{sprefix} . $index;

    if ($column->{type} eq "daterange")
    {
        # If it's a daterange, we have to be intelligent about the way the
        # search is constructed. Greater than, less than, equals all require
        # different values of the date range to be searched
        if ($operator eq "equal")
        {
            ("$sfield.value", { '=', $value});
        }
        elsif ($operator eq "gt")
        {
            ("$sfield.from", { '>', $value});
        }
        elsif ($operator eq "lt")
        {
            ("$sfield.to", { '<', $value});
        }
        elsif ($operator eq "contains")
        {
            ("$sfield.from", { '<', $value}, 'to', { '>', $value});
        }
    }
    else {
        if ($operator eq "equal")
        {
            ("$sfield.value", { '=', $value});
        }
        elsif ($operator eq "gt")
        {
            ("$sfield.value", { '>', $value});
        }
        elsif ($operator eq "lt")
        {
            ("$sfield.value", { '<', $value});
        }
        elsif ($operator eq "contains")
        {
            ("$sfield.value", { '-like', "%$value%"});
        }
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

sub data_calendar
{
    my ($self, $view_id, $from, $to) = @_;

    my $fromdt  = DateTime->from_epoch( epoch => ( $from / 1000 ) );
    my $todt    = DateTime->from_epoch( epoch => ( $to / 1000 ) );
    my @records = $self->current({ view_id => $view_id, from => $fromdt, to => $todt });
    my $columns = GADS::View->columns({ view_id => $view_id });

    my @colors = qw/event-important event-success event-warning event-info event-inverse event-special/;
    my @result; my %datecolors;
    foreach my $record (@records)
    {
        my @dates; my @titles;
        foreach my $column (@$columns)
        {
            if ($column->{type} eq "daterange" || $column->{type} eq "date")
            {
                # Create colour if need be
                $datecolors{$column->{id}} = shift @colors unless $datecolors{$column->{id}};

                # Set colour
                my $color = $datecolors{$column->{id}};

                # Get item value
                my $d = item_value($column, $record, {epoch=>1});

                # Push value onto stack
                if ($column->{type} eq "daterange")
                {
                    $d->{color} = $color;
                    push @dates, $d;
                }
                else {
                    push @dates, {
                        from => $d,
                        to   => $d,
                        color => $color,
                    };
                }
            }
            else {
                # Not a date value, push onto title
                my $v = item_value($column, $record, {plain => 1, encode_entities => 1});
                push @titles, $v if $v;
            }
        }

        # Create title label
        my $title = join ' - ', @titles;
        if (length $title > 90)
        {
            $title = substr($title, 0, 86).'...';
        }

        foreach my $d (@dates)
        {
            next unless $d->{from} && $d->{to};
            my $item = {
                "url"   => "/record/".$record->id,
                "class" => $d->{color},
                "title" => $title,
                "id"    => $record->id,
                "start" => $d->{from}*1000,
                "end"   => $d->{to}*1000,
            };
            push @result, $item;
        }
    }

    \@result;
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
    elsif (!$rag)
    {
        return 'grey'
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

        my $okaycount = 0;
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
    elsif(!$calc)
    {
        return undef;
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

    my $field = $column->{field};
    my $item  = $record->$field;

    return undef unless $item; # Missing value

    if ($item->value && defined $item->value->value)
    {
        return $item->value->value;
    }
    else {
        return $class->person_update_value($item->value);
    }
}

sub person_update_value
{   my ($class, $person) = @_;
    $person or return;
    my $firstname = $person->firstname || '';
    my $surname   = $person->surname || '';
    my $value     = "$surname, $firstname";

    $person->update({
        value     => $value,
    }) if $value ne $person->value;
    $value;
}

sub daterange
{   my ($class, $column, $record) = @_;

    my $field = $column->{field};
    my $item  = $record->$field;

    return undef unless $item; # Missing value

    if (defined $item->value)
    {
        return $item->value;
    }
    else {
        return $class->daterange_update_value($item);
    }
}

sub daterange_update_value
{   my ($class, $daterange) = @_;
    return unless $daterange->from && $daterange->to;
    my $value     = $daterange->from->ymd . " to " . $daterange->to->ymd;

    $daterange->update({
        value     => $value,
    }) if $value ne $daterange->value;
    $value;
}

sub _process_input_value
{
    # $savedvalue is the value submitted by the originator, used
    # when approving an entry
    my ($column, $value, $uploads, $savedvalue) = @_;

    # Set up a date parser
    my $format = DateTime::Format::Strptime->new(
         pattern   => '%Y-%m-%d',
         time_zone => 'local',
    );

    if ($column->{type} eq 'date')
    {
        $value or return; # Do not return empty string for unspecified date
        # Convert to DateTime object if required
        my $new = $format->parse_datetime($value);
        $new or ouch 'invaliddate', "Invalid date \"$value\" for $column->{name}";
    }
    elsif ($column->{type} eq 'daterange')
    {
        # Convert to DateTime objects
        $value or return;
        my ($from, $to) = split ' to ', $value;
        $from && $to or ouch 'invaliddate', "Please select 2 dates for the date range $column->{name}";
        my $f = _parse_daterange($from, $to, $format);
        $f->{from} or ouch 'invaliddate', "Invalid from date in range: \"$from\" in $column->{name}";
        $f->{to}   or ouch 'invaliddate', "Invalid to date in range: \"$to\" in $column->{name}";
        # Swap dates around if from is after the to
        ($f->{to}, $f->{from}) = ($f->{from}, $f->{to}) if DateTime->compare($f->{from}, $f->{to}) == 1;
        $f;
    }
    elsif ($column->{type} eq 'file')
    {
        # Find the file upload and store for later
        if (my $upload = $uploads->{"file$column->{id}"})
        {
            ouch 'toobig', "The uploaded file is greater than the maximum size allowed for this field"
                if $column->{file_option}->{filesize} && $upload->size > $column->{file_option}->{filesize} * 1024;
            {
                name     => $upload->filename,
                mimetype => $upload->type,
                content  => $upload->content,
            };
        }
        else {
            # Database ID of existing filename, but only if checkbox ticked to include
            # and if one was previously uploaded
            $value && $savedvalue && $savedvalue->value ? $savedvalue->value->id : undef;
        }
    }
    elsif ($column->{type} eq 'tree' || $column->{type} eq 'enum' || $column->{type} eq 'person')
    {
        # The values of these in the database reference other tables,
        # so if a value is not input then set that DB value to undef
        $value ? $value : undef;
    }
    else
    {
        $value;
    }
}

sub _field_write
{
    my ($column, $record, $value) = @_;
    my $entry = {
        record_id => $record->id,
        layout_id => $column->{id},
    };
    # Blank cached values to cause update later.
    # Only really needed for approval, as normal
    # updates will write a new row.
    if ($column->{hascache})
    {
        $entry->{value} = undef;
    }
    if ($column->{type} eq "daterange")
    {
        $entry->{from}  = $value->{from};
        $entry->{to}    = $value->{to};
    }
    else {
        $entry->{value} = $value;
    }
    $entry;
}

sub approve
{   my ($class, $user, $id, $values, $uploads) = @_;

    # Search for records requiring approval
    my $search->{approval} = 1;
    $search->{id} = $id if $id; # with ID if required
    my @r = rset('Record')->search($search)->all;

    return \@r unless $values; # Summary only required

    # $r contains the record with the values in that need approving.
    # $previous contains the associated record from the same data entry,
    # but containing the submitted values that didn't need approving.
    # If all fields need approving (eg new entry) then $previous
    # will not be set
    my $r = shift @r; # Just the first please
    my $previous;
    $previous = $r->record if $r->record; # Its related record

    my $columns = GADS::View->columns; # All fields

    foreach my $col (@$columns)
    {
        next unless $col->{userinput};
        my $fn = $col->{field};

        my $recordvalue = $r ? $r->$fn : undef;
        my $newvalue = _process_input_value($col, $values->{$fn}, $uploads, $recordvalue);
        if ($col->{type} eq 'file')
        {
            # If a new file has been uploaded, use that instead
            # and convert value (the uploaded file) to its database ID
            if (ref $newvalue eq 'HASH')
            {
                # Unlikely, but there is a chance that a previous uploaded
                # file does not exist to update (if the field has become
                # mandatory for example). Create one if it doesn't exist
                if ($r->$fn->value)
                {
                    $newvalue = $r->$fn->value->update($newvalue)->id;
                }
                else {
                    $newvalue = rset('Fileval')->create($newvalue)->id;
                }
            }
            elsif($newvalue) {
                # Use the file that was submitted by the originator,
                # only if not removed by approver
                if ($r->$fn->value)
                {
                    # If the originator submitted a file
                    $newvalue = $r->$fn->value->id;
                }
                else {
                    # Otherwise he removed it
                    $newvalue = undef;
                }
            }
        }

        # See if approver has deleted any fields submitted by originator. $values->{fn}
        # would not exist in which case. Changing it to undef will force it to appear
        # as a submitted field that is now undefined
        $values->{$fn} = undef if $r->$fn && $r->$fn->value && !exists $values->{$fn};

        # This assumes the value was visible in the form. It should be, even if
        # the field was made compulsory after added the initial submission.
        if (!$col->{optional} && !$newvalue)
        {
            ouch 'missing', "Field \"$col->{name}\" is not optional. Please enter a value.";
        }

        if (!exists $values->{$fn})
        {
            # Field was not submitted in approval form. Use previously submitted
            # value if it exists
            $newvalue = $previous->$fn->value
                if ($previous && $previous->$fn);
        }

        # Does a value exist to update?
        if ($r->$fn)
        {
            if (exists $values->{$fn})
            {
                # The value that was originally submitted for approval
                my $orig_submitted_file = $col->{type} eq 'file' && $r->$fn->value
                                        ? $r->$fn->value->id
                                        : undef;

                my $write = _field_write($col, $r, $newvalue);
                $r->$fn->update($write)
                    or ouch 'dbfail', "Database error updating new approved values";

                if (!defined($values->{$fn}) && $orig_submitted_file && !($previous && $previous->$fn && $previous->$fn->value))
                {
                    # If a value was not submitted in the approval, but there was
                    # a value in the record submitted for approval, and there was
                    # no previous value, then delete the associated file
                    rset('Fileval')->find($orig_submitted_file)->delete; # Otherwise orphaned
                }
            }
        }
        else {
            my $table = $col->{table};
            rset($table)->create({
                record_id => $r->id,
                layout_id => $col->{id},
                value     => $newvalue,
            }) or ouch 'dbfail', "Failed to create database entry for appproved field ".$col->{name};
        }
    }
    $r->update({ approval => 0, record_id => undef, approvedby => $user->{id}, created => \"NOW()" })
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

    my $noapproval = $user->{permissions}->{update_noneed_approval} || $user->{permissions}->{approver};

    # First loop round: sanitise and see which if any have changed
    my $newvalue; my $changed; my $oldvalue;
    my %appfields; # Any fields that need approval
    my ($need_app, $need_rec); # Whether a new approval_rs or record_rs needs to be created
    my $all_columns = GADS::View->columns;
    foreach my $column (@$all_columns)
    {
        next unless $column->{userinput};

        my $fn      = $column->{field};
        my $fieldid = $column->{id};

        # Keep a record of all the old values so that we can compare
        if ($old && $old->$fn)
        {
            if ($column->{type} eq "daterange")
            {

                $oldvalue->{$fieldid} = { from => $old->$fn->from, to => $old->$fn->to };
            }
            else {
                $oldvalue->{$fieldid} = $old->$fn->value;
            }
        }

        my $value = $params->{$fn};

        if (!$value && !$column->{optional} && (!$old || ($old && $oldvalue->{$fieldid})))
        {
            # Only if a value was set previously, otherwise a field that had no
            # value might be made mandatory, but if it's read-only then that will
            # stop users updating other fields of the record
            ouch 'missing', qq("$column->{name}" is not optional. Please enter a value.);
        }
        $newvalue->{$fieldid} = _process_input_value($column, $value, $uploads);

        # Keep a track as to whether a value has changed. Keep it undef for new values
        $changed->{$fieldid} = $old ? _changed($column, $oldvalue->{$fieldid}, $newvalue->{$fieldid}) : undef;

        ouch 'nopermission', "Field ID $fieldid is read only"
            if $changed->{$fieldid} &&
            $column->{permission} == READONLY &&
            !$noapproval;

        if ($old && $changed->{$fieldid})
        {
            # Update to record and the field has changed
            if ($column->{permission} == APPROVE)
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
                if (($column->{permission }== APPROVE || $column->{permission} == READONLY)
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
    my $approval_rs = approval_rs($current_id, $rid, $user) if $need_app;

    unless ($old)
    {
        # New entry, so save record ID to user for retrieval of previous
        # values if needed for another new entry. Use the approval ID id
        # it exists, otherwise the record ID.
        my $id = $approval_rs ? $approval_rs->id : $record_rs->id;
        rset('User')->find($user->{id})->update({ lastrecord => $id });
    }

    # Write all the values
    foreach my $column (@$all_columns)
    {
        next unless $column->{userinput};

        my $fieldid = $column->{id};
        my $value = $newvalue->{$fieldid};

        # If new file, store it
        if ($column->{type} eq 'file' && $newvalue->{$fieldid} && ($changed->{$fieldid} || !$old))
        {
            # Okay, this is probably bad programming practice, but it seems
            # the tidyiest way to do it. $newvalue contains the file hash
            # if it's a new file, but an integer of the existing filename ID
            # if it's not been updated. Either way, on exit from here, it
            # contains the ID of the file
            my $file = rset('Fileval')->create($newvalue->{$fieldid});
            $newvalue->{$fieldid} = $file->id;
        }
        my $table = $column->{table};
        if ($record_rs) # For new records, only set if user has create permissions without approval
        {
            my $v;
            # Need to write all values regardless
            if ($column->{permission} == OPEN || $noapproval)
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
                my $entry = _field_write($column, $record_rs, $v);
                rset($table)->create($entry)
                    or ouch 'dbfail', "Failed to create database entry for field ".$column->{name};
            }
        }
        if ($approval_rs)
        {
            # Only need to write values that need approval
            next unless $appfields{$fieldid};
            my $entry = _field_write($column, $approval_rs, $newvalue->{$fieldid});
            rset($table)->create($entry)
                or ouch 'dbfail', "Failed to create approval database entry for field ".$column->{name};
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

sub _parse_daterange
{
    my ($from, $to, $parser) = @_;
    $parser = DateTime::Format::Strptime->new(
         pattern   => '%Y-%m-%d',
         time_zone => 'local',
    ) unless $parser;
    {
        from => $parser->parse_datetime($from),
        to   => $parser->parse_datetime($to),
    }
}

sub _changed
{
    my ($field, $old, $new) = @_;

    # Return true if no new value
    return 1 if $old && !$new;

    # Return true if no old value
    return 1 if !$old && $new;

    # Return false if both undefined (prevent undefined warnings below)
    return 0 if !$old && !$new;

    if ($field->{type} eq 'string')
    {
        return $old ne $new;
    }
    elsif($field->{type} eq 'intgr')
    {
        return $old != $new;
    }
    elsif($field->{type} eq 'file')
    {
        return ref $new eq 'HASH' ? 1 : 0;
    }
    elsif($field->{type} eq 'enum' || $field->{type} eq 'tree' || $field->{type} eq 'person')
    {
        return $old->id != $new;
    }
    elsif($field->{type} eq 'date')
    {
        return DateTime->compare($old, $new);
    }
    elsif($field->{type} eq 'daterange')
    {
        return DateTime->compare($old->{from}, $new->{from})
            || DateTime->compare($old->{to}, $new->{to})
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
    my ($current_id, $record_id, $user) = @_;
    my $record;
    $record->{current_id} = $current_id;
    $record->{created}    = \"NOW()";
    $record->{record_id}  = $record_id;
    $record->{approval}   = 1;
    $record->{createdby}  = $user->{id};
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

