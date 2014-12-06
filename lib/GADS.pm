package GADS;
use Dancer2;
use GADS::Record;
use GADS::User;
use GADS::View;
use GADS::Layout;
use GADS::Email;
use GADS::Graph;
use GADS::Config;
use GADS::Alert;
use GADS::Audit;
use GADS::DB;
use GADS::Util         qw(:all);
use Dancer2::Plugin::Auth::Complete;
use Ouch;
use DateTime;
use HTML::Entities;
use JSON qw(decode_json encode_json);
use Text::CSV;

set serializer => 'JSON';
set behind_proxy => config->{behind_proxy}; # XXX Why doesn't this work in config file

our $VERSION = '0.1';

Dancer2::Plugin::Auth::Complete->user_callback( sub {
    my ($retuser, $user) = @_;
    $retuser->{value} = GADS::Record->person_update_value($user);
    $retuser->{views} = GADS::View->all($user->id);
    $retuser->{lastrecord} = $user->lastrecord ? $user->lastrecord->id : undef;
    $retuser;
});

hook before => sub {

    # Static content
    return if request->uri =~ m!^/(error|js|css|login|images|fonts|resetpw)!;
    return if param 'error';

    # Redirect on no session
    redirect '/login' unless user;

    # Dynamically generate "virtual" columns for each row of data, based on the
    # configured layout
    GADS::DB->setup;

};

hook before_template => sub {
    my $tokens = shift;

    # Log to audit
    my $user = user;
    my $method = request->method;
    my $path   = request->path;
    GADS::Audit->user_action($user->{id}, qq(User $user->{username} made $method request to $path))
        if $user;

    my $base = request->base;
    $tokens->{url}->{css}  = "${base}css";
    $tokens->{url}->{js}   = "${base}js";
    $tokens->{url}->{page} = $base;
    $tokens->{url}->{page} =~ s!.*/!!; # Remove trailing slash
    $tokens->{hostlocal}   = config->{gads}->{hostlocal};

    $tokens->{header} = config->{gads}->{header};

    $tokens->{approve_waiting} = scalar @{GADS::Record->approve}
        if permission 'approver';
    $tokens->{messages} = session('messages');
    $tokens->{user}     = $user;
    session 'messages' => [];

};

get '/' => sub {

    template 'index' => {
        config => GADS::Config->conf,
        page   => 'index'
    };
};

get '/data_calendar/:time' => sub {

    # Time variable is used to prevent caching by browser

    my $view_id = session 'view_id';
    my $from    = param 'from';
    my $to      = param 'to';

    header "Cache-Control" => "max-age=0, must-revalidate, private";
    {
        "success" => 1,
        "result"  => GADS::Record->data_calendar($view_id, user, $from, $to),
    }
};

