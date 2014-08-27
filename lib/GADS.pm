package GADS;
use Dancer2;
use GADS::Record;
use GADS::User;
use GADS::View;
use GADS::Layout;
use GADS::Email;
use GADS::Graph;
use GADS::Util         qw(:all);
use Dancer2::Plugin::DBIC qw(schema resultset rset);
use String::CamelCase qw(camelize);
use Ouch;
use DateTime;
use JSON qw(decode_json encode_json);
use Text::CSV;

set serializer => 'JSON';

our $VERSION = '0.1';

hook before => sub {

    # Static content
    return if request->uri =~ m!^/(error|js|css|login|images|fonts|resetpw)!;
    return if param 'error';

    # Redirect on no session
    redirect '/login' unless session('user_id');

    # Redirect if user no longer valid
    my $user = GADS::User->user({ id => session('user_id') })
        or redirect '/login';
    var 'user' => $user;

    # Dynamically generate "virtual" columns for each row of data, based on the
    # configured layout

    my $layout_rs = rset('Layout');
    my @cols = $layout_rs->all;

    foreach my $col (@cols)
    {
        my $coltype = $col->type eq "tree"
                    ? 'enum'
                    : $col->type eq "calc"
                    ? 'calcval'
                    : $col->type eq "rag"
                    ? 'ragval'
                    : $col->type;

        my $colname = "field".$col->id;

        # Temporary hack
        # very inefficient and needs to go away when the rel options show up
        my $rec_class = schema->class('Record');
        $rec_class->might_have(
            $colname => camelize($coltype),
            sub {
                my $args = shift;

                return {
                    "$args->{foreign_alias}.record_id" => { -ident => "$args->{self_alias}.id" },
                    "$args->{foreign_alias}.layout_id" => $col->id,
                };
            }
        );
        schema->unregister_source('Record');
        schema->register_class(Record => $rec_class);
    }
};

hook before_template => sub {
    my $tokens = shift;

    $tokens->{url}->{css}  = request->base . 'css';
    $tokens->{url}->{js}   = request->base . 'js';
    $tokens->{url}->{page} = request->base;
    $tokens->{url}->{page} =~ s!.*/!!; # Remove trailing slash
    $tokens->{hostlocal}   = config->{gads}->{hostlocal};

    $tokens->{header} = config->{gads}->{header};

    $tokens->{messages} = session('messages');
    $tokens->{user}     = var('user');
    session 'messages' => [];

};

get '/' => sub {

    template 'index';

};

get '/data_calendar' => sub {

    my $view_id = session 'view_id';
    my $from    = param 'from';
    my $to      = param 'to';

    header "Cache-Control" => "max-age=0";
    {
        "success" => 1,
        "result"  => GADS::Record->data_calendar($view_id, $from, $to),
    }
};

any '/data' => sub {

    if (my $view_id = param('view'))
    {
        session 'view_id' => $view_id;
    }

    if (my $rows = param('rows'))
    {
        session 'rows' => int $rows;
    }

    if (my $page = param('page'))
    {
        session 'page' => int $page;
    }

    if (my $viewtype = param('viewtype'))
    {
        if ($viewtype eq 'graph' || $viewtype eq 'table' || $viewtype eq 'calendar')
        {
            session 'viewtype' => $viewtype;
        }
    }

    my $view_id  = session 'view_id';

    my $columns;
    my $user = GADS::User->user({ id => session('user_id') });
    eval { $columns = GADS::View->columns({ view_id => $view_id, user => $user }) };
    if (hug)
    {
        session 'view_id' => undef;
        return forwardHome({ danger => bleep });
    }

    my $params; # Variable for the template

    if (session('viewtype') eq 'graph')
    {
        my $todraw = GADS::Graph->all({ user => var('user') });

        my @graphs;
        foreach my $g (@$todraw)
        {
            my $graph = GADS::Graph->data({ graph => $g, view_id => $view_id });
            push @graphs, $graph if $graph;
        }

        $params = {
            graphs      => \@graphs,
            all_columns => GADS::View->columns,
            viewtype    => 'graph',
        };

    }
    elsif (session('viewtype') eq 'calendar')
    {
        # Get details of the view and work out color markers for date fields
        my $columns = GADS::View->columns({ view_id => $view_id });
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
        }
    }
    else {
        session 'rows' => 50 unless session 'rows';
        session 'page' => 1 unless session 'page';

        # @records contains all the information for each required record
        my $get = {
            view_id => $view_id,
            rows    => session('rows'),
            page    => session('page'),
        };

        my @records = GADS::Record->current($get);
        my $pages = $get->{pages};
        # @output contains just the data itself, which can be sent straight to a CSV
        my $options = defined param('download') ? { download => 1 } : {};
        my @output = GADS::Record->data($view_id, \@records, $options);

        my @colnames = ('Serial');
        foreach my $column (@$columns)
        {
            push @colnames, $column->{name};
        }

        my $subset = {
            rows  => session('rows'),
            pages => $pages,
            page  => session('page'),
        };

        $params = {
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
                unless var('user')->{permissions}->{admin};

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
                send_file( \$csv, content_type => 'text/csv', filename => "$now.csv" );
            }
        }
    }

    $params->{v}        = GADS::View->view($view_id),  # View is reserved TT word
    $params->{page}     = 'data';
    template 'data' => $params;
};

