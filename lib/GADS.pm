package GADS;

use DateTime;
use GADS::Alert;
use GADS::Audit;
use GADS::Column;
use GADS::Column::Calc;
use GADS::Column::Date;
use GADS::Column::Daterange;
use GADS::Column::Enum;
use GADS::Column::File;
use GADS::Column::Intgr;
use GADS::Column::Person;
use GADS::Column::Rag;
use GADS::Column::String;
use GADS::Column::Tree;
use GADS::Config;
use GADS::DB;
use GADS::Email;
use GADS::Graph;
use GADS::Graph::Data;
use GADS::Graphs;
use GADS::Layout;
use GADS::Record;
use GADS::Records;
use GADS::User;
use GADS::Util         qw(:all);
use GADS::View;
use GADS::Views;
use HTML::Entities;
use JSON qw(decode_json encode_json);
use Log::Report mode => 'DEBUG';
use String::CamelCase qw(camelize);
use Text::CSV;

use Dancer2; # Last to stop Moo generating conflicting namespace
use Dancer2::Plugin::Auth::Complete;
use Dancer2::Plugin::DBIC qw(schema resultset rset);

schema->storage->debug(1);

our $VERSION = '0.1';

# set serializer => 'JSON';
set behind_proxy => config->{behind_proxy}; # XXX Why doesn't this work in config file

# Callback dispatcher to send error messages to the web browser
dispatcher CALLBACK => 'error_handler'
   , callback => \&error_handler
   , mode => 'DEBUG';

# And a syslog dispatcher
dispatcher SYSLOG => 'gads'
  , identity => 'gads'
  , facility => 'local0'
  , flags    => "pid ndelay nowait"
  , mode     => 'DEBUG';

Dancer2::Plugin::Auth::Complete->user_callback( sub {
    my ($retuser, $user) = @_;
    $retuser->{lastrecord} = $user->lastrecord ? $user->lastrecord->id : undef;
    $retuser;
});

hook init_error => sub {
    my $error = shift;
    # Catch other exceptions. This is hook is called for all errors
    # not just exceptions (including for example 404s), so check first.
    # If it's an exception then panic it to get Log::Report
    # to handle it nicely. If it's another error such as a 404
    # then exception will not be set.
    panic $error->{exception} if $error->{exception};
};

hook before => sub {

    # Static content
    return if request->uri =~ m!^/(error|js|css|login|images|fonts|resetpw|ping)!;
    return if param 'error';

    # Redirect on no session
    redirect '/login' unless user;

    # Dynamically generate "virtual" columns for each row of data, based on the
    # configured layout
    GADS::DB->setup(schema);

    if (config->{gads}->{aup})
    {
        # Redirect if AUP not signed
        my $aup_date     = user->{aup_accepted};
        my $aup_accepted = $aup_date && DateTime->compare( $aup_date, DateTime->now->subtract(months => 12) ) > 0;
        redirect '/aup' unless $aup_accepted || request->uri =~ m!^/aup!;
    }

    if (config->{gads}->{user_status} && !session('status_accepted'))
    {
        # Redirect to user status page if required and not seen this session
        redirect '/user_status' unless request->uri =~ m!^/(user_status|aup)!;
    }
};

hook before_template => sub {
    my $tokens = shift;

    # Log to audit
    my $user = user;
    my $method = request->method;
    my $path   = request->path;
    my $audit  = GADS::Audit->new(schema => schema, user => $user);
    $audit->user_action(qq(User $user->{username} made $method request to $path))
        if $user;

    my $base = request->base;
    $tokens->{url}->{css}  = "${base}css";
    $tokens->{url}->{js}   = "${base}js";
    $tokens->{url}->{page} = $base;
    $tokens->{url}->{page} =~ s!.*/!!; # Remove trailing slash
    $tokens->{hostlocal}   = config->{gads}->{hostlocal};

    $tokens->{header} = config->{gads}->{header};

    if (permission 'approver')
    {
        $tokens->{approve_waiting} = GADS::Records->approval_count(schema);
    }
    $tokens->{messages} = session('messages');
    $tokens->{user}     = $user;
    $tokens->{config}   = config;
    session 'messages' => [];

};

get '/' => sub {

    my $config = GADS::Config->new(schema => schema);
    template 'index' => {
        instance => $config,
        page     => 'index'
    };
};

get '/ping' => sub {
    content_type 'text/plain';
    'alive';
};

any '/aup' => sub {

    if (param 'accepted')
    {
        my %user = (
            id           => user->{id},
            aup_accepted => DateTime->now,
        );
        user update => %user;
        redirect '/';
    }

    template aup => {
        page => 'aup',
    };
};