get '/search' => sub {

    my $search = param 'search';
    my @results = GADS::Record->search($search, user);
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
        eval { GADS::Alert->alert($alert_view, param('frequency'), $user) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
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

    if (my $sort = param('sort'))
    {
        my $existing = session 'sort';
        $sort = int $sort;
        my $type;
        if ($existing && $existing->{id} == $sort)
        {
            $type = $existing->{type} eq 'asc' ? 'desc' : 'asc';
        }
        else {
            $type = 'asc';
        }
        session 'sort' => { type => $type, id => $sort };
    }
    elsif (defined param('sort'))
    {
        # Provide a way of resetting sort to default
        session 'sort' => undef;
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

    my $default_view = shift @{$user->{views}};
    my $view_id  = session('view_id') || $default_view->id;

    my $columns;
    eval { $columns = GADS::View->columns({ view_id => $view_id, user => $user, no_hidden => 1 }) };
    if (hug)
    {
        session 'view_id' => undef;
        return forwardHome({ danger => bleep });
    }

    my $params; # Variable for the template

    if ($viewtype eq 'graph')
    {
        my $todraw = GADS::Graph->all({ user => $user });

        my @graphs;
        foreach my $g (@$todraw)
        {
            my $graph = GADS::Graph->data({ graph => $g, view_id => $view_id, user => $user });
            push @graphs, $graph if $graph;
        }

        $params = {
            graphs      => \@graphs,
            viewtype    => 'graph',
        };

    }
    elsif ($viewtype eq 'calendar')
    {
        # Get details of the view and work out color markers for date fields
        my @colors = qw/event-important event-success event-warning event-info event-inverse event-special/;
        my %datecolors;
        foreach my $column (@$columns)
        {
            if ($column->{type} eq "daterange" || $column->{type} eq "date")
            {
                $datecolors{$column->{name}} = shift @colors;
            }
        }

        $params = {
            datecolors => \%datecolors,
            viewtype   => 'calendar',
            time       => time,
        }
    }
    else {
        session 'rows' => 50 unless session 'rows';
        session 'page' => 1 unless session 'page';

        my $rows = defined param('download') ? undef : session('rows');
        my $page = defined param('download') ? undef : session('page');

        # @records contains all the information for each required record
        my $get = {
            view_id => $view_id,
            user    => $user,
            rows    => $rows,
            page    => $page,
            sort    => session('sort'),
        };

        my @records = GADS::Record->current($get);
        my $pages = $get->{pages};
        # @output contains just the data itself, which can be sent straight to a CSV
        my $options = defined param('download') ? { plain => 1 } : { encode_entities => 1 };
        $options->{user} = $user;
        my @output = GADS::Record->data($view_id, \@records, $options);

        my @colnames = ('Serial');
        foreach my $column (@$columns)
        {
            push @colnames, $column->{name};
        }

        my $subset = {
            rows  => session('rows'),
            pages => $pages,
            page  => $page,
        };

        $params = {
            sort     => session('sort'),
            subset   => $subset,
            records  => \@output,
            columns  => $columns,
            viewtype => 'table',
            rag      => sub { GADS::Record->rag(@_) },
        };

        if (param 'sendemail')
        {
            forwardHome({ danger => "There are no records in this view and therefore nobody to email"}, 'data')
                unless @records;

            return forwardHome(
                { danger => 'You do not have permission to send messages' }, 'data' )
                unless permission 'message';

            # Collect all the actual record IDs, including RAG filters
            my @ids;
            foreach my $o (@output)
            {
                push @ids, $o->[0];
            }

            my $params = params;

            eval { GADS::Email->message($params, \@records, \@ids, $user) };
            if (hug)
            {
                messageAdd({ danger => bleep });
            }
            else {
                return forwardHome(
                    { success => "The message has been sent successfully" }, 'data' );
            }
        }

        if (defined param('download'))
        {
            forwardHome({ danger => "You do not have permission to download data"}, 'data')
                unless permission 'download';

            forwardHome({ danger => "There are no records to download in this view"}, 'data')
                unless @records;

            my $csv;
            eval { $csv = GADS::Record->csv(\@colnames, \@output) };
            if (hug)
            {
                messageAdd({ danger => bleep });
            }
            else {
                my $now = DateTime->now();
                return send_file( \$csv, content_type => 'text/csv', filename => "$now.csv" );
            }
        }
    }

    $params->{v}        = GADS::View->view($view_id, $user),  # View is reserved TT word
    $params->{alerts}   = GADS::Alert->all($user->{id});
    $params->{page}     = 'data';
    template 'data' => $params;
};

any '/account/?:action?/?' => sub {

    my $action = param 'action';

    if (param 'newpassword')
    {
        # See if existing password is correct first
        if (my $newpw = reset_pw 'password' => param('oldpassword'))
        {
            GADS::Audit->login_change(user->{id}, "New password set for user");
            forwardHome({ success => qq(Your password has been changed to: $newpw)}, 'account/detail' );
        }
        else {
            forwardHome({ danger => "The existing password entered is incorrect"}, 'account/detail' );
        }
    }

    if (param 'graphsubmit')
    {
        eval { GADS::User->graphs(user, param('graphs')) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            return forwardHome(
                { success => "The selected graphs have been updated" }, 'account/graph' );
        }
    }

    if (param 'submit')
    {
        # Update of user details
        my %update = (
            id           => user->{id},
            firstname    => param('firstname')    || undef,
            surname      => param('surname')      || undef,
            email        => param('email'),
            username     => param('email'),
            telephone    => param('telephone')    || undef,
            title        => param('title')        || undef,
            organisation => param('organisation') || undef,
        );

        eval { user update => %update };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            GADS::Audit->login_change(user->{id},
                "User updated own account details. New (or unchanged) email: $update{email}");
            return forwardHome(
                { success => "The account details have been updated" }, 'account/detail' );
        }
    }

    my $data;

    if ($action eq 'graph')
    {
        $data->{graphs} = GADS::Graph->all({ user => user, all => 1 });
        template 'account' => {
            data   => $data,
            action => $action,
            page   => 'account',
        };
    }
    elsif ($action eq 'detail')
    {
        template 'user' => {
            edit          => user->{id},
            users         => [user],
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

    if (param 'update')
    {
        my $params = params;
        eval { GADS::Config->conf($params)};
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            return forwardHome(
                { success => "Configuration settings have been updated successfully" } );
        }
    }

    my $autoserial = config->{gads}->{serial} eq "auto" ? 1 : 0;
    template 'config' => {
        all_columns => GADS::View->columns,
        autoserial  => $autoserial,
        config      => GADS::Config->conf,
        page        => 'config'
    };
};


any '/graph/?:id?' => sub {

    my $id = param 'id';

    return forwardHome(
        { danger => 'You do not have permission to edit graphs' } )
        unless permission 'layout';

    if (param 'delete')
    {
        eval { GADS::Graph->delete(param 'id') };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            return forwardHome(
                { success => "The graph has been deleted successfully" }, 'graph' );
        }
    }

    if (param 'submit')
    {
        my $values = params;
        eval { GADS::Graph->graph($values) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            my $action = param('id') ? 'updated' : 'created';
            return forwardHome(
                { success => "Graph has been $action successfully" }, 'graph' );
        }
    }

    my $graphs;
    if ($id)
    {
        $graphs = GADS::Graph->graph({ id => $id });
    }
    else {
        $graphs = GADS::Graph->all;
    }

    my $output  = template 'graph' => {
        edit        => $id,
        graphs      => $graphs,
        dategroup   => GADS::Graph->dategroup,
        graphtypes  => [GADS::Graph->graphtypes],
        all_columns => GADS::View->columns,
        page        => 'graph'
    };
    $output;
};

any '/view/:id' => sub {

    my $view_id = param('id');
    my @ucolumns; my $view;

    if (param 'update')
    {
        my $values = params;
        eval { GADS::View->view($view_id, user, $values) };

        if (hug)
        {
            $view = $values;
            @ucolumns = @{delete $view->{column}};
            messageAdd({ danger => bleep });
        }
        else {
            # Set current view to the one created/edited
            session 'view_id' => $values->{view_id};
            return forwardHome(
                { success => "The view has been updated successfully" }, 'data' );
        }
    }

    if (param 'delete')
    {
        session 'view_id' => undef;
        eval { GADS::View->delete(param('id'), user) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            return forwardHome(
                { success => "The view has been deleted successfully" }, 'data' );
        }
    }

    $view_id = param('clone') if param('clone') && !request->is_post;

    unless ($view)
    {
        $view = GADS::View->view($view_id, user);
        my $viewcols;
        eval { $viewcols = GADS::View->columns({ view_id => $view_id, user => user }) };
        if (hug)
        {
            return forwardHome({ danger => bleep });
        }

        foreach my $c (@$viewcols)
        {
            push @ucolumns, $c->{id};
        }
    }

    my $autoserial = config->{gads}->{serial} eq "auto" ? 1 : 0;
    my $output = template 'view' => {
        all_columns  => GADS::View->columns({ user => user, no_hidden => 1 }),
        autoserial   => $autoserial,
        sorts        => GADS::View->sorts($view_id),
        sort_types   => GADS::View->sort_types,
        ucolumns     => \@ucolumns,
        v            => $view, # TT does not like variable "view"
        page         => 'view'
    };
    $output;
};

any qr{/tree[0-9]*/([0-9]*)/?([0-9]*)} => sub {
    # Random number can be used after "tree" to prevent caching

    my ($layout_id, $value) = splat;

    if (param 'data')
    {
        return forwardHome(
            { danger => 'You do not have permission to edit trees' } )
            unless permission 'layout';

        my $tree = JSON->new->utf8(0)->decode(param 'data');
        GADS::Layout->tree($layout_id, { tree => $tree} );
    }
    header "Cache-Control" => "max-age=0, must-revalidate, private";

    # If record is specified, select the record's value in the returned JSON
    GADS::Layout->tree(
        $layout_id,
        {
            value => $value,
        }
    );
};

any '/layout/?:id?' => sub {

    my $id = param 'id';

    return forwardHome(
        { danger => 'You do not have permission to edit the database layout' } )
        unless permission 'layout';

    if (param 'delete')
    {
        eval { GADS::Layout->delete(param 'id') };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            return forwardHome(
                { success => "The item has been deleted successfully" }, 'layout' );
        }
    }

    if (param 'submit')
    {
        my $values = params;
        eval { GADS::Layout->item($values) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            my $action = param('id') ? 'updated' : 'created';
            return forwardHome(
                { success => "Item has been $action successfully" }, 'layout' );
        }
    }

    if (param 'saveposition')
    {
        my $values = params;
        eval { GADS::Layout->position($values) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            return forwardHome(
                { success => "The ordering has been saved successfully" }, 'layout' );
        }
    }

    my $items;
    if ($id)
    {
        $items = GADS::Layout->item({ id => $id });
    }

    my $output = template 'layout' => {
        edit        => $id,
        all_items   => GADS::Layout->all,
        items       => $items,
        page        => 'layout'
    };
    $output;
};

