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

    redirect '/login' unless session('user_id');

    var 'user' => GADS::User->user({ id => session('user_id') });

    # Dynamically generate "virtual" columns for each row of data, based on the
    # configured layout

    my $layout_rs = rset('Layout');
    my @cols = $layout_rs->all;

    foreach my $col (@cols)
    {
        next if $col->type eq "rag"; # Not a real column
        my $coltype = $col->type eq "tree" ? 'enum' : $col->type;
        my $colname = "field".$col->id;
        schema->source('Record')->add_relationship(
            $colname => camelize($coltype),
            sub {
                my $args = shift;

                return {
                    "$args->{foreign_alias}.record_id" => { -ident => "$args->{self_alias}.id" },
                    "$args->{foreign_alias}.layout_id" => $col->id,
                };
            }
        );
        GADS::Schema::Result::Record->has_one(
            $colname => camelize($coltype),
            sub {
                my $args = shift;

                return {
                    "$args->{foreign_alias}.record_id" => { -ident => "$args->{self_alias}.id" },
                    "$args->{foreign_alias}.layout_id" => $col->id,
                };
            }
        );
    }
};

hook before_template => sub {
    my $tokens = shift;

    $tokens->{url}->{css}  = request->base . 'css';
    $tokens->{url}->{js}   = request->base . 'js';
    $tokens->{url}->{page} = request->base;
    $tokens->{url}->{page} =~ s!.*/!!; # Remove trailing slash

    $tokens->{header} = config->{gads}->{header};

    $tokens->{messages} = session('messages');
    $tokens->{user}     = var('user');
    session 'messages' => [];

};

get '/' => sub {

    my $todraw = GADS::Graph->all({ user => var('user') });

    my @graphs;
    foreach my $g (@$todraw)
    {
        my @records = GADS::Record->current({ view_id => $g->view_id });
        my $graph = GADS::Graph->data({ graph => $g, records => \@records });
        push @graphs, $graph if $graph;
    }

    my $output  = template 'index' => {
        graphs      => \@graphs,
        all_columns => GADS::View->columns,
        page        => 'index'
    };
    $output;
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

    my $view_id = session 'view_id';

    my $columns;
    my $user = GADS::User->user({ id => session('user_id') });
    eval { $columns = GADS::View->columns({ view_id => $view_id, user => $user }) };
    if (hug)
    {
        session 'view_id' => undef;
        return forwardHome({ danger => bleep });
    }

    # @records contains all the information for each required record
    my $get = {
        view_id => $view_id,
        rows    => session('rows'),
        page    => session('page'),
    };

    my @records = GADS::Record->current($get);
    my $pages = $get->{pages};
    # @output contains just the data itself, which can be sent straight to a CSV
    my @output = GADS::Record->data($view_id, @records);

    my @colnames = ('Serial');
    foreach my $column (@$columns)
    {
        push @colnames, $column->{name};
    }

    if (param 'sendemail')
    {
        # Collect all the actual record IDs, including RAG filters
        my @ids;
        foreach my $o (@output)
        {
            push @ids, $o->[0];
        }
        my @emails;
        my $field = param('peopcol'); # The people field to use
        foreach my $record (@records)
        {
            push @emails, $record->$field->value->email
                if grep {$_ == $record->id} @ids;
        }
        my $email = {
            subject => param('subject'),
            emails  => \@emails,
            text    => param('text'),
        };
        eval { GADS::Email->send($email) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            return forwardHome(
                { success => "The message has been sent successfully" } );
        }
    }

    if (defined param('download'))
    {
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
    else
    {
        my $subset = {
            rows  => session('rows'),
            pages => $pages,
            page  => session('page'),
        };

        my $output  = template 'data' => {
            subset      => $subset,,
            records     => \@output,
            columns     => $columns,
            rag         => sub { GADS::Record->rag(@_) },
            view_id     => $view_id,
            page        => 'data'
        };
        $output;
    }
};

any '/account/?:action?/?' => sub {

    my $action = param 'action';

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
    }
    else {
        return forwardHome({ danger => "Unrecognised action $action" });
    }

    my $output  = template 'account' => {
        data   => $data,
        action => $action,
        page   => 'account',
    };
    $output;
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

any '/tree/:id?/?:value?' => sub {

    my $layout_id = param 'id';

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
        param('id'),
        {
            value => param('value'),
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
        unless var('user')->{permissions}->{admin};

    if (param 'submit')
    {
        my $values = params;

        eval { GADS::User->update($values, {url => request->base}) };
        if (hug)
        {
            messageAdd({ danger => bleep });
        }
        else {
            my $action = param('id') ? 'updated' : 'created';
            return forwardHome(
                { success => "User has been $action successfully" }, 'user' );
        }
    }

    if (param 'delete')
    {
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


    my $users;
    if ($id)
    {
        $users = GADS::User->user({ id => $id });
    }
    else {
        $users = GADS::User->all;
    }

    my $output = template 'user' => {
        edit        => $id,
        users       => $users,
        page        => 'user'
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
        my $values = params;
        eval { GADS::Record->approve($id, $values) };
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

    my $record;
    if (param 'submit')
    {
        my $params = params;
        eval { GADS::Record->update($params, $user) };
        if (hug)
        {
            foreach my $fn (keys %$params)
            {
                next unless $fn =~ /^field(\d+)$/;
                $record->{$fn} = {value => $params->{$fn}};
            }
            messageAdd( { danger => bleep } );
        }
        else {
            return forwardHome(
                { success => 'Record has been successfully updated' }, 'data' );
        }
    }
    else {
        $record = $id ? GADS::Record->current({ current_id => $id }) : {};
    }

    use Data::Dumper;
    say STDERR Dumper $record;
    my $autoserial = config->{gads}->{serial} eq "auto" ? 1 : 0;
    my $output = template 'edit' => {
        record      => $record,
        autoserial  => $autoserial,
        people      => GADS::User->all,
        all_columns => GADS::View->columns,
        page        => 'edit'
    };
    $output;
};

any '/record/:id' => sub {
    my $id = param 'id';
    my $record = $id ? GADS::Record->current({ record_id => $id }) : {};
    my $versions = $id ? GADS::Record->versions($record->current->id) : {};
    my $autoserial = config->{gads}->{serial} eq "auto" ? 1 : 0;
    my $output = template 'record' => {
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

    # Request a password reset
    if (param('resetpwd'))
    {
        GADS::User->resetpwreq_email(param('emailreset'), request->base)
        ? messageAdd( { success => 'An email has been sent to your email address with a link to reset your password' } )
        : messageAdd( { danger => 'Failed to send a password reset link. Did you enter a valid email address?' } );
    }

    if (param('email'))
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
    }

    my $output  = template 'login' => {
        page     => 'login',
    };
    $output;
};

get '/resetpw/:code' => sub {

    my $pw;
    eval { $pw = GADS::User->resetpwdo(param 'code') };
    if (hug)
    {
        return forwardHome(
            { danger => bleep }, 'login'
        );
    }
    else {
        context->destroy_session;
        return forwardHome(
            { success => "Your password has been reset to '$pw'"}, 'login'
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
    my $text    = ( values %$message )[0];
    my $type    = ( keys %$message )[0];
    my $msgs    = session 'messages';
    push @$msgs, { text => $text, type => $type };
    session 'messages' => $msgs;
}

true;