get '/aup_text' => sub {
    template 'aup_text', {}, { layout => undef };
};

any '/user_status' => sub {

    if (param 'accepted')
    {
        session 'status_accepted' => 1;
        redirect '/';
    }

    template user_status => {
        lastlogin => session('last_login'),
        message   => config->{gads}->{user_status_message},
        page      => 'user_status',
    };
};

get '/data_calendar/:time' => sub {

    # Time variable is used to prevent caching by browser

    my $view_id = session 'view_id';

    my $fromdt  = DateTime->from_epoch( epoch => ( param('from') / 1000 ) )->truncate( to => 'day'); 
    my $todt    = DateTime->from_epoch( epoch => ( param('to') / 1000 ) ); 

    my $diff     = $todt->subtract_datetime($fromdt);
    my $dt_view  = $diff->years
                 ? 'year'
                 : $diff->weeks
                 ? 'week'
                 : $diff->days
                 ? 'day'
                 : 'month'; # Default to month

    # Remember previous day and view. Day is difficult, due to the
    # timezone issues described above. XXX How to fix?
    session 'calendar' => {
        day  => $todt->clone->subtract(days => 1),
        view => $dt_view,
    };

    # Epochs received from the calendar module are based on the timezone of the local
    # browser. So in BST, 24th August is requested as 23rd August 23:00. Rather than
    # trying to convert timezones, we keep things simple and round down any "from"
    # times and round up any "to" times.
    if ($todt->hms('') ne '000000')
    {
        # If time is after midnight, round down to midnight and add day
        $todt->set(hour => 0, minute => 0, second => 0);
        $todt->add(days => 1);
    }

    if ($fromdt->hms('') ne '000000')
    {
        # If time is after midnight, round down to midnight
        $fromdt->set(hour => 0, minute => 0, second => 0);
    }

    my $user    = user;
    my $layout  = GADS::Layout->new(user => $user, schema => schema);
    my $views   = GADS::Views->new(user => $user, schema => schema, layout => $layout);
    my $view    = $views->view(session 'view_id') || $views->default; # Can still be undef
    my $records = GADS::Records->new(user => $user, layout => $layout, schema => schema);
    $records->search(
        view    => $view,
        from    => $fromdt,
        to      => $todt,
    );

    header "Cache-Control" => "max-age=0, must-revalidate, private";
    content_type 'application/json';
    encode_json({
        "success" => 1,
        "result"  => $records->data_calendar,
    });
};

get '/data_graph/:id/:time' => sub {

    my $user    = user;
    my $id      = param 'id';
    my $layout  = GADS::Layout->new(user => $user, schema => schema);
    my $views   = GADS::Views->new(user => $user, schema => schema, layout => $layout);
    my $view    = $views->view(session 'view_id') || $views->default; # Can still be undef
    my $graph   = GADS::Graph->new(id => $id, schema => schema);
    my $records = GADS::Records->new(user => $user, layout => $layout, schema => schema);
    $records->search(
        view    => $view,
        columns => [
            $graph->x_axis,
            $graph->y_axis,
            $graph->group_by,
        ],
    );

    my $gdata = GADS::Graph::Data->new(id => $id, records => $records, schema => schema);

    header "Cache-Control" => "max-age=0, must-revalidate, private";
    content_type 'application/json';
    encode_json({
        points  => $gdata->points,
        labels  => $gdata->labels,
        xlabels => $gdata->xlabels,
    });
};

get '/search' => sub {

    my $search = param 'search';
    my $user = user;
    my $layout = GADS::Layout->new(user => $user, schema => schema);
    my $records = GADS::Records->new(schema => schema, user => $user, layout => $layout);
    my @results = $records->search_all_fields($search);
    template 'search' => {
        results => \@results,
        search  => $search,
        page    => 'search',
    };
};