any '/user/?:id?' => sub {
    my $id = param 'id';

    return forwardHome(
        { danger => 'You do not have permission to manage users' } )
        unless permission('useradmin');

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
        eval { $newuser = user update => %values };
        if (hug)
        {
            if (param('page') eq 'user')
            {
                messageAdd({ danger => bleep });
            }
            else {
                return forwardHome(
                    { danger => bleep }, '/user' );
            }
        }
        else {
            # Delete account request user if this is a new account request
            user delete => id => param('account_request')
                if param 'account_request';

            my $action;
            my $audit_perms = join ', ', @audit_permissions;
            if ($id) {
                GADS::Audit->login_change(user->{id},
                    "User updated: ID $newuser->{id}, username: $newuser->{username}; permissions: $audit_perms");
                $action = 'updated';
            }
            else {
                GADS::Audit->login_change(user->{id},
                    "New user created: ID $newuser->{id}, username: $newuser->{username}; permissions: $audit_perms");
                $action = 'created';
            }


            my $page   = param('page');
            return forwardHome(
                { success => "User has been $action successfully" }, $page );
        }
    }

    my $users; my $register_requests;

    if (param('neworganisation') || param('newtitle'))
    {
        if (my $org = param 'neworganisation')
        {
            eval { GADS::User->organisation_new({ name => $org }) };
            if (hug)
            {
                messageAdd({ danger => bleep });
            }
            else {
                GADS::Audit->login_change(user->{id}, "Organisation $org created");
                messageAdd({ success => "The organisation has been created successfully" });
            }
        }

        if (my $title = param 'newtitle')
        {
            eval { GADS::User->title_new({ name => $title }) };
            if (hug)
            {
                messageAdd({ danger => bleep });
            }
            else {
                GADS::Audit->login_change(user->{id}, "Title $title created");
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
        eval { GADS::User->delete($delete_id) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            GADS::Audit->login_change(user->{id}, "User ID $delete_id deleted");
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
    my $id = param 'id';

    return forwardHome(
        { danger => 'You do not have permission to approve records' } )
        unless permission 'approver';

    if (param 'submit')
    {
        # Do approval
        my $values  = params;
        my $uploads = request->uploads;
        eval { GADS::Record->approve(user, $id, $values, $uploads) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            return forwardHome(
                { success => 'Record has been successfully approved' }, 'approval' );
        }
    }

    my ($items, $page);
    if ($id)
    {
        $items = GADS::Record->approve(user, $id);
        $page  = 'edit';
    }
    else {
        $items = GADS::Record->approve;
        $page  = 'approval';
    }

    my $autoserial = config->{gads}->{serial} eq "auto" ? 1 : 0;
    my $output = template $page => {
        form_value     => sub {item_value(@_, {raw => 1, encode_entities => 1})},
        item_value     => sub {item_value(@_, {encoded_entities => 1})},
        person_popover => sub {GADS::Record->person_popover(@_)},
        approves       => $items,
        autoserial     => $autoserial,
        people         => GADS::User->all,
        all_columns    => GADS::View->columns,
        page           => 'approval',
    };
    $output;
};

get '/helptext/:id?' => sub {
    my $id = param 'id';
    my $col = GADS::Layout->item({ id => $id });
    template 'helptext.tt', { column => $col }, { layout => undef };
};

any '/edit/:id?' => sub {
    my $id = param 'id';

    my $all_columns = GADS::View->columns({ user => user, no_hidden => 1 }),
    my $record;
    if (param 'submit')
    {
        my $params = params;
        my $uploads = request->uploads;
        eval { GADS::Record->update($params, user, $uploads) };
        if (hug)
        {

            my $bleep = bleep; # Otherwise it's overwritten

            my %columns = map { $_->{id} => $_ } @$all_columns; # Need this to check column type easily

            my $has_file;
            # Remember previous submitted values in event of error
            foreach my $fn (keys %$params)
            {
                next unless $fn =~ /^field(\d+)$/;
                if ($params->{"file$1"})
                {
                    $has_file = 1
                }
                elsif ($columns{$1}->{type} ne "file")
                {
                    # If it's a file field that wasn't submitted,
                    # then that submitted form value is 1. Ignore.
                    $record->{$fn} = {value => $params->{$fn}};
                }
            }
            # For the hidden current_id field
            $record->{current}->{id} = $params->{current_id};

            # For files, we have to retrieve the previous filenames,
            # as we don't know what they were from the submit
            if ($id)
            {
                my %files = GADS::Record->files($id);
                foreach my $fn (keys %files)
                {
                    $record->{$fn} = {value => $files{$fn}};
                }
            }

            $bleep .= " Please note that you will need to reselect your uploaded files." if $has_file;
            messageAdd( { danger => $bleep } );
        }
        else {
            return forwardHome(
                { success => 'Submission has been completed successfully' }, 'data' );
        }
    }
    elsif($id) {
        $record = GADS::Record->current({ current_id => $id, user => user });
    }
    elsif(my $previous = user->{lastrecord})
    {
        # Prefill previous values, but only those tagged to be remembered
        my $previousr = GADS::Record->current({ record_id => $previous, remembered_only => 1 });
        foreach my $column (@$all_columns)
        {
            if ($column->{remember})
            {
                my $v = item_value($column, $previousr, {raw => 1, encoded_entities => 1});
                if ($column->{fixedvals}) {
                    # Value may no longer be valid. Check it.
                    eval {GADS::View->is_valid_enumval($v, $column)}; # Borks on error
                    $v = undef if hug;
                }
                my $field = $column->{field};
                $record->{$field} = {value => $v} if $column->{remember};
            }
        }
    }

    my $autoserial = config->{gads}->{serial} eq "auto" ? 1 : 0;
    my $output = template 'edit' => {
        form_value  => sub {item_value(@_, {raw => 1, encode_entities => 1})},
        plain_value => sub {item_value(@_, {plain => 1, encode_entities => 1})},
        record      => $record,
        autoserial  => $autoserial,
        people      => GADS::User->all,
        all_columns => $all_columns,
        page        => 'edit'
    };
    $output;
};

any '/file/:id' => sub {
    my $id = param 'id';
    my $file;
    eval { $file = GADS::Record->file($id, user) };
    if (hug)
    {
        forwardHome({ danger => bleep });
    }
    send_file( \($file->content), content_type => $file->mimetype, filename => $file->name );
};

any '/record/:id' => sub {
    my $id = param 'id';

    if (my $delete_id = param 'delete')
    {
        return forwardHome(
            { danger => 'You do not have permission to delete records' }, 'data' )
            unless permission('delete') || permission('delete_noneed_approval');

        eval { GADS::Record->delete($delete_id, user) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            return forwardHome(
                { success => 'Record has been deleted successfully' }, 'data' );
        }
    }

    my $record = $id ? GADS::Record->current({ record_id => $id, user => user }) : {};
    my $versions = $id ? GADS::Record->versions(rfield($record, 'current')->id) : {};
    my $autoserial = config->{gads}->{serial} eq "auto" ? 1 : 0;
    my $output = template 'record' => {
        item_value     => sub {item_value(@_, {encode_entities => 1})},
        person_popover => sub {GADS::Record->person_popover(@_)},
        record         => $record,
        autoserial     => $autoserial,
        versions       => $versions,
        all_columns    => GADS::View->columns({ user => user, no_hidden => 1 }),
        page           => 'record'
    };
    $output;
};

any '/login' => sub {
    if (defined param('logout'))
    {
        GADS::Audit->logout(user->{id}, user->{username}) if user;
        context->destroy_session;
    }

    # Don't allow login page to be displayed when logged-in, to prevent
    # user thinking they are logged out when they are not
    return forwardHome({}, '') if session 'user_id';

    # Request a password reset
    if (param('resetpwd'))
    {
        my $username = param('emailreset');
        GADS::Audit->login_change(undef, "Password reset request for $username");
        reset_pw('send' => $username)
        ? messageAdd( { success => 'An email has been sent to your email address with a link to reset your password' } )
        : messageAdd( { danger => 'Failed to send a password reset link. Did you enter a valid email address?' } );
    }

    my $error;

    if (param 'register')
    {
        my $params = params;
        eval { GADS::User->register($params) };
        if (hug)
        {
            $error = bleep;
        }
        else {
            GADS::Audit->login_change(undef, "New user account request for $params->{email}");
            return forwardHome({ success => "Your account request has been received successfully" });
        }
    }

    if (param('signin'))
    {
        if (login)
        {
            GADS::Audit->login_success(user->{id}, user->{username});
            forwardHome();
        }
        else {
            GADS::Audit->login_failure(param 'username');
            messageAdd({ danger => "The username or password was not recognised" });
        }
    }

    my $output  = template 'login' => {
        error         => $error,
        config        => GADS::Config->conf,
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
        GADS::Audit->login_change($user_id, "Password reset performed for user ID $user_id");
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

true;
