=pod
GADS - Globally Accessible Data Store
Copyright (C) 2015 Ctrl O Ltd

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

package GADS;

use Crypt::URandom; # Make Dancer session generation cryptographically secure
use DateTime;
use File::Temp qw/ tempfile /;
use GADS::Alert;
use GADS::Approval;
use GADS::Audit;
use GADS::Column;
use GADS::Column::Autocur;
use GADS::Column::Calc;
use GADS::Column::Curval;
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
use GADS::DBICProfiler;
use GADS::Email;
use GADS::Graph;
use GADS::Graph::Data;
use GADS::Graphs;
use GADS::Group;
use GADS::Groups;
use GADS::Import;
use GADS::Instances;
use GADS::Layout;
use GADS::MetricGroup;
use GADS::MetricGroups;
use GADS::Record;
use GADS::Records;
use GADS::RecordsGroup;
use GADS::Type::Permissions;
use GADS::Users;
use GADS::View;
use GADS::Views;
use GADS::Helper::BreadCrumbs qw(Crumb);
use HTML::Entities;
use JSON qw(decode_json encode_json);
use Math::Random::ISAAC::XS; # Make Dancer session generation cryptographically secure
use MIME::Base64;
use Session::Token;
use String::CamelCase qw(camelize);
use Text::CSV;
use Tie::Cache;
use WWW::Mechanize::PhantomJS;

use Dancer2; # Last to stop Moo generating conflicting namespace
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Auth::Extensible::Provider::DBIC 0.623;
use Dancer2::Plugin::LogReport 'linkspace';

schema->storage->debugobj(new GADS::DBICProfiler);
schema->storage->debug(1);

# There should never be exceptions from DBIC, so we want to panic them to
# ensure they get notified at the correct level. Unfortunately, DBIC's internal
# code uses exceptions, and if these are panic'ed then they are not caught
# properly. Use this dirty hack for the moment, but I am told these part of
# DBIC may change in the future.
schema->exception_action(sub {
    die $_[0] if $_[0] =~ /^Unable to satisfy requested constraint/; # Expected
    panic @_; # Not expected
});

tie %{schema->storage->dbh->{CachedKids}}, 'Tie::Cache', 100;
# Dynamically generate all relationships for columns. These may be added to as
# the program's layout changes, but they can never be removed (program restart
# required for that)
GADS::DB->setup(schema);

our $VERSION = '0.1';

# set serializer => 'JSON';
set behind_proxy => config->{behind_proxy}; # XXX Why doesn't this work in config file

GADS::Config->instance(
    config => config,
);

GADS::SchemaInstance->instance(
    schema => schema,
);

GADS::Email->instance(
    config => config,
);