any '/data' => sub {

    my $user = user;

    # Deal with any alert requests
    if (my $alert_view = param 'alert')
    {
        if (process(sub { GADS::Alert->alert($alert_view, param('frequency'), $user) }))
        {
            return forwardHome(
                { success => "The alert has been saved successfully" }, 'data' );
        }
    }

    if (my $view_id = param('view'))
    {
        session 'view_id' => $view_id;
        # When a new view is selected, unset sort, otherwise it's
        # not possible to remove a sort once it's been clicked
        session 'sort'    => undef;
    }

    if (my $rows = param('rows'))
    {
        session 'rows' => int $rows;
    }

    if (my $page = param('page'))
    {
        session 'page' => int $page;
    }

    my $viewtype;
    if ($viewtype = param('viewtype'))
    {
        if ($viewtype eq 'graph' || $viewtype eq 'table' || $viewtype eq 'calendar')
        {
            session 'viewtype' => $viewtype;
        }
    }
    else {
        $viewtype = session('viewtype') || 'table';
    }

    my $layout = GADS::Layout->new(user => $user, schema => schema);
    my $views  = GADS::Views->new(user => $user, schema => schema, layout => $layout);
    my $view   = $views->view(session 'view_id') || $views->default; # Can still be undef

    my $params; # Variable for the template

    if ($viewtype eq 'graph')
    {
        $params = {
            graphs   => GADS::Graphs->new(user => $user, schema => schema, layout => $layout)->all,
            viewtype => 'graph',
        };
    }
    elsif ($viewtype eq 'calendar')
    {
        # Get details of the view and work out color markers for date fields
        my @colors = qw/event-important event-success event-warning event-info event-inverse event-special/;
        my %datecolors;

        my @columns = $layout->view($view->id);

        foreach my $column (@columns)
        {
            if ($column->type eq "daterange" || ($column->return_type && $column->return_type eq "date"))
            {
                $datecolors{$column->name} = shift @colors;
            }
        }

        $params = {
            calendar   => session('calendar'), # Remember previous day viewed
            datecolors => \%datecolors,
            viewtype   => 'calendar',
        }
    }
    else {
        session 'rows' => 50 unless session 'rows';
        session 'page' => 1 unless session 'page';

        my $rows = defined param('download') ? undef : session('rows');
        my $page = defined param('download') ? undef : session('page');

        my $records = GADS::Records->new(user => $user, layout => $layout, schema => schema);

        if (defined param('sort'))
        {
            my $sort     = int param 'sort';
            my $existing = session('sort');
            if (!$existing && @{$view->sorts})
            {
                # Get first sort of existing view
                my $sort = $view->sorts->[0];
                $existing = {
                    id => $sort->{layout_id},
                    type => $sort->{type},
                };
            }
            my $type;
            if ($existing && $existing->{id} == $sort)
            {
                $type = $existing->{type} eq 'desc' ? 'asc' : 'desc';
            }
            else {
                $type = 'asc'; #$existing ? 'asc' : 'desc';
            }
            session 'sort' => { type => $type, id => $sort };
        }

        unless (session 'sort')
        {
            # Default sort if not set
            # Set here in case it's a hidden column
            my $config = GADS::Config->new(schema => schema);
            my $sort = {
                id   => $config->sort_layout_id,
                type => $config->sort_type,
            };
            # session 'sort' => $sort;
            $records->default_sort($sort);
        }

        $records->search(
            view    => $view,
            rows    => $rows,
            page    => $page,
            sort    => session('sort'),
            format  => (defined param('download') ? {plain => 1} : {encode_entities => 1}),
        );
        my $pages = $records->pages;

        my $subset = {
            rows  => session('rows'),
            pages => $pages,
            page  => $page,
        };

        if (param 'sendemail')
        {
            forwardHome({ danger => "There are no records in this view and therefore nobody to email"}, 'data')
                unless $records->results;

            return forwardHome(
                { danger => 'You do not have permission to send messages' }, 'data' )
                unless permission 'message';

            my $params = params;

            my $email = GADS::Email->new(
                message_prefix => config->{gads}->{message_prefix},
                email_from     => config->{gads}->{email_from},
                subject        => param('subject'),
                text           => param('text'),
            );
            if (process( sub { $email->message($records, param('peopcol'), $user) }))
            {
                return forwardHome(
                    { success => "The message has been sent successfully" }, 'data' );
            }
        }

        if (defined param('download'))
        {
            forwardHome({ danger => "You do not have permission to download data"}, 'data')
                unless permission 'download';

            forwardHome({ danger => "There are no records to download in this view"}, 'data')
                unless $records->results;

            my $csv = $records->csv;
            my $now = DateTime->now();
            my $header;
            if ($header = config->{gads}->{header})
            {
                $csv       = "$header\n$csv" if $header;
                $header    = "-$header" if $header;
            }
            return send_file( \$csv, content_type => 'text/csv', filename => "$now$header.csv" );
        }
        else {
            my @columns = $view ? $layout->view($view->id) : $layout->all;
            $params = {
                sort     => $records->sort,
                subset   => $subset,
                records  => $records->results,
                columns  => \@columns,
                viewtype => 'table',
            };
        }
    }

    $params->{v}          = $view,  # View is reserved TT word
    $params->{user_views} = $views->user_views;
    $params->{alerts}     = GADS::Alert->all($user->{id});
    $params->{page}       = 'data';
    template 'data' => $params;
};