any '/account/?:action?/?' => sub {

    my $action = param 'action';

    if (param 'newpassword')
    {
        # See if existing password is correct first
        GADS::User->user({
            username => var('user')->{username},
            password => param('oldpassword'),
        }) or forwardHome({ danger => 'The existing password entered is incorrect'}, 'account/detail');

        my $user_id = var('user')->{id};
        my $newpw   = GADS::User->resetpw(var('user')->{id});

        if ($newpw)
        {
            forwardHome({ success => qq(<h3 class="text-center"><small>Your password has been changed to:</small> $newpw</h3>)}, 'account/detail' );
        }
        else {
            forwardHome({ danger => "There was an error generating a new password"}, 'account/detail' );
        }
    }

    if (param 'graphsubmit')
    {
        eval { GADS::User->graphs(var('user'), param('graphs')) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            return forwardHome(
                { success => "The selected graphs have been updated" }, 'account/graph' );
        }
    }

    my $data;

    if ($action eq 'graph')
    {
        $data->{graphs} = GADS::Graph->all({ user => var('user'), all => 1 });
        template 'account' => {
            data   => $data,
            action => $action,
            page   => 'account',
        };
    }
    elsif ($action eq 'detail')
    {
        template 'user' => {
            edit          => var('user')->{id},
            users         => [var('user')],
            titles        => GADS::User->titles,
            organisations => GADS::User->organisations,
            page          => 'account/detail'
        };
    }
    else {
        return forwardHome({ danger => "Unrecognised action $action" });
    }
};