hook before => sub {

    schema->site_id(undef);

    # See if there are multiple sites. If so, find site and configure in schema
    if (schema->resultset('Site')->next && request->dispatch_path !~ m{/invalidsite})
    {
        my ($site) = schema->resultset('Site')->search({
            host => request->base->host,
        })
            or redirect '/invalidsite';
        var 'site' => $site;
        my $site_id = $site->id;
        trace __x"Site ID is {id}", id => $site_id;
        schema->site_id($site_id);
    }
    else {
        my $site = schema->resultset('Site')->next;
        trace __x"Single site, site ID is {id}", id => $site->id;
        schema->site_id($site->id);
        var 'site' => $site;
    }

    # Add any new relationships for new fields. These are normally
    # added when the field is created, but with multiple processes
    # these will not have been created for the other processes.
    # This subroutine checks for missing ones and adds them.
    GADS::DB->update(schema);

    my $user = logged_in_user;

    # Log to audit
    my $method = request->method;
    my $path   = request->path;
    my $query  = request->query_string;
    my $audit  = GADS::Audit->new(schema => schema, user => $user);
    my $description = $user
        ? qq(User "$user->{username}" made "$method" request to "$path")
        : qq(Unauthenticated user made "$method" request to "$path");
    $description .= qq( with query "$query") if $query;
    $audit->user_action(description => $description, url => $path, method => $method)
        if $user;

    if (config->{gads}->{aup} && $user)
    {
        # Redirect if AUP not signed
        my $aup_accepted;
        if (my $aup_date = $user->{aup_accepted})
        {
            my $db_parser   = schema->storage->datetime_parser;
            my $aup_date_dt = $db_parser->parse_datetime($aup_date);
            $aup_accepted   = $aup_date_dt && DateTime->compare( $aup_date_dt, DateTime->now->subtract(months => 12) ) > 0;
        }
        redirect '/aup' unless $aup_accepted || request->uri =~ m!^/aup!;
    }

    if (logged_in_user && config->{gads}->{user_status} && !session('status_accepted'))
    {
        # Redirect to user status page if required and not seen this session
        redirect '/user_status' unless request->uri =~ m!^/(user_status|aup)!;
    }
    elsif (logged_in_user_password_expired)
    {
        # Redirect to user details page if password expired
        forwardHome({ danger => "Your password has expired. Please use the Change password button
            below to set a new password." }, 'account/detail')
                unless request->uri eq '/account/detail' || request->uri eq '/logout';
    }

    if ($user)
    {
        header "X-Frame-Options" => "DENY"; # Prevent clickjacking
        # Make sure we have suitable persistent hash to update. All these options are
        # used as hashrefs themselves, so prevent trying to access non-existent hash.
        if (!session 'persistent')
        {
            my $session_settings;
            try { $session_settings = decode_json $user->{session_settings} };
            session 'persistent' => ($session_settings || {});
        }
        my $persistent = session 'persistent';

        if (my $instance_id = param('instance'))
        {
            session 'search' => undef;
        }
        elsif (!$persistent->{instance_id})
        {
            $persistent->{instance_id} = config->{gads}->{default_instance};
        }
        # Instance ID can be overriden using the parameter "oi". This is
        # a bit hacky, but it allows (for example) the session instance to
        # be one sheet, but then a linked record to be viewed from another
        # sheet. This is used in the links for the Curval column type
        my $instance_id = param('oi') || param('instance') || $persistent->{instance_id};
        my $instances = GADS::Instances->new(schema => schema, user => $user);
        $instance_id = $instances->is_valid($instance_id) || $instances->all->[0] && $instances->all->[0]->instance_id;
        if (!$instance_id && request->uri !~ m!^/user!)
        {
            forwardHome({ danger => "You do not have any access rights to any data in this application" })
                unless request->uri eq '/';
        }
        var 'layout' => $instances->layout($instance_id)
            if $instance_id;
        $persistent->{instance_id} = $instance_id
            unless param 'oi';
        var 'instances' => $instances;
    }
};

hook before_template => sub {
    my $tokens = shift;

    my $user   = logged_in_user;

    my $base = $tokens->{base} || request->base;
    $tokens->{url}->{css}  = "${base}css";
    $tokens->{url}->{js}   = "${base}js";
    $tokens->{url}->{page} = $base;
    $tokens->{url}->{page} =~ s!.*/!!; # Remove trailing slash
    $tokens->{scheme}    ||= request->scheme; # May already be set for phantomjs requests
    $tokens->{hostlocal}   = config->{gads}->{hostlocal};

    $tokens->{header} = config->{gads}->{header};

    my $layout = var 'layout';
    # Possible for $layout to be undef if user has no access
    if ($user && $layout && ($layout->user_can('approve_new') || $layout->user_can('approve_existing')))
    {
        my $approval = GADS::Approval->new(
            schema => schema,
            user   => $user,
            layout => $layout
        );
        $tokens->{user_can_approve} = 1;
        $tokens->{approve_waiting} = $approval->count;
    }
    if (logged_in_user)
    {
        $tokens->{instances}     = var('instances')->all;
        $tokens->{instance_name} = var('layout')->name if var('layout');
        $tokens->{user}          = $user;
        $tokens->{search}        = session 'search';
        # Somehow this sets the instance_id session if no persistent session exists
        $tokens->{instance_id}   = session('persistent')->{instance_id}
            if session 'persistent';
        $tokens->{user_can_edit}   = $layout->user_can('write_existing');
        $tokens->{user_can_create} = $layout->user_can('write_new');
        $tokens->{layout}          = $layout;
        $tokens->{v}               = current_view(logged_in_user, $layout);  # View is reserved TT word
    }
    $tokens->{messages}      = session('messages');
    $tokens->{site}          = var 'site';
    $tokens->{config}        = GADS::Config->instance;
    session 'messages' => [];
};

hook after_template_render => sub {
    if (logged_in_user)
    {
        my $user = schema->resultset('User')->find(logged_in_user->{id});
        $user->update({
            session_settings => encode_json(session('persistent')),
        });
    }
};

get '/' => require_login sub {

    template 'index' => {
        layout      => var('layout'),
        page        => 'index',
        breadcrumbs => [Crumb()]
    };
};

get '/ping' => sub {
    content_type 'text/plain';
    'alive';
};

any '/aup' => require_login sub {

    if (param 'accepted')
    {
        update_current_user aup_accepted => DateTime->now;
        redirect '/';
    }

    template aup => {
        page => 'aup',
    };
};

get '/aup_text' => require_login sub {
    template 'aup_text', {}, { layout => undef };
};

# Shows last login time etc
any '/user_status' => require_login sub {

    if (param 'accepted')
    {
        session 'status_accepted' => 1;
        redirect '/';
    }

    template user_status => {
        lastlogin => logged_in_user_lastlogin,
        message   => config->{gads}->{user_status_message},
        page      => 'user_status',
    };
};

get '/data_calendar/:time' => require_login sub {

    # Time variable is used to prevent caching by browser

    my $fromdt  = DateTime->from_epoch( epoch => ( param('from') / 1000 ) );
    my $todt    = DateTime->from_epoch( epoch => ( param('to') / 1000 ) ); 

    # Attempt to find period requested. Sometimes the duration is
    # slightly less than expected, hence the multiple tests
    my $diff     = $todt->subtract_datetime($fromdt);
    my $dt_view  = ($diff->months >= 11 || $diff->years)
                 ? 'year'
                 : ($diff->weeks > 1 || $diff->months)
                 ? 'month'
                 : ($diff->days >= 6 || $diff->weeks)
                 ? 'week'
                 : 'day'; # Default to month

    # Attempt to remember day viewed. This is difficult, due to the
    # timezone issues described below. XXX How to fix?
    session 'calendar' => {
        day  => $todt->clone->subtract(days => 1),
        view => $dt_view,
    };

    # Epochs received from the calendar module are based on the timezone of the local
    # browser. So in BST, 24th August is requested as 23rd August 23:00. Rather than
    # trying to convert timezones, we keep things simple and round down any "from"
    # times and round up any "to" times.
    $fromdt->truncate( to => 'day'); 
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

    my $user    = logged_in_user;
    my $layout  = var 'layout';
    my $view    = current_view($user, $layout);

    my $records = GADS::Records->new(
        user                 => $user,
        layout               => $layout,
        schema               => schema,
        view                 => $view,
        from                 => $fromdt,
        to                   => $todt,
        search               => session('search'),
        interpolate_children => 0,
    );

    header "Cache-Control" => "max-age=0, must-revalidate, private";
    content_type 'application/json';
    my $data = $records->data_calendar;
    encode_json({
        "success" => 1,
        "result"  => $data,
    });
};

sub _data_graph
{   my $id = shift;
    my $user    = logged_in_user;
    my $layout  = var 'layout';
    my $view    = current_view($user, $layout);
    my $records = GADS::RecordsGroup->new(
        user   => $user,
        search => session('search'),
        layout => $layout,
        schema => schema,
    );
    GADS::Graph::Data->new(
        id      => $id,
        records => $records,
        schema  => schema,
        view    => $view,
    );
}

get '/data_graph/:id/:time' => require_login sub {

    my $id      = param 'id';
    my $gdata = _data_graph($id);

    header "Cache-Control" => "max-age=0, must-revalidate, private";
    content_type 'application/json';
    encode_json({
        points  => $gdata->points,
        labels  => $gdata->labels_encoded,
        xlabels => $gdata->xlabels,
        options => $gdata->options,
    });
};

any '/data' => require_login sub {

    my $user   = logged_in_user;
    my $layout = var 'layout';

    # Check for bulk delete
    if (param 'modal_delete')
    {
        my $records = GADS::Records->new(
            user   => $user,
            search => session('search'),
            layout => $layout,
            schema => schema,
            rewind => session('rewind'),
            view   => current_view($user, $layout),
        );
        my $count; # Count actual number deleted, not number reported by search result
        while (my $record = $records->single)
        {
            $count++
                if (process sub { $record->delete_current });
        }
        return forwardHome(
            { success => "$count records successfully deleted" }, 'data' );
    }

    # Check for rewind configuration
    if (param('modal_rewind') || param('modal_rewind_reset'))
    {
        if (param('modal_rewind_reset') || !param('rewind_date'))
        {
            session rewind => undef;
        }
        else {
            my $input = param('rewind_date');
            $input   .= ' ' . (param('rewind_time') ? param('rewind_time') : '23:59:59');
            my $dt    = GADS::DateTime::parse_datetime($input)
                or error __x"Invalid date or time: {datetime}", datetime => $input;
            session rewind => $dt;
        }
    }

    # Search submission or clearing a search?
    if (defined(param('search_text')) || defined(param('clear_search')))
    {
        error __"Not possible to conduct a search when viewing data on a previous date"
            if session('rewind');
        my $search  = param('clear_search') ? '' : param('search_text');
        $search =~ s/\h+$//;
        $search =~ s/^\h+//;
        session 'search' => $search;
        if ($search)
        {
            my $records = GADS::Records->new(
                search => $search,
                schema => schema,
                user   => $user,
                layout => $layout,
            );
            my $results = $records->current_ids;

            # Redirect to record if only one result
            redirect "/record/$results->[0]"
                if @$results == 1;
        }
    }

    # Deal with any alert requests
    if (param 'modal_alert')
    {
        my $alert = GADS::Alert->new(
            user      => $user,
            layout    => $layout,
            schema    => schema,
            frequency => param('frequency'),
            view_id   => param('view_id'),
        );
        if (process(sub { $alert->write }))
        {
            return forwardHome(
                { success => "The alert has been saved successfully" }, 'data' );
        }
    }

    if (my $view_id = param('view'))
    {
        session('persistent')->{view}->{$layout->instance_id} = $view_id;
        # Save to database for next login.
        # Check that it's valid first, otherwise database will bork
        my $view = current_view($user, $layout);
        # When a new view is selected, unset sort, otherwise it's
        # not possible to remove a sort once it's been clicked
        session 'sort' => undef;
        # Also reset page number to 1
        session 'page' => undef;
        # And remove any search to avoid confusion
        session search => '';
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
        if ($viewtype eq 'graph' || $viewtype eq 'table' || $viewtype eq 'calendar' || $viewtype eq 'timeline')
        {
            session('persistent')->{viewtype}->{$layout->instance_id} = $viewtype;
        }
    }
    else {
        $viewtype = session('persistent')->{viewtype}->{$layout->instance_id} || 'table';
    }

    my $view       = current_view($user, $layout);

    my $params = {
        page => 'data',
    }; # Variable for the template

    if ($viewtype eq 'graph')
    {
        $params->{viewtype} = 'graph';
        if (my $png = param('png'))
        {
            my $gdata = _data_graph($png);
            my $json  = encode_json {
                points  => $gdata->points,
                labels  => $gdata->labels_encoded,
                xlabels => $gdata->xlabels,
                options => $gdata->options,
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

            my $png= $mech->content_as_png();
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
    }
    elsif ($viewtype eq 'calendar')
    {
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
    }
    elsif ($viewtype eq 'timeline')
    {
        my $records = GADS::Records->new(
            user                 => $user,
            view                 => $view,
            search               => session('search'),
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
        my $tl_options = session('persistent')->{tl_options}->{$layout->instance_id} || {};
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
    else {
        session 'rows' => 50 unless session 'rows';
        session 'page' => 1 unless session 'page';

        my $rows = defined param('download') ? undef : session('rows');
        my $page = defined param('download') ? undef : session('page');

        my $records = GADS::Records->new(
            user   => $user,
            search => session('search'),
            layout => $layout,
            schema => schema,
            rewind => session('rewind'),
        );

        $records->view($view);
        $records->rows($rows);
        $records->page($page);
        $records->sort(session 'sort');

        # Default sort if not set
        my $sort = {
            id   => $layout->sort_layout_id,
            type => $layout->sort_type,
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
                unless $layout->user_can("message");

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
        $params->{user_can_edit}  = $layout->user_can('write_existing');
        $params->{sort}           = $records->sort_first;
        $params->{subset}         = $subset;
        $params->{records}        = $records->presentation(@columns);
        $params->{count}          = $records->count;
        $params->{columns}        = [ map $_->presentation, @columns ];
        $params->{has_rag_column} = grep { $_->type eq 'rag' } @columns;
        $params->{viewtype}       = 'table';

    }

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

    $params->{user_views}      = $views->user_views;
    $params->{alerts}          = $alert->all;

    $params->{breadcrumbs} = [Crumb() => Crumb( '/data' => 'records' )];

    template 'data' => $params;
};

any '/purge/?' => require_login sub {

    my $user        = logged_in_user;
    my $layout      = var 'layout';

    forwardHome({ danger => "You do not have permission to manage deleted records"}, '')
        unless $layout->user_can("purge");

    if (param('purge') || param('restore'))
    {
        my @current_ids = body_parameters->get_all('record_selected')
            or forwardHome({ danger => "Please select some records before clicking an action" }, 'purge');
        my $records = GADS::Records->new(
            current_ids => [@current_ids],
            columns     => [],
            user        => $user,
            is_deleted  => 1,
            layout      => $layout,
            schema      => schema,
        );
        if (param 'purge')
        {
            my $record;
            $record->purge_current while $record = $records->single;
            forwardHome({ success => "Records have now been purged" }, 'purge');
        }
        if (param 'restore')
        {
            my $record;
            $record->restore while $record = $records->single;
            forwardHome({ success => "Records have now been restored" }, 'purge');
        }
    }

    my $records = GADS::Records->new(
        columns    => [],
        user       => $user,
        is_deleted => 1,
        layout     => $layout,
        schema     => schema,
    );

    my $params = {
        records => $records->presentation,
    };

    template 'purge' => $params;
};

any '/account/?:action?/?' => require_login sub {

    my $action = param 'action';
    my $user   = rset('User')->find(logged_in_user->{id});
    my $audit  = GADS::Audit->new(schema => schema, user => $user);

    if (param 'newpassword')
    {
        my $new_password = _random_pw();
        if (user_password password => param('oldpassword'), new_password => $new_password)
        {
            $audit->login_change("New password set for user");
            forwardHome({ success => qq(Your password has been changed to: $new_password)}, 'account/detail', user_only => 1 ); # Don't log elsewhere
        }
        else {
            forwardHome({ danger => "The existing password entered is incorrect"}, 'account/detail' );
        }
    }

    if (param 'graphsubmit')
    {
        if (process( sub { $user->graphs(param('graphs')) }))
        {
            return forwardHome(
                { success => "The selected graphs have been updated" }, 'account/graph' );
        }
    }

    if (param 'submit')
    {
        my $params = params;
        # Update of user details
        my %update = (
            firstname    => param('firstname')    || undef,
            surname      => param('surname')      || undef,
            email        => param('email'),
            username     => param('email'),
            freetext1    => param('freetext1')    || undef,
            freetext2    => param('freetext2')    || undef,
            title        => param('title')        || undef,
            organisation => param('organisation') || undef,
        );

        if (process( sub { $user->update_user(current_user => logged_in_user, %update) }))
        {
            return forwardHome(
                { success => "The account details have been updated" }, 'account/detail' );
        }
    }

    my $data;

    if ($action eq 'graph')
    {
        my $graphs = GADS::Graphs->new(
            user   => $user,
            schema => schema,
            layout => var('layout')
        );
        my $all_graphs = $graphs->all;
        template 'account' => {
            graphs => $all_graphs,
            action => $action,
            page   => 'account/graph',
        };
    }
    elsif ($action eq 'detail')
    {
        my $users = GADS::Users->new(schema => schema);
        template 'user' => {
            edit          => $user->id,
            users         => [$user],
            titles        => $users->titles,
            organisations => $users->organisations,
            page          => 'account/detail'
        };
    }
    else {
        return forwardHome({ danger => "Unrecognised action $action" });
    }
};

any '/config/?' => require_login sub {

    my $user        = logged_in_user;
    my $layout      = var 'layout';

    forwardHome({ danger => "You do not have permission to manage general settings"}, '')
        unless $layout->user_can("layout");

    my $instance = rset('Instance')->find(var('layout')->instance_id);

    if (param 'update')
    {
        $instance->homepage_text(param 'homepage_text');
        $instance->homepage_text2(param 'homepage_text2');
        $instance->sort_layout_id(param('sort_layout_id') || undef);
        $instance->sort_type(param 'sort_type');

        if (process( sub { $instance->update }))
        {
            return forwardHome(
                { success => "Configuration settings have been updated successfully" } );
        }
    }

    my @all_columns = $layout->all;
    template 'config' => {
        all_columns => \@all_columns,
        instance    => $instance,
        page        => 'config'
    };
};


any '/graph/?' => require_login sub {

    my $user        = logged_in_user;
    my $layout      = var 'layout';

    forwardHome({ danger => "You do not have permission to manage graphs" }, '')
        unless $layout->user_can("layout");

    my $graphs = GADS::Graphs->new(schema => schema, layout => $layout)->all;

    my $params = {
        layout => $layout,
        page   => 'graph',
        graphs => $graphs,
    };

    template 'graphs' => $params;
};

any '/graph/:id' => require_login sub {

    my $user        = logged_in_user;
    my $layout      = var 'layout';

    forwardHome({ danger => "You do not have permission to manage graphs" }, '')
        unless $layout->user_can("layout");

    my $params = {
        layout => $layout,
        page   => defined param('id') && !param('id') ? 'graph/0' : 'graph',
    };

    my $id = param 'id';

    my $graph = GADS::Graph->new(
        id     => $id,
        layout => $layout,
        schema => schema,
    );

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
                y_axis_label y_axis_stack group_by stackseries metric_group_id/);
        if(process( sub { $graph->write }))
        {
            my $action = param('id') ? 'updated' : 'created';
            return forwardHome(
                { success => "Graph has been $action successfully" }, 'graph' );
        }
    }

    $params->{graph}         = $graph;
    $params->{dategroup}     = GADS::Graphs->dategroup;
    $params->{graphtypes}    = [GADS::Graphs->types];
    $params->{metric_groups} = GADS::MetricGroups->new(
        schema      => schema,
        instance_id => session('persistent')->{instance_id},
    )->all;

    template 'graph' => $params;
};

get '/metrics/?' => require_login sub {

    my $user        = logged_in_user;
    my $layout      = var 'layout';

    forwardHome({ danger => "You do not have permission to manage metrics" }, '')
        unless $layout->user_can("layout");

    my $metrics = GADS::MetricGroups->new(
        schema      => schema,
        instance_id => $layout->instance_id,
    )->all;

    my $params = {
        layout  => $layout,
        page    => 'metric',
        metrics => $metrics,
    };

    template 'metrics' => $params;
};

any '/metric/:id' => require_login sub {

    my $user        = logged_in_user;
    my $layout      = var 'layout';

    forwardHome({ danger => "You do not have permission to manage metrics" }, '')
        unless $layout->user_can("layout");

    my $params = {
        layout => $layout,
        page   => 'metric',
    };

    my $id = param 'id';

    my $metricgroup = GADS::MetricGroup->new(
        schema      => schema,
        id          => $id,
        instance_id => $layout->instance_id,
    );

    if (param 'delete_all')
    {
        if (process( sub { $metricgroup->delete }))
        {
            return forwardHome(
                { success => "The metric has been deleted successfully" }, 'metrics' );
        }
    }

    # Delete an individual item from a group
    if (param 'delete_metric')
    {
        if (process( sub { $metricgroup->delete_metric(param 'metric_id') }))
        {
            return forwardHome(
                { success => "The metric has been deleted successfully" }, "metric/$id" );
        }
    }

    if (param 'submit')
    {
        $metricgroup->name(param 'name');
        if(process( sub { $metricgroup->write }))
        {
            my $action = param('id') ? 'updated' : 'created';
            return forwardHome(
                { success => "Metric has been $action successfully" }, 'metrics' );
        }
    }

    # Update/create an individual item in a group
    if (param 'update_metric')
    {
        my $metric = GADS::Metric->new(
            id                    => param('metric_id') || undef,
            metric_group_id       => $id,
            x_axis_value          => param('x_axis_value'),
            y_axis_grouping_value => param('y_axis_grouping_value'),
            target                => param('target'),
            schema                => schema,
        );
        if(process( sub { $metric->write }))
        {
            my $action = param('id') ? 'updated' : 'created';
            return forwardHome(
                { success => "Metric has been $action successfully" }, "metric/$id" );
        }
    }

    $params->{metricgroup} = $metricgroup;

    template 'metric' => $params;
};

any '/group/?:id?' => require_role useradmin => sub {

    my $id = param 'id';
    my $group  = GADS::Group->new(schema => schema);
    my $layout = var 'layout';
    $group->from_id($id);

    my @permissions = GADS::Type::Permissions->all;

    if (param 'submit')
    {
        $group->name(param 'name');
        foreach my $perm (@permissions)
        {
            my $name = "default_".$perm->short;
            $group->$name(param($name) ? 1 : 0);
        }
        if (process(sub {$group->write}))
        {
            my $action = param('id') ? 'updated' : 'created';
            return forwardHome(
                { success => "Group has been $action successfully" }, 'group' );
        }
    }

    if (param 'delete')
    {
        if (process(sub {$group->delete}))
        {
            return forwardHome(
                { success => "The group has been deleted successfully" }, 'group' );
        }
    }

    my $params = {
        page => 'group'
    };

    if (defined $id)
    {
        # id will be 0 for new group
        $params->{group} = $group;
        $params->{permissions} = [@permissions];
    }
    else {
        my $groups = GADS::Groups->new(schema => schema);
        $params->{groups} = $groups->all;
        $params->{layout} = $layout;
    }
    template 'group' => $params;
};

get '/table/?' => require_role superadmin => sub {

    template 'tables' => {
        page      => 'table',
        instances => [rset('Instance')->all],
    };
};

any '/table/:id' => require_role superadmin => sub {

    my $id          = param 'id';
    my $user        = logged_in_user;
    my $layout_edit = $id && var('instances')->layout($id);

    $id && !$layout_edit
        and error __x"Instance ID {id} not found", id => $id;

    if (param('submit') || param('delete'))
    {
        if (param 'submit')
        {
            if (!$layout_edit)
            {
                $layout_edit = GADS::Layout->new(
                    user   => $user,
                    schema => schema,
                    config => config,
                );
            }
            $layout_edit->name(param 'name');
            $layout_edit->set_groups([body_parameters->get_all('permissions')]);

            if (process(sub {$layout_edit->write}))
            {
                # Switch user to new table
                my $msg = param('id') ? 'The table has been updated successfully' : 'Your new table has been created successfully';
                return forwardHome(
                    { success => $msg }, 'table' );
            }
        }

        if (param 'delete')
        {
            if (process(sub {$layout_edit->delete}))
            {
                return forwardHome(
                    { success => "The table has been deleted successfully" }, 'table' );
            }
        }
    }

    template 'table' => {
        page        => $id ? 'table' : 'table/0',
        layout_edit => $layout_edit,
        groups      => GADS::Groups->new(schema => schema)->all,
    }
};

any '/view/:id' => require_login sub {

    my $user   = logged_in_user;
    my $layout = var 'layout';

    return forwardHome(
        { danger => 'You do not have permission to edit views' }, 'data' )
        unless $layout->user_can("view_create");

    my $view_id = param('id');
    $view_id = param('clone') if param('clone') && !request->is_post;
    my @ucolumns; my $view_values;

    my %vp = (
        user        => $user,
        schema      => schema,
        layout      => $layout,
        instance_id => $layout->instance_id,
    );
    $vp{id} = $view_id if $view_id;
    my $view = GADS::View->new(%vp);

    if (param 'update')
    {
        my $params = params;
        my $columns = ref param('column') ? param('column') : [ param('column') // () ]; # Ensure array
        $view->columns($columns);
        $view->global(param('global') ? 1 : 0);
        $view->is_admin(param('is_admin') ? 1 : 0);
        $view->name  (param 'name');
        $view->filter->as_json(param 'filter');
        if (process( sub { $view->write }))
        {
            $view->set_sorts($params->{sortfield}, $params->{sorttype});
            # Set current view to the one created/edited
            session('persistent')->{view}->{$layout->instance_id} = $view->id;
            # And remove any search to avoid confusion
            session search => '';
            # And remove any custom sorting, so that sort of view takes effect
            session 'sort' => undef;
            return forwardHome(
                { success => "The view has been updated successfully" }, 'data' );
        }
    }

    if (param 'delete')
    {
        session('persistent')->{view}->{$layout->instance_id} = undef;
        if (process( sub { $view->delete }))
        {
            return forwardHome(
                { success => "The view has been deleted successfully" }, 'data' );
        }
    }

    my $page = param('clone')
        ? 'view/clone'
        : defined param('id') && !param('id')
        ? 'view/0' : 'view';

    my $output = template 'view' => {
        layout       => $layout,
        sort_types   => $view->sort_types,
        view_edit    => $view, # TT does not like variable "view"
        clone        => param('clone'),
        page         => $page,
    };
    $output;
};

any qr{/tree[0-9]*/([0-9]*)/?([0-9]*)} => require_login sub {
    # Random number can be used after "tree" to prevent caching

    my ($layout_id, $value) = splat;
    my $layout      = var 'layout';

    my $tree = var('layout')->column($layout_id)
        or error __x"Invalid tree ID {id}", id => $layout_id;

    if (param 'data')
    {
        return forwardHome(
            { danger => 'You do not have permission to edit trees' } )
            unless $layout->user_can("layout");

        my $newtree = JSON->new->utf8(0)->decode(param 'data');
        $tree->update($newtree);
        return;
    }
    my $json = $tree->type eq 'tree' ? $tree->json($value) : [];

    # If record is specified, select the record's value in the returned JSON
    header "Cache-Control" => "max-age=0, must-revalidate, private";
    content_type 'application/json';
    encode_json($json);

};

any '/layout/?:id?' => require_login sub {

    my $user        = logged_in_user;
    my $layout      = var 'layout';

    forwardHome({ danger => "You do not have permission to manage fields"}, '')
        unless $layout->user_can("layout");

    my @all_columns = $layout->all;

    my $params = {
        page        => defined param('id') && !param('id') ? 'layout/0' : 'layout',
        all_columns => \@all_columns,
    };

    if (defined param('id'))
    {
        # Get all layouts of all instances for field linking
        $params->{instance_layouts} = [grep { $_->instance_id != $layout->instance_id } @{var('instances')->all}];
        $params->{instances_object} = var('instances'); # For autocur. Don't conflict with other instances var
    }

    if (param('id') || param('submit') || param('update_perms'))
    {

        my $column;
        if (my $id = param('id'))
        {
            $column = $layout->column($id)
                or error __x"Column ID {id} not found", id => $id;
        }
        else {
            my $class = param('type');
            grep {$class eq $_} GADS::Column::types
                or error __x"Invalid column type {class}", class => $class;
            $class = "GADS::Column::".camelize($class);
            $column = $class->new(
                schema => schema,
                user   => $user,
                layout => $layout
            );
        }

        if (param 'delete')
        {
            # Provide plenty of logging in case of repercussions of deletion
            my $colname = $column->name;
            trace __x"Starting deletion of column {name}", name => $colname;
            my $audit  = GADS::Audit->new(schema => schema, user => $user);
            my $description = qq(User "$user->{username}" deleted field "$colname");
            $audit->user_action(description => $description);
            if (process( sub { $column->delete }))
            {
                return forwardHome(
                    { success => "The item has been deleted successfully" }, 'layout' );
            }
        }

        if (param 'submit')
        {

            my @permission_params = grep { /^permission_(?:.*?)_\d+$/ } keys %{ params() };

            if (@permission_params) {
                my %permissions;

                foreach (@permission_params) {
                    my ($name, $group_id) = m/^permission_(.*?)_(\d+)$/;
                    push @{ $permissions{$group_id} ||= [] }, $name;
                }
                
                $column->set_permissions(\%permissions);
            }

            $column->$_(param $_)
                foreach (qw/name name_short description helptext optional isunique multivalue remember link_parent_id/);
            $column->type(param 'type')
                unless param('id'); # Can't change type as it would require DBIC resultsets to be removed and re-added
            $column->$_(param $_)
                foreach @{$column->option_names};
            if (param 'display_condition')
            {
                $column->display_field(param 'display_field');
                $column->display_regex(param 'display_regex');
            }
            else {
                $column->display_field(undef);
            }

            my $no_alerts;
            if ($column->type eq "file")
            {
                $column->filesize(param('filesize') || undef) if $column->type eq "file";
            }
            elsif ($column->type eq "rag")
            {
                $column->code(param 'code_rag');
                $column->base_url(request->base); # For alerts
                $no_alerts = param('no_alerts_rag');
            }
            elsif ($column->type eq "enum")
            {
                my $params = params;
                $column->enumvals($params);
                $column->ordering(param('ordering') || undef);
            }
            elsif ($column->type eq "calc")
            {
                $column->code(param 'code_calc');
                $column->return_type(param 'return_type');
                $column->base_url(request->base); # For alerts
                $no_alerts = param('no_alerts_calc');
            }
            elsif ($column->type eq "tree")
            {
                $column->end_node_only(param 'end_node_only');
            }
            elsif ($column->type eq "string")
            {
                $column->textbox(param 'textbox');
                $column->force_regex(param 'force_regex');
            }
            elsif ($column->type eq "curval")
            {
                $column->typeahead(param 'typeahead');
                $column->refers_to_instance_id(param 'refers_to_instance_id');
                $column->filter->as_json(param 'filter');
                my $curval_field_ids = ref param('curval_field_ids') ? param('curval_field_ids') : [param('curval_field_ids')||()];
                $column->curval_field_ids($curval_field_ids);
            }
            elsif ($column->type eq "autocur")
            {
                my @curval_field_ids = body_parameters->get_all('curval_field_ids');
                $column->curval_field_ids([@curval_field_ids]);
                $column->related_field_id(param 'related_field_id');
            }

            if (process( sub { $column->write(no_alerts => $no_alerts, no_cache_update => param('no_cache_update')) }))
            {
                my $msg = param('id')
                    ? qq(Your field has been updated successfully. You can <a href="/layout/0">create another one</a> or return to the <a href="/layout">main data layout page</a>.)
                    : qq(Your field has been created. Next you need to <a href="" data-toggle="modal" data-target="#modal_permissions">set permissions for this field</a>);

                report NOTICE => $msg, _class => 'html,success';
                return forwardHome( undef, "layout/".$column->id );
            }
        }
        $params->{column} = $column;
        $params->{groups} = GADS::Groups->new(schema => schema);
        $params->{permissions} = [GADS::Type::Permissions->all];
    }
    elsif (defined param('id'))
    {
        $params->{column} = 0; # New
        $params->{groups} = GADS::Groups->new(schema => schema);
        $params->{permissions} = [GADS::Type::Permissions->all];
    }

    if (param 'saveposition')
    {
        my @position = body_parameters->get_all('position');
        if (process( sub { $layout->position(@position) }))
        {
            return forwardHome(
                { success => "The ordering has been saved successfully" }, 'layout' );
        }
    }

    template 'layout' => $params;
};

any '/user/upload' => require_any_role [qw/useradmin superadmin/] => sub {

    my $userso = GADS::Users->new(schema => schema);

    if (param 'submit')
    {
        my $count;
        if (process sub {
            $count = rset('User')->upload(upload('file') || undef, # if no file then upload() returns empty array
                request_base => request->base,
                view_limits  => [body_parameters->get_all('view_limits')],
                groups       => [body_parameters->get_all('groups')],
                permissions  => [body_parameters->get_all('permission')],
            )}
        )
        {
            return forwardHome(
                { success => "$count users were successfully uploaded" }, 'user' );
        }
    }

    # Get all layouts of all instances for view restrictions
    # (XXX code to be removed for menu branch)
    my $user = logged_in_user;
    my $instances = GADS::Instances->new(schema => schema, user => $user);
    my @layouts;
    foreach my $instance (@{$instances->all})
    {
        push @layouts, GADS::Layout->new(
            user        => $user,
            schema      => schema,
            config      => config,
            instance_id => $instance->id,
            instance    => $instance,
        );
    }

    template 'user/upload' => {
        groups      => GADS::Groups->new(schema => schema)->all,
        layouts     => [@layouts],
        permissions => $userso->permissions,
        user_fields => $userso->user_fields,
    };
};

any '/user/?:id?' => require_any_role [qw/useradmin superadmin/] => sub {

    my $id = body_parameters->get('id');

    my $user            = logged_in_user;
    my $userso          = GADS::Users->new(schema => schema);
    my %all_permissions = map { $_->id => $_->name } @{$userso->permissions};
    my $audit           = GADS::Audit->new(schema => schema, user => $user);
    my $logged_in_user  = rset('User')->find($user->{id}), # XXX Remove once $user is object
    my $users;

    if (param 'sendemail')
    {
        my @emails = param('email_organisation')
                   ? (map { $_->email } @{$userso->all_in_org(param 'email_organisation')})
                   : (map { $_->email } @{$userso->all});
        my $email  = GADS::Email->instance;
        my $args   = {
            subject => param('email_subject'),
            text    => param('email_text'),
            emails  => \@emails,
        };

        if (process( sub { $email->message($args, logged_in_user) }))
        {
            return forwardHome(
                { success => "The message has been sent successfully" }, 'user' );
        }
    }

    # The submit button will still be triggered on a new org/title creation,
    # if the user has pressed enter, in which case ignore it
    if (param('submit') && !param('neworganisation') && !param('newtitle'))
    {
        my %values = (
            firstname             => param('firstname'),
            surname               => param('surname'),
            email                 => param('email'),
            username              => param('email'),
            freetext1             => param('freetext1'),
            freetext2             => param('freetext2'),
            title                 => param('title') || undef,
            organisation          => param('organisation') || undef,
            account_request       => param('account_request'),
            account_request_notes => param('account_request_notes'),
            view_limits           => [body_parameters->get_all('view_limits')],
            groups                => [body_parameters->get_all('groups')],
            permissions           => [body_parameters->get_all('permission')],
        );

        if (!param('account_request') && $id) # Original username to update (hidden field)
        {
            if (process sub {
                my $user = rset('User')->active->search({ id => $id })->next;
                # Don't use DBIC update directly, so that permissions etc are updated properly
                $user->update_user(current_user => $logged_in_user, %values);
            })
            {
                return forwardHome(
                    { success => "User has been updated successfully" }, 'user' );
            }
        }
        else {
            # This sends a welcome email etc
            if (process(sub { rset('User')->create_user(current_user => $logged_in_user, request_base => request->base, %values) }))
            {
                return forwardHome(
                    { success => "User has been created successfully" }, 'user' );
            }
        }

        # In case of failure, pass back to form
        my $view_limits_with_blank = [ map {
            +{
                view_id => $_
            }
        } body_parameters->get_all('view_limits') ];
        $values{view_limits_with_blank} = $view_limits_with_blank;
        $users = [\%values];
    }

    my $register_requests;
    if (param('neworganisation') || param('newtitle'))
    {
        if (my $org = param 'neworganisation')
        {
            if (process( sub { $userso->organisation_new({ name => $org })}))
            {
                $audit->login_change("Organisation $org created");
                success __"The organisation has been created successfully";
            }
        }

        if (my $title = param 'newtitle')
        {
            if (process( sub { $userso->title_new({ name => $title }) }))
            {
                $audit->login_change("Title $title created");
                success __"The title has been created successfully";
            }
        }

        # Remember values of user creation in progress.
        # XXX This is a mess (repeated code from above). Need to get
        # DPAE to use a user object
        my @groups      = ref param('groups') ? @{param('groups')} : (param('groups') || ());
        my %groups      = map { $_ => 1 } @groups;
        my $view_limits_with_blank = [ map {
            +{
                view_id => $_
            }
        } body_parameters->get_all('view_limits') ];

        $users = [{
            firstname              => param('firstname'),
            surname                => param('surname'),
            email                  => param('email'),
            freetext1              => param('freetext1'),
            freetext2              => param('freetext2'),
            title                  => { id => param('title') },
            organisation           => { id => param('organisation') },
            view_limits_with_blank => $view_limits_with_blank,
            groups                 => \%groups,
        }];
    }
    elsif (my $delete_id = param('delete'))
    {
        return forwardHome(
            { danger => "Cannot delete current logged-in User" } )
            if logged_in_user->{id} eq $delete_id;
        my $usero = rset('User')->find($delete_id);
        if (process( sub { $usero->retire(send_reject_email => 1) }))
        {
            $audit->login_change("User ID $delete_id deleted");
            return forwardHome(
                { success => "User has been deleted successfully" }, 'user' );
        }
    }

    if (defined param 'download')
    {
        my $csv = $userso->csv;
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

    my $route_id = route_parameters->get('id');

    if ($route_id)
    {
        $users = [ rset('User')->find($route_id) ] if !$users;
    }
    elsif (!defined $route_id) {
        $users             = $userso->all;
        $register_requests = $userso->register_requests;
    }
    else {
        # Horrible hack to get a limit view drop-down to display
        $users = [
            +{
                view_limits_with_blank => [ undef ],
            }
        ] if !$users; # Only if not already submitted
    }

    my $output = template 'user' => {
        edit              => $route_id,
        logged_in_user    => $logged_in_user,
        users             => $users,
        groups            => GADS::Groups->new(schema => schema)->all,
        register_requests => $register_requests,
        titles            => $userso->titles,
        organisations     => $userso->organisations,
        permissions       => $userso->permissions,
        page              => 'user'
    };
    $output;
};

any '/approval/?:id?' => require_login sub {
    my $id   = param 'id';
    my $user = logged_in_user;

    my $layout = var 'layout';

    # If we're viewing or approving an individual record, first
    # see if it's a new record or edit of existing. This affects
    # permissions
    my $approval_of_new = $id
        ? GADS::Record->new(
            user               => $user,
            layout             => $layout,
            schema             => schema,
            include_approval   => 1,
            record_id          => $id,
        )->approval_of_new
        : 0;

    my @columns_to_show = $approval_of_new ? $layout->all(user_can_approve_new => 1)
        : $layout->all(user_can_approve_existing => 1);

    if (param 'submit')
    {
        # Get latest record for this approval
        my $record = GADS::Record->new(
            user             => $user,
            layout           => $layout,
            schema           => schema,
            approval_id      => $id,
            doing_approval   => 1,
            base_url         => request->base,
        );
        # See if the record exists as a "normal" entry. In the case
        # of an approval for a new record, this will not be the case,
        # so catch the resulting exception, and create a new record,
        # but set the current ID.
        unless (try { $record->find_current_id(param 'current_id') })
        {
            $record->current_id(param 'current_id');
            $record->initialise;
        }
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
        foreach my $col (@columns_to_show)
        {
            my $newv = param($col->field);
            if ($col->userinput && defined $newv) # Not calculated fields
            {
                # No need to do anything if the file's just been uploaded
                unless (upload "file".$col->id)
                {
                    $failed = !process( sub { $record->fields->{$col->id}->set_value($newv) } ) || $failed;
                }
            }
            elsif ($col->type eq 'file')
            {
                # Not defined file field. Must have been removed.
                $failed = !process( sub { $record->fields->{$col->id}->set_value(undef) } ) || $failed;
            }
        }
        if (!$failed && process( sub { $record->write }))
        {
            return forwardHome(
                { success => 'Record has been successfully approved' }, 'approval' );
        }
    }

    my $page;
    my $params = {
        all_columns => \@columns_to_show,
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
        unless ($approval_of_new)
        {
            my $existing = GADS::Record->new(
                user            => $user,
                layout          => $layout,
                schema          => schema,
            );
            $existing->find_current_id($record->current_id);
            $params->{existing} = $existing;
        }
        $page  = 'edit';
    }
    else {
        $page  = 'approval';
        my $approval = GADS::Approval->new(
            schema => schema,
            user   => $user,
            layout => $layout
        );
        $params->{records} = $approval->records;
    }

    template $page => $params;
};

get '/helptext/:id?' => require_login sub {
    my $id     = param 'id';
    my $user   = logged_in_user;
    my $layout = var 'layout';
    my $column = $layout->column($id);
    template 'helptext.tt', { column => $column }, { layout => undef };
};

any '/link/:id?' => require_login sub {
    my $id = param 'id';

    my $layout = var 'layout';
    my $record = GADS::Record->new(
        user     => logged_in_user,
        layout   => $layout,
        schema   => schema,
        base_url => request->base,
    );

    if ($id)
    {
        $record->find_current_id($id);
    }

    if (param 'submit')
    {
        my $result;
        if ($id)
        {
            $result = process( sub { $record->write_linked_id(param 'linked_id') });
        }
        else {
            $record->initialise;
            $result = process( sub { $record->write })
                && process( sub { $record->write_linked_id(param 'linked_id' ) });
        }
        if ($result)
        {
            return forwardHome(
                { success => 'Record has been linked successfully' }, 'data' );
        }
    }

    template 'link' => {
        record      => $record,
        page        => 'link',
    };
};

post '/edits' => require_login sub {
    my $user   = logged_in_user;
    my $layout = var 'layout';

    my $records = eval { from_json param('q') };
    if ($@) {
        status 'bad_request';
        return 'Request body must contain JSON';
    }

    my $failed;
    while ( my($id, $values) = each %$records ) {
        my $record = GADS::Record->new(
            user     => $user,
            layout   => $layout,
            schema   => schema,
            base_url => request->base,
        );

        $record->find_current_id($values->{current_id});
        $layout = $record->layout; # May have changed if record from other datasheet
        if ($layout->column($values->{column})->type eq 'date')
        {
            my $to_write = $values->{from};
            unless (process sub { $record->fields->{ $values->{column} }->set_value($to_write) })
            {
                $failed = 1;
                next;
            }
        }
        else {
            # daterange
            my $to_write = {
                from    => $values->{from},
                to      => $values->{to},
            };
            # The end date as reported by the timeline will be a day later than
            # expected (it will be midnight the following day instead.
            # Therefore subtract one day from it
            unless (process sub { $record->fields->{ $values->{column} }->set_value($to_write, subtract_days_end => 1) })
            {
                $failed = 1;
                next;
            }
        }

        process sub { $record->write }
            or $failed = 1;
    }

    if ($failed) {
        redirect '/data'; # Errors already written to display
    }
    else {
        return forwardHome(
            { success => 'Submission has been completed successfully' }, 'data' );
    }
};

any '/bulk/:type/?' => require_login sub {

    my $user   = logged_in_user;
    my $layout = var 'layout';
    my $view   = current_view($user, $layout);
    my $type   = param 'type';

    forwardHome({ danger => "You do not have permission to perform bulk operations"}, 'data')
        unless $layout->user_can("bulk_update");

    $type eq 'update' || $type eq 'clone'
        or error __x"Invalid bulk type: {type}", type => $type;

    # The dummy record to test for updates
    my $record = GADS::Record->new(
        user     => $user,
        layout   => $layout,
        schema   => schema,
        base_url => request->base,
    );
    $record->initialise;

    # Files not supported at this time
    my @columns_to_show = grep { $type eq 'clone' || $_->type ne 'file' } $layout->all(user_can_write_new => 1);

    # The records to update
    my $records = GADS::Records->new(
        view                 => $view,
        search               => session('search'),
        retrieve_all_columns => 1, # Need all columns to be able to write updated records
        schema               => schema,
        user                 => $user,
        layout               => $layout,
    );

    if (param 'submit')
    {
        $record->editor_shown_fields([body_parameters->get_all('shown_fields')]);

        # See which ones to update
        my $failed_initial; my @updated;
        foreach my $col (@columns_to_show)
        {
            next unless body_parameters->get('bulk_inc_'.$col->id); # Is it ticked to be included?
            my $newv = [body_parameters->get_all($col->field)];
            my $datum = $record->fields->{$col->id};
            my $success = process( sub { $datum->set_value($newv, bulk => 1) } );
            push @updated, $col
                if $success;
            $failed_initial = $failed_initial || !$success;
        }
        if (!$failed_initial)
        {
            my ($success, $failures);
            while (my $record_update = $records->single)
            {
                $record_update->remove_id
                    if $type eq 'clone';
                my $failed;
                foreach my $col (@updated)
                {
                    my $newv = [body_parameters->get_all($col->field)];
                    last if $failed = !process( sub { $record_update->fields->{$col->id}->set_value($newv, bulk => 1) } );
                }
                if (!$failed)
                {
                    # Use force_mandatory to skip "was previously blank" warnings. No
                    # records will actually be made blank, as we wouldn't write otherwise
                    if (process( sub { $record_update->write(force_mandatory => 1) } )) { $success++ } else { $failures++ };
                }
                else {
                    $failures++;
                }
            }
            if (!$success && !$failures)
            {
                notice __"No updates have been made";
            }
            elsif ($success && !$failures)
            {
                my $msg = __xn"{_count} record was {type}d successfully", "{_count} records were {type}d successfully",
                    $success, type => $type;
                return forwardHome(
                    { success => $msg->toString }, 'data' );
            }
            else # Failures, back round the buoy
            {
                my $s = __xn"{_count} record was {type}d successfully", "{_count} records were {type}d successfully",
                    ($success || 0), type => $type;
                my $f = __xn", {_count} record failed to be {type}d", ", {_count} records failed to be {type}d",
                    ($failures || 0), type => $type;
                mistake $s.$f;
            }
        }
    }

    my $view_name = $view ? $view->name : 'All data';

    # Get number of records in view for sanity check for user
    my $count = $records->count;
    my $count_msg = __xn", which contains 1 record.", ", which contains {_count} records.", $count;
    if ($type eq 'update')
    {
        my $notice = session('search')
            ? __x(qq(Use this page to update all records in the
                current search results. Tick the fields whose values should be
                updated. Fields that are not ticked will retain their existing value.
                The current search is "{search}"), search => session('search'))
            : __x(qq(Use this page to update all records in the
                currently selected view. Tick the fields whose values should be
                updated. Fields that are not ticked will retain their existing value.
                The current view is "{view}"), view => $view_name);
        notice $notice.$count_msg;
    }
    else {
        my $notice = session('search')
            ? __x(qq(Use this page to bulk clone all of the records in
                the current search results. The cloned records will be created using
                the same existing values by default, but replaced with the values below
                where that value is ticked. Values that are not ticked will be cloned
                with their current value. The current search is "{search}"), search => session('search'))
            : __x(qq(Use this page to bulk clone all of the records in
                the currently selected view. The cloned records will be created using
                the same existing values by default, but replaced with the values below
                where that value is ticked. Values that are not ticked will be cloned
                with their current value. The current view is "{view}"), view => $view_name);
        notice $notice.$count_msg;
    }

    template 'edit' => {
        view        => $view,
        record      => $record,
        all_columns => \@columns_to_show,
        bulk_type   => $type,
        page        => 'bulk'
    };
};

any '/edit/:id?' => require_login sub {
    my $id = param 'id';

    my $user   = logged_in_user;
    my $layout = var 'layout';
    my $record = GADS::Record->new(
        user     => $user,
        layout   => $layout,
        schema   => schema,
        base_url => request->base,
    );

    if (my $delete_id = param 'delete')
    {
        $record->find_current_id($delete_id);
        if (process( sub { $record->delete_current }))
        {
            return forwardHome(
                { success => 'Record has been deleted successfully' }, 'data' );
        }
    }

    my $child = param 'child';

    # XXX Move into user class once properly available
    my ($lastrecord) = rset('UserLastrecord')->search({
        instance_id => $layout->instance_id,
        user_id     => $user->{id},
    })->all;

    if ($id)
    {
        $record->find_current_id($id);
        $layout = $record->layout; # May have changed if record from other datasheet
    }

    my @columns_to_show = $id || $child # show all cols for new child, to allow inc/exc of field
        ? $layout->all(user_can_readwrite_existing => 1)
        : $layout->all(user_can_write_new => 1);

    $record->initialise unless $id;

    if (param 'submit')
    {
        $record->editor_previous_fields([body_parameters->get_all('previous_fields')]);
        $record->editor_next_fields([body_parameters->get_all('next_fields')]);
        $record->editor_shown_fields([body_parameters->get_all('shown_fields')]);
        my $params = params;
        my $uploads = request->uploads;
        foreach my $key (keys %$uploads)
        {
            next unless $key =~ /^file([0-9]+)/;
            my $upload = $uploads->{$key};
            my $col_id = $1;
            my $filecol = $layout->column($col_id);
            $record->fields->{$col_id}->set_value({
                name     => $upload->filename,
                mimetype => $upload->type,
                content  => $upload->content,
            });
        }
        my $failed;

        error __"You do not have permission to create a child record"
            if $child && !$id && !$layout->user_can('create_child');
        $record->parent_id($child);

        my %child_inc = map { $_ => 1 } (ref(param 'child_inc') ? @{param 'child_inc'} : (param('child_inc') || ()));

        # We actually only need the write columns for this. The read-only
        # columns can be ignored, but if we do write them, an error will be
        # thrown to the user if they've been changed. This is better than
        # just silently ignoring them, IMHO.
        my @display_on_fields;
        foreach my $col (@columns_to_show)
        {
            next unless defined body_parameters->get($col->field);
            my $newv = [body_parameters->get_all($col->field)];
            if ($col->userinput && defined $newv) # Not calculated fields
            {
                # No need to do anything if the file's just been uploaded
                unless (upload "file".$col->id)
                {
                    my $datum = $record->fields->{$col->id};
                    if ($child)
                    {
                        if ($child_inc{$col->id} && !$datum->child_unique
                            || !$child_inc{$col->id} && $datum->child_unique
                        ) {
                            error __"You do not have permission to change the fields of the child record"
                                unless $layout->user_can('create_child');
                        }
                        $datum->child_unique($child_inc{$col->id});
                    }
                    $failed = !process( sub { $record->fields->{$col->id}->set_value($newv) } ) || $failed;
                }
            }
            elsif ($col->type eq 'file' && !upload("file".$col->id))
            {
                # Not defined file field and not just uploaded. Must have been removed.
                $failed = !process( sub { $record->fields->{$col->id}->set_value(undef) } ) || $failed;
            }
        }

        # Call this now, to write and blank out any non-displayed values,
        # before testing has_not_done
        $record->set_blank_dependents;

        if (param('submit') eq 'back')
        {
            $record->move_back;
        }
        elsif ($record->has_not_done)
        {
            if (!$failed && process( sub { $record->write(dry_run => 1) } ))
            {
                # Everything submitted is okay, continue to next stage
                $record->move_forward;
            }
            else {
                # Something wasn't correct, keep field display same as submitted
                $record->move_nowhere;
            }
        }
        elsif (!$failed && process( sub { $record->write }))
        {
            return forwardHome(
                { success => 'Submission has been completed successfully for record ID '.$record->current_id }, 'data' );
        }
        else {
            # Something wasn't correct, keep field display same as submitted
            $record->move_nowhere;
        }
    }
    elsif($id) {
        # Do nothing, record already loaded
    }
    elsif (my $from = param('from'))
    {
        $record->find_current_id($from);
        $record->remove_id;
    }
    elsif($lastrecord)
    {
        my $previous = GADS::Record->new(
            user   => $record->user,
            layout => $record->layout,
            schema => $record->schema,
        );
        # Prefill previous values, but only those tagged to be remembered
        if (my @remember = map {$_->id} $layout->all(remember => 1))
        {
            $previous->columns(\@remember);
            $previous->include_approval(1);
            $previous->init_no_value(0);
            $previous->find_record_id($lastrecord->record_id);
            $record->fields->{$_->id} = $previous->fields->{$_->id}
                foreach @{$previous->columns_retrieved_do};
        }
        if ($record->approval_flag)
        {
            # The last edited record was one for approval. This will
            # be missing values, so get its associated main record,
            # and use the values for that too.
            # There will only be an associated main record if some
            # values did not need approval
            if ($record->approval_record_id)
            {
                my $child = GADS::Record->new(
                    user             => $user,
                    layout           => $layout,
                    schema           => schema,
                    include_approval => 1,
                    base_url         => request->base,
                );
                $child->find_record_id($record->approval_record_id);
                foreach my $col (@columns_to_show)
                {
                    next unless $col->userinput;
                    # See if the record above had a value. If not, fill with the
                    # approval record's value
                    $record->fields->{$col->id} = $child->fields->{$col->id}
                        if !$record->fields->{$col->id}->has_value && $col->remember;
                }
            }
        }
        $record->remove_id;
    }
    else {
        $record->initialise;
    }

    foreach my $col ($layout->all(user_can_write => 1))
    {
        $record->fields->{$col->id}->set_value("")
            if !$col->user_can('read');
    }

    my $child_rec = $child && $layout->user_can('create_child')
        ? int(param 'child')
        : $record->parent_id
        ? $record->parent_id
        : undef;

    notice __"Please tick the fields that will have their own values for this child record "
        ."(at least one must be ticked). Any fields that are not ticked will inherit their "
        ."value from the parent. Values of the parent record are shown, which will be used "
        ."unless the box is ticked and a different value entered."
            if $child_rec;

    my $output = template 'edit' => {
        record      => $record,
        child       => $child_rec,
        clone       => param('from'),
        all_columns => \@columns_to_show,
        page        => 'edit'
    };
    $output;
};

get '/file/?' => require_login sub {

    my $user        = logged_in_user;
    my $layout      = var 'layout';

    forwardHome({ danger => "You do not have permission to manage files"}, '')
        unless $layout->user_can("layout");

    my @files = rset('Fileval')->search({
        'files.id' => undef,
    },{
        join     => 'files',
        order_by => 'me.id',
    })->all;

    template 'files' => {
        files => [@files],
    };
};

get '/file/:id' => require_login sub {
    my $id = param 'id';
    my $layout = var 'layout';

    # Need to get file details first, to be able to populate
    # column details of applicable.
    my $fileval = $id =~ /^[0-9]+$/ && schema->resultset('Fileval')->find($id)
        or error __x"File ID {id} cannot be found", id => $id;
    my ($file_rs) = $fileval->files; # In theory can be more than one, but not in practice (yet)
    my $file = GADS::Datum::File->new(id => $id);
    # Get appropriate column, if applicable (could be unattached document)
    # This will control access to the file
    if ($file_rs && $file_rs->layout_id)
    {
        if ($layout->instance_id == $file_rs->layout->instance_id)
        {
            $file->column($layout->column($file_rs->layout_id));
        }
        else {
            # XXX At some point the generation of different layouts each
            # request needs to go, replaced with a persistent object with all
            # layouts
            my $layout = GADS::Layout->new(
                user        => logged_in_user,
                schema      => schema,
                config      => GADS::Config->instance,
                instance_id => $file_rs->layout->instance_id,
            );
            $file->column($layout->column($file_rs->layout_id));
        }
    }
    else {
        $file->schema(schema);
    }
    send_file( \($file->content), content_type => $file->mimetype, filename => $file->name );
};

post '/file/?' => require_login sub {

    my $ajax = defined param('ajax');

    if (my $upload = upload('file'))
    {
        my $file;
        if (process( sub { $file = rset('Fileval')->create({
            name     => $upload->filename,
            mimetype => $upload->type,
            content  => $upload->content,
        }) } ))
        {
            if ($ajax)
            {
                return encode_json({
                    url   => "/file/".$file->id,
                    is_ok => 1,
                });
            }
            else {
                my $msg = __x"File has been uploaded as ID {id}", id => $file->id;
                return forwardHome( { success => "$msg" }, 'file' );
            }
        }
        elsif ($ajax) {
            return encode_json({
                is_ok => 0,
                error => $@,
            });
        }
    }
    elsif ($ajax) {
        return encode_json({
            is_ok => 0,
            error => "No file was submitted",
        });
    }
    else {
        error __"No file submitted";
    }

};

get '/record_body/:id' => require_login sub {

    my $id = param('id');

    my $user   = logged_in_user;
    my $layout = var 'layout';
    my $record = GADS::Record->new(
        user   => $user,
        layout => $layout,
        schema => schema,
        rewind => session('rewind'),
    );

    $record->find_current_id($id);
    my @columns = $layout->all(user_can_read => 1);
    template 'record_body' => {
        record         => $record,
        all_columns    => \@columns,
    }, { layout => undef };
};

any qr{/(record|history|purge|purgehistory)/([0-9]+)} => require_login sub {

    my ($action, $id) = splat;

    my $user   = logged_in_user;
    my $layout = var 'layout';

    forwardHome({ danger => "You do not have permission to manage deleted records"}, '')
        if $action =~ /purge/ && !$layout->user_can("purge");

    my $record = GADS::Record->new(
        user   => $user,
        layout => $layout,
        schema => schema,
        rewind => session('rewind'),
    );

      $action eq 'history'
    ? $record->find_record_id($id)
    : $action eq 'purge'
    ? $record->find_deleted_currentid($id)
    : $action eq 'purgehistory'
    ? $record->find_deleted_recordid($id)
    : $record->find_current_id($id);
    $layout = $record->layout; # May have changed if record from other datasheet

    my @versions    = $record->versions;
    my @columns     = $layout->all(user_can_read => 1);
    my %first_crumb = $action eq 'purge' ? ( '/purge' => 'deleted records' ) : ( '/data' => 'records' );
    my $output = template 'record' => {
        record         => $record,
        versions       => \@versions,
        all_columns    => \@columns,
        page           => 'record',
        breadcrumbs    => [Crumb() => Crumb(%first_crumb) => Crumb( request->path, => 'record id ' . $id )]
    };
    $output;
};

any '/audit/?' => require_role audit => sub {

    my $audit = GADS::Audit->new(schema => schema);
    my $users = GADS::Users->new(schema => schema, config => config);

    if (param 'audit_filtering')
    {
        session 'audit_filtering' => {
            method => param('method'),
            type   => param('type'),
            user   => param('user'),
            from   => param('from'),
            to     => param('to'),
        }
    }

    $audit->filtering(session 'audit_filtering')
        if session 'audit_filtering';

    if (defined param 'download')
    {
        my $csv = $audit->csv;
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

    template 'audit' => {
        logs        => $audit->logs(session 'audit_filtering'),
        users       => $users,
        filtering   => $audit->filtering,
        audit_types => GADS::Audit::audit_types,
        page        => 'audit',
    };
};

any '/import/?' => require_any_role [qw/layout useradmin/] => sub {

    if (param 'clear')
    {
        rset('Import')->search({
            completed => { '!=' => undef },
        })->delete;
    }

    template 'import' => {
        imports => [rset('Import')->search({},{ order_by => { -desc => 'me.completed' } })->all],
        page    => 'import',
    };
};

any '/import/rows/:import_id' => require_any_role [qw/layout useradmin/] => sub {

    rset('Import')->find(param 'import_id')
        or error __"Requested import not found";

    my $rows = rset('ImportRow')->search({
        import_id => param('import_id'),
    },{
        order_by => {
            -asc => 'me.id',
        }
    });

    template 'import/rows' => {
        import_id => param('import_id'),
        rows      => $rows,
        page      => 'import',
    };
};

any '/import/data/?' => require_login sub {

    my $user        = logged_in_user;
    my $layout      = var 'layout';

    forwardHome({ danger => "You do not have permission to import data"}, '')
        unless $layout->user_can("layout");

    if (param 'submit')
    {
        if (my $upload = upload('file'))
        {
            my %options = map { $_ => 1 } body_parameters->get_all('import_options');
            $options{no_change_unless_blank} = 'skip_new' if $options{no_change_unless_blank};
            $options{update_unique} = param('update_unique') if param('update_unique');
            $options{skip_existing_unique} = param('skip_existing_unique') if param('skip_existing_unique');
            my $import = GADS::Import->new(
                file     => $upload->tempname,
                schema   => schema,
                layout   => var('layout'),
                user_id  => logged_in_user->{id},
                %options,
            );

            if (process sub { $import->process })
            {
		return forwardHome(
		    { success => "The file import process has been started and can be monitored using the Import Status below" }, 'import' );
            }
        }
        else {
            report({is_fatal => 0}, ERROR => 'Please select a file to upload');
        }
    }

    template 'import/data' => {
        layout => var('layout'),
        page   => 'import',
    };
};

sub reset_text {
    my ($dsl, %options) = @_;
    my $name = config->{gads}->{name};
    my $url  = request->base . "resetpw/$options{code}";
    my $body = <<__BODY;
A request to reset your $name password has been received. Please
click on the following link to set and retrieve a new password:

$url
__BODY
    (
        from    => config->{gads}->{email_from},
        subject => 'Password reset request',
        plain   => $body,
    )
}

sub welcome_text
{   my ($dsl, %options) = @_;
    my $name = config->{gads}->{name};
    my $url  = request->base . "resetpw/$options{code}";
    my $new_account = config->{gads}->{new_account};
    my $subject = $new_account && $new_account->{subject}
        || "Your new account details";
    my $body = $new_account && $new_account->{body} || <<__BODY;

An account for $name has been created for you. Please
click on the following link to retrieve your password:

[URL]
__BODY

    $body =~ s/\Q[URL]/$url/;
    (
        from    => config->{gads}->{email_from},
        subject => $subject,
        plain   => $body,
    );
}

get '/login/denied' => sub {
    forwardHome({ danger => "You do not have permission to access this page" });
};

any '/login' => sub {

    my $audit = GADS::Audit->new(schema => schema);
    my $user  = logged_in_user;

    # Don't allow login page to be displayed when logged-in, to prevent
    # user thinking they are logged out when they are not
    return forwardHome() if $user;

    # Request a password reset
    if (param('resetpwd'))
    {
        my $username = param('emailreset');
        $audit->login_change("Password reset request for $username");
        defined password_reset_send(username => $username)
        ? success(__('An email has been sent to your email address with a link to reset your password'))
        : report({is_fatal => 0}, ERROR => 'Failed to send a password reset link. Did you enter a valid email address?');
    }

    my $error;
    my $users = GADS::Users->new(schema => schema, config => config);

    if (param 'register')
    {
        my $params = params;
        # Check whether this user already has an account
        if ($users->user_exists($params->{email}))
        {
            my $reset_code = Session::Token->new( length => 32 )->get;
            my $user       = schema->resultset('User')->active->search({ username => $params->{email} })->next;
            $user->update({ resetpw => $reset_code });
            my %welcome_text = welcome_text(undef, code => $reset_code);
            my $email        = GADS::Email->instance;
            my $args = {
                subject => $welcome_text{subject},
                text    => $welcome_text{plain},
                emails  => [$params->{email}],
            };

            if (process( sub { $email->send($args) }))
            {
                # Show same message as normal request
                return forwardHome(
                    { success => "Your account request has been received successfully" }, 'data' );
            }
            $audit->login_change("Account request for $params->{email}. Account already existed, resending welcome email.");
            return forwardHome({ success => "Your account request has been received successfully" });
        }
        else {
            try { $users->register($params) };
            if(my $exception = $@->wasFatal)
            {
                $error = $exception->message->toString;
            }
            else {
                $audit->login_change("New user account request for $params->{email}");
                return forwardHome({ success => "Your account request has been received successfully" });
            }
        }
    }

    if (param('signin'))
    {
        my $username  = param('username');
        my $lastfail  = DateTime->now->subtract(minutes => 15);
        my $lastfailf = schema->storage->datetime_parser->format_datetime($lastfail);
        my $fail      = $users->user_rs->search({
            username  => $username,
            failcount => { '>=' => 5 },
            lastfail  => { '>' => $lastfailf },
        })->count;
        $fail and assert "Reached fail limit for user $username";
        my ($success, $realm) = !$fail && authenticate_user(
            $username, params->{password}
        );
        if ($success) {
            # change session ID if we have a new enough D2 version with support
            app->change_session_id
                if app->can('change_session_id');
            session logged_in_user => $username;
            session logged_in_user_realm => $realm;
            if (param 'remember_me')
            {
                my $secure = request->scheme eq 'https' ? 1 : 0;
                cookie 'remember_me' => param('username'), expires => '60d',
                    secure => $secure, http_only => 1 if param('remember_me');
            }
            else {
                cookie remember_me => '', expires => '-1d' if cookie 'remember_me';
            }
            $user = logged_in_user;
            $audit->user($user);
            $audit->login_success;
            rset('User')->find($user->{id})->update({
                failcount => 0,
                lastfail  => undef,
            });
            forwardHome();
        }
        else {
            $audit->login_failure($username);
            my ($user) = $users->user_rs->search({
                username        => $username,
                account_request => 0,
            })->all;
            if ($user)
            {
                $user->update({
                    failcount => $user->failcount + 1,
                    lastfail  => DateTime->now,
                });
                trace "Fail count for $username is now ".$user->failcount;
            }
            report {is_fatal=>0}, ERROR => "The username or password was not recognised";
        }
    }

    my $output  = template 'login' => {
        error         => "".($error||""),
        username      => cookie('remember_me'),
        titles        => $users->titles,
        organisations => $users->organisations,
        register_text => var('site')->register_text,
        page          => 'login',
    };
    $output;
};

any '/logout' => sub {
    app->destroy_session;
    forwardHome();
};

any '/resetpw/:code' => sub {

    # Strange things happen if running this code when already logged in.
    # Log the existing user out first
    app->destroy_session if logged_in_user;

    # Perform check first in order to get user ID for audit
    if (my $username = user_password code => param('code'))
    {
        my $new_password;

        if (param 'execute_reset')
        {
            context->destroy_session;
            my $user   = rset('User')->active(username => $username)->next;
            # Now we know this user is genuine, reset any failure that would
            # otherwise prevent them logging in
            $user->update({ failcount => 0 });
            my $audit  = GADS::Audit->new(schema => schema, user => $user);
            $audit->login_change("Password reset performed for user ID ".$user->id);
            $new_password = _random_pw();
            user_password code => param('code'), new_password => $new_password;
        }
        my $output  = template 'login' => {
            reset_code => 1,
            password   => $new_password,
            page       => 'login',
        };
        return $output;
    }
    else {
        return forwardHome(
            { danger => qq(The password reset code is not valid. Please request a new one
                using the "Reset Password" link) }, 'login'
        );
    }
};

get '/invalidsite' => sub {
    template 'invalidsite' => {
        page => 'invalidsite'
    };
};

get '/match/layout/:layout_id' => require_login sub {
    my $query = param('q');
    my $layout_id = param('layout_id');

    my $column = var('layout')->column($layout_id, permission => 'read');

    content_type 'application/json';
    to_json [ $column->values_beginning_with($query) ];
};

sub current_view {
    my ($user, $layout) = @_;

    my $views      = GADS::Views->new(
        user        => $user,
        schema      => schema,
        layout      => $layout,
        instance_id => session('persistent')->{instance_id},
    );
    my $view;
    # If an invalid view is stuck in the session, then this can result in the
    # user in a continuous loop unable to open any other views
    try { $view = $views->view(session('persistent')->{view}->{$layout->instance_id}) };
    $@->reportAll(is_fatal => 0); # XXX results in double reporting
    return $view || $views->default; # Can still be undef
};

sub forwardHome {
    my ($message, $page, %options) = @_;

    if ($message)
    {
        my ($type) = keys %$message;
        my $lroptions = {};
        # Check for option to only display to user (e.g. passwords)
        $lroptions->{to} = 'error_handler' if $options{user_only};

        if ($type eq 'danger')
        {
            $lroptions->{is_fatal} = 0;
            report $lroptions, ERROR => $message->{$type};
        }
        elsif ($type eq 'notice') {
            report $lroptions, NOTICE => $message->{$type};
        }
        else {
            report $lroptions, NOTICE => $message->{$type}, _class => 'success';
        }
    }
    $page ||= '';
    redirect "/$page";
}

# Implementation of String::Random with better entropy
sub _token_template {
   my (%m) = @_;

   %m = map { $_ => Session::Token->new(alphabet => $m{$_}, length => 1) } keys %m;

   return sub {
     my $v = shift;
     $v =~ s/(.)/$m{$1}->get/eg;
     return $v;
   };
}

sub _random_pw
{   my $foo = _token_template(
        v => [ 'a', 'e', 'i', 'o', 'u' ],
        i => [ 'b'..'d', 'f'..'h', 'j'..'n', 'p'..'t', 'v'..'z' ],
    );

    $foo->("iviiviivi");
}

sub _page_as_mech
{   my ($template, $params) = @_;
    $params->{scheme}       = 'http';
    my $public              = path(setting('appdir'), 'public');
    $params->{base}         = "file://$public/";
    $params->{page_as_mech} = 1;
    my $timeline_html       = template $template, $params;
    my ($fh, $filename)     = tempfile(SUFFIX => '.html');
    print $fh $timeline_html;
    close $fh;
    my $mech = WWW::Mechanize::PhantomJS->new;
    $mech->get_local($filename);
    unlink $filename;
    return $mech;
}

true;
