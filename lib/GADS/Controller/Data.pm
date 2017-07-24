package GADS::Controller::Data;

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

use Dancer2;

sub bulk_delete ($user, $layout, $view) {
    my $records = GADS::Records->new(
        user   => $user,
        layout => $layout,
        view   => $view,
        schema => schema,
        rewind => session('rewind'),
    );

    $_->delete_current while($_ = $records->single);
}

sub rewind () {
    return (session rewind => undef) if 
        (param('modal_rewind_reset') || !param('rewind_date'));

    my $datetime = param('rewind_date') . ' ' . (param('rewind_time') || '23:59:59');

    my $parsed_datetime = GADS::DateTime::parse_datetime($datetime)
        or error __x"Invalid date or time: {datetime}", datetime => $datetime;

    session rewind => $parsed_datetime;
}

sub clear_search () {
    session 'search' => '';
}

sub search ($search) {
    return session('rewind') && 
        error __"Not possible to conduct a search when viewing data on a previous date";

    $search =~ s/\h+$//;
    $search =~ s/^\h+//;

    session 'search' => $search;

    return unless $search;
    
    my $records = GADS::Records->new(schema => schema, user => $user, layout => $layout);
    my $results = $records->search_all_fields($search);

    # Redirect to record if only one result
    redirect sprintf('/record/%d', $results->[0])
        if @$results == 1;
}

sub save_alert () {
    my $alert = GADS::Alert->new(
        user      => $user,
        layout    => $layout,
        schema    => schema,
        frequency => param('frequency'),
        view_id   => param('view_id'),
    );
    
    return process(sub {
        $alert->write;
    });
}

sub cleanup_session () {
    if (my $view_id = param('view')) {
        session('persistent')->{view}->{$layout->instance_id} = $view_id;
        # Save to database for next login.
        # When a new view is selected, unset sort, otherwise it's
        # not possible to remove a sort once it's been clicked
        session 'sort' => undef;
        # Also reset page number to 1
        session 'page' => undef;
        # And remove any search to avoid confusion
        session search => '';
    }

    if (my $rows = param('rows')) {
        session 'rows' => int $rows;
    }

    if (my $page = param('page')) {
        session 'page' => int $page;
    }
}

sub viewtype_graph () {
    my %params;

    if (my $png = param('png')) {
        my $gdata = _data_graph($png);
        
        my $json  = encode_json {
            points  => $gdata->points,
            labels  => $gdata->labels_encoded,
            xlabels => $gdata->xlabels,
        };

        my $graph = GADS::Graph->new(
            id     => $png,
            layout => $layout,
            schema => schema
        );
        
        my $options_in = encode_json {
            type         => $graph->type,
            x_axis_name  => $graph->x_axis_name,
            y_axis_label => $graph->y_axis_label,
            stackseries  => \$graph->stackseries,
            showlegend   => \$graph->showlegend,
            id           => $png,
        };

        my $mech = _page_as_mech('data_graph', $params);

        $mech->eval_in_page('(function(plotData, options_in){do_plot_json(plotData, options_in)})(arguments[0],arguments[1]);',
            $json, $options_in
        );

        my $png = $mech->content_as_png();

        return send_file(
            \$png,
            content_type => 'image/png',
            filename     => "graph".$graph->id.".png",
        );
    }
    elsif (my $csv = param('csv'))
    {
        my $graph = GADS::Graph->new(
            id     => $csv,
            layout => $layout,
            schema => schema
        );
        my $gdata       = _data_graph($csv);
        my $csv_content = $gdata->csv;
        return send_file(
            \$csv_content,
            content_type => 'text/csv',
            filename     => "graph".$graph->id.".csv",
        );
    }
    else {
        $params->{graphs} = GADS::Graphs->new(user => $user, schema => schema, layout => $layout)->all;
    }

    return \%params;
}

