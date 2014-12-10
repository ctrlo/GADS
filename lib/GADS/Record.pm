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
use GADS::Config;
use GADS::View;
use String::CamelCase qw(camelize);
use Ouch;
use Safe;
use DateTime;
use DateTime::Format::Strptime qw( );
use Data::Compare;
use POSIX qw(ceil);
use JSON qw(decode_json encode_json);
use Scalar::Util qw(looks_like_number);
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
        $files{$f} = rfield($record,$f) && rfield($record,$f)->value ? rfield($record,$f)->value->name : '';
    }
    %files;
}

sub file
{   my ($self, $id, $user) = @_;
    $id or ouch 'missing', "No ID provided for file retrieval";
    my $fileval = rset('Fileval')->find($id)
        or ouch 'notfound', "File ID $id cannot be found";
    # Check whether this is hidden and whether the user has access
    my ($file) = $fileval->files; # In theory can be more than one, but not in practice
    if ($file && $file->layout->hidden) # Could be unattached document
    {
        ouch 'noperms', "You do not have access to this document"
            unless $user->{permission}->{layout};
    }
    $fileval;
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
    foreach my $j (@$joins, @$prefetches)
    {
        if ($key && ref $j eq 'HASH')
        {
            $found{$key}++;
            return $found{$key} if Compare $toadd, $j;
        }
        elsif ($toadd eq $j)
        {
            return 1;
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
    $found{$key}++ if $key;
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

sub _columns
{   my ($user, $no_hidden) = @_;

    # A hash of the columns with the ID as a key, in order to
    # easily look up a column from an ID number. Used by search
    my $columns;
    my $options = $no_hidden ? { user => $user, no_hidden => 1 } : {};
    foreach my $c (@{GADS::View->columns($options)})
    {
        $columns->{$c->{id}} = $c;
    }
    $columns;
}

# A function to see if any views have a particular record within
sub search_views
{   my ($self, $current_id, @views) = @_;

    return unless @views;

    my $joins = [];
    my $prefetches = [];

    my $columns = _columns;
    my @search;

    # XXX This is up for debate. First, do a search with all views in, as it only
    # requires one SQL query (albeit a big one). If none match, happy days.
    # If one does match though, we have to redo all the searches individually
    # to find which one matched. Is this the most efficient way of doing it?
    foreach my $view (@views)
    {
        if (my $filter = $view->filter)
        {
            # XXX Do not send alerts for hidden fields
            my $decoded = decode_json($filter);
            if (keys %$decoded)
            {
                my @s = @{_search_construct($decoded, $columns, $prefetches, $joins)};
                push @search, \@s;
            }
        }
    }

    my $count = rset('Current')->search({
        'me.id' => $current_id,
        '-or'   => \@search,
    },{
        join     => {'record' => $joins},
    })->count;

    my @foundin;
    if ($count)
    {
        foreach my $view (@views)
        {
            if (my $filter = $view->filter)
            {
                my $decoded = decode_json($filter);
                if (keys %$decoded)
                {
                    my @s = @{_search_construct($decoded, $columns, $prefetches, $joins)};
                    my @found = rset('Current')->search({
                        'me.id' => $current_id,
                        @s,
                    },{
                        join     => {'record' => $joins},
                    })->all;
                    my @ids = map { $_->id } @found;
                    push @foundin, {
                        view => $view,
                        ids  => \@ids,
                    } if @found;
                }
            }
        }
    }
    @foundin;
}

sub search
{   my ($self, $search, $user) = @_;

    $search or return;

    my %results;

    if ($search =~ s/\*/%/g )
    {
        $search = { like => $search };
    }

    my @fields = (
        { type => 'string', plural => 'strings' },
        { type => 'int'   , plural => 'intgrs' },
        { type => 'date'  , plural => 'dates' },
        { type => 'string', plural => 'dateranges' },
        { type => 'string', plural => 'ragvals' },
        { type => 'string', plural => 'calcvals' },
        { type => 'string', plural => 'enums', sub => 1 },
        { type => 'string', plural => 'people', sub => 1 },
    );

    # Set up a date parser
    my $format = DateTime::Format::Strptime->new(
         pattern   => '%Y-%m-%d',
         time_zone => 'local',
    );
    foreach my $field (@fields)
    {
        next if $field->{type} eq 'int' && !looks_like_number $search;
        next if $field->{type} eq 'date' &&  !$format->parse_datetime($search);

        my $plural   = $field->{plural};
        my $s        = $field->{sub} ? 'value.value' : 'value';
        my $prefetch = $field->{sub}
                     ? {
                           'record' => 
                               {
                                   $plural => ['value', 'layout']
                               },
                       } 
                     : {
                           'record' => { $plural => 'layout' },
                       };

        my @currents = rset('Current')->search({
            $s => $search,
        },{
            prefetch => $prefetch,
            collapse => 1,
        })->all;

        foreach my $current (@currents)
        {
            my @r;
            foreach my $string ($current->record->$plural)
            {
                my $v = $field->{sub} ? $string->value->value : $string->value;
                push @r, $string->layout->name. ": ". $v;
            }
            my $hl = join(', ', @r);
            if ($results{$current->id})
            {
                $results{$current->id}->{results} .= ", $hl";
            }
            else {
                $results{$current->id} = {
                    current_id => $current->id,
                    record_id  => $current->record->id,
                    results    => $hl,
                };
            }
        }
    }

    sort {$a->{current_id} <=> $b->{current_id}} values %results;
}

sub current($$)
{   my ($class, $item) = @_;

    # If no_hidden is true, then do not show hidden fields
    my $no_hidden = exists $item->{no_hidden} ? $item->{no_hidden} : 1;

    # First, add all the columns in the view as a prefetch. During
    # this stage, we keep track of what we've added, so that we
    # can act accordingly during the filters
    my @columns;
    if ($item->{columns})
    {
        @columns = @{$item->{columns}};
    }
    elsif (my $view_id = $item->{view_id})
    {
        @columns = @{GADS::View->columns({ view_id => $view_id, no_hidden => $no_hidden, user => $item->{user} })};
    }
    else {
        my $params = { no_hidden => $no_hidden, user => $item->{user} };
        $params->{remembered_only} = $item->{remembered_only};
        @columns = @{GADS::View->columns($params)};
    }
    my %cache_cols; # Any column in the view that should be cached
    my $prefetches = []; # Tables to prefetch - data being viewed
    my $joins = [];      # Tables to join - data being searched
    my $cache_joins;     # Tables that have data needed for calculated fields
    my @search_date;     # The search criteria to narrow-down by date range
    foreach my $c (@columns)
    {
        # If it's a calculated/rag value, log as prefetch for cached fields
        # in case we need to recalculate them
        next unless $c->{id}; # Special ID column has no id value
        if (($c->{type} eq 'rag' || $c->{type} eq 'calc') && $c->{$c->{type}})
        {
            foreach (@{$c->{$c->{type}}->{columns}})
            {
                $cache_joins->{$_->{field}} = 1 if $_->{id};
            }
        }
        elsif ($c->{type} eq "date" || $c->{type} eq "daterange")
        {
            # Apply any date filters if required
            my @f;
            if (my $to = $item->{to})
            {
                my $f = {
                    id       => $c->{id},
                    operator => 'less',
                    value    => $to->ymd,
                };
                push @f, $f;
            }
            if (my $from = $item->{from})
            {
                my $f = {
                    id       => $c->{id},
                    operator => 'greater',
                    value    => $from->ymd,
                };
                push @f, $f;
            }
            push @search_date, {
                condition => "AND",
                rules     => \@f,
            } if @f;
        }
        # Flag cache if need be - may need updating
        $cache_cols{$c->{field}} = $c
            if $c->{hascache};
        # We're viewing this, so prefetch all the values
        _add_prefetch ($c->{join}, $prefetches, $joins);
    }

    my $columns = _columns($item->{user}, $no_hidden);

    my @limit; # The overall limit, for example reduction by date range or approval field
    # Add any date ranges to the search from above
    if (@search_date)
    {
        # _search_construct returns an array ref, so dereference it first
        my @res = @{(_search_construct {condition => 'OR', rules => \@search_date}, $columns, $prefetches, $joins)};
        push @limit, @res if @res;
    }

    my $approval = $item->{approval} ? 1 : 0;
    if($item->{record_id}) {
        push @limit, ("me.id" => $item->{record_id});
    }
    elsif ($item->{current_id})
    {
        push @limit, ("me.id"  => $item->{current_id});
    }
    else {
        push @limit, ("record.record_id" => undef)
            unless $approval;
    }
    push @limit, (approval => $approval);

    my @calcsearch; # The search for fields that may need to be recalculated
    my @search;     # The user search
    my @orderby;
    # Configure specific user selected sort. Do it now, as they may
    # not have view selected
    my $index_sort = config->{gads}->{serial} eq "auto" ? 'me.id' : 'me.serial';
    if (my $sort = $item->{sort})
    {
        my $type = $sort->{type} eq 'desc' ? '-desc' : '-asc';
        if ($sort->{id} == -1)
        {
            push @orderby, { $type => $index_sort };
        }
        elsif (my $column  = $columns->{$sort->{id}})
        {
            if (my $s_table = _table_name($column, $prefetches, $joins))
            {
                push @orderby, { $type => "$s_table.value" };
            }
        }
    }
    # Now add all the filters as joins (we don't need to prefetch this data). However,
    # the filter might also be a column in the view from before, in which case add
    # it to, or use, the prefetch. We use the tracking variables from above.
    if (my $view = GADS::View->view($item->{view_id}, $item->{user}))
    {
        if (my $filter = $view->{filter})
        {
            my $decoded = decode_json($filter);
            # Do 2 loops through all the filters and gather the joins. The reason is that
            # any extra joins will be added *before* the prefetches, thereby making the
            # prefetch join numbers unpredictable. By doing an initial run, when we
            # repeat we will have predictable join numbers.
            if (keys %$decoded)
            {
                _search_construct $decoded, $columns, $prefetches, $joins;
                # Get the user search criteria
                @search     = @{_search_construct($decoded, $columns, $prefetches, $joins)};
                # Put together the search to look for undefined calculated fields
                @calcsearch = @{_search_construct($decoded, $columns, $prefetches, $joins, \%cache_cols)};
            }
        }
        unless ($item->{sort})
        {
            foreach my $sort (@{$view->{sorts}})
            {
                if (my $column = $sort->{column})
                {
                    my $s_table = _table_name($column, $prefetches, $joins);
                    my $type = $sort->{type} eq 'desc' ? '-desc' : '-asc';
                    push @orderby, { $type => "$s_table.value" };
                }
                else {
                    # No column defined means sort by ID
                    my $type = $sort->{type} eq 'desc' ? '-desc' : '-asc';
                    push @orderby, { $type => $index_sort };
                }
            }
        }
    }
    # Default sort
    unless (@orderby)
    {
        my $config = GADS::Config->conf;
        my $type = $config->sort_type eq 'desc' ? '-desc' : '-asc';
        if (my $layout = $config->sort_layout_id)
        {
            # Get column afresh rather than from $columns, as the
            # default sort could be a hidden field
            if (my $cols = GADS::View->columns({ id => $layout }))
            {
                my $column = pop @$cols;
                my $s_table = _table_name($column, $prefetches, $joins);
                push @orderby, { $type => "$s_table.value" }
            }
        }
        else {
            push @orderby, { $type => $index_sort };
        }
    }

    my $search = [-and => [@search, @limit]];
    my $result;
    if ($item->{record_id} || $approval)
    {
#        unshift @$prefetches, 'current'; # Add info about related current record

        my $select = {
            prefetch => 'current',
            join     => [@$joins, @$prefetches],
        };

        $result = rset('Record')->search(
            $search, $select
        );
    }
    elsif ($approval)
    {
        # Can't use next statement as searching Current will not
        # show new records waiting approval
    }
    else {
        # XXX Okay, this is a bit weird - we join current to record to current.
        # This is because we return records at the end, and it allows current
        # to be used when the record is used. Is there a better way?
        unshift @$prefetches, 'current';

        my $select = {
            join     => {'record' => [@$joins, @$prefetches] },
            prefetch => {'record' => 'current'},
            order_by => \@orderby,
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
        $result = rset('Current')->search(
            $search, $select
        );
    }

    # XXX Temp hack to try and speed things up. Will the rel
    # options remove the need for this section of code?
    my $fields;
    foreach my $table (@$prefetches)
    {
        my $field;
        if (ref $table eq "HASH")
        {
            ($field) = %$table;
        }
        else {
            $field = $table;
        }
        $field =~ /field([0-9]+)/
            or next;
        my $col = $columns->{$1};
        if (ref $fields->{$col->{table}} eq 'ARRAY')
        {
            push $fields->{$col->{table}}, $col;
        }
        else {
            $fields->{$col->{table}} = [$col];
        }
    }

    my @rids = ($item->{record_id} || $approval)
             ? map { $_->id } $result->all
             : map { $_->record->id } $result->all;

    my $res;
    foreach my $type (keys %$fields)
    {
        my @fids;
        foreach my $col (@{$fields->{$type}})
        {
            push @fids, $col->{id};
        }
        my $pref = $type eq "Enum" || $type eq "Tree" || $type eq "Person" ? {prefetch => 'value'} : {};
        my @values = rset($type)->search({
            'me.layout_id' => \@fids,
            record_id => \@rids,
        },
            $pref
        )->all;

        foreach my $value (@values)
        {
            my $f = "field".$value->layout_id;
            my $r = $value->record_id;
            $res->{$r}->{$f} = $value;
        }
    }

    foreach my $r ($result->all)
    {
        my $rr = ($item->{record_id} || $approval) ? $r : $r->record;
        $res->{$rr->id}->{current}    = $rr->current;
        $res->{$rr->id}->{current_id} = $rr->current->id;
        $res->{$rr->id}->{createdby}  = $rr->createdby;
        $res->{$rr->id}->{record}     = $rr->record;
        $res->{$rr->id}->{id}         = $rr->id;
    }

    my @all = ($item->{record_id} || $approval)
            ? map { $res->{$_->id} } $result->all
            : map { $res->{$_->record->id} } $result->all;
    wantarray ? @all : pop(@all);
}

sub update_cache
{   my ($self, $columns) = @_;

    my $record_columns_needed = []; # The columns we need to fetch for calculations
    # First delete old cached values
    foreach my $col (@$columns)
    {
        rset($col->{table})->search({ layout_id => $col->{id} })->delete;
        my $type = $col->{type} eq 'rag' ? 'rag' : 'calc';
        push $record_columns_needed, @{$col->{$type}->{columns}};
    }

    # Get all records needed to update this calculated field
    my @records = GADS::Record->current({ columns => $record_columns_needed, no_hidden => 0 });

    my @changed;
    foreach my $rec (@records)
    {
        my $has_change;
        foreach my $col (@$columns)
        {
            my $field = $col->{field};
            my $old   = item_value($col, $rec);
            # Force creation of the cache value
            my $new = item_value($col, $rec, {force_update => 1});
            $has_change = $new ne $old;
        }
        push @changed, $rec if $has_change;
    }

    my $columns_changed;
    my $all_columns = GADS::View->columns;
    foreach my $col (@$columns)
    {
        $columns_changed->{$col->{id}} = $col if $col->{id};
        # See whether any other calculations refer to this and also
        # need updating
        foreach my $c (@$all_columns)
        {
            my $depends = ($c->{calc} && $c->{calc}->{columns}) || ($c->{rag} && $c->{rag}->{columns});
            foreach my $d (@$depends)
            {
                $self->update_cache([$c]) if $d->{id} == $col->{id};
            }
        }
    }
    my @changed_vals = map { rfield $_, 'current_id' } @changed;
    GADS::Alert->process(\@changed_vals, $columns_changed);
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

sub _table_name
{   my ($column, $prefetches, $joins) = @_;
    my $jn = _add_join ($column->{join}, $prefetches, $joins);
    my $index = $jn > 1 ? "_$jn" : '';
    $column->{sprefix} . $index;
}

sub _search_construct
{   my ($filter, $columns, $prefetches, $joins, $calcnull) = @_;

    if (my $rules = $filter->{rules})
    {
        # Filter has other nested filters
        my @final;
        foreach my $rule (@$rules)
        {
            my @res = _search_construct $rule, $columns, $prefetches, $joins, $calcnull;
            push @final, @res if @res;
        }
        my $condition = $filter->{condition} eq 'OR' ? '-or' : '-and';
        return [$condition => \@final];
    }

    my %ops = (
        equal            => '=',
        greater          => '>',
        greater_or_equal => '>=',
        less             => '<',
        less_or_equal    => '<=',
        contains         => '-like',
        begins_with      => '-like',
        not_equal        => '!=',
    );

    my $column   = $columns->{$filter->{id}}
        or return;
    my $operator = $ops{$filter->{operator}}
        or ouch 'invop', "Invalid operator $filter->{operator}";

    my $vprefix = $filter->{operator} eq 'contains' ? '%' : '';
    my $vsuffix = $filter->{operator} =~ /contains|begins_with/ ? '%' : '';
    
    my $s_table = _table_name $column, $prefetches, $joins;

    # Is the search looking for missing calculated values?
    if ($column->{hascache} == 1 && ref $calcnull eq 'HASH')
    {
        $calcnull->{$column->{field}} = $column;
        return;
    }
    my $value = $vprefix.$filter->{value}.$vsuffix;

    my $s_field;
    if ($column->{type} eq "daterange")
    {
        $value = DateTime->now if $filter->{value} eq "CURDATE";
        
        # If it's a daterange, we have to be intelligent about the way the
        # search is constructed. Greater than, less than, equals all require
        # different values of the date range to be searched
        if ($operator eq "=")
        {
            $s_field = "value";
        }
        elsif ($operator eq ">" || $operator eq ">=")
        {
            $s_field = "to";
        }
        elsif ($operator eq "<" || $operator eq "<=")
        {
            $s_field = "from";
        }
        elsif ($operator eq "-like")
        {
            # Requires 2 searches ANDed together
            return ('-and' => ["$s_table.from" => { '<=', $value}, "$s_table.to" => { '>=', $value}]);
        }
        else {
            ouch 'invop', "Invalid operator $operator for date range";
        }
    }
    else {
        $s_field = "value";
    }

    $value =~ s/\_/\\\_/g if $operator eq '-like';
    ("$s_table.$s_field" => {$operator, $value});
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

    my $columns = GADS::View->columns({ view_id => $view_id, no_hidden => 1, user => $options->{user} });

    RECORD:
    foreach my $record (@$records)
    {
        my $serial = config->{gads}->{serial} eq "auto" ? rfield($record,'current')->id : rfield($record,'current')->serial;
        my @rec = ($record->{id}, $serial);

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
    my ($self, $view_id, $user, $from, $to) = @_;

    # Epochs received from the calendar module are based on the timezone of the local
    # browser. So in BST, 24th August is requested as 23rd August 23:00. Rather than
    # trying to convert timezones, we keep things simple and round down any "from"
    # times and round up any "to" times.
    my $fromdt  = DateTime->from_epoch( epoch => ( $from / 1000 ) )->truncate( to => 'day');
    my $todt    = DateTime->from_epoch( epoch => ( $to / 1000 ) );
    if ($todt->hms('') ne '000000')
    {
        # If time is after midnight, round down to midnight and add day
        $todt->set(hour => 0, minute => 0, second => 0);
        $todt->add(days => 1);
    }
    my @records = $self->current({ view_id => $view_id, from => $fromdt, to => $todt, user => $user, no_hidden => 1 });
    my $columns = GADS::View->columns({ view_id => $view_id, user => $user, no_hidden => 1 });

    my @colors = qw/event-important event-success event-warning event-info event-inverse event-special/;
    my @result; my %datecolors;
    foreach my $record (@records)
    {
        my @dates; my @titles;
        foreach my $column (@$columns)
        {
            if ($column->{type} eq "daterange" || $column->{vtype} eq "date")
            {
                # Create colour if need be
                $datecolors{$column->{id}} = shift @colors unless $datecolors{$column->{id}};

                # Set colour
                my $color = $datecolors{$column->{id}};

                # Get item value
                my $d = item_value($column, $record, {epoch=>1, encode_entites => 1});

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
                "url"   => "/record/" . rfield($record,'id'),
                "class" => $d->{color},
                "title" => $title,
                "id"    => rfield($record,'id'),
                "start" => $d->{from}*1000,
                "end"   => $d->{to}*1000,
            };
            push @result, $item;
        }
    }

    \@result;
}

sub rag
{   my ($class, $column, $record, $options) = @_;

    my $rag   = $column->{rag};
    my $field = $column->{field};
    my $item  = rfield($record,$field);
    if (defined $item && !$options->{force_update})
    {
        return $item->value;
    }
    elsif (!$rag)
    {
        return 'a_grey'
    }
    else {
        my $green = $rag->{green};
        my $amber = $rag->{amber};
        my $red   = $rag->{red};

        foreach my $col (@{$rag->{columns}})
        {
            my $name = $col->{name};
            my $value = item_value($col, $record, {epoch => 1, plain => 1});

            # If field is numeric but does not have numeric value, then return
            # grey, otherwise the value will be treated as zero
            # and will probably return misleading RAG values
            if ($col->{numeric})
            {
                if (
                       ($col->{type} eq "daterange" && (!$value->{from} || !$value->{to}))
                    ||  $col->{type} ne "daterange" && !looks_like_number $value
                )
                {
                    _write_rag($record, $column, 'a_grey');
                    return 'a_grey'
                }
            }

            if ($col->{type} eq "daterange")
            {
                $green =~ s/\[$name\.from\]/$value->{from}/gi;
                $green =~ s/\[$name\.to\]/$value->{to}/gi;
                $amber =~ s/\[$name\.from\]/$value->{from}/gi;
                $amber =~ s/\[$name\.to\]/$value->{to}/gi;
                $red   =~ s/\[$name\.from\]/$value->{from}/gi;
                $red   =~ s/\[$name\.to\]/$value->{to}/gi;
            }
            else {
                $value = "\"$value\"" unless $col->{numeric};
                $green =~ s/\[$name\]/$value/gi;
                $amber =~ s/\[$name\]/$value/gi;
                $red   =~ s/\[$name\]/$value/gi;
            }
        }

        # Insert current date if required
        my $now = time;
        $green =~ s/CURDATE/$now/g;
        $amber =~ s/CURDATE/$now/g;
        $red   =~ s/CURDATE/$now/g;

        my $okaycount = 0;
        foreach my $code ($green, $amber, $red)
        {
            # If there are still square brackets then something is wrong
            $okaycount++ if $code !~ /[\[\]]+/;
        }

        my $ragvalue;
        # XXX Log somewhere if this fails
        if ($okaycount == 3)
        {
            if ($red && eval { _safe_eval "($red)" } )
            {
                $ragvalue = 'b_red';
            }
            elsif (!hug && $amber && eval { _safe_eval "($amber)" } )
            {
                $ragvalue = 'c_amber';
            }
            elsif (!hug && $green && eval { _safe_eval "($green)" } )
            {
                $ragvalue = 'd_green';
            }
            elsif (hug) {
                # An exception occurred evaluating the code
                $ragvalue = 'e_purple';
            }
            else {
                $ragvalue = 'a_grey';
            }
        }
        else {
            $ragvalue = 'a_grey';
        }
        _write_rag($record, $column, $ragvalue);
        $ragvalue;
    }
}

sub _write_cache
{   my ($table, $record, $column, $value) = @_;

    my $tablec = camelize $table;
    # The cache tables have unqiue constraints to prevent
    # duplicate cache values for the same records. Using an eval
    # catches any attempts to write duplicate values.
    # XXX Should table locking be used instead? Currently there
    # appears to be no cross-database compatability
    eval {
        rset($tablec)->create({
            record_id => rfield($record, 'id'),
            layout_id => $column->{id},
            value     => $value,
        });
    }
}

sub _write_rag
{   my ($record, $column, $ragvalue) = @_;
    _write_cache('ragval', @_);
}

sub calc
{   my ($class, $column, $record, $options) = @_;

    my $calc  = $column->{calc};
    my $field = $column->{field};
    my $item  = rfield($record,$field);
    if (defined $item && !$options->{force_update})
    {
        return $item->value;
    }
    elsif(!$calc)
    {
        # Still write cache value, so that the system doesn't keep thinking
        # that it's missing and trying to regenerate it
        _write_calc($record, $column, '');
        return '';
    }
    else {
        my $code = $calc->{calc};
        foreach my $col (@{$calc->{columns}})
        {
            my $name = $col->{name};
            my $extra = $col->{suffix};
            next unless $code =~ /\Q[$name\E$extra\Q]/i;

            my $value = item_value($col, $record, {epoch => 1, plain => 1});
            if ($col->{type} eq "daterange")
            {
                $code =~ s/\[$name\.from\]/$value->{from}/gi;
                $code =~ s/\[$name\.to\]/$value->{to}/gi;
            }
            else {
                # XXX Is there a q char delimiter that is safe regardless
                # of input? Backtick is unlikely to be used...
                if ($col->{numeric})
                {
                    $value = $value || 0;
                }
                else {
                    $value = "q`$value`";
                }
                $code =~ s/\[$name\]/$value/gi;
            }
        }
        # Insert current date if required
        my $now = time;
        $code =~ s/CURDATE/$now/g;

        # If there are still square brackets then something is wrong
        my $value = $code =~ /[\[\]]+/
                  ? 'Invalid field names in calc formula'
                  : eval { _safe_eval "$code" } || bleep;

        _write_calc($record, $column, $value);
        $value;
    }
}

sub _write_calc
{   my ($record, $column, $value) = @_;
    _write_cache('calcval', @_);
}

sub person
{   my ($class, $column, $record) = @_;

    my $field = $column->{field};
    my $item  = rfield($record,$field);

    return undef unless $item; # Missing value

    if ($item->value && defined $item->value->value)
    {
        return $item->value->value;
    }
    else {
        return $class->person_update_value($item->value);
    }
}

sub person_popover
{   my ($self, $person) = @_;
    $person || return;
    my $value = $person->value;
    my @details;
    if (my $e = $person->email)
    {
        push @details, qq(Email: <a href='mailto:$e'>$e</a>);
    }
    if (my $t = $person->telephone)
    {
        push @details, qq(Telephone: $t);
    }
    my $details = join '<br>', @details;
    return qq(<a style="cursor: pointer" class="personpop" data-toggle="popover"
        title="$value"
        data-content="$details">$value</a>
    );
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
    my $item  = rfield($record,$field);

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
        # Daterange values will always be 2 values in an arrayref
        return unless $value;
        my ($from, $to) = @$value;
        return unless $from || $to; # No dates entered - blank value
        $from && $to or ouch 'invaliddate', qq(Please select 2 dates for "$column->{name}");
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
            $value && $savedvalue ? $savedvalue->id : undef;
        }
    }
    elsif ($column->{type} eq 'tree' || $column->{type} eq 'enum' || $column->{type} eq 'person')
    {
        # First check if the value is valid
        if ($value)
        {
            GADS::View->is_valid_enumval($value, $column); # borks on error
        }
        # The values of these in the database reference other tables,
        # so if a value is not input (may be an empty string) then set
        # that DB value to undef
        $value ? $value : undef;
    }
    elsif ($column->{type} eq "intgr")
    {
        ouch 'badparam', "Field \"$column->{name}\" requires an integer value."
            unless $value =~ /^[0-9]*$/;
        # Submitted integers will be and empty string
        # for no value. We want undef
        !$value && !looks_like_number($value) ? undef : $value;
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
        record_id => rfield($record, 'id'),
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

sub delete
{   my ($self, $id, $user) = @_;

    my @records = rset('Record')->search({ current_id => $id })->all;

    foreach my $record (@records)
    {
        my $rid = $record->id;
        rset('Ragval')   ->search({ record_id  => $rid })->delete;
        rset('Calcval')  ->search({ record_id  => $rid })->delete;
        rset('Enum')     ->search({ record_id  => $rid })->delete;
        rset('String')   ->search({ record_id  => $rid })->delete;
        rset('Intgr')    ->search({ record_id  => $rid })->delete;
        rset('Daterange')->search({ record_id  => $rid })->delete;
        rset('Date')     ->search({ record_id  => $rid })->delete;
        rset('Person')   ->search({ record_id  => $rid })->delete;
        rset('File')     ->search({ record_id  => $rid })->delete;
        rset('User')     ->search({ lastrecord => $rid })->update({ lastrecord => undef });
    }
    rset('Current')->find($id)->update({ record_id => undef });
    rset('Record') ->search({ current_id => $id })->update({ record_id => undef });
    rset('AlertCache')->search({ current_id => $id })->delete;
    rset('Record') ->search({ current_id => $id })->delete;
    rset('Current')->find($id)->delete;
}

sub _is_blank
{
    my ($column, $value) = @_;
    if ($column->{type} eq "intgr")
    {
        return !$value && !looks_like_number $value;
    }
    else {
        # Array ref for data ranges (with 2 values within)
        return !$value || (ref $value eq 'ARRAY' && !(scalar grep {$_} @$value)) ? 1 : 0;
    }
}

sub approve
{   my ($class, $user, $id, $values, $uploads) = @_;

    # Search for records requiring approval
    my $search->{approval} = 1;

    my $r;
    if ($id)
    {
        $search->{record_id} = $id; # with ID if required
        $r = GADS::Record->current($search);
        return $r unless $values;
    }
    else {
        my @rs = rset('Record')->search($search)->all;
        return \@rs; # Summary only required
    }

    # $r contains the record with the values in that need approving.
    # $previous contains the associated record from the same data entry,
    # but containing the submitted values that didn't need approving.
    # If all fields need approving (eg new entry) then $previous
    # will not be set
    my $previous;
    $previous = rfield($r, 'record') if rfield($r, 'record'); # Its related record

    my $columns = GADS::View->columns; # All fields
    my %columns_changed; # Track which columns have changed

    # First check whether anything is missing. Do it now before
    # we start writing values to the database
    foreach my $col (@$columns)
    {
        my $fn = $col->{field};
        my $recordvalue = $r && rfield($r,$fn) ? rfield($r,$fn)->value : undef;
        my $newvalue = _process_input_value($col, $values->{$fn}, $uploads, $recordvalue);
        # This assumes the value was visible in the form. It should be, even if
        # the field was made compulsory after added the initial submission.
        if (!$col->{optional} && rfield($r,$fn) && _is_blank $col, $newvalue)
        {
            ouch 'missing', "Field \"$col->{name}\" is not optional. Please enter a value.";
        }
    }

    foreach my $col (@$columns)
    {
        next unless $col->{userinput};
        my $fn = $col->{field};

        my $recordvalue = $r && rfield($r,$fn) ? rfield($r,$fn)->value : undef;
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
                if (rfield($r,$fn)->value)
                {
                    $newvalue = rfield($r,$fn)->value->update($newvalue)->id;
                }
                else {
                    $newvalue = rset('Fileval')->create($newvalue)->id;
                }
            }
            elsif($newvalue) {
                # Use the file that was submitted by the originator,
                # only if not removed by approver
                if (rfield($r,$fn)->value)
                {
                    # If the originator submitted a file
                    $newvalue = rfield($r,$fn)->value->id;
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
        $values->{$fn} = undef if rfield($r,$fn) && rfield($r,$fn)->value && !exists $values->{$fn};

        if (!exists $values->{$fn})
        {
            # Field was not submitted in approval form. Use previously submitted
            # value if it exists
            $newvalue = item_value($col, $previous, {raw => 1});
        }

        # Does a value exist to update?
        if (rfield($r,$fn))
        {
            if (exists $values->{$fn}) # Field submitted on approval form
            {
                # The value that was originally submitted for approval
                my $orig_submitted_file = $col->{type} eq 'file' && rfield($r,$fn)->value
                                        ? rfield($r,$fn)->value->id
                                        : undef;

                my $write = _field_write($col, $r, $newvalue);
                rfield($r,$fn)->update($write)
                    or ouch 'dbfail', "Database error updating new approved values";

                if (!defined($values->{$fn}) && $orig_submitted_file && !($previous && rfield($previous,$fn) && rfield($previous,$fn)->value))
                {
                    # If a value was not submitted in the approval, but there was
                    # a value in the record submitted for approval, and there was
                    # no previous value, then delete the associated file
                    rset('Fileval')->find($orig_submitted_file)->delete; # Otherwise orphaned
                }
                $columns_changed{$col->{id}} = $col; # Field has changed by means of being here
            }
        }
        else {
            my $table = $col->{table};
            my $write = _field_write($col, $r, $newvalue);
            rset($table)->create($write)
                or ouch 'dbfail', "Failed to create database entry for field ".$col->{name};
        }
    }

    # At this point we do not have a resource set to update, just its values
    # in a hash ref. Therefore, get the resource set
    my $rs = rset('Record')->find($r->{id});
    $rs->update({ approval => 0, record_id => undef, approvedby => $user->{id}, created => \"NOW()" })
        or ouch 'dbfail', "Database error when removing approval status from updated record";
    rset('Current')->find(rfield($r, 'current_id'))->update({ record_id => rfield($r, 'id') })
        or ouch 'dbfail', "Database error when updating current record tracking";

    # Send any alerts. Not if onboarding ($user will not be set)
    GADS::Alert->process(rfield($r, 'current_id'), \%columns_changed) if $user;

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
            if $user && !$user->{permission}->{update};
        $old = GADS::Record->current({ current_id => $current_id });
    }
    else
    {
        ouch 'nopermission', "No permissions to add a new entry"
            if $user && !$user->{permission}->{create};
    }

    my $noapproval = !$user || $user->{permission}->{update_noneed_approval} || $user->{permission}->{approver};

    # First loop round: sanitise and see which if any have changed
    my $newvalue; my $changed; my $oldvalue;
    my %appfields; # Any fields that need approval
    my ($need_app, $need_rec); # Whether a new approval_rs or record_rs needs to be created
    my $all_columns = GADS::View->columns;
    foreach my $column (@$all_columns)
    {
        my $fn      = $column->{field};
        my $fieldid = $column->{id};

        # Keep a record of all the old values so that we can compare
        if ($old && rfield($old,$fn))
        {
            if ($column->{type} eq "daterange")
            {

                $oldvalue->{$fieldid} = { from => rfield($old,$fn)->from, to => rfield($old,$fn)->to };
            }
            else {
                $oldvalue->{$fieldid} = rfield($old,$fn)->value;
            }
        }

        next unless $column->{userinput};

        # If field is hidden then use previous value (if normal user)
        my $value;
        if ($column->{hidden} && $user && !$user->{permission}->{layout})
        {
            $value = item_value($column, $old, {raw => 1})
                if $old;
        }
        else {
            $value = $params->{$fn};
        }

        if (
               _is_blank($column, $value) # New value is blank
            && !$column->{optional}       # Field is not optional
            && (!$current_id || !_is_blank($column, $oldvalue->{$fieldid})) # Old value was not blank
        )
        {
            # Only if a value was set previously, otherwise a field that had no
            # value might be made mandatory, but if it's read-only then that will
            # stop users updating other fields of the record
            ouch 'missing', qq("$column->{name}" is not optional. Please enter a value.);
        }
        $newvalue->{$fieldid} = _process_input_value($column, $value, $uploads, $oldvalue->{$fieldid});

        # Keep a track as to whether a value has changed. Keep it undef for new values
        $changed->{$fieldid} = 1 if $old && _changed($column, $oldvalue->{$fieldid}, $newvalue->{$fieldid});

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

    my $record_rs;
    $record_rs = record_rs($current_id, $user) if $need_rec;

    my $rid = $need_rec ? $record_rs->id
                        : $old
                        ? rfield($old, 'id') : undef;

    my $approval_rs;
    $approval_rs = approval_rs($current_id, $rid, $user) if $need_app;

    if (!$old && $user)
    {
        # New entry, so save record ID to user for retrieval of previous
        # values if needed for another new entry. Use the approval ID id
        # it exists, otherwise the record ID.
        my $id = $approval_rs ? $approval_rs->id : $record_rs->id;
        rset('User')->find($user->{id})->update({ lastrecord => $id });
    }

    # Write all the values
    my %columns_changed; my @columns_cached;
    foreach my $column (@$all_columns)
    {
        my $fieldid = $column->{id};

        if (!$column->{userinput})
        {
            # Make a note of cached columns that need updating
            # Don't write now as we haven't finished creating the record
            push @columns_cached, $column;
            next;
        }

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
                $columns_changed{$fieldid} = $column if $changed->{$fieldid};

                # Write new value
                $v = $newvalue->{$fieldid};
            }
            else {
                # Write old value
                $v = $oldvalue->{$fieldid};
            }
            unless (_is_blank $column, $v)
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

    # Write cached values
    foreach my $col (@columns_cached)
    {
        # Get old value
        my $old = $oldvalue->{$col->{id}};
        # Force new value to be written
        my $new = item_value($col, $record_rs);
        # Changed?
        $columns_changed{$col->{id}} = $col if $old ne $new;
    }

    # Send any alerts
    GADS::Alert->process($current_id, \%columns_changed);

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
    return 0 if !defined $old && !defined $new;

    if ($field->{type} eq 'string')
    {
        return $old ne $new;
    }
    elsif($field->{type} eq 'intgr')
    {
        return 1 if !looks_like_number $old && looks_like_number $new;
        return 1 if looks_like_number $old && !looks_like_number $new;
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
    $record->{createdby} = $user->{id} if $user;
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
    $record->{createdby}  = $user->{id} if $user;
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
    $cpt->permit(qw(not lt i_lt gt i_gt le i_le ge i_ge eq i_eq ne i_ne ncmp i_ncmp slt sgt sle sge seq sne scmp));

    # XXX fix later? See https://rt.cpan.org/Public/Bug/Display.html?id=89437
    $cpt->permit(qw(rv2gv));

    # Base math
    $cpt->permit(qw(preinc i_preinc predec i_predec postinc i_postinc postdec i_postdec int hex oct abs pow multiply i_multiply divide i_divide modulo i_modulo add i_add subtract i_subtract));

    #Conditionals
    $cpt->permit(qw(cond_expr flip flop andassign orassign and or xor));

    # String functions
    $cpt->permit(qw(concat substr index));

    # Regular expression pattern matching
    $cpt->permit(qw(match));

    #Advanced math
    #$cpt->permit(qw(atan2 sin cos exp log sqrt rand srand));

    my($ret) = $cpt->reval($expr);

    if($@)
    {
        die $@;
    }
    else {
        return $ret;
    }
}

1;