any '/graph/?:id?' => sub {

    my $id = param 'id';

    return forwardHome(
        { danger => 'You do not have permission to edit graphs' } )
        unless var('user')->{permissions}->{admin};

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

    my $user = GADS::User->user({ id => session('user_id') });

    my $view_id = param('id');

    if (param 'update')
    {
        my $values = params;

        # First update selected columns
        my $params = {
            view_id => $view_id, # ID returned here in case of new view
            user    => $user,
        };
        eval { GADS::View->columns($params, $values) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            # Set current view to the one created/edited
            session 'view_id' => $params->{view_id};
            # Then update any filters
            eval { GADS::View->filters($params->{view_id}, $values) };
            if (hug)
            {
                messageAdd({ danger => $@ });
            }
            else {
                return forwardHome(
                    { success => "The view has been updated successfully" }, 'data' );
            }
        }
    }

    if (param 'delete')
    {
        session 'view_id' => undef;
        eval { GADS::View->delete(param('id'), $user) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            return forwardHome(
                { success => "The view has been deleted successfully" }, 'data' );
        }
    }

    my @ucolumns;
    my $viewcols;
    eval { $viewcols = GADS::View->columns({ view_id => $view_id, user => $user }) };
    if (hug)
    {
        return forwardHome({ danger => bleep });
    }

    foreach my $c (@$viewcols)
    {
        push @ucolumns, $c->{id};
    }
    my $view = GADS::View->view($view_id);
    my $output  = template 'view' => {
        all_columns  => GADS::View->columns,
        filters      => GADS::View->filters($view_id),
        filter_types => GADS::View->filter_types,
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
            unless var('user')->{permissions}->{admin};

        my $tree = decode_json(param 'data');
        GADS::Layout->tree($layout_id, { tree => $tree} );
    }
    header "Cache-Control" => "max-age=0";

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
        unless var('user')->{permissions}->{admin};

    if (param 'delete')
    {
        eval { GADS::Layout->delete(param 'id') };
        if (hug)
        {
            messageAdd({ danger => $@ });
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

    if (param 'saveorder')
    {
        my $values = params;
        eval { GADS::Layout->order($values) };
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
    else {
        $items = GADS::Layout->all;
    }

    my $output = template 'layout' => {
        edit        => $id,
        items       => $items,
        page        => 'layout'
    };
    $output;
};

any '/user/?:id?' => sub {
    my $id = param 'id';

    return forwardHome(
        { danger => 'You do not have permission to manage users' } )
        unless var('user')->{permissions}->{admin}
            || var('user')->{id} == $id;

    # Check normal submit first. We do this now, as it could be a normal
    # user doing the submit, and we won't allow them much furthe. However,
    # we need to check that it's not an admin creating a new title or org,
    # as they should be handled differently. The submit button will still
    # be triggered on a new org/title creation, if the user has pressed enter
    if (param('submit') && !param('neworganisation') && !param('newtitle'))
    {
        my $values = params;
        delete $values->{id} if param 'account_request';

        eval { GADS::User->update($values, {url => request->base}) };
        if (hug)
        {
            if (param('page') eq 'user')
            {
                messageAdd({ danger => bleep });
            }
            else {
                # Forward to the sending page if not users page,
                # otherwise attempt will be made to send somebody
                # editing their own account details to the users
                # page on error
                my $page   = param('page');
                return forwardHome(
                    { danger => bleep }, $page );
            }
        }
        else {
            # Delete account request user if this is a new account request
            GADS::User->delete(param 'account_request')
                if param 'account_request';

            my $action = $id ? 'updated' : 'created';
            my $page   = param('page');
            return forwardHome(
                { success => "User has been $action successfully" }, $page );
        }
    }

    # This shouldn't happen for a normal user, but let's
    # play it safe
    return forwardHome(
        { danger => 'You do not have permission to manage users' } )
        unless var('user')->{permissions}->{admin};

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
    elsif (param 'delete')
    {
        return forwardHome(
            { danger => "Cannot delete current logged-in User" } )
            if var('user')->{id} eq param('delete');
        eval { GADS::User->delete(param 'delete') };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            return forwardHome(
                { success => "User has been deleted successfully" }, 'user' );
        }
    }

    if ($id)
    {
        $users = GADS::User->user({ id => $id });
    }
    elsif (!defined $id) {
        $users             = GADS::User->all;
        $register_requests = GADS::User->register_requests;
    }

    my $output = template 'user' => {
        edit              => $id,
        users             => $users,
        register_requests => $register_requests,
        titles            => GADS::User->titles,
        organisations     => GADS::User->organisations,
        page              => 'user'
    };
    $output;
};

any '/approval/?:id?' => sub {
    my $id = param 'id';

    return forwardHome(
        { danger => 'You do not have permission to approve records' } )
        unless var('user')->{permissions}->{approver};

    if (param 'submit')
    {
        # Do approval
        my $values  = params;
        my $uploads = request->uploads;
        eval { GADS::Record->approve($id, $values, $uploads) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            return forwardHome(
                { success => 'Record has been successfully approved', 'approval' } );
        }
    }

    my ($items, $page);
    if ($id)
    {
        $items = GADS::Record->approve($id);
        $page  = 'edit';
    }
    else {
        $items = GADS::Record->approve;
        $page  = 'approval';
    }

    my $autoserial = config->{gads}->{serial} eq "auto" ? 1 : 0;
    my $output = template $page => {
        form_value  => sub {item_value(@_, {raw => 1})},
        item_value  => sub {item_value(@_)},
        approves    => $items,
        autoserial  => $autoserial,
        people      => GADS::User->all,
        all_columns => GADS::View->columns,
        page        => 'approval',
    };
    $output;
};

any '/edit/:id?' => sub {
    my $id = param 'id';
    my $user = GADS::User->user({ id => session('user_id') });

    my $all_columns = GADS::View->columns;
    my $record;
    if (param 'submit')
    {
        my $params = params;
        my $uploads = request->uploads;
        eval { GADS::Record->update($params, $user, $uploads) };
        if (hug)
        {

            my $bleep = bleep; # Otherwise it's overwritten

            # Remember previous submitted values in event of error
            foreach my $fn (keys %$params)
            {
                next unless $fn =~ /^field(\d+)$/;
                $record->{$fn} = {value => $params->{$fn}};
            }

            # For files, we have to retrieve the previous filenames,
            # as we don't know what they were from the submit
            my %files = GADS::Record->files($id);
            foreach my $fn (keys %files)
            {
                $record->{$fn} = {value => $files{$fn}};
            }

            messageAdd( { danger => $bleep } );
        }
        else {
            return forwardHome(
                { success => 'Record has been successfully updated' }, 'data' );
        }
    }
    elsif($id) {
        $record = GADS::Record->current({ current_id => $id });
    }
    elsif(my $previous = $user->{lastrecord})
    {
        # Prefill previous values, but only those tagged to be remembered
        my $previousr = GADS::Record->current({ record_id => $previous });
        foreach my $column (@$all_columns)
        {
            if ($column->{remember})
            {
                my $v = item_value($column, $previousr, {raw => 1});
                my $field = $column->{field};
                $record->{$field} = {value => $v} if $column->{remember};
            }
        }
    }

    my $autoserial = config->{gads}->{serial} eq "auto" ? 1 : 0;
    my $output = template 'edit' => {
        form_value  => sub {item_value(@_, {raw => 1})},
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
    my $file = rset('Fileval')->find($id)
        or return forwardHome( { error => 'File ID $id cannot be found' } );
    send_file( \($file->content), content_type => $file->mimetype );
};

any '/record/:id' => sub {
    my $id = param 'id';
    my $record = $id ? GADS::Record->current({ record_id => $id }) : {};
    my $versions = $id ? GADS::Record->versions($record->current->id) : {};
    my $autoserial = config->{gads}->{serial} eq "auto" ? 1 : 0;
    my $output = template 'record' => {
        item_value  => sub {item_value(@_)},
        record      => $record,
        autoserial  => $autoserial,
        versions    => $versions,
        all_columns => GADS::View->columns,
        page        => 'record'
    };
    $output;
};

any '/login' => sub {
    if (defined param('logout'))
    {
        context->destroy_session;
    }

    # Don't allow login page to be displayed when logged-in, to prevent
    # user thinking they are logged out when they are not
    return forwardHome({}, '') if session 'user_id';

    # Request a password reset
    if (param('resetpwd'))
    {
        GADS::User->resetpwreq_email(param('emailreset'), request->base)
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
            return forwardHome({ success => "Your account request has been received successfully" });
        }
    }

    if (param('signin'))
    {
        my $user = GADS::User->user({
            username => param('email'),
            password => param('password'),
        });
        if ($user)
        {
            session 'user_id' => $user->{id};
            forwardHome();
        }
        else {
            messageAdd({ danger => "The username or password was not recognised" });
        }
    }

    my $output  = template 'login' => {
        error         => $error,
        register_text => GADS::User->register_text,
        page          => 'login',
    };
    $output;
};

get '/resetpw/:code' => sub {

    my $password;
    eval { $password = GADS::User->resetpwdo(param 'code') };
    if (hug)
    {
        return forwardHome(
            { danger => bleep }, 'login'
        );
    }
    else {
        context->destroy_session;
        my $output  = template 'login' => {
            password => $password,
            page     => 'login',
        };
        $output;
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
    push @$msgs, { text => $text, type => $type };
    session 'messages' => $msgs;
}

true;