any '/account/?:action?/?' => sub {

    my $action = param 'action';
    my $user   = user;
    my $audit  = GADS::Audit->new(schema => schema, user => $user);

    if (param 'newpassword')
    {
        # See if existing password is correct first
        if (my $newpw = reset_pw 'password' => param('oldpassword'))
        {
            $audit->login_change("New password set for user");
            forwardHome({ success => qq(Your password has been changed to: $newpw)}, 'account/detail' );
        }
        else {
            forwardHome({ danger => "The existing password entered is incorrect"}, 'account/detail' );
        }
    }

    if (param 'graphsubmit')
    {
        if (process( sub { GADS::User->graphs($user, param('graphs')) }))
        {
            return forwardHome(
                { success => "The selected graphs have been updated" }, 'account/graph' );
        }
    }

    if (param 'submit')
    {
        # Update of user details
        my %update = (
            id           => $user->{id},
            firstname    => param('firstname')    || undef,
            surname      => param('surname')      || undef,
            email        => param('email'),
            username     => param('email'),
            telephone    => param('telephone')    || undef,
            title        => param('title')        || undef,
            organisation => param('organisation') || undef,
        );

        if (process( sub { user update => %update }))
        {
            $audit->login_change(
                "User updated own account details. New (or unchanged) email: $update{email}");
            return forwardHome(
                { success => "The account details have been updated" }, 'account/detail' );
        }
    }

    my $data;

    if ($action eq 'graph')
    {
        my $graphs = GADS::Graphs->new(user => $user, schema => schema);
        my $all_graphs = $graphs->all;
        template 'account' => {
            graphs => $all_graphs,
            action => $action,
            page   => 'account',
        };
    }
    elsif ($action eq 'detail')
    {
        template 'user' => {
            edit          => user->{id},
            users         => [$user],
            titles        => GADS::User->titles,
            organisations => GADS::User->organisations,
            page          => 'account/detail'
        };
    }
    else {
        return forwardHome({ danger => "Unrecognised action $action" });
    }
};

any '/config/?' => sub {

    return forwardHome(
        { danger => 'You do not have permission to edit general settings' } )
        unless permission 'layout';

    my $config = GADS::Config->new(schema => schema);

    if (param 'update')
    {
        $config->homepage_text(param 'homepage_text');
        $config->homepage_text2(param 'homepage_text2');
        $config->sort_layout_id(param 'sort_layout_id');
        $config->sort_type(param 'sort_type');

        if (process( sub { $config->write }))
        {
            return forwardHome(
                { success => "Configuration settings have been updated successfully" } );
        }
    }

    my $layout = GADS::Layout->new(
        user   => user,
        schema => schema,
    );
    my @all_columns = $layout->all;
    template 'config' => {
        all_columns => \@all_columns,
        instance    => $config,
        page        => 'config'
    };
};


any '/graph/?:id?' => sub {

    return forwardHome(
        { danger => 'You do not have permission to edit graphs' } )
        unless permission 'layout';

    my $layout = GADS::Layout->new(user => user, schema => schema);
    my $params = {
        layout => $layout,
        page   => 'graph',
    };

    my $id = param 'id';
    if (defined $id)
    {
        my $graph = GADS::Graph->new(schema => schema);
        $graph->id($id) if $id;

        if (param 'delete')
        {
            if (process( sub { $graph->delete }))
            {
                return forwardHome(
                    { success => "The graph has been deleted successfully" }, 'graph' );
            }
        }

        if (param 'submit')
        {
            my $values = params;
            $graph->$_(param $_)
                foreach (qw/title description type x_axis x_axis_grouping y_axis
                    y_axis_label y_axis_stack group_by stackseries/);
            if(process( sub { $graph->write }))
            {
                my $action = param('id') ? 'updated' : 'created';
                return forwardHome(
                    { success => "Graph has been $action successfully" }, 'graph' );
            }
        }
        $params->{graph} = $graph;
        $params->{dategroup} = GADS::Graphs->dategroup;
        $params->{graphtypes} = [GADS::Graphs->types];
    }
    else {
        my $graphs = GADS::Graphs->new(schema => schema)->all;
        $params->{graphs} = $graphs;
    }

    template 'graph' => $params;
};