sub viewtype_calendar () {
    my %params;

    # Get details of the view and work out color markers for date fields
    my @colors = qw/event-important event-success event-warning event-info event-inverse event-special/;
    my %datecolors;

    my @columns = $view
        ? $layout->view($view->id, user_can_read => 1)
        : $layout->all(user_can_read => 1);

    foreach my $column (@columns)
    {
        if ($column->type eq "daterange" || ($column->return_type && $column->return_type eq "date"))
        {
            $datecolors{$column->name} = shift @colors;
        }
    }

    $params->{calendar}   = session('calendar'); # Remember previous day viewed
    $params->{datecolors} = \%datecolors;
    $params->{viewtype}   = 'calendar';

    return \%params;
}

sub viewtype_timeline () {
    my $records = GADS::Records->new(
        user                 => $user,
        layout               => $layout,
        schema               => schema,
        rewind               => session('rewind'),
        interpolate_children => 0,
    );
    if (param 'modal_timeline')
    {
        session('persistent')->{tl_options}->{$layout->instance_id} = {
            label => param('tl_label'),
            group => param('tl_group'),
            color => param('tl_color'),
        };
    }
    my @extra;
    my $tl_options = session('persistent')->{tl_options}->{$layout->instance_id} || {};
    push @extra, $tl_options->{label} if $tl_options->{label};
    push @extra, $tl_options->{group} if $tl_options->{group};
    push @extra, $tl_options->{color} if $tl_options->{color};
    $records->view($view);
    $records->columns_extra([@extra]);
    $records->search_all_fields(session 'search')
        if session 'search';
    my $timeline = $records->data_timeline(%{$tl_options});
    $params->{records}      = encode_base64(encode_json(delete $timeline->{items}));
    $params->{groups}       = encode_base64(encode_json(delete $timeline->{groups}));
    $params->{timeline}     = $timeline;
    $params->{tl_options}   = $tl_options;
    $params->{columns_read} = [$layout->all(user_can_read => 1)];
    $params->{viewtype}     = 'timeline';

    if (my $png = param('png'))
    {
        my $png = _page_as_mech('data_timeline', $params)->content_as_png;
        return send_file(
            \$png,
            content_type => 'image/png',
        );
    }

}

sub viewtype_table () {
    session 'rows' => 50 unless session 'rows';
    session 'page' => 1 unless session 'page';

    my $rows = defined param('download') ? undef : session('rows');
    my $page = defined param('download') ? undef : session('page');

    my $records = GADS::Records->new(
        user   => $user,
        layout => $layout,
        schema => schema,
        rewind => session('rewind'),
    );
    $records->search_all_fields(session 'search')
        if session 'search';

    $records->view($view);
    $records->rows($rows);
    $records->page($page);
    $records->sort(session 'sort');

    # Default sort if not set
    my $config = GADS::Instance->new(
        id     => $layout->instance_id,
        schema => schema,
    );
    my $sort = {
        id   => $config->sort_layout_id,
        type => $config->sort_type,
    };
    $records->default_sort($sort);

    if (defined param('sort'))
    {
        my $sort     = int param 'sort';
        # Check user has access
        forwardHome({ danger => "Invalid column ID for sort" }, '/data')
            unless !$sort || ($layout->column($sort) && $layout->column($sort)->user_can('read'));
        my $existing = $records->sort_first;
        my $type;
        if ($existing->{id} == $sort)
        {
            $type = $existing->{type} eq 'desc' ? 'asc' : 'desc';
        }
        else {
            $type = 'asc';
        }
        session 'sort' => { type => $type, id => $sort };
        $records->clear_sorts;
        $records->sort(session 'sort');
    }

    if (param 'modal_sendemail')
    {
        forwardHome({ danger => "There are no records in this view and therefore nobody to email"}, 'data')
            unless $records->results;

        return forwardHome(
            { danger => 'You do not have permission to send messages' }, 'data' )
            unless user_has_role 'message';

        my $email  = GADS::Email->instance;
        my $args   = {
            subject => param('subject'),
            text    => param('text'),
            records => $records,
            col_id  => param('peopcol'),
        };

        if (process( sub { $email->message($args, $user) }))
        {
            return forwardHome(
                { success => "The message has been sent successfully" }, 'data' );
        }
    }

    if (defined param('download'))
    {
        forwardHome({ danger => "You do not have permission to download data"}, 'data')
            unless user_has_role 'download';

        forwardHome({ danger => "There are no records to download in this view"}, 'data')
            unless $records->count;

        my $csv = $records->csv;
        my $now = DateTime->now();
        my $header;
        if ($header = config->{gads}->{header})
        {
            $csv       = "$header\n$csv" if $header;
            $header    = "-$header" if $header;
        }
        # XXX Is this correct? We can't send native utf-8 without getting the error
        # "Strings with code points over 0xFF may not be mapped into in-memory file handles".
        # So, encode the string (e.g. "\x{100}"  becomes "\xc4\x80) and then send it,
        # telling the browser it's utf-8
        utf8::encode($csv);
        return send_file( \$csv, content_type => 'text/csv; charset="utf-8"', filename => "$now$header.csv" );
    }

    my $pages = $records->pages;

    my $subset = {
        rows  => session('rows'),
        pages => $pages,
        page  => $page,
    };
    if ($pages > 50)
    {
        my @pnumbers = (1..5);
        if ($page-5 > 6)
        {
            push @pnumbers, '...';
            my $max = $page + 5 > $pages ? $pages : $page + 5;
            push @pnumbers, ($page-5..$max);
        }
        else {
            push @pnumbers, (6..15);
        }
        if ($pages-5 > $page+5)
        {
            push @pnumbers, '...';
            push @pnumbers, ($pages-4..$pages);
        }
        elsif ($pnumbers[-1] < $pages)
        {
            push @pnumbers, ($pnumbers[-1]+1..$pages);
        }
        $subset->{pnumbers} = [@pnumbers];
    }
    else {
        $subset->{pnumbers} = [1..$pages];
    }

    my @columns = $view
        ? $layout->view($view->id, user_can_read => 1)
        : $layout->all(user_can_read => 1);
    $params->{user_can_edit} = $layout->user_can('write_existing');
    $params->{sort}          = $records->sort_first;
    $params->{subset}        = $subset;
    $params->{records}       = $records->results;
    $params->{count}         = $records->count;
    $params->{columns}       = \@columns;
    $params->{viewtype}      = 'table';

}

sub handle_viewtype ($viewtype, $layout, $params) {
    my $default_viewtype = 'table';

    if ($viewtype) {
        if (!grep { $_ eq $viewtype } qw(graph table calendar timeline)) {
            $viewtype = $default_viewtype;
        } 
        session('persistent')->{viewtype}{$layout->instance_id} = $viewtype;
    } else {
        $viewtype = session('persistent')->{viewtype}{$layout->instance_id} || $default_viewtype;
    }

    my %dispatch = {
        graph    => \&viewtype_graph,
        table    => \&viewtype_table,
        calendar => \&viewtype_calendar,
        timeline => \&viewtype_timeline
    };

    my $results = $dispatch{$viewtype}->();

    $results->{viewtype} = $viewtype;

    return $results;
}

sub handler {
    my $user   = logged_in_user;
    my $layout = var 'layout';

    # Get all alerts
    my $alert = GADS::Alert->new(
        user      => $user,
        layout    => $layout,
        schema    => schema,
    );

    my $views      = GADS::Views->new(
        user        => $user,
        schema      => schema,
        layout      => $layout,
        instance_id => $layout->instance_id,
    );

    my $view = current_view($user, $layout);

    my %params = (
        page            => 'data',
        v               => $view,  # View is reserved TT word
        user_views      => $views->user_views,
        alerts          => $alert->all,
        user_can_create => $layout->user_can('write_new'),
        show_link       => rset('Current')->count,
    );

    cleanup_session();

    bulk_delete($user, $layout, $view) if defined param('modal_delete');
    rewind() if (param('modal_rewind') || param('modal_rewind_reset'));
    clear_search() if defined param('clear_search');
    do_search(param('search_text')) if defined param('search_text');

    return forwardHome(
        { success => "The alert has been saved successfully" },
        'data' 
    ) if param('modal_alert') && save_alert();

    my $viewtype_data = handle_viewtype(param('viewtype'));

    template 'data' => {
        %params,
        %$viewtype_data
    };
};


any '/data' => require_login handler;