any '/view/:id' => sub {

    my $view_id = param('id');
    $view_id = param('clone') if param('clone') && !request->is_post;
    my @ucolumns; my $view_values;

    my $user = user;
    my $layout = GADS::Layout->new(
        user   => $user,
        schema => schema,
    );
    my %vp = (
        user   => $user,
        schema => schema,
        layout => $layout,
    );
    $vp{id} = $view_id if $view_id;
    my $view = GADS::View->new(%vp);

    if (param 'update')
    {
        my $params = params;
        my $columns = ref param('column') ? param('column') : [ param('column') // () ]; # Ensure array
        $view->columns($columns);
        $view->global (param('global') ? 1 : 0);
        $view->name   (param 'name');
        $view->filter (param 'filter');
        if (process( sub { $view->write }))
        {
            $view->set_sorts($params);
            # Set current view to the one created/edited
            session 'view_id' => $view->id;
            return forwardHome(
                { success => "The view has been updated successfully" }, 'data' );
        }
    }

    if (param 'delete')
    {
        session 'view_id' => undef;
        if (process( sub { $view->delete }))
        {
            return forwardHome(
                { success => "The view has been deleted successfully" }, 'data' );
        }
    }


    my @all_columns = $layout->all;
    my $output = template 'view' => {
        all_columns  => \@all_columns,
        sort_types   => $view->sort_types,
        v            => $view, # TT does not like variable "view"
        page         => 'view'
    };
    $output;
};

any qr{/tree[0-9]*/([0-9]*)/?([0-9]*)} => sub {
    # Random number can be used after "tree" to prevent caching

    my ($layout_id, $value) = splat;

    my $tree = GADS::Column::Tree->new(schema => schema);

    if (param 'data')
    {
        return forwardHome(
            { danger => 'You do not have permission to edit trees' } )
            unless permission 'layout';

        $tree->id($layout_id);
        my $newtree = JSON->new->utf8(0)->decode(param 'data');
        $tree->update($newtree);
        return;
    }
    header "Cache-Control" => "max-age=0, must-revalidate, private";

    # If record is specified, select the record's value in the returned JSON
    $tree->from_id($layout_id);
    header "Cache-Control" => "max-age=0, must-revalidate, private";
    content_type 'application/json';
    encode_json($tree->json($value));

};

any '/layout/?:id?' => sub {

    return forwardHome(
        { danger => 'You do not have permission to edit the database layout' } )
        unless permission 'layout';

    my $layout      = GADS::Layout->new(user => user, schema => schema);
    my @all_columns = $layout->all;

    my $params = {
        page        => 'layout',
        all_columns => \@all_columns,
    };

    if (param('id') || param('submit'))
    {
        my $id = param('id');
        my $class = (param('type') && grep {param('type') eq $_} GADS::Column::types)
                  ? param('type')
                  : rset('Layout')->find($id)->type;
        $class = "GADS::Column::".camelize($class);
        my $column = $class->new(schema => schema, user => user, layout => $layout);
        $column->from_id($id) if $id;
        
        if (param 'delete')
        {
            if (process( sub { $column->delete }))
            {
                return forwardHome(
                    { success => "The item has been deleted successfully" }, 'layout' );
            }
        }

        if (param 'submit')
        {
            $column->$_(param $_)
                foreach (qw/name type permission description helptext optional hidden remember/);
            if (param 'display_condition')
            {
                $column->display_field(param 'display_field');
                $column->display_regex(param 'display_regex');
            }
            else {
                $column->display_field(undef);
            }
            if ($column->type eq "file")
            {
                $column->filesize(param('filesize') || undef) if $column->type eq "file";
            }
            elsif ($column->type eq "rag")
            {
                $column->red  (param 'red');
                $column->amber(param 'amber');
                $column->green(param 'green');
            }
            elsif ($column->type eq "enum")
            {
                my $params = params;
                $column->enumvals_from_form($params);
                $column->ordering(param('ordering') || undef);
            }
            elsif ($column->type eq "calc")
            {
                $column->calc(param 'calc');
                $column->return_type(param 'return_type');
            }
            elsif ($column->type eq "tree")
            {
                $column->end_node_only(param 'end_node_only');
            }

            if (process( sub { $column->write }))
            {
                my $action = param('id') ? 'updated' : 'created';
                return forwardHome(
                    { success => "Item has been $action successfully" }, 'layout' );
            }
        }
        $params->{column} = $column;
    }
    elsif (defined param('id'))
    {
        $params->{column} = 0; # New
    }

    if (param 'saveposition')
    {
        my $values = params;
        if (process( sub { $layout->position($values) }))
        {
            return forwardHome(
                { success => "The ordering has been saved successfully" }, 'layout' );
        }
    }

    template 'layout' => $params;
};

any '/user/?:id?' => sub {
    my $id = param 'id';

    return forwardHome(
        { danger => 'You do not have permission to manage users' } )
        unless permission('useradmin');

    my $audit  = GADS::Audit->new(schema => schema, user => user);

    # Retrieve conf to get details of defined permissions
    my $conf = Dancer2::Plugin::Auth::Complete->configure;

    # The submit button will still be triggered on a new org/title creation,
    # if the user has pressed enter, in which case ignore it
    if (param('submit') && !param('neworganisation') && !param('newtitle'))
    {
        my %values = %{params()};
        delete $values{id}              if  param 'account_request';
        delete $values{account_request} if  param 'account_request';
        delete $values{organisation} unless param 'organisation';
        delete $values{title}        unless param 'title';
        $values{username} = $values{email};

        my @audit_permissions;
        foreach my $permission (keys %{$conf->{permissions}})
        {
            $values{permission}->{$permission} = $values{"permission_$permission"} ? 1 : 0;
            push @audit_permissions, "$permission: $values{permission}->{$permission}";
        }

        my $newuser;
        if (process( sub { $newuser = user update => %values }))
        {
            # Delete account request user if this is a new account request
            user delete => id => param('account_request')
                if param 'account_request';

            my $action;
            my $audit_perms = join ', ', @audit_permissions;
            if ($id) {
                $audit->login_change(
                    "User updated: ID $newuser->{id}, username: $newuser->{username}; permissions: $audit_perms");
                $action = 'updated';
            }
            else {
                $audit->login_change(
                    "New user created: ID $newuser->{id}, username: $newuser->{username}; permissions: $audit_perms");
                $action = 'created';
            }

            return forwardHome(
                { success => "User has been $action successfully" }, 'user' );
        }
    }

    my $users; my $register_requests;

    if (param('neworganisation') || param('newtitle'))
    {
        if (my $org = param 'neworganisation')
        {
            if (process( sub { GADS::User->organisation_new({ name => $org })}))
            {
                $audit->login_change("Organisation $org created");
                messageAdd({ success => "The organisation has been created successfully" });
            }
        }

        if (my $title = param 'newtitle')
        {
            if (process( sub { GADS::User->title_new({ name => $title }) }))
            {
                $audit->login_change("Title $title created");
                messageAdd({ success => "The title has been created successfully" });
            }
        }

        $users = [{
            firstname    => param('firstname'),
            surname      => param('surname'),
            email        => param('email'),
            title        => { id => param('title') },
            organisation => { id => param('organisation') },
        }];
    }
    elsif (my $delete_id = param('delete'))
    {
        return forwardHome(
            { danger => "Cannot delete current logged-in User" } )
            if user->{id} eq $delete_id;
        if (process( sub { GADS::User->delete($delete_id) }))
        {
            $audit->login_change("User ID $delete_id deleted");
            return forwardHome(
                { success => "User has been deleted successfully" }, 'user' );
        }
    }

    if ($id)
    {
        $users = user get => id => $id, account_request => [0,1];
    }
    elsif (!defined $id) {
        $users             = GADS::User->all;
        $register_requests = GADS::User->register_requests;
    }

    # Get permissions and sort them
    my @permissions;
    my %permissions = %{$conf->{permissions}};
    foreach my $perm (sort { $permissions{$a}->{value} <=> $permissions{$b}->{value} } keys %permissions)
    {
        push @permissions, {$perm => $permissions{$perm}};
    }

    my $output = template 'user' => {
        edit              => $id,
        users             => $users,
        register_requests => $register_requests,
        titles            => GADS::User->titles,
        organisations     => GADS::User->organisations,
        permissions       => \@permissions,
        page              => 'user'
    };
    $output;
};

any '/approval/?:id?' => sub {
    my $id   = param 'id';
    my $user = user;
    return forwardHome(
        { danger => 'You do not have permission to approve records' } )
        unless permission 'approver';

    my $layout = GADS::Layout->new(user => $user, schema => schema);
    if (param 'submit')
    {
        # Get latest record for this approval
        my $record = GADS::Record->new(
            user             => $user,
            layout           => $layout,
            schema           => schema,
            include_approval => 1,
        );
        $record->find_current_id(param 'current_id');
        my $uploads = request->uploads;
        foreach my $key (keys %$uploads)
        {
            next unless $key =~ /^file([0-9]+)/;
            my $upload = $uploads->{$key};
            my $col_id = $1;
            $record->fields->{$col_id}->set_value({
                name     => $upload->filename,
                mimetype => $upload->type,
                content  => $upload->content,
            });
        }
        my $failed;
        foreach my $col ($layout->all)
        {
            if ($col->userinput) # Not calculated fields
            {
                # No need to do anything if the file's just been uploaded
                if (my $newv = param($col->field))
                {
                    $failed = !process( sub { $record->fields->{$col->id}->set_value($newv) } ) || $failed;
                }
            }
        }
        if (!$failed && process( sub { $record->write }))
        {
            # If we've been writing to a newer record, then delete the approval
            if ($record->record_id != $id)
            {
                GADS::Record->new(
                    user      => $user,
                    layout    => $layout,
                    schema    => schema,
                    record_id => $id,
                )->delete;
            }
            else {
                # Otherwise remove approval flag
                $record->approval_flag(0);
            }
            return forwardHome(
                { success => 'Record has been successfully approved' }, 'approval' );
        }
    }

    my $page;
    my @all_columns = $layout->all;
    my $params = {
        all_columns => \@all_columns,
        page        => 'approval',
    };

    if ($id)
    {
        # Get the record of values needing approval
        my $record = GADS::Record->new(
            user             => $user,
            init_no_value    => 0,
            layout           => $layout,
            include_approval => 1,
            schema           => schema,
        );
        $record->find_record_id($id);
        $params->{record} = $record;

        # Get existing values for comparison
        my $existing = GADS::Record->new(
            user            => $user,
            layout          => $layout,
            schema          => schema,
        );
        my $found = $existing->find_current_id($record->current_id);
        $params->{existing} = $existing if $found;
        $page  = 'edit';
    }
    else {
        $page  = 'approval';
        my $records = GADS::Records->new(
            user             => $user,
            include_approval => 1,
            layout           => $layout,
            schema           => schema,
            columns          => []
        );
        $records->search(approval => 1);
        $params->{records} = $records->results;
    }

    template $page => $params;
};

get '/helptext/:id?' => sub {
    my $id = param 'id';
    my $layout = GADS::Layout->new(user => user, schema => schema);
    my $column = GADS::Column->new(schema => schema, user => user, layout => $layout);
    $column->from_id(param 'id');
    template 'helptext.tt', { column => $column }, { layout => undef };
};

any '/edit/:id?' => sub {
    my $id = param 'id';

    my $layout = GADS::Layout->new(user => user, schema => schema);
    my $record = GADS::Record->new(
        user   => user,
        layout => $layout,
        schema => schema,
    );

    if ($id)
    {
        $record->find_current_id($id);
    }

    my @all_columns = $layout->all;
    if (param 'submit')
    {
        $record->initialise unless $id;
        my $params = params;
        my $uploads = request->uploads;
        foreach my $key (keys %$uploads)
        {
            next unless $key =~ /^file([0-9]+)/;
            my $upload = $uploads->{$key};
            my $col_id = $1;
            $record->fields->{$col_id}->set_value({
                name     => $upload->filename,
                mimetype => $upload->type,
                content  => $upload->content,
            });
        }
        my $failed;
        foreach my $col ($layout->all)
        {
            if ($col->userinput) # Not calculated fields
            {
                # No need to do anything if the file's just been uploaded
                unless (upload "file".$col->id)
                {
                    my $newv = param($col->field);
                    $failed = !process( sub { $record->fields->{$col->id}->set_value($newv) } ) || $failed;
                }
            }
        }
        if (!$failed && process( sub { $record->write }))
        {
            return forwardHome(
                { success => 'Submission has been completed successfully' }, 'data' );
        }
    }
    elsif($id) {
        $record->find_current_id($id);
    }
    elsif(my $previous = user->{lastrecord})
    {
        # Prefill previous values, but only those tagged to be remembered
        my @remember = map {$_->id} $layout->all(remember => 1);
        $record->columns(\@remember);
        $record->include_approval(1);
        $record->find_record_id($previous);
        $record->columns_retrieved(\@all_columns); # Force all columns to be shown
        $record->current_id(undef);
    }
    else {
        $record->initialise;
    }

    my $output = template 'edit' => {
        record      => $record,
        all_columns => \@all_columns,
        page        => 'edit'
    };
    $output;
};

any '/file/:id' => sub {
    my $id = param 'id';
    my $file;
    process (sub { $file = GADS::Datum::File->get_file($id, schema, user) });
    send_file( \($file->content), content_type => $file->mimetype, filename => $file->name );
};

any '/record/:id' => sub {
    my $id = param 'id';

    my $layout = GADS::Layout->new(user => user, schema => schema);
    my $record = GADS::Record->new(
        user   => user,
        layout => $layout,
        schema => schema,
    );
    $record->find_record_id($id);
    my @versions = $record->versions;

    if (my $delete_id = param 'delete')
    {
        if (process( sub { $record->delete_current }))
        {
            return forwardHome(
                { success => 'Record has been deleted successfully' }, 'data' );
        }
    }

    my @columns = $layout->all;
    my $output = template 'record' => {
        record         => $record,
        versions       => \@versions,
        all_columns    => \@columns,
        page           => 'record'
    };
    $output;
};

any '/login' => sub {

    my $audit  = GADS::Audit->new(schema => schema);

    if (defined param('logout'))
    {
        $audit->user(user);
        $audit->logout(user->{username}) if user;
        context->destroy_session;
    }

    # Don't allow login page to be displayed when logged-in, to prevent
    # user thinking they are logged out when they are not
    return forwardHome({}, '') if user;

    # Request a password reset
    if (param('resetpwd'))
    {
        my $username = param('emailreset');
        $audit->login_change("Password reset request for $username");
        reset_pw('send' => $username)
        ? messageAdd( { success => 'An email has been sent to your email address with a link to reset your password' } )
        : messageAdd( { danger => 'Failed to send a password reset link. Did you enter a valid email address?' } );
    }

    my $error;

    if (param 'register')
    {
        my $params = params;
        try { GADS::User->register($params) };
        if(my $exception = $@->wasFatal)
        {
            $error = $exception->message->toString;
        }
        else {
            $audit->login_change("New user account request for $params->{email}");
            return forwardHome({ success => "Your account request has been received successfully" });
        }
    }

    if (param('signin'))
    {
        if (login)
        {
            $audit->user(user);
            $audit->login_success;
            forwardHome();
        }
        else {
            $audit->login_failure(param 'username');
            messageAdd({ danger => "The username or password was not recognised" });
        }
    }

    my $config = GADS::Config->new(schema => schema);
    my $output  = template 'login' => {
        error         => "".($error||""),
        instance      => $config,
        titles        => GADS::User->titles,
        organisations => GADS::User->organisations,
        register_text => GADS::User->register_text,
        page          => 'login',
    };
    $output;
};

get '/resetpw/:code' => sub {

    # Perform check first in order to get user ID for audit
    if (my $user_id = reset_pw 'check' => param('code'))
    {
        context->destroy_session;
        my $audit  = GADS::Audit->new(schema => schema, user => {id => $user_id});
        $audit->login_change("Password reset performed for user ID $user_id");
        my $password = reset_pw 'code' => param('code');
        my $output  = template 'login' => {
            password => $password,
            page     => 'login',
        };
        $output;
    }
    else {
        return forwardHome(
            { danger => "The requested authorisation code could not be processed" }, 'login'
        );
    }
};

sub forwardHome {
    if (my $message = shift)
    {
        messageAdd($message);
    }
    my $page = shift || '';
    redirect "/$page";
}

sub messageAdd($) {
    my $message = shift;
    return unless keys %$message;
    my $text    = ( values %$message )[0];
    my $type    = ( keys %$message )[0];
    my $msgs    = session 'messages';
    push @$msgs, { text => encode_entities($text), type => $type };
    session 'messages' => $msgs;
}

sub error_handler
{   my ($disp, $options, $reason, $message) = @_;

    if ($reason =~ /(TRACE|ASSERT|INFO)/)
    {
        # Debug info. Log to syslog.
    }
    elsif ($reason eq 'NOTICE')
    {
        # Notice that something has happened. Not an error.
        messageAdd({ info => "$message" });
    }
    elsif ($reason =~ /(WARNING|MISTAKE)/)
    {
        # Non-fatal problem. Show warning.
        messageAdd({ warning => "$message" });
    }
    elsif ($reason eq 'ERROR') {
        # A user-created error condition that is not recoverable.
        # This could have already been caught by the process
        # subroutine, in which case we should continue running
        # of the program. In all other cases, we should bail
        # out. With the former, the exception will have been
        # re-thrown as a non-fatal exception, so check that.
        exists $options->{is_fatal} && !$options->{is_fatal}
            ? messageAdd({ danger => "$message" })
            : forwardHome({ danger => "$message" });
    }
    else {
        # 'FAULT', 'ALERT', 'FAILURE', 'PANIC'
        # All these are fatal errors. Display error to user, but
        # forward home so that we can reload. However, don't if
        # it's a GET request to the home, as it will cause a recursive
        # loop. In this case, do nothing, and let dancer handle it.
        forwardHome({ danger => "$message" })
            unless request->uri eq '/' && request->is_get;
    }
}

# This runs a code block and catches errors, which in then
# handles in a more graceful manner, throwing as required
sub process
{
    my $coderef = shift;
    try {&$coderef};
    my $result = $@ ? 0 : 1; # Return true on success
    if (my $exception = $@->wasFatal)
    {
        $exception->throw(is_fatal => 0);
    }
    $result;
}

true;
