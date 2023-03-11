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

use CtrlO::Crypt::XkcdPassword;
use Crypt::URandom; # Make Dancer session generation cryptographically secure
use Data::Dumper;
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
use GADS::Column::Filval;
use GADS::Column::Intgr;
use GADS::Column::Person;
use GADS::Column::Rag;
use GADS::Column::String;
use GADS::Column::Tree;
use GADS::Config;
use GADS::DB;
use GADS::DBICProfiler;
use GADS::Email;
use GADS::Filecheck;
use GADS::Globe;
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
use GADS::RecordsGraph;
use GADS::SAML;
use GADS::Type::Permissions;
use GADS::Users;
use GADS::Util;
use GADS::View;
use GADS::Views;
use GADS::Helper::BreadCrumbs qw(Crumb);
use HTML::Entities;
use HTML::FromText qw(text2html);
use JSON qw(decode_json encode_json);
use Math::Random::ISAAC::XS; # Make Dancer session generation cryptographically secure
use MIME::Base64;
use Session::Token;
use String::CamelCase qw(camelize);
use Text::CSV;
use Text::Wrap qw(wrap $huge);
$huge = 'overflow';
use Tie::Cache;
use URI;
use URI::Escape qw/uri_escape_utf8 uri_unescape/;

use Log::Log4perl qw(:easy); # Just for WWW::Mechanize::Chrome
use WWW::Mechanize::Chrome;

use Dancer2; # Last to stop Moo generating conflicting namespace
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Auth::Extensible::Provider::DBIC 0.623;
use Dancer2::Plugin::LogReport 'linkspace';

use GADS::API; # API routes

# Uncomment for DBIC traces
#schema->storage->debugobj(new GADS::DBICProfiler);
#schema->storage->debug(1);

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
    config       => config,
    app_location => app->location,
);

GADS::SchemaInstance->instance(
    schema => schema,
);

# Ensure efficient use of Magic library
my $filecheck = GADS::Filecheck->instance;

config->{plugins}->{'Auth::Extensible'}->{realms}->{dbic}->{user_as_object}
    or panic "Auth::Extensible DBIC provider needs to be configured with user_as_object";

# Make sure that internal columns have been populated in tables (new feature at
# time of writing)
{
    local $GADS::Schema::IGNORE_PERMISSIONS = 1;
    my $instances = GADS::Instances->new(schema => schema, user => undef);
    $_->create_internal_columns foreach @{$instances->all};
}

my $password_generator = CtrlO::Crypt::XkcdPassword->new;

sub _update_csrf_token
{   session csrf_token => Session::Token->new(length => 32)->get;
}

hook before => sub {

    schema->site_id(undef);

    # See if there are multiple sites. If so, find site and configure in schema
    if (schema->resultset('Site')->count > 1 && request->dispatch_path !~ m{/invalidsite})
    {
        my $site = schema->resultset('Site')->search({
            host => request->base->host,
        })->next
            or redirect '/invalidsite';
        var 'site' => $site;
        my $site_id = $site->id;
        trace __x"Site ID is {id}", id => $site_id;
        schema->site_id($site_id);
    }
    else {
        my $site = schema->resultset('Site')->next;
        # Stop random host names being used to access the site. The reason for
        # this is that the host name is inserted directly into emails (amongst
        # other things), so a check here prevents emails being generated with
        # hostnames that are attack websites. A nicer fix (to allow different
        # host names) would be to use the host from the database.
        if (request->base->host ne $site->host)
        {
            trace __x"Unknown host: {host}. Redirecting to configured host: {site}",
                host => request->base->host, site => $site->host;
            my $uri = request->base;
            $uri->host($site->host);
            redirect $uri;
        }
        trace __x"Single site, site ID is {id}", id => $site->id;
        schema->site_id($site->id);
        var 'site' => $site;
    }

    # Add any new relationships for new fields. These are normally
    # added when the field is created, but with multiple processes
    # these will not have been created for the other processes.
    # This subroutine checks for missing ones and adds them.
    GADS::DB->update(schema);

    my $user = request->uri =~ m!^/api/! && var('api_user') # Some API calls will be AJAX from standard logged-in user
        ? var('api_user')
        : logged_in_user;

    if (request->is_post && request->path !~ m!^(/api/token|/print|/saml)$!)
    {
        # Protect against CSRF attacks. NB: csrf_token can be in query params
        # or body params (different keys).
        my $token = query_parameters->get('csrf-token') || body_parameters->get('csrf_token');
        panic __x"csrf-token missing for uri {uri}, params {params}", uri => request->uri, params => Dumper({params})
            if !$token;
        error __x"The CSRF token is invalid or has expired. Please try reloading the page and making the request again."
            if $token ne session('csrf_token');

        # If it's a potential login, change the token
        _update_csrf_token()
            if request->path eq '/login';
    }

    if ($user)
    {
        my $instances = GADS::Instances->new(schema => schema, user => $user);
        var 'instances' => $instances;

        if (my $layout_name = route_parameters->get('layout_name'))
        {
            if (my $layout = var('instances')->layout_by_shortname($layout_name, no_errors => 1))
            {
                var 'layout' => $layout;
            }
        }
    }

    # Log to audit, unless a record view in which case we do not have the
    # instance_id until the request is processed (log these later)
    _audit_log()
        unless request->path =~ m!^/(record|record_body)/!;

    # The following use logged_in_user so as not to apply for API requests
    if (logged_in_user)
    {
        if (config->{gads}->{aup})
        {
            # Redirect if AUP not signed
            my $aup_accepted;
            if (my $aup_date = $user->aup_accepted)
            {
                my $db_parser   = schema->storage->datetime_parser;
                my $aup_date_dt = $db_parser->parse_datetime($aup_date);
                $aup_accepted   = $aup_date_dt && DateTime->compare( $aup_date_dt, DateTime->now->subtract(months => 12) ) > 0;
            }
            redirect '/aup' unless $aup_accepted || request->uri =~ m!^/aup!;
        }

        if (config->{gads}->{user_status} && !session('status_accepted'))
        {
            # Redirect to user status page if required and not seen this session
            redirect '/user_status' unless request->uri =~ m!^/(user_status|aup)!;
        }
        elsif (logged_in_user_password_expired && !session('is_sso'))
        {
            # Redirect to user details page if password expired
            forwardHome({ danger => "Your password has expired. Please use the Change password button
                below to set a new password." }, 'myaccount')
                    unless request->uri eq '/myaccount' || request->uri eq '/logout';
        }

        response_header "X-Frame-Options" => "DENY" # Prevent clickjacking
            unless request->uri eq '/aup_text' # Except AUP, which will be in an iframe
                || request->path eq '/file'; # Or iframe posts for file uploads (hidden iframe used for IE8)

        # CSP
        response_header "Content-Security-Policy" => "script-src 'self';";

        # Make sure we have suitable persistent hash to update. All these options are
        # used as hashrefs themselves, so prevent trying to access non-existent hash.
        my $persistent = session 'persistent';

        if (my $instance_id = param('instance'))
        {
            session 'search' => undef;
        }
        elsif (!$persistent->{instance_id})
        {
            $persistent->{instance_id} = var('instances')->all->[0]->instance_id
                if @{var('instances')->all};
        }

        if (var 'layout') {
            $persistent->{instance_id} = var('layout')->instance_id;
        }

        notice __"You do not have permission to access any part of this application. Please contact your system administrator."
            if !@{var('instances')->all};

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
        # var 'instances' not set for 404
        my $instances = var('instances') || GADS::Instances->new(schema => schema, user => $user);
        $tokens->{instances}     = $instances->all;
        $tokens->{instance_name} = var('layout')->name if var('layout');
        $tokens->{user}          = $user;
        $tokens->{search}        = session 'search';
        # Somehow this sets the instance_id session if no persistent session exists
        $tokens->{instance_id}   = session('persistent')->{instance_id}
            if session 'persistent';
        $tokens->{user_can_edit}   = $layout && $layout->user_can('write_existing');
        $tokens->{user_can_create} = $layout && $layout->user_can('write_new');
        $tokens->{show_link}       = rset('Current')->next ? 1 : 0;
        $tokens->{layout}          = $layout;
        $tokens->{v}               = current_view(logged_in_user, $layout);  # View is reserved TT word
    }
    $tokens->{messages}      = session('messages');
    $tokens->{site}          = var 'site';
    $tokens->{config}        = GADS::Config->instance;

    # This line used to be pre-request. However, occasionally errors have been
    # experienced with pages not submitting CSRF tokens. I think these may have
    # been race conditions where the session had been destroyed between the
    # pre-request and template rendering functions. Therefore, produce the
    # token here if needed
    _update_csrf_token()
        if !session 'csrf_token';
    $tokens->{csrf_token}    = session 'csrf_token';

    if (session('views_other_user_id') && $tokens->{page} =~ /(data|view)/)
    {
        notice __x"You are currently viewing, editing and creating views as {name}",
            name => rset('User')->find(session 'views_other_user_id')->value;
    }
    session 'messages' => [];
};

hook after_template_render => sub {
    _update_persistent();
};

sub _update_persistent
{
    if (my $user = logged_in_user)
    {
        $user->update({
            session_settings => encode_json(session('persistent')),
        });
    }
}

sub _forward_last_table
{
    forwardHome() if !var('site')->remember_user_location;
    my $forward;
    if (my $l = session('persistent')->{instance_id})
    {
        my $instances = GADS::Instances->new(schema => schema, user => logged_in_user);
        my $layout = $instances->layout($l);
        if ($layout) {
            $forward = $layout->identifier;
        }
    }
    forwardHome(undef, $forward);
}

get '/' => require_login sub {

    my $site = var 'site';
    my $user    = logged_in_user;

    if (my $dashboard_id = query_parameters->get('did'))
    {
        session('persistent')->{dashboard}->{0} = $dashboard_id;
    }

    my $dashboard_id = session('persistent')->{dashboard}->{0};

    my %params = (
        id     => $dashboard_id,
        user   => $user,
        site   => var('site'),
    );

    my $dashboard = schema->resultset('Dashboard')->dashboard(%params)
        || schema->resultset('Dashboard')->shared_dashboard(%params);

    my $params = {
        readonly        => $dashboard->is_shared && !$user->permission->{superadmin},
        dashboard       => $dashboard,
        dashboards_json => schema->resultset('Dashboard')->dashboards_json(%params),
        page            => 'index',
    };

    if (my $download = param('download'))
    {
        $params->{readonly} = 1;
        if ($download eq 'pdf')
        {
            my $pdf = _page_as_mech('index', $params, pdf => 1)->content_as_pdf(
                paperWidth => 16.5, paperHeight => 11.7 # A3 landscape
            );
            return send_file(
                \$pdf,
                content_type => 'application/pdf',
            );
        }
    }

    template 'index' => $params;
};

get '/ping' => sub {
    content_type 'text/plain';
    'alive';
};

any ['get', 'post'] => '/aup' => require_login sub {

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
any ['get', 'post'] => '/user_status' => require_login sub {

    if (param 'accepted')
    {
        session 'status_accepted' => 1;
        _forward_last_table();
    }

    template user_status => {
        lastlogin => logged_in_user_lastlogin,
        message   => config->{gads}->{user_status_message},
        page      => 'user_status',
    };
};

get '/saml' => sub {
    redirect '/';
};

post '/saml' => sub {

    my $saml = GADS::SAML->new(
        request_id => session('request_id'),
        base_url   => request->base,
    );
    my $callback = $saml->callback(
        saml_response => body_parameters->get('SAMLResponse'),
    );

    my $authentication = schema->resultset('Authentication')->find(session 'authentication_id')
        or error "Error finding authentication provider";

    my $username = $callback->{nameid};
    my $user = schema->resultset('User')->active->search({ username => $username })->next;

    if (!$user)
    {
        my $msg = $authentication->user_not_found_error;
        return forwardHome({ danger => __x($msg, username => $username) }, 'login?password=1' );
    }

    $user->update_attributes($callback->{attributes});
    $user->update({ lastlogin => DateTime->now });

    session 'is_sso' => 1;

    return _successful_login($username, 'dbic');
};

get '/login/denied' => sub {
    forwardHome({ danger => "You do not have permission to access this page" });
};

sub _successful_login
{   my ($username, $realm) = @_;

    # change session ID if we have a new enough D2 version with support
    app->change_session_id
        if app->can('change_session_id');

    session logged_in_user => $username;
    session logged_in_user_realm => $realm;

    if (param 'remember_me')
    {
        my $secure = request->scheme eq 'https' ? 1 : 0;
        cookie 'remember_me' => $username, expires => '60d',
            secure => $secure, http_only => 1 if param('remember_me');
    }
    else {
        cookie remember_me => '', expires => '-1d' if cookie 'remember_me';
    }

    my $audit = GADS::Audit->new(schema => schema);
    my $user = logged_in_user;

    $audit->user($user);
    $audit->login_success;
    $user->update({
        failcount => 0,
        lastfail  => undef,
    });

    # Load previous settings
    my $session_settings;
    try { $session_settings = decode_json $user->session_settings };
    session 'persistent' => ($session_settings || {});
    if (my $url = query_parameters->get('return_url'))
    {
        $url = uri_unescape($url);
        return _forward_last_table() if $url eq '/';
        my $uri = URI->new($url);
        # Construct a URL using uri_for, which ensures that the correct base domain
        # is used (preventing open URL redirection attacks). The query needs to be
        # parsed and passed as an option, otherwise it is not encoded properly
        return redirect request->uri_for($uri->path, $uri->query_form_hash);
    }
    else {
        # forward to previous table if applicable
        return _forward_last_table();
    }
}

any ['get', 'post'] => '/login' => sub {

    my $audit = GADS::Audit->new(schema => schema);
    my $user  = logged_in_user;

    # Don't allow login page to be displayed when logged-in, to prevent
    # user thinking they are logged out when they are not
    return forwardHome() if $user;

    # Get authentication provider
    my $enabled = schema->resultset('Authentication')->enabled;

    if ($enabled->count == 1 && !query_parameters->get('password'))
    {
        my $auth = $enabled->next;
        if ($auth->type eq 'saml2')
        {
            my $saml = GADS::SAML->new(
                authentication => $auth,
                base_url       => request->base,
            );
            $saml->initiate;
            session request_id => $saml->request_id;
            session authentication_id => $auth->id;
            redirect $saml->redirect;
        }
    }

    my ($error, $error_modal);

    # Request a password reset
    if (param('resetpwd'))
    {
        if (my $username = param('emailreset'))
        {
            if (GADS::Util->email_valid($username))
            {
                $audit->login_change("Password reset request for $username");
                my $result = password_reset_send(username => $username);
                defined $result
                    ? success(__('An email has been sent to your email address with a link to reset your password'))
                    : report({is_fatal => 0}, ERROR => 'Failed to send a password reset link. Did you enter a valid email address?');
                report INFO =>  __x"Password reset requested for non-existant username {username}", username => $username
                    if defined $result && !$result;
            }
            else {
                $error = qq("$username" is not a valid email address);
                $error_modal = 'resetpw';
            }
        }
        else {
            $error = 'Please enter an email address for the password reset to be sent to';
            $error_modal = 'resetpw';
        }
    }

    my $users = GADS::Users->new(schema => schema, config => config);

    if (param 'register')
    {
        error __"Self-service account requests are not enabled on this site"
            if var('site')->hide_account_request;
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
                html    => $welcome_text{html},
                emails  => [$params->{email}],
            };

            if (process( sub { $email->send($args) }))
            {
                # Show same message as normal request
                return forwardHome(
                    { success => "Your account request has been received successfully" } );
            }
            $audit->login_change("Account request for $params->{email}. Account already existed, resending welcome email.");
            return forwardHome({ success => "Your account request has been received successfully" });
        }
        else {
            try { $users->register($params) };
            if(my $exception = $@->wasFatal)
            {
                if ($exception->reason eq 'ERROR')
                {
                    $error = $exception->message->toString;
                    $error_modal = 'register';
                }
                else {
                    $exception->throw;
                }
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
            return _successful_login($username, $realm);
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
                report {to => 'syslog'},
                    INFO => __x"debug_login set - failed username \"{username}\", password: \"{password}\"",
                    username => $user->username, password => params->{password}
                        if $user->debug_login;
            }
            report {is_fatal=>0}, ERROR => "The username or password was not recognised";
        }
    }

    my $output  = template 'login' => {
        error         => "".($error||""),
        error_modal   => $error_modal,
        username      => cookie('remember_me'),
        titles        => $users->titles,
        organisations => $users->organisations,
        departments   => $users->departments,
        teams         => $users->teams,
        register_text => var('site')->register_text,
        page          => 'login',
    };
    $output;
};

any ['get', 'post'] => '/edit/:id' => require_login sub {
    my $id = param 'id';
    redirect "/record/$id";
};

any ['get', 'post'] => '/myaccount/?' => require_login sub {

    my $user   = logged_in_user;
    my $audit  = GADS::Audit->new(schema => schema, user => $user);

    if (param 'newpassword')
    {
        my $new_password = _random_pw();
        if (user_password password => param('oldpassword'), new_password => $new_password)
        {
            $audit->login_change("New password set for user");
            forwardHome({ success => qq(Your password has been changed to: $new_password)}, 'myaccount', user_only => 1 ); # Don't log elsewhere
        }
        else {
            forwardHome({ danger => "The existing password entered is incorrect"}, 'myaccount' );
        }
    }

    if (param 'submit')
    {
        my $params = params;
        # Update of user details
        my %update;
        foreach my $field (var('site')->user_fields)
        {
            next if !$field->{editable};
            $update{$field->{name}} = param($field->{name}) || undef;
        }

        if (process( sub { $user->update_user(current_user => logged_in_user, %update) }))
        {
            return forwardHome(
                { success => "The account details have been updated" }, 'myaccount' );
        }
    }

    my $users = GADS::Users->new(schema => schema);
    template 'user' => {
        edit          => $user->id,
        users         => [$user],
        titles        => $users->titles,
        values            => {
            title            => $users->titles,
            organisation     => $users->organisations,
            department_id    => $users->departments,
            team_id          => $users->teams,
        },
        page          => 'myaccount',
        breadcrumbs   => [Crumb( '/myaccount/' => 'my details' )],
    };
};

my $new_account = config->{gads}->{new_account};

my $default_email_welcome_subject = ($new_account && $new_account->{subject})
    || "Your new account details";
my $default_email_welcome_text = ($new_account && $new_account->{body}) || <<__BODY;
An account for [NAME] has been created for you. Please
click on the following link to retrieve your password:

[URL]
__BODY

any ['get', 'post'] => '/system/?' => require_login sub {

    my $user = logged_in_user;
    my $site = var 'site';

    forwardHome({ danger => "You do not have permission to manage system settings"}, '')
        unless logged_in_user->permission->{superadmin};

    if (param 'update')
    {
        $site->email_welcome_subject(param 'email_welcome_subject');
        $site->email_welcome_text(param 'email_welcome_text');
        $site->name(param 'name');

        if (process( sub {
            $site->update;
            $site->update_user_editable_fields(body_parameters->get_all('user_editable'));
        }))
        {
            return forwardHome(
                { success => "Configuration settings have been updated successfully" } );
        }
    }

    $site->email_welcome_subject($default_email_welcome_subject)
        if !$site->email_welcome_subject;
    $site->email_welcome_text($default_email_welcome_text)
        if !$site->email_welcome_text;
    $site->name(config->{gads}->{name} || 'Linkspace')
        if !$site->name;

    template 'system' => {
        instance    => $site,
        page        => 'system',
        breadcrumbs => [Crumb( '/system' => 'system-wide settings' )],
    };
};


any ['get', 'post'] => '/group/?:id?' => require_any_role [qw/useradmin superadmin/] => sub {

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
        page => defined $id && !$id ? 'group/0' : 'group'
    };

    if (defined $id)
    {
        # id will be 0 for new group
        $params->{group}       = $group;
        $params->{permissions} = [@permissions];
        my $group_name = $id ? $group->name : 'new group';
        my $group_id   = $id ? $group->id : 0;
        $params->{breadcrumbs} = [Crumb( '/group' => 'groups' ) => Crumb( "/group/$group_id" => $group_name )];
    }
    else {
        my $groups = GADS::Groups->new(schema => schema);
        $params->{groups}      = $groups->all;
        $params->{layout}      = $layout;
        $params->{breadcrumbs} = [Crumb( '/group' => 'groups' )];
    }
    template 'group' => $params;
};

any ['get', 'post'] => '/organisation/?:id?' => require_any_role [qw/useradmin superadmin/] => sub {

    my $id     = route_parameters->get('id');

    my $organisation = $id
        ? schema->resultset('Organisation')->find($id)
        : schema->resultset('Organisation')->new({});

    my $organisation_name = var('site')->organisation_name;

    if (body_parameters->get('submit'))
    {
        $organisation->name(body_parameters->get('name'));
        if (process( sub { $organisation->insert_or_update } ))
        {
            return forwardHome(
                { success => "The $organisation_name has been updated successfully" }, 'organisation/' );
        }
    }

    if ($id && body_parameters->get('delete'))
    {
        if (process( sub { $organisation->delete_organisation } ))
        {
            return forwardHome(
                { success => "The $organisation_name has been deleted successfully" }, 'organisation/' );
        }
    }

    template 'organisation' => {
        organisation  => defined $id && $organisation,
        organisations => [schema->resultset('Organisation')->ordered],
        page          => 'organisation',
    };

};

any ['get', 'post'] => '/department/?:id?' => require_any_role [qw/useradmin superadmin/] => sub {

    my $id     = route_parameters->get('id');

    my $department = $id
        ? schema->resultset('Department')->find($id)
        : schema->resultset('Department')->new({});

    my $department_name = var('site')->department_name;

    if (body_parameters->get('submit'))
    {
        $department->name(body_parameters->get('name'));
        if (process( sub { $department->insert_or_update } ))
        {
            return forwardHome(
                { success => "The $department_name has been updated successfully" }, 'department/' );
        }
    }

    if ($id && body_parameters->get('delete'))
    {
        if (process( sub { $department->delete_department } ))
        {
            return forwardHome(
                { success => "The $department_name has been deleted successfully" }, 'department/' );
        }
    }

    template 'department' => {
        department  => defined $id && $department,
        departments => [schema->resultset('Department')->ordered],
        page        => 'department',
    };

};

any ['get', 'post'] => '/team/?:id?' => require_any_role [qw/useradmin superadmin/] => sub {

    my $id     = route_parameters->get('id');

    my $team = $id
        ? schema->resultset('Team')->find($id)
        : schema->resultset('Team')->new({});

    my $team_name = var('site')->team_name;

    if (body_parameters->get('submit'))
    {
        $team->name(body_parameters->get('name'));
        if (process( sub { $team->insert_or_update } ))
        {
            return forwardHome(
                { success => "The $team_name has been updated successfully" }, 'team/' );
        }
    }

    if ($id && body_parameters->get('delete'))
    {
        if (process( sub { $team->delete_team } ))
        {
            return forwardHome(
                { success => "The $team_name has been deleted successfully" }, 'team/' );
        }
    }

    template 'team' => {
        team  => defined $id && $team,
        teams => [schema->resultset('Team')->ordered],
        page  => 'team',
    };

};

any ['get', 'post'] => '/title/?:id?' => require_any_role [qw/useradmin superadmin/] => sub {

    my $id     = route_parameters->get('id');

    my $title = $id
        ? schema->resultset('Title')->find($id)
        : schema->resultset('Title')->new({});

    if (body_parameters->get('submit'))
    {
        $title->name(body_parameters->get('name'));
        if (process( sub { $title->insert_or_update } ))
        {
            return forwardHome(
                { success => "The title has been updated successfully" }, 'title/' );
        }
    }

    if ($id && body_parameters->get('delete'))
    {
        if (process( sub { $title->delete_title } ))
        {
            return forwardHome(
                { success => "The title has been deleted successfully" }, 'title/' );
        }
    }

    template 'title' => {
        title  => defined $id && $title,
        titles => [schema->resultset('Title')->ordered],
        page   => 'title',
    };

};

get '/table/?' => require_role superadmin => sub {

    template 'tables' => {
        page        => 'table',
        instances   => [rset('Instance')->all],
        breadcrumbs => [Crumb( '/table' => 'tables' )],
    };
};

any ['get', 'post'] => '/table/:id' => require_role superadmin => sub {

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
            $layout_edit->name_short(param 'name_short');
            $layout_edit->hide_in_selector(param 'hide_in_selector');
            $layout_edit->sort_layout_id(param('sort_layout_id') || undef);
            $layout_edit->sort_type(param('sort_type') || undef);
            $layout_edit->view_limit_id(param('view_limit_id') || undef);
            $layout_edit->set_groups([body_parameters->get_all('permissions')]);
            $layout_edit->set_alert_columns([body_parameters->get_all('alert_column')]);
            $layout_edit->set_rags(body_parameters);

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

    my $table_name = $id ? $layout_edit->name : 'new table';
    my $table_id   = $id ? $layout_edit->instance_id : 0;

    template 'table' => {
        page        => $id ? 'this_table' : 'table/0',
        layout_edit => $layout_edit,
        groups      => GADS::Groups->new(schema => schema)->all,
        breadcrumbs => [Crumb( '/table' => 'tables' ) => Crumb( "/table/$table_id" => $table_name )],
    }
};

any ['get', 'post'] => '/user/upload' => require_any_role [qw/useradmin superadmin/] => sub {

    my $userso = GADS::Users->new(schema => schema);

    if (param 'submit')
    {
        my $count;
        my $file = upload('file') && upload('file')->tempname;
        if (process sub {
            $count = rset('User')->upload($file,
                request_base => request->base,
                view_limits  => [body_parameters->get_all('view_limits')],
                groups       => [body_parameters->get_all('groups')],
                permissions  => [body_parameters->get_all('permission')],
                current_user => logged_in_user,
            )}
        )
        {
            return forwardHome(
                { success => "$count users were successfully uploaded" }, 'user' );
        }
    }

    template 'user/upload' => {
        page        => 'user',
        groups      => GADS::Groups->new(schema => schema)->all,
        permissions => $userso->permissions,
        breadcrumbs => [Crumb( '/user' => 'users' ), Crumb( '/user/upload' => "user upload" ) ],
        # XXX Horrible hack - see single user edit route
        edituser    => +{ view_limits_with_blank => [ undef ] },
    };
};

any ['get', 'post'] => '/user/export/?' => require_any_role [qw/useradmin superadmin/] => sub {

    my $users = GADS::Users->new(schema => schema);

    if (body_parameters->get('submit'))
    {
        if (process( sub { $users->csv(logged_in_user) }))
        {
            return forwardHome(
                { success => "The export has been started successfully" }, 'user/export' );
        }
    }

    if (my $id = query_parameters->get('download'))
    {
        my $export = schema->resultset('Export')->search({
            id      => $id,
            user_id => logged_in_user->id,
        })->next or error "Download not found";

        my $csv = $export->content;
        my $now = $export->completed;
        my $header;
        if ($header = config->{gads}->{header})
        {
            $csv       = "$header\n$csv" if $header;
            $header    = "-$header" if $header;
        }
        # Content in database already UTF-8 encoded
        return send_file( \$csv, content_type => 'text/csv; charset="utf-8"', filename => "$now$header.csv" );
    }

    if (body_parameters->get('clear'))
    {
        my $export = schema->resultset('Export')->search({
            user_id => logged_in_user->id,
        });

        if (process( sub { $export->delete }))
        {
            return forwardHome(
                { success => "The export has been deleted successfully" }, 'user/export' );
        }
    }

    template 'user/export' => {
        exports     => schema->resultset('Export')->user(logged_in_user->id),
        page        => 'user',
        breadcrumbs => [Crumb( '/user' => 'users' ), Crumb( '/user/export' => "user export" ) ],
    };
};

any ['get', 'post'] => '/user/?:id?' => require_any_role [qw/useradmin superadmin/] => sub {

    my $id = body_parameters->get('id');

    my $user            = logged_in_user;
    my $userso          = GADS::Users->new(schema => schema);
    my %all_permissions = map { $_->id => $_->name } @{$userso->permissions};
    my $audit           = GADS::Audit->new(schema => schema, user => $user);
    my $users;

    if (param 'sendemail')
    {
        my @emails = param('group_ids')
                   ? (map { $_->email } @{$userso->all_in_groups(param 'group_ids')})
                   : (map { $_->email } @{$userso->all});
        my $email  = GADS::Email->instance;
        my $args   = {
            subject => param('email_subject'),
            text    => param('email_text'),
            emails  => \@emails,
        };

        if (@emails)
        {
            if (process( sub { $email->message($args, logged_in_user) }))
            {
                return forwardHome(
                    { success => "The message has been sent successfully" }, 'user' );
            }
        }
        else {
            report({is_fatal => 0}, ERROR => 'The groups selected contain no users');
        }
    }

    # The submit button will still be triggered on a new org/title creation,
    # if the user has pressed enter, in which case ignore it
    if (param('submit') && !param('neworganisation') && !param('newdepartment') && !param('newtitle') && !param('newteam'))
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
            department_id         => param('department_id') || undef,
            team_id               => param('team_id') || undef,
            account_request       => param('account_request'),
            account_request_notes => param('account_request_notes'),
            view_limits           => [body_parameters->get_all('view_limits')],
            groups                => [body_parameters->get_all('groups')],
        );
        $values{permissions} = [body_parameters->get_all('permission')]
            if logged_in_user->permission->{superadmin};

        if (!param('account_request') && $id) # Original username to update (hidden field)
        {
            if (process sub {
                my $user = rset('User')->active->search({ id => $id })->next
                    or error __x"User ID {id} not found", id => $id;
                # Don't use DBIC update directly, so that permissions etc are updated properly
                $user->update_user(current_user => logged_in_user, %values);
            })
            {
                return forwardHome(
                    { success => "User has been updated successfully" }, 'user' );
            }
        }
        else {
            # This sends a welcome email etc
            if (process(sub { rset('User')->create_user(current_user => $user, request_base => request->base, %values) }))
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
    if (param('neworganisation') || param('newtitle') || param('newdepartment') || param('newteam'))
    {
        if (my $org = param 'neworganisation')
        {
            if (process( sub { $userso->organisation_new({ name => $org })}))
            {
                $audit->login_change("Organisation $org created");
                success __"The organisation has been created successfully";
            }
        }

        if (my $dep = param 'newdepartment')
        {
            if (process( sub { $userso->department_new({ name => $dep })}))
            {
                $audit->login_change("Department $dep created");
                my $depname = lc var('site')->register_department_name || 'department';
                success __x"The {dep} has been created successfully", dep => $depname;
            }
        }

        if (my $team = param 'newteam')
        {
            if (process( sub { $userso->team_new({ name => $team })}))
            {
                $audit->login_change("Team $team created");
                my $teamname = lc var('site')->register_team_name || 'team';
                success __x"The {team} has been created successfully", team => $teamname;
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
            department_id          => { id => param('department_id') },
            team_id                => { id => param('team_id') },
            view_limits_with_blank => $view_limits_with_blank,
            groups                 => \%groups,
        }];
    }
    elsif (my $delete_id = param('delete'))
    {
        return forwardHome(
            { danger => "Cannot delete current logged-in User" } )
            if logged_in_user->id eq $delete_id;
        my $usero = rset('User')->find($delete_id);
        if (process( sub { $usero->retire(send_reject_email => 1) }))
        {
            $audit->login_change("User ID $delete_id deleted");
            return forwardHome(
                { success => "User has been deleted successfully" }, 'user' );
        }
    }

    my $route_id = route_parameters->get('id');

    if ($route_id)
    {
        my $u = rset('User')->active_and_requests->search({ id => $route_id})->next
            or error __x"User id {id} not found", id => $route_id;
        $users = [ $u ] if !$users;
    }
    elsif (!defined $route_id) {
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

    my $breadcrumbs = [Crumb( '/user' => 'users' )];
    push @$breadcrumbs, Crumb( "/user/$route_id" => "edit user $route_id" ) if $route_id;
    push @$breadcrumbs, Crumb( "/user/$route_id" => "new user" ) if defined $route_id && !$route_id;
    my $output = template 'user' => {
        edit              => $route_id,
        users             => $users,
        groups            => GADS::Groups->new(schema => schema)->all,
        register_requests => $register_requests,
        values            => {
            title            => $userso->titles,
            organisation     => $userso->organisations,
            department_id    => $userso->departments,
            team_id          => $userso->teams,
        },
        permissions       => $userso->permissions,
        page              => defined $route_id && !$route_id ? 'user/0' : 'user',
        breadcrumbs       => $breadcrumbs,
    };
    $output;
};

get '/helptext/:id?' => require_login sub {
    my $id     = param 'id';
    my $user   = logged_in_user;
    my $layout = var('instances')->all->[0];
    my $column = $layout->column($id);
    template 'helptext.tt', { column => $column }, { layout => undef };
};

get '/file/?' => require_login sub {

    my $user        = logged_in_user;

    forwardHome({ danger => "You do not have permission to manage files"}, '')
        unless logged_in_user->permission->{superadmin};

    my @files = rset('Fileval')->independent->all;

    template 'files' => {
        files       => [@files],
        breadcrumbs => [Crumb( "/file" => 'files' )],
    };
};

get '/file/:id' => require_login sub {
    my $id = param 'id';

    # Need to get file details first, to be able to populate
    # column details of applicable.
    my $fileval = $id =~ /^[0-9]+$/ && schema->resultset('Fileval')->find($id)
        or error __x"File ID {id} cannot be found", id => $id;
    my ($file_rs) = $fileval->files; # In theory can be more than one, but not in practice (yet)
    my $file = GADS::Datum::File->new(ids => $id);
    # Get appropriate column, if applicable (could be unattached document)
    # This will control access to the file
    if ($file_rs && $file_rs->layout_id)
    {
        my $layout = var('instances')->layout($file_rs->layout->instance_id);
        $file->column($layout->column($file_rs->layout_id));
    }
    elsif (!$fileval->is_independent)
    {
        # If the file has been uploaded via a record edit and it hasn't been
        # attached to a record yet (or the record edit was cancelled) then do
        # not allow access
        error __"Access to this file is not allowed"
            unless $fileval->edit_user_id && $fileval->edit_user_id == logged_in_user->id;
        $file->schema(schema);
    }
    else {
        $file->schema(schema);
    }
    # Call content from the Datum::File object, which will ensure the user has
    # access to this file. The other parameters are taken straight from the
    # database resultset
    send_file( \($file->content), content_type => $fileval->mimetype, filename => $fileval->name );
};

# File upload through the "manage files" interface
post '/file/?' => require_login sub {

    my $upload = upload('file')
        or error __"No file submitted";
    my $mimetype = $filecheck->check_file($upload); # Borks on invalid file type
    my $file;
    if (process( sub { $file = rset('Fileval')->create({
        name           => $upload->filename,
        mimetype       => $mimetype,
        content        => $upload->content,
        is_independent => 1,
        edit_user_id   => undef,
    }) } ))
    {
        my $msg = __x"File has been uploaded as ID {id}", id => $file->id;
        return forwardHome( { success => "$msg" }, 'file' );
    }
};

# Use api route to ensure errors are returned as JSON
post '/api/file/?' => require_login sub {

    if (my $upload = upload('file'))
    {
        my $mimetype = $filecheck->check_file($upload); # Borks on invalid file type
        my $file;
        if (process( sub { $file = rset('Fileval')->create({
            name           => $upload->filename,
            mimetype       => $mimetype,
            content        => $upload->content,
            is_independent => 0,
            edit_user_id   => logged_in_user->id,
        }) } ))
        {
            return encode_json({
                id       => $file->id,
                filename => $upload->filename,
                url      => "/file/".$file->id,
                is_ok    => 1,
            });
        }
        return encode_json({
            is_ok => 0,
            error => $@,
        });
    }
    else {
        return encode_json({
            is_ok => 0,
            error => "No file was submitted",
        });
    }
};

get '/record_body/:id' => require_login sub {

    my $id         = param('id');
    my $version_id = param('version_id');

    my $user   = logged_in_user;
    my $record = GADS::Record->new(
        user   => $user,
        schema => schema,
        rewind => session('rewind'),
    );

    # Wait until record has been found before logging to audit, so that the
    # instance_id is known. If it's an invalid request though, log to audit and
    # then bounce
    try { $version_id ? $record->find_record_id($version_id) : $record->find_current_id($id) };
    if ($@)
    {
        my $err = $@;
        _audit_log();
        $err->reportFatal;
    }

    my $layout = $record->layout;
    var 'layout' => $layout;
    _audit_log();

    my ($return, $options, $is_raw) = _process_edit($id, $record);
    return $return if $is_raw;
    $options->{layout} = undef;
    $return->{view_modal} = 1; # Assume modal if loaded via this route

    template 'edit' => $return, $options;
};

get '/chronology/:id?' => require_login sub {

    my $user   = logged_in_user;
    my $id     = route_parameters->get('id');
    my $record = GADS::Record->new(
        user   => $user,
        schema => schema,
    );
    $record->find_chronology_id($id);

    my $breadcrumbs = [
        Crumb( $record->layout ),
        Crumb( $record->layout, "/data" => 'records' ),
        Crumb( "/chronology/".$record->current_id => 'record id ' . $record->current_id ),
    ];

    template 'chronology' => {
        record      => $record,
        breadcrumbs => $breadcrumbs,
        page        => 'chronology',
    };
};

any qr{/(record|history|purge|purgehistory)/([0-9]+)} => require_login sub {

    my ($action, $id) = splat;

    my $user   = logged_in_user;

    my $record = GADS::Record->new(
        user   => $user,
        schema => schema,
        rewind => session('rewind'),
    );

    # Wait until record has been found before logging to audit, so that the
    # instance_id is known. If it's an invalid request though, log to audit and
    # then bounce
    try {
          $action eq 'history'
        ? $record->find_record_id($id)
        : $action eq 'purge'
        ? $record->find_deleted_currentid($id)
        : $action eq 'purgehistory'
        ? $record->find_deleted_recordid($id)
        : $record->find_current_id($id);
    };

    if ($@)
    {
        my $err = $@;
        _audit_log();
        $err->reportFatal;
    }

    my $layout = $record->layout;
    var 'layout' => $layout;
    _audit_log();

    if (defined param('pdf') && !$record->layout->no_download_pdf)
    {
        my $pdf = $record->pdf->content;
        return send_file(\$pdf, content_type => 'application/pdf', filename => "Record-".$record->current_id.".pdf" );
    }

    if ( app->has_hook('plugin.linkspace.record_before_template') ) {
        app->execute_hook( 'plugin.linkspace.record_before_template', record => $record );
    }

    my @first_crumb = $action eq 'purge' ? ( $layout, "/purge" => 'deleted records' ) : ( $layout, "/data" => 'records' );

    my ($return, $options, $is_raw) = _process_edit($id, $record);
    return $return if $is_raw;
    $return->{is_history} = $action eq 'history';
    $return->{breadcrumbs} = [Crumb($layout) => Crumb(@first_crumb) => Crumb( "/record/".$record->current_id => 'record id ' . $record->current_id )];
    template 'edit' => $return, $options;
};

get '/match/user/' => require_role audit => sub {
    my $query = param('q');
    content_type 'application/json';
    to_json [ rset('User')->match($query) ];
};

any ['get', 'post'] => '/audit/?' => require_role audit => sub {

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
        filter_user => $audit->filtering->{user} && schema->resultset('User')->find($audit->filtering->{user}),
        audit_types => GADS::Audit::audit_types,
        page        => 'audit',
        breadcrumbs => [Crumb( "/audit" => 'audit logs' )],
    };
};


get '/logout' => sub {
    app->destroy_session;
    forwardHome();
};

any ['get', 'post'] => '/resetpw/:code' => sub {

    # Strange things happen if running this code when already logged in.
    # Log the existing user out first
    if (logged_in_user)
    {
        app->destroy_session;
        _update_csrf_token();
    }

    # Perform check first in order to get user ID for audit
    if (my $username = user_password code => param('code'))
    {
        my $new_password;

        if (param 'execute_reset')
        {
            app->destroy_session;
            my $user   = rset('User')->active(username => $username)->next;
            # Now we know this user is genuine, reset any failure that would
            # otherwise prevent them logging in
            $user->update({ failcount => 0 });
            my $audit  = GADS::Audit->new(schema => schema, user => $user);
            $audit->login_change("Password reset performed for user ID ".$user->id);
            $new_password = _random_pw();
            user_password code => param('code'), new_password => $new_password;
            report {to => 'syslog'},
                INFO => __x"debug_login set - new password for username \"{username}\", password: \"{password}\"",
                username => $user->username, password => $new_password
                    if $user->debug_login;
            _update_csrf_token();
        }
        my $output  = template 'login' => {
            site_name  => var('site')->name || 'Linkspace',
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

post '/print' => require_login sub {
    my $html = body_parameters->get('html')
        or error __"Missing body parameter: html";

    my $pdf  = _page_as_mech(undef, undef, html => $html)->content_as_pdf(
        paperWidth => 16.5, paperHeight => 11.7 # A3 landscape
    );
    return send_file(
        \$pdf,
        content_type => 'application/pdf',
    );
};

prefix '/:layout_name' => sub {

    get '/?' => require_login sub {
        my $layout = var('layout') or pass;

        my $user    = logged_in_user;

        if (my $dashboard_id = query_parameters->get('did'))
        {
            session('persistent')->{dashboard}->{$layout->instance_id} = $dashboard_id;
        }

        my $dashboard_id = session('persistent')->{dashboard}->{$layout->instance_id};

        my %params = (
            id     => $dashboard_id,
            user   => $user,
            layout => $layout,
            site   => var('site'),
        );

        my $dashboard = schema->resultset('Dashboard')->dashboard(%params)
            || schema->resultset('Dashboard')->shared_dashboard(%params);

        # If the shared dashboard is blank for this table then show the site
        # dashboard by default. That is, unless the shared dashboard has been
        # specifically requested, in which case we allow access in order to be
        # able to update it
        if (!$dashboard || (!query_parameters->get('did') && $dashboard->is_shared && $dashboard->is_empty))
        {
            my %params = (
                user   => $user,
                site   => var('site'),
            );
            $dashboard = schema->resultset('Dashboard')->dashboard(%params)
                || schema->resultset('Dashboard')->shared_dashboard(%params);
        }

        my $params = {
            readonly        => $dashboard->is_shared && !$layout->user_can('layout'),
            dashboard       => $dashboard,
            dashboards_json => schema->resultset('Dashboard')->dashboards_json(%params),
            page            => 'index',
            breadcrumbs     => [Crumb($layout)],
        };

        if (my $download = param('download'))
        {
            $params->{readonly} = 1;
            if ($download eq 'pdf' && !$layout->no_download_pdf)
            {
                my $pdf = _page_as_mech('index', $params, pdf => 1)->content_as_pdf(
                    paperWidth => 16.5, paperHeight => 11.7 # A3 landscape
                );
                return send_file(
                    \$pdf,
                    content_type => 'application/pdf',
                );
            }
        }

        template 'index' => $params;
    };

    get '/data_calendar/:time' => require_login sub {

        my $layout = var('layout') or pass;

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
        my $view    = current_view($user, $layout);

        my $records = GADS::Records->new(
            user                => $user,
            layout              => $layout,
            schema              => schema,
            from                => $fromdt,
            to                  => $todt,
            max_results         => 1000,
            view                => $view,
            search              => session('search'),
            view_limit_extra_id => current_view_limit_extra_id($user, $layout),
        );

        response_header "Cache-Control" => "max-age=0, must-revalidate, private";
        content_type 'application/json';
        my $data = $records->data_calendar;
        encode_json({
            "success" => 1,
            "result"  => $data,
        });
    };

    get '/data_timeline/:time' => require_login sub {

        my $layout = var('layout') or pass;

        # If getting data for the dashboard, then ignore all the normal records
        # settings and retrieve according to the dashboard and its view
        my $is_dashboard = param('dashboard');

        # Time variable is used to prevent caching by browser

        my $fromdt  = DateTime->from_epoch( epoch => int ( param('from') / 1000 ) );
        my $todt    = DateTime->from_epoch( epoch => int ( param('to') / 1000 ) );

        my $user    = logged_in_user;
        my $view_id = $is_dashboard && param('view');
        my $view    = current_view($user, $layout, $view_id);

        my $records = GADS::Records->new(
            from                => $fromdt,
            to                  => $todt,
            exclusive           => param('exclusive'),
            user                => $user,
            layout              => $layout,
            schema              => schema,
            view                => $view,
            search              => $is_dashboard ? undef : session('search'),
            rewind              => $is_dashboard ? undef : session('rewind'),
            view_limit_extra_id => current_view_limit_extra_id($user, $layout),
        );

        response_header "Cache-Control" => "max-age=0, must-revalidate, private";
        content_type 'application/json';

        my $tl_options = (!$is_dashboard && session('persistent')->{tl_options}->{$layout->instance_id}) || {};
        my $timeline = $records->data_timeline(%{$tl_options});
        encode_json($timeline->{items});
    };

    post '/data_timeline' => require_login sub {

        my $layout = var('layout') or pass;

        my $tl_options         = session('persistent')->{tl_options}->{$layout->instance_id} ||= {};
        $tl_options->{from}    = int(param('from') / 1000) if param('from');
        $tl_options->{to}      = int(param('to') / 1000) if param('to');
        my $view               = current_view(logged_in_user, $layout);
        $tl_options->{view_id} = $view && $view->id;
        # Note the current time so that we can decide later if it's relevant to
        # load these settings
        $tl_options->{now}  = DateTime->now->epoch;

        # XXX Application session settings do not seem to be updated without
        # calling template (even calling _update_persistent does not help)
        return template 'index' => {};
    };

    get '/data_graph/:id/:time' => require_login sub {

        my $id      = param 'id';
        my $gdata = _data_graph($id);

        response_header "Cache-Control" => "max-age=0, must-revalidate, private";
        content_type 'application/json';
        encode_json({
            points  => $gdata->points,
            labels  => $gdata->labels_encoded,
            xlabels => $gdata->xlabels,
            options => $gdata->options,
        });
    };

    any ['get', 'post'] => '/data' => require_login sub {

        my $layout = var('layout') or pass;

        my $user   = logged_in_user;

        my @additional_filters;
        foreach my $key (keys %{query_parameters()})
        {
            $key =~ /^field([0-9]+)$/
                or next;
            my $fid = $1;
            my @values = query_parameters->get_all($key);
            push @additional_filters, {
                id    => $fid,
                value => [query_parameters->get_all($key)],
            };
        }

        # Check for bulk delete
        if (param 'modal_delete')
        {
            forwardHome({ danger => "You do not have permission to bulk delete records"}, $layout->identifier.'/data')
                unless $layout->user_can("bulk_delete");
            my %params = (
                user                => $user,
                search              => session('search'),
                layout              => $layout,
                schema              => schema,
                rewind              => session('rewind'),
                view                => current_view($user, $layout),
                view_limit_extra_id => current_view_limit_extra_id($user, $layout),
                additional_filters  => \@additional_filters,
            );
            $params{limit_current_ids} = [body_parameters->get_all('delete_id')]
                if body_parameters->get_all('delete_id');
            my $records = GADS::Records->new(%params);

            my $count; # Count actual number deleted, not number reported by search result
            while (my $record = $records->single)
            {
                $count++
                    if (process sub { $record->delete_current });
            }
            return forwardHome(
                { success => "$count records successfully deleted" }, $layout->identifier.'/data' );
        }

        if ( app->has_hook('plugin.linkspace.data_before_request') ) {
            app->execute_hook( 'plugin.linkspace.data_before_request', user => $user );
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
                    search              => $search,
                    schema              => schema,
                    user                => $user,
                    layout              => $layout,
                    view_limit_extra_id => current_view_limit_extra_id($user, $layout),
                );
                my $results = $records->current_ids;

                # Redirect to record if only one result
                redirect "/record/$results->[0]"
                    if @$results == 1;
            }
        }

        # Setting a new view limit extra
        if (my $extra = $layout->user_can('view_limit_extra') && param('extra'))
        {
            session('persistent')->{view_limit_extra}->{$layout->instance_id} = $extra;
        }

        my $new_view_id = param('view');
        if (param 'views_other_user_clear')
        {
            session views_other_user_id => undef;
            my $views      = GADS::Views->new(
                user        => $user,
                schema      => schema,
                layout      => $layout,
                instance_id => session('persistent')->{instance_id},
            );
            $new_view_id = $views->default->id;
        }
        elsif (my $user_id = param 'views_other_user_id')
        {
            session views_other_user_id => $user_id;
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
                    { success => "The alert has been saved successfully" }, $layout->identifier.'/data' );
            }
        }

        if ($new_view_id)
        {
            session('persistent')->{view}->{$layout->instance_id} = $new_view_id;
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
            if ($viewtype =~ /^(graph|table|calendar|timeline|globe)$/)
            {
                session('persistent')->{viewtype}->{$layout->instance_id} = $viewtype;
            }
        }
        else {
            $viewtype = session('persistent')->{viewtype}->{$layout->instance_id} || 'table';
        }

        my $view       = current_view($user, $layout);

        my $params = {
            layout => var('layout'),
        }; # Variable for the template

        if ($viewtype eq 'graph')
        {
            $params->{page}     = 'data_graph';
            $params->{viewtype} = 'graph';
            if (my $png = param('png'))
            {
                my $gdata = _data_graph($png);
                my $json  = encode_base64($gdata->as_json,'');
                my $graph = GADS::Graph->new(
                    id     => $png,
                    layout => $layout,
                    schema => schema
                );
                my $options_in = encode_base64($graph->as_json,'');
                $params->{graph_id} = $png;

                my $mech = _page_as_mech('data_graph', $params);
                $mech->eval_in_page("(function(plotData, options_in){do_plot_json(plotData, options_in)})('$json','$options_in');");

                my $png = $mech->content_as_png(undef, { width => 630, height => 400 });
                # Send as inline images to make copy and paste easier
                return send_file(
                    \$png,
                    content_type        => 'image/png',
                    content_disposition => 'inline', # Default is attachment
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
                $params->{graphs} = GADS::Graphs->new(current_user => $user, schema => schema, layout => $layout)->all;
            }
        }
        elsif ($viewtype eq 'calendar')
        {
            # Get details of the view and work out color markers for date fields
            my $records = GADS::Records->new(
                user    => $user,
                view    => $view,
                layout  => $layout,
                schema  => schema,
            );
            my @columns = @{$records->columns_render};
            my @colors;
            my $graph = GADS::Graph::Data->new(
                schema  => schema,
                records => undef,
            );

            foreach my $column (@columns)
            {
                if ($column->type eq "daterange" || ($column->return_type && $column->return_type eq "date"))
                {
                    my $color = $graph->get_color($column->name);
                    push @colors, { key => $column->name, color => $color};
                }
            }

            $params->{calendar} = session('calendar'); # Remember previous day viewed
            $params->{colors}   = \@colors;
            $params->{page}     = 'data_calendar';
            $params->{viewtype} = 'calendar';
        }
        elsif ($viewtype eq 'timeline')
        {
            my $records = GADS::Records->new(
                user                => $user,
                view                => $view,
                search              => session('search'),
                layout              => $layout,
                # No "to" - will take appropriate number from today
                from                => DateTime->now, # Default
                schema              => schema,
                rewind              => session('rewind'),
                view_limit_extra_id => current_view_limit_extra_id($user, $layout),
            );
            my $tl_options = session('persistent')->{tl_options}->{$layout->instance_id} ||= {};
            if (param 'modal_timeline')
            {
                $tl_options->{label}            = param('tl_label');
                $tl_options->{group}            = param('tl_group');
                $tl_options->{all_group_values} = param('tl_all_group_values');
                $tl_options->{color}            = param('tl_color');
                $tl_options->{overlay}          = param('tl_overlay');
            }

            # See whether to restore remembered range
            if (
                defined $tl_options->{from}   # Remembered range exists?
                && defined $tl_options->{to}
                && ((!$tl_options->{view_id} && !$view) || ($view && $tl_options->{view_id} == $view->id)) # Using the same view
                && $tl_options->{now} > DateTime->now->subtract(days => 7)->epoch # Within sensible window
            )
            {
                $records->from(DateTime->from_epoch(epoch => $tl_options->{from}));
                $records->to(DateTime->from_epoch(epoch => $tl_options->{to}));
            }

            my $timeline = $records->data_timeline(%{$tl_options});
            $params->{records}              = encode_base64(encode_json(delete $timeline->{items}), '');
            $params->{groups}               = encode_base64(encode_json(delete $timeline->{groups}), '');
            $params->{colors}               = delete $timeline->{colors};
            $params->{timeline}             = $timeline;
            $params->{tl_options}           = $tl_options;
            $params->{columns_read}         = [$layout->all(user_can_read => 1)];
            $params->{page}                 = 'data_timeline';
            $params->{viewtype}             = 'timeline';
            $params->{search_limit_reached} = $records->search_limit_reached;

            if (my $png = param('png'))
            {
                my $png = _page_as_mech('data_timeline', $params)->content_as_png;
                return send_file(
                    \$png,
                    content_type => 'image/png',
                );
            }
            if (param('modal_pdf') && !$layout->no_download_pdf)
            {
                $tl_options->{pdf_zoom} = param('pdf_zoom');
                my $pdf = _page_as_mech('data_timeline', $params, pdf => 1, zoom => $tl_options->{pdf_zoom})->content_as_pdf(
                    paperWidth => 16.5, paperHeight => 11.7 # A3 landscape
                );
                return send_file(
                    \$pdf,
                    content_type => 'application/pdf',
                );
            }
        }
        elsif ($viewtype eq 'globe')
        {
            my $globe_options = session('persistent')->{globe_options}->{$layout->instance_id} ||= {};
            if (param 'modal_globe')
            {
                $globe_options->{group} = param('globe_group');
                $globe_options->{color} = param('globe_color');
                $globe_options->{label} = param('globe_label');
            }

            my $records_options = {
                user   => $user,
                view   => $view,
                search => session('search'),
                layout => $layout,
                schema => schema,
                rewind => session('rewind'),
            };
            my $globe = GADS::Globe->new(
                group_col_id    => $globe_options->{group},
                color_col_id    => $globe_options->{color},
                label_col_id    => $globe_options->{label},
                records_options => $records_options,
            );
            $params->{globe_data} = encode_base64(encode_json($globe->data), '');
            $params->{colors}               = $globe->colors;
            $params->{globe_options}        = $globe_options;
            $params->{columns_read}         = [$layout->columns_for_filter];
            $params->{viewtype}             = 'globe';
            $params->{page}                 = 'data_globe';
            $params->{search_limit_reached} = $globe->records->search_limit_reached;
            $params->{count}                = $globe->records->count;
        }
        else {
            session 'rows' => 50 unless session 'rows';
            session 'page' => 1 unless session 'page';

            my $rows = defined param('download') ? undef : session('rows');
            my $page = defined param('download') ? undef : session('page');

            my %params = (
                user                => $user,
                search              => session('search'),
                layout              => $layout,
                schema              => schema,
                rewind              => session('rewind'),
                additional_filters  => \@additional_filters,
                view_limit_extra_id => current_view_limit_extra_id($user, $layout),
            );
            # If this is a filter from a group view, then disable the group for
            # this rendering
            my $disable_group = defined query_parameters->get('group_filter') && @additional_filters;
            $params{is_group} = 0 if $disable_group;

            $params{for_curval} = {
                layout_id => query_parameters->get('curval_layout_id'),
                record_id => query_parameters->get('curval_record_id'),
            } if query_parameters->get('curval_record_id');

            my $records = GADS::Records->new(%params);

            $records->view($view);
            $records->rows($rows);
            $records->page($page);
            $records->sort(session 'sort');

            if (param('sort') && param('sort') =~ /^([0-9]+)(asc|desc)$/)
            {
                my $sortcol  = $1;
                my $sorttype = $2;
                # Check user has access
                forwardHome({ danger => "Invalid column ID for sort" }, $layout->identifier.'/data')
                    unless $layout->column($sortcol) && $layout->column($sortcol)->user_can('read');
                my $existing = $records->sort_first;
                my $type;
                session 'sort' => { type => $sorttype, id => $sortcol };
                $records->clear_sorts;
                $records->sort(session 'sort');
            }

            if (param 'modal_sendemail')
            {
                forwardHome({ danger => "There are no records in this view and therefore nobody to email"}, $layout->identifier.'/data')
                    unless $records->results;

                return forwardHome(
                    { danger => 'You do not have permission to send messages' }, $layout->identifier.'/data' )
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
                        { success => "The message has been sent successfully" }, $layout->identifier.'/data' );
                }
            }

            if (defined param('download'))
            {
                forwardHome({ danger => "There are no records to download in this view"}, $layout->identifier.'/data')
                    unless $records->count;

                # Return CSV as a streaming response, otherwise a long delay whilst
                # the CSV is generated can cause a client to timeout
                return delayed {
                    # XXX delayed() does not seem to use normal Dancer error
                    # handling - make sure any fatal errors are caught
                    try {
                        my $now = DateTime->now;
                        my $header = config->{gads}->{header} || '';
                        $header = "-$header" if $header;
                        response_header 'Content-Disposition' => "attachment; filename=\"$now$header.csv\"";
                        content_type 'text/csv; charset="utf-8"';

                        flush; # Required to start the async send
                        content $records->csv_header;

                        while ( my $row = $records->csv_line ) {
                            utf8::encode($row);
                            content $row;
                        }
                        done;
                    } accept => 'WARNING-'; # Don't collect the thousands of trace messages
                    # Not ideal, but throw exceptions somewhere...
                    say STDERR "$@" if $@;
                } on_error => sub {
                    # This doesn't seen to get called
                    say STDERR "Failed to stream: @_";
               };
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

            my @columns = @{$records->columns_render};
            $params->{user_can_edit}        = $layout->user_can('write_existing');
            $params->{sort}                 = $records->sort_first;
            $params->{subset}               = $subset;
            $params->{records}              = $records->presentation;
            $params->{aggregate}            = $records->aggregate_presentation;
            $params->{count}                = $records->count;
            $params->{columns}              = [ map $_->presentation(
                sort             => $records->sort_first,
                filters          => \@additional_filters,
                query_parameters => query_parameters,
            ), @columns ];
            $params->{is_group}             = $records->is_group,
            $params->{has_rag_column}       = grep { $_->type eq 'rag' } @columns;
            $params->{viewtype}             = 'table';
            $params->{page}                 = 'data_table';
            $params->{search_limit_reached} = $records->search_limit_reached;
            if (@additional_filters)
            {
                # Should be moved into presentation layer
                my @filters;
                foreach my $add (@additional_filters)
                {
                    push @filters, "field$add->{id}=".uri_escape_utf8($_)
                        foreach @{$add->{value}};
                }
                push @filters, "group_filter"
                    if $disable_group;
                $params->{filter_url} = join '&', @filters;
            }
        }

        # Get all alerts
        my $alert = GADS::Alert->new(
            user      => $user,
            layout    => $layout,
            schema    => schema,
        );

        my $views      = GADS::Views->new(
            user          => $user,
            other_user_id => session('views_other_user_id'),
            schema        => schema,
            layout        => $layout,
            instance_id   => $layout->instance_id,
        );

        if ( app->has_hook('plugin.linkspace.data_before_template') ) {
            my %arg = (
                user => $user,
                layout => $layout,
                params => $params,
            );
            # Note, this might modify $params
            app->execute_hook( 'plugin.linkspace.data_before_template', %arg );
        }

        $params->{user_views}               = $views->user_views;
        $params->{views_limit_extra}        = $views->views_limit_extra;
        $params->{current_view_limit_extra} = current_view_limit_extra($user, $layout) || $layout->default_view_limit_extra;
        $params->{alerts}                   = $alert->all;
        $params->{views_other_user}         = session('views_other_user_id') && rset('User')->find(session('views_other_user_id')),
        $params->{breadcrumbs}              = [Crumb($layout) => Crumb( $layout, '/data' => 'records' )];

        template 'data' => $params;
    };

    # any ['get', 'post'] => qr{/tree[0-9]*/([0-9]*)/?} => require_login sub {
    any ['get', 'post'] => '/tree:any?/:layout_id/?' => require_login sub {
        # Random number can be used after "tree" to prevent caching

        my $layout      = var('layout') or pass;
        my ($layout_id) = splat;
        $layout_id = route_parameters->get('layout_id');

        my $tree = $layout->column($layout_id)
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
        my @ids  = query_parameters->get_all('ids');
        my $json = $tree->type eq 'tree' ? $tree->json(@ids) : [];

        # If record is specified, select the record's value in the returned JSON
        response_header "Cache-Control" => "max-age=0, must-revalidate, private";
        content_type 'application/json';
        encode_json($json);

    };

    any ['get', 'post'] => '/purge/?' => require_login sub {

        my $layout = var('layout') or pass;

        my $user        = logged_in_user;

        forwardHome({ danger => "You do not have permission to manage deleted records"}, '')
            unless $layout->user_can("purge");

        if (param('purge') || param('restore'))
        {
            my @current_ids = body_parameters->get_all('record_selected')
                or forwardHome({ danger => "Please select some records before clicking an action" }, $layout->identifier.'/purge');
            my $records = GADS::Records->new(
                limit_current_ids   => [@current_ids],
                columns             => [],
                user                => $user,
                is_deleted          => 1,
                layout              => $layout,
                schema              => schema,
                include_children    => 1,
                view_limit_extra_id => undef, # Override any value that may be set
            );
            if (param 'purge')
            {
                my $record;
                $record->purge_current while $record = $records->single;
                forwardHome({ success => "Records have now been purged" }, $layout->identifier.'/purge');
            }
            if (param 'restore')
            {
                my $record;
                $record->restore while $record = $records->single;
                forwardHome({ success => "Records have now been restored" }, $layout->identifier.'/purge');
            }
        }

        my $records = GADS::Records->new(
            columns             => [],
            user                => $user,
            is_deleted          => 1,
            layout              => $layout,
            schema              => schema,
            include_children    => 1,
            view_limit_extra_id => undef, # Override any value that may be set
        );

        my $params = {
            page    => 'purge',
            records => $records->presentation(purge => 1),
        };

        $params->{breadcrumbs} = [Crumb($layout) => Crumb( $layout, '/data' => 'records' ) => Crumb( $layout, '/purge' => 'purge records' )];
        template 'purge' => $params;
    };

    any ['get', 'post'] => '/graph/:id' => require_login sub {

        my $layout = var('layout') or pass;

        my $user        = logged_in_user;

        my $params = {
            layout => $layout,
            page   => 'graph',
        };

        my $id = param 'id';

        my $graph = GADS::Graph->new(
            id           => $id,
            layout       => $layout,
            schema       => schema,
            current_user => $user,
        );

        if (param 'delete')
        {
            if (process( sub { $graph->delete }))
            {
                return forwardHome(
                    { success => "The graph has been deleted successfully" }, $layout->identifier.'/graphs' );
            }
        }

        if (param 'submit')
        {
            my $values = params;
            $graph->$_(param $_)
                foreach (qw/title description type set_x_axis x_axis_grouping y_axis
                    y_axis_label y_axis_stack group_by stackseries metric_group_id as_percent
                    is_shared group_id trend from to x_axis_range/);
            if(process( sub { $graph->write }))
            {
                my $action = param('id') ? 'updated' : 'created';
                return forwardHome(
                    { success => "Graph has been $action successfully" }, $layout->identifier.'/graphs' );
            }
        }

        $params->{graph}         = $graph;
        $params->{metric_groups} = GADS::MetricGroups->new(
            schema      => schema,
            instance_id => session('persistent')->{instance_id},
        )->all;

        my $graph_name = $id ? $graph->title : "add a graph";
        my $graph_id   = $id ? $graph->id : 0;
        $params->{breadcrumbs}   = [
            Crumb($layout) => Crumb( $layout, '/data' => 'records' )
                => Crumb( $layout, '/graphs' => 'graphs' ) => Crumb( $layout, "/graph/$graph_id" => $graph_name )
        ],

        template 'graph' => $params;
    };

    get '/metrics/?' => require_login sub {

        my $layout = var('layout') or pass;

        my $user        = logged_in_user;

        forwardHome({ danger => "You do not have permission to manage metrics" }, '')
            unless $layout->user_can("layout");

        my $metrics = GADS::MetricGroups->new(
            schema      => schema,
            instance_id => $layout->instance_id,
        )->all;

        my $params = {
            layout      => $layout,
            page        => 'metric',
            metrics     => $metrics,
            breadcrumbs => [Crumb($layout) => Crumb( $layout, '/data' => 'records' )
                => Crumb( $layout, '/graphs' => 'graphs' )
                => Crumb( $layout, '/metrics' => 'metrics' )
            ],
        };

        template 'metrics' => $params;
    };

    any ['get', 'post'] => '/metric/:id' => require_login sub {

        my $layout = var('layout') or pass;

        my $user        = logged_in_user;

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
                    { success => "The metric has been deleted successfully" }, $layout->identifier.'/metrics' );
            }
        }

        # Delete an individual item from a group
        if (param 'delete_metric')
        {
            if (process( sub { $metricgroup->delete_metric(param 'metric_id') }))
            {
                return forwardHome(
                    { success => "The metric has been deleted successfully" }, $layout->identifier."/metric/$id" );
            }
        }

        if (param 'submit')
        {
            $metricgroup->name(param 'name');
            if(process( sub { $metricgroup->write }))
            {
                my $action = param('id') ? 'updated' : 'created';
                return forwardHome(
                    { success => "Metric has been $action successfully" }, $layout->identifier.'/metrics' );
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
                    { success => "Metric has been $action successfully" }, $layout->identifier."/metric/$id" );
            }
        }

        $params->{metricgroup} = $metricgroup;

        my $metric_name = $id ? $metricgroup->name : "add a metric";
        my $metric_id   = $id ? $metricgroup->id : 0;
        $params->{breadcrumbs} = [Crumb($layout) => Crumb( $layout, '/data' => 'records' )
                => Crumb( $layout, '/graphs' => 'graphs' )
                => Crumb( $layout, '/metrics' => 'metrics' ) => Crumb( $layout, "/metric/$metric_id" => $metric_name )
        ],

        template 'metric' => $params;
    };

    any ['get', 'post'] => '/topic/:id' => require_login sub {

        my $layout = var('layout') or pass;

        my $user        = logged_in_user;

        my $instance_id = $layout->instance_id;

        forwardHome({ danger => "You do not have permission to manage topics"}, '')
            unless $layout->user_can("layout");

        my $id = param 'id';
        my $topic = $id && schema->resultset('Topic')->search({
            id          => $id,
            instance_id => $instance_id,
        })->next;

        !$id || $topic or error __x"Topic ID {id} not found", id => $id;

        if (param 'submit')
        {
            $topic = schema->resultset('Topic')->new({ instance_id => $instance_id })
                if !$id;

            $topic->name(param 'name');
            $topic->description(param 'description');
            $topic->click_to_edit(param 'click_to_edit');
            $topic->initial_state(param 'initial_state');
            $topic->prevent_edit_topic_id(param('prevent_edit_topic_id') || undef);

            if (process(sub {$topic->update_or_insert}))
            {
                my $action = param('id') ? 'updated' : 'created';
                return forwardHome(
                    { success => "Topic has been $action successfully" }, $layout->identifier.'/topics' );
            }
        }

        if (param 'delete_topic')
        {
            if (process(sub {$topic->delete}))
            {
                return forwardHome(
                    { success => "The topic has been deleted successfully" }, $layout->identifier.'/topics' );
            }
        }

        my $topic_name = $id ? $topic->name : 'new topic';
        my $topic_id   = $id ? $topic->id : 0;
        template 'topic' => {
            topic       => $topic,
            topics      => [schema->resultset('Topic')->search({ instance_id => $instance_id })->all],
            breadcrumbs => [Crumb($layout) => Crumb( $layout, '/topics' => 'topics' ) => Crumb( $layout, "/topic/$topic_id" => $topic_name )],
            page        => !$id ? 'topic/0' : 'topics',
        }
    };

    get '/topics/?' => require_login sub {

        my $layout = var('layout') or pass;

        my $user        = logged_in_user;

        my $instance_id = $layout->instance_id;

        forwardHome({ danger => "You do not have permission to manage topics"}, '')
            unless $layout->user_can("layout");

        template 'topics' => {
            layout      => $layout,
            topics      => [schema->resultset('Topic')->search({ instance_id => $instance_id })->all],
            breadcrumbs => [Crumb($layout) => Crumb( $layout, '/topics' => 'topics' )],
            page        => 'topics',
        };
    };

    any ['get', 'post'] => '/view/:id' => require_login sub {

        my $layout = var('layout') or pass;

        my $user   = logged_in_user;

        return forwardHome(
            { danger => 'You do not have permission to edit views' }, $layout->identifier.'/data' )
            unless $layout->user_can("view_create");

        my $view_id = param('id');

        error __x"Invalid view ID: {id}", id => $view_id
            unless $view_id =~ /^[0-9]+$/;

        $view_id = param('clone') if param('clone') && !request->is_post;
        my @ucolumns; my $view_values;

        my %vp = (
            user          => $user,
            other_user_id => session('views_other_user_id'),
            schema        => schema,
            layout        => $layout,
            instance_id   => $layout->instance_id,
        );
        $vp{id} = $view_id if $view_id;
        my $view = GADS::View->new(%vp);

        # If this is a clone of a full global view, but the user only has group
        # view creation rights, then remove the global parameter, otherwise it
        # means that it is ticked by default but only for a group instead
        $view->global(0) if param('clone') && !$view->group_id && !$layout->user_can('layout');

        if (param 'update')
        {
            my $params = params;
            my $columns = ref param('column') ? param('column') : [ param('column') // () ]; # Ensure array
            $view->columns($columns);
            $view->global(param('global') ? 1 : 0);
            $view->is_admin(param('is_admin') ? 1 : 0);
            $view->group_id(param 'group_id');
            $view->name  (param 'name');
            $view->filter->as_json(param 'filter');
            $view->set_sorts({
                fields => [body_parameters->get_all('sortfield')],
                types  => [body_parameters->get_all('sorttype')],
            });
            $view->set_groups(
                [body_parameters->get_all('groupfield')],
            );
            if (process( sub { $view->write }))
            {
                # Set current view to the one created/edited
                session('persistent')->{view}->{$layout->instance_id} = $view->id;
                # And remove any search to avoid confusion
                session search => '';
                # And remove any custom sorting, so that sort of view takes effect
                session 'sort' => undef;
                return forwardHome(
                    { success => "The view has been updated successfully" }, $layout->identifier.'/data' );
            }
        }

        if (param 'delete')
        {
            session('persistent')->{view}->{$layout->instance_id} = undef;
            if (process( sub { $view->delete }))
            {
                return forwardHome(
                    { success => "The view has been deleted successfully" }, $layout->identifier.'/data' );
            }
        }

        my $page = param('clone')
            ? 'view/clone'
            : defined param('id') && !param('id')
            ? 'view/0' : 'view';

        my $breadcrumbs = [Crumb($layout) => Crumb( $layout, '/data' => 'records' )];
        push @$breadcrumbs, Crumb( $layout, "/view/0?clone=$view_id" => 'clone view "'.$view->name.'"' ) if param('clone');
        push @$breadcrumbs, Crumb( $layout, "/view/$view_id" => 'edit view "'.$view->name.'"' ) if $view_id && !param('clone');
        push @$breadcrumbs, Crumb( $layout, "/view/0" => 'new view' ) if !$view_id && defined $view_id;

        my $output = template 'view' => {
            layout      => $layout,
            sort_types  => $view->sort_types,
            view_edit   => $view, # TT does not like variable "view"
            clone       => param('clone'),
            page        => $page,
            breadcrumbs => $breadcrumbs,
        };
        $output;
    };

    any ['get', 'post'] => '/layout/?:id?' => require_login sub {

        my $layout = var('layout') or pass;

        my $user        = logged_in_user;

        forwardHome({ danger => "You do not have permission to manage fields"}, '')
            unless $layout->user_can("layout");

        my $params = {
            page => defined param('id') && !param('id') ? 'layout/0' : 'layout',
        };

        if (defined param('id'))
        {
            # Get all layouts of all instances for field linking
            $params->{instance_layouts} = var('instances')->all;
            $params->{instances_object} = var('instances'); # For autocur. Don't conflict with other instances var
        }

        my $breadcrumbs = [Crumb($layout) => Crumb( $layout, '/layout' => 'fields' )];
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
                my $username = $user->username;
                my $description = qq(User "$username" deleted field "$colname");
                $audit->user_action(description => $description);
                if (process( sub { $column->delete }))
                {
                    return forwardHome(
                        { success => "The item has been deleted successfully" }, $layout->identifier.'/layout' );
                }
            }

            if (param 'submit')
            {

                my @permission_params = grep { /^permission_(?:.*?)_\d+$/ } keys %{ params() };

                my %permissions;

                foreach (@permission_params) {
                    my ($name, $group_id) = m/^permission_(.*?)_(\d+)$/;
                    push @{ $permissions{$group_id} ||= [] }, $name;
                }

                $column->set_permissions(\%permissions);

                $column->$_(param $_)
                    foreach (qw/name name_short description helptext optional isunique set_can_child
                        multivalue remember link_parent_id topic_id width aggregate group_display/);
                $column->type(param 'type')
                    unless param('id'); # Can't change type as it would require DBIC resultsets to be removed and re-added
                $column->$_(param $_)
                    foreach @{$column->option_names};
                $column->display_fields(param 'display_fields');
                # Set the layout in the GADS::Filter object, in case the write
                # doesn't success, in which case the filter will need to be
                # turned into base64 which requires layout to be set in
                # GADS::Filter (to prevent a panic)
                $column->display_fields->layout($layout);

                my $no_alerts;
                if ($column->type eq "file")
                {
                    $column->filesize(param('filesize') || undef) if $column->type eq "file";
                }
                elsif ($column->type eq "rag")
                {
                    $column->code(param 'code_rag');
                    $no_alerts = param('no_alerts_rag');
                }
                elsif ($column->type eq "enum")
                {
                    my $params = params;
                    $column->enumvals({
                        enumvals    => [body_parameters->get_all('enumval')],
                        enumval_ids => [body_parameters->get_all('enumval_id')],
                    });
                    $column->ordering(param('ordering') || undef);
                }
                elsif ($column->type eq "calc")
                {
                    $column->code(param 'code_calc');
                    $column->return_type(param 'return_type');
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
                    $column->refers_to_instance_id(param 'refers_to_instance_id');
                    $column->filter->as_json(param 'filter');
                    my @curval_field_ids = body_parameters->get_all('curval_field_ids');
                    $column->curval_field_ids([@curval_field_ids]);
                }
                elsif ($column->type eq "autocur")
                {
                    my @curval_field_ids = body_parameters->get_all('autocur_field_ids');
                    $column->curval_field_ids([@curval_field_ids]);
                    $column->related_field_id(param 'related_field_id');
                }
                elsif ($column->type eq "filval")
                {
                    my @curval_field_ids = body_parameters->get_all('filval_field_ids');
                    $column->curval_field_ids([@curval_field_ids]);
                    $column->related_field_id(param 'filval_related_field_id');
                }

                my $no_cache_update = $column->type eq 'rag' ? param('no_cache_update_rag') : param('no_cache_update_calc');
                if (process( sub { $column->write(no_alerts => $no_alerts, no_cache_update => $no_cache_update) }))
                {
                    my $msg = param('id')
                        ? qq(Your field has been updated successfully)
                        : qq(Your field has been created successfully);

                    return forwardHome( { success => $msg }, $layout->identifier.'/layout' );
                }
            }
            $params->{column} = $column;
            push @$breadcrumbs, Crumb( $layout, "/layout/".$column->id => 'edit field "'.$column->name.'"' );
        }
        elsif (defined param('id'))
        {
            $params->{column} = 0; # New
            push @$breadcrumbs, Crumb( $layout, "/layout/0" => 'new field' );
        }
        $params->{groups}             = GADS::Groups->new(schema => schema);
        $params->{permissions}        = [GADS::Type::Permissions->all];
        $params->{permission_mapping} = GADS::Type::Permissions->permission_mapping;
        $params->{permission_inputs}  = GADS::Type::Permissions->permission_inputs;
        $params->{topics}             = [schema->resultset('Topic')->search({ instance_id => $layout->instance_id })->all];

        if (param 'saveposition')
        {
            my @position = body_parameters->get_all('position');
            if (process( sub { $layout->position(@position) }))
            {
                return forwardHome(
                    { success => "The ordering has been saved successfully" }, $layout->identifier.'/layout' );
            }
        }

        $params->{breadcrumbs} = $breadcrumbs;
        template 'layout' => $params;
    };

    any ['get', 'post'] => '/approval/?:id?' => require_login sub {

        my $layout = var('layout') or pass;
        my $id   = param 'id';
        my $user = logged_in_user;

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

        if (param 'submit')
        {
            # Get latest record for this approval
            my $record = GADS::Record->new(
                user           => $user,
                layout         => $layout,
                schema         => schema,
                approval_id    => $id,
                doing_approval => 1,
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
            my $failed;
            foreach my $col ($record->edit_columns(new => $approval_of_new, approval => 1))
            {
                my $newv = param($col->field);
                if ($col->userinput && defined $newv) # Not calculated fields
                {
                    $failed = !process( sub { $record->fields->{$col->id}->set_value($newv) } ) || $failed;
                }
            }
            if (!$failed && process( sub { $record->write }))
            {
                return forwardHome(
                    { success => 'Record has been successfully approved' }, $layout->identifier.'/approval' );
            }
        }

        my $page;
        my $params = {
            page => 'approval',
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
            $params->{record_presentation} = $record->presentation(edit => 1, new => $approval_of_new, approval => 1);

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
            $params->{breadcrumbs} = [Crumb($layout) =>
                Crumb( $layout, '/approval' => 'approve records' ), Crumb( $layout, "/approval/$id" => "approve record $id" ) ];
        }
        else {
            $page  = 'approval';
            my $approval = GADS::Approval->new(
                schema => schema,
                user   => $user,
                layout => $layout
            );
            $params->{records} = $approval->records;
            $params->{breadcrumbs} = [Crumb($layout) =>
                Crumb( $layout, '/approval' => 'approve records' ) ];
        }

        template $page => $params;
    };

    any ['get', 'post'] => '/link/:id?' => require_login sub {

        my $layout = var('layout') or pass;

        my $id = param 'id';

        my $record = GADS::Record->new(
            user   => logged_in_user,
            layout => $layout,
            schema => schema,
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
                    { success => 'Record has been linked successfully' }, $layout->identifier.'/data' );
            }
        }

        my $breadcrumbs = [Crumb($layout)];
        if ($id)
        {
            push @$breadcrumbs, Crumb( $layout, "/link/$id" => "edit linked record $id" );
        }
        else {
            push @$breadcrumbs, Crumb( $layout, '/link/' => 'add linked record' );
        }
        template 'link' => {
            breadcrumbs => $breadcrumbs,
            record      => $record,
            page        => 'link',
        };
    };

    post '/edits' => require_login sub {

        my $layout = var('layout') or pass;

        my $user   = logged_in_user;

        my $records = eval { from_json param('q') };
        if ($@) {
            status 'bad_request';
            return 'Request body must contain JSON';
        }

        my $failed;
        while ( my($id, $values) = each %$records ) {
            my $record = GADS::Record->new(
                user   => $user,
                layout => $layout,
                schema => schema,
            );

            $record->find_current_id($values->{current_id});
            $layout = $record->layout; # May have changed if record from other datasheet
            if ($layout->column($values->{column})->type eq 'date')
            {
                my $to_write = DateTime->from_epoch(epoch => $values->{from} / 1000);
                unless (process sub { $record->fields->{ $values->{column} }->set_value($to_write) })
                {
                    $failed = 1;
                    next;
                }
            }
            else {
                # daterange
                my $to_write = [
                    DateTime->from_epoch(epoch => $values->{from} / 1000),
                    DateTime->from_epoch(epoch => $values->{to} / 1000),
                ];
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
                { success => 'Submission has been completed successfully' }, $layout->identifier.'/data' );
        }
    };

    any ['get', 'post'] => '/bulk/:type/?' => require_login sub {

        my $layout = var('layout') or pass;

        my $user   = logged_in_user;
        my $view   = current_view($user, $layout);
        my $type   = param 'type';

        forwardHome({ danger => "You do not have permission to perform bulk operations"}, $layout->identifier.'/data')
            unless $layout->user_can("bulk_update");

        $type eq 'update' || $type eq 'clone'
            or error __x"Invalid bulk type: {type}", type => $type;

        # The dummy record to test for updates
        my $record = GADS::Record->new(
            user   => $user,
            layout => $layout,
            schema => schema,
        );
        $record->initialise;

        # The records to update
        my %params = (
            view                 => $view,
            is_group             => 0,
            search               => session('search'),
            columns              => [map { $_->id } $layout->all], # Need all columns to be able to write updated records
            schema               => schema,
            user                 => $user,
            layout               => $layout,
            view_limit_extra_id  => current_view_limit_extra_id($user, $layout),
        );
        $params{limit_current_ids} = [query_parameters->get_all('id')]
            if query_parameters->get_all('id');
        my $records = GADS::Records->new(%params);

        if (param 'submit')
        {
            # See which ones to update
            my $failed_initial; my @updated;
            foreach my $col ($record->edit_columns(new => 1, bulk => $type))
            {
                my @newv = body_parameters->get_all($col->field);
                my $included = body_parameters->get('bulk_inc_'.$col->id); # Is it ticked to be included?
                report WARNING => __x"Field \"{name}\" contained a submitted value but was not checked to be included", name => $col->name
                    if join('', @newv) && !$included;
                next unless body_parameters->get('bulk_inc_'.$col->id); # Is it ticked to be included?
                my $datum = $record->fields->{$col->id};
                my $success = process( sub { $datum->set_value(\@newv, bulk => 1) } );
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
                    $record_update->fields->{$_->id}->re_evaluate(force => 1)
                        foreach $layout->all(has_cache => 1);
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
                        { success => $msg->toString }, $layout->identifier.'/data' );
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
                : $params{limit_current_ids}
                ? __x(qq(Use this page to update all currently selected records.
                    Tick the fields whose values should be updated. Fields that are
                    not ticked will retain their existing value.
                    The current number of selected records is {count}.), count => scalar @{$params{limit_current_ids}})
                : __x(qq(Use this page to update all records in the
                    currently selected view. Tick the fields whose values should be
                    updated. Fields that are not ticked will retain their existing value.
                    The current view is "{view}"), view => $view_name);
            my $msg = $notice;
            $msg .= $count_msg unless $params{limit_current_ids};
            notice $msg;
        }
        else {
            my $notice = session('search')
                ? __x(qq(Use this page to bulk clone all of the records in
                    the current search results. The cloned records will be created using
                    the same existing values by default, but replaced with the values below
                    where that value is ticked. Values that are not ticked will be cloned
                    with their current value. The current search is "{search}"), search => session('search'))
                : $params{limit_current_ids}
                ? __x(qq(Use this page to bulk clone all currently selected records.
                    The cloned records will be created using
                    the same existing values by default, but replaced with the values below
                    where that value is ticked. Values that are not ticked will be cloned
                    with their current value.
                    The current number of selected records is {count}.), count => scalar @{$params{limit_current_ids}})
                : __x(qq(Use this page to bulk clone all of the records in
                    the currently selected view. The cloned records will be created using
                    the same existing values by default, but replaced with the values below
                    where that value is ticked. Values that are not ticked will be cloned
                    with their current value. The current view is "{view}"), view => $view_name);
            my $msg = $notice;
            $msg .= $count_msg unless $params{limit_current_ids};
            notice $msg;
        }

        template 'edit' => {
            view        => $view,
            record      => $record->presentation(edit => 1, new => 1, bulk => $type),
            bulk_type   => $type,
            page        => 'bulk',
            breadcrumbs => [Crumb($layout), Crumb( $layout, "/data" => 'records' ), Crumb( $layout, "/bulk/$type" => "bulk $type records" )],
        };
    };

    any ['get', 'post'] => '/record/?' => require_login sub {

        my $layout = var('layout') or pass;
        my ($return, $options, $is_raw) = _process_edit();
        return $return if $is_raw;
        template 'edit' => $return, $options;
    };

    any ['get', 'post'] => '/import/?' => require_login sub {

        my $layout = var('layout') or pass;

        forwardHome({ danger => "You do not have permission to import data"}, '')
            unless $layout->user_can("layout");

        my $imp = rset('Import')->search({
            instance_id => $layout->instance_id,
        },{
            order_by => { -desc => 'me.completed' },
        });

        if (param 'clear')
        {
            $imp->search({
                completed => { '!=' => undef },
            })->delete;
        }

        template 'import' => {
            imports     => [$imp->all],
            page        => 'import',
            breadcrumbs => [Crumb($layout) => Crumb( $layout, "/data" => 'records' ) => Crumb( $layout, "/import" => 'imports' )],
        };
    };

    get '/import/rows/:import_id' => require_login sub {

        my $layout = var('layout') or pass;

        forwardHome({ danger => "You do not have permission to import data"}, '')
            unless $layout->user_can("layout");

        my $import_id = param 'import_id';
        my $import = rset('Import')->search({
            'me.id'          => $import_id,
            'me.instance_id' => $layout->instance_id,
        })->next
            or error __"Requested import not found";

        my $rows = $import->import_rows->search({},{
            order_by => {
                -asc => 'me.id',
            }
        });

        template 'import/rows' => {
            import_id   => param('import_id'),
            rows        => $rows,
            page        => 'import',
            breadcrumbs => [Crumb($layout) => Crumb( $layout, "/data" => 'records' )
                => Crumb( $layout, "/import" => 'imports' ), Crumb( $layout, "/import/rows/$import_id" => "import ID $import_id" ) ],
        };
    };

    any ['get', 'post'] => '/import/data/?' => require_login sub {

        my $layout = var('layout') or pass;

        my $user        = logged_in_user;

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
                    user     => $user,
                    %options,
                );

                if (process sub { $import->process })
                {
                    return forwardHome(
                        { success => "The file import process has been started and can be monitored using the Import Status below" }, $layout->identifier.'/import' );
                }
            }
            else {
                report({is_fatal => 0}, ERROR => 'Please select a file to upload');
            }
        }

        template 'import/data' => {
            layout      => var('layout'),
            page        => 'import',
            breadcrumbs => [Crumb($layout) => Crumb( $layout, "/data" => 'records' )
                => Crumb( $layout, "/import" => 'imports' ), Crumb( $layout, "/import/data" => 'new import' ) ],
        };
    };

    any ['get', 'post'] => '/graphs/?' => require_login sub {

        my $layout = var('layout') or pass;
        my $user   = logged_in_user;
        my $audit  = GADS::Audit->new(schema => schema, user => $user);

        if (param 'graphsubmit')
        {
            if (process( sub { $user->graphs($layout->instance_id, [body_parameters->get_all('graphs')]) }))
            {
                return forwardHome(
                    { success => "The selected graphs have been updated" }, $layout->identifier.'/data' );
            }
        }

        my $graphs = GADS::Graphs->new(
            current_user => $user,
            schema       => schema,
            layout       => $layout,
        );
        my $all_graphs = $graphs->all;

        template 'graphs' => {
            graphs      => $all_graphs,
            page        => 'graphs',
            breadcrumbs => [Crumb($layout) => Crumb( $layout, '/data' => 'records' ) => Crumb( $layout, '/graph' => 'graphs' )],
        };
    };

    get '/match/user/' => require_login sub {

        my $layout = var('layout') or pass;
        $layout->user_can("layout") or error "No access to search for users";

        my $query = param('q');
        content_type 'application/json';
        to_json [ rset('User')->match($query) ];
    };

    get '/match/layout/:layout_id' => require_login sub {

        my $layout = var('layout') or pass;
        my $query = param('q');
        my $layout_id = param('layout_id');

        my $column = $layout->column($layout_id, permission => 'read');

        content_type 'application/json';
        # To match data structure returned from getting filtered curval values
        to_json {
            error   => 0,
            records => [ $column->values_beginning_with($query, noempty => query_parameters->get('noempty')) ]
        };
    };

};

sub reset_text {
    my ($dsl, %options) = @_;
    my $site = var 'site';
    my $name = $site->name || config->{gads}->{name} || 'Linkspace';
    my $url  = request->base . "resetpw/$options{code}";
    my $body = <<__BODY;
A request to reset your $name password has been received. Please
click on the following link to set and retrieve a new password:

$url
__BODY

    my $html = <<__HTML;
<p>A request to reset your $name password has been received. Please
click on the following link to set and retrieve a new password:</p>

<p><a href="$url">$url<a></p>
__HTML

    return (
        from    => config->{gads}->{email_from},
        subject => 'Password reset request',
        plain   => wrap('', '', $body),
        html    => $html,
    )
}

sub welcome_text
{   my ($dsl, %options) = @_;
    my $site = var 'site';
    my $name = $site->name || config->{gads}->{name} || 'Linkspace';
    my $url  = request->base . "resetpw/$options{code}";
    my $new_account = config->{gads}->{new_account};
    my $subject = $site->email_welcome_subject
        || $default_email_welcome_subject;

    my $body = $site->email_welcome_text
        || $default_email_welcome_text;

    $body =~ s/\Q[URL]/$url/;
    $body =~ s/\Q[NAME]/$name/;

    my $html = text2html(
        $body,
        lines     => 1,
        urls      => 1,
        email     => 1,
        metachars => 1,
    );

    (
        from    => config->{gads}->{email_from},
        subject => $subject,
        plain   => $body,
        html    => $html,
    );
}

sub current_view {
    my ($user, $layout, $view_id) = @_;

    $layout or return undef;

    my $views      = GADS::Views->new(
        user        => $user,
        schema      => schema,
        layout      => $layout,
        instance_id => $layout->instance_id,
    );
    my $view;
    # If an invalid view is stuck in the session, then this can result in the
    # user in a continuous loop unable to open any other views
    $view_id ||= session('persistent')->{view}->{$layout->instance_id};
    try { $view = $views->view($view_id) };
    $@->reportAll(is_fatal => 0); # XXX results in double reporting
    return $view || $views->default || undef; # Can still be undef
};

sub current_view_limit_extra
{   my ($user, $layout) = @_;
    my $extra_id = session('persistent')->{view_limit_extra}->{$layout->instance_id};
    $extra_id ||= $layout->default_view_limit_extra_id;
    if ($extra_id)
    {
        # Check it's valid
        my $extra = schema->resultset('View')->find($extra_id);
        return $extra
            if $extra && $extra->instance_id == $layout->instance_id;
    }
    return undef;
}

sub current_view_limit_extra_id
{   my ($user, $layout) = @_;
    my $view = current_view_limit_extra($user, $layout);
    $view ? $view->id : undef;
}

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

sub _audit_log
{   my $method      = request->method;
    my $path        = request->path;
    my $query       = request->query_string;
    my $user        = logged_in_user;
    my $audit       = GADS::Audit->new(schema => schema, user => $user);
    my $username    = $user && $user->username;
    my $description = $user
        ? qq(User "$username" made "$method" request to "$path")
        : qq(Unauthenticated user made "$method" request to "$path");
    $description .= qq( with query "$query") if $query;
    $audit->user_action(description => $description, url => $path, method => $method, layout => var('layout'))
        if $user;
}

sub _random_pw
{   $password_generator->xkcd( words => 3, digits => 2 );
}

# check if PDF printing still needs this sub
sub _page_as_mech
{   my ($template, $params, %options) = @_;
    $params->{scheme}       = 'http';
    my $public              = path(setting('appdir'), 'public');
    $params->{base}         = "file://$public/";
    $params->{page_as_mech} = 1;
    $params->{zoom}         = ($options{zoom} ? int($options{zoom}) : 100) / 100;
    my $timeline_html       = $options{html} || template $template, $params;
    my ($fh, $filename)     = tempfile(SUFFIX => '.html');
    print $fh $timeline_html;
    close $fh;

    my $mech = WWW::Mechanize::Chrome->new(
	headless   => 1,
        launch_exe => '/usr/bin/chromium',
    );

    # In order to use the full page of PDFs (rendered as A3) we need to set the
    # applicable viewport size
    if ($options{pdf})
    {
        # A3 is 29.7 × 42 cm
        # Subtract 0.5cm * 2 for borders (see local.css)
        # = 28.7cm x 41
        # Pixels as per https://www.unitconverters.net/typography/centimeter-to-pixel-x.htm
        # 1085 x 1550
        $mech->viewport_size({ width => 1550, height => 1085 });
        $mech->get_local("${filename}?pdf=1");
    }
    else
    {
        $mech->get_local($filename);
    }

    # Sometimes the timeline does not render properly (it is completely blank).
    # This only seems to happen in certain views, but adding a brief sleep
    # seems to fix it - maybe things are going out of scope before Mechanize has
    # finished its work?
    sleep 3; # Extended to allow timeline to render
    unlink $filename;
    return $mech;
}

sub _data_graph
{   my $id = shift;
    my $user    = logged_in_user;
    my $layout  = var 'layout';
    my $view    = current_view($user, $layout);
    my $records = GADS::RecordsGraph->new(
        user                => $user,
        search              => session('search'),
        view_limit_extra_id => current_view_limit_extra_id($user, $layout),
        rewind              => session('rewind'),
        layout              => $layout,
        schema              => schema,
    );
    GADS::Graph::Data->new(
        id      => $id,
        records => $records,
        schema  => schema,
        view    => $view,
    );
}

sub _process_edit
{   my ($id, $record) = @_;

    my $user   = logged_in_user;
    my %params = (
        user   => $user,
        schema => schema,
    );
    $params{layout} = var('layout') if var('layout'); # Used when creating a new record

    my $layout;

    if (my $delete_id = param 'delete')
    {
        if (process( sub { $record->delete_current }))
        {
            return forwardHome(
                { success => 'Record has been deleted successfully' }, $record->layout->identifier.'/data' );
        }
    }

    if ($id && $record)
    {
        $layout = $record->layout;
    }
    elsif ($id)
    {
        $record = GADS::Record->new(%params);
        my $include_draft = defined(param 'include_draft') ? $user->id : undef;
        $record->find_current_id($id, include_draft => $include_draft);
        $layout = $record->layout;
        var 'layout' => $layout;
    }
    else {
        # New record
        # var 'layout' will be set for new record due to URL
        $layout = $params{layout} = var('layout');
        $record = GADS::Record->new(%params);
        $record->initialise unless $id;
    }

    my $child = param('child') || $record->parent_id;

    my $modal = param('modal') && int param('modal');
    my $oi = param('oi') && int param('oi');
    my $clone_from = $layout->no_copy_record ? undef : param('from');


    if (param('submit') || param('draft') || $modal || defined(param 'validate'))
    {
        my $failed;

        error __"You do not have permission to create a child record"
            if $child && !$id && !$layout->user_can('create_child');
        $record->parent_id($child);

        # We actually only need the write columns for this. The read-only
        # columns can be ignored, but if we do write them, an error will be
        # thrown to the user if they've been changed. This is better than
        # just silently ignoring them, IMHO.
        my @display_on_fields;
        my @validation_errors;
        foreach my $col ($record->edit_columns(new => !$id, modal => $modal))
        {
            my $newv;
            if ($modal)
            {
                next unless defined query_parameters->get($col->field);
                $newv = [query_parameters->get_all($col->field)];
            }
            else {
                next unless defined body_parameters->get($col->field);
                $newv = [body_parameters->get_all($col->field)];
            }
            if ($col->userinput && defined $newv) # Not calculated fields
            {
                # No need to do anything if the file's just been uploaded
                my $datum = $record->fields->{$col->id};
                if (defined(param 'validate'))
                {
                    try { $datum->set_value($newv) };
                    if (my $e = $@->wasFatal)
                    {
                        push @validation_errors, $e->reason eq 'PANIC' ? 'An unexpected error occurred' : $e->message;
                    }
                }
                else {
                    $failed = !process( sub { $datum->set_value($newv) } ) || $failed;
                }
            }
        }

        if (defined(param 'validate'))
        {
            # The "source" parameter is user input, make sure still valid
            my $source_curval = $layout->column(param('source'), permission => 'read');
            try { $record->write(dry_run => 1, parent_curval => $source_curval) };
            if (my $e = $@->wasFatal)
            {
                push @validation_errors, $e->reason eq 'PANIC' ? 'An unexpected error occurred' : $e->message;
            }
            my $message = join '; ', @validation_errors;
            content_type 'application/json; charset="utf-8"';
            my $return = encode_json ({
                error   => $message ? 1 : 0,
                message => $message,
                # Send values back to browser to display on main record. Only
                # include ones that user has access to
                values  => +{ map { $_->field => $record->fields->{$_->id}->as_string } @{$source_curval->curval_fields} },
            });
            return ($return, undef, 1);
        }
        elsif ($modal)
        {
            # Do nothing, just a live edit, no write required
        }
        elsif (param 'draft')
        {
            if (process sub { $record->write(draft => 1, submission_token => param('submission_token')) })
            {
                return forwardHome(
                    { success => 'Draft has been saved successfully'}, $layout->identifier.'/data' );
            }
            elsif ($record->already_submitted_error)
            {
                return forwardHome(undef, $layout->identifier.'/data');
            }
        }
        elsif (!$failed)
        {
            if (process( sub { $record->write(submission_token => param('submission_token')) }))
            {
                my $forward = (!$id && $layout->forward_record_after_create) || param('submit') eq 'submit-and-remain'
                    ? 'record/'.$record->current_id
                    : $layout->identifier.'/data';
                return forwardHome(
                    { success => 'Submission has been completed successfully for record ID '.$record->current_id }, $forward );
            }
            elsif ($record->already_submitted_error)
            {
                return forwardHome(undef, $layout->identifier.'/data');
            }
        }
    }
    elsif($id) {
        # Do nothing, record already loaded
    }
    elsif ($clone_from)
    {
        my $toclone = GADS::Record->new(
            user   => $user,
            layout => $layout,
            schema => schema,
        );
        $toclone->find_current_id($clone_from);
        $record = $toclone->clone;
    }
    else {
        $record->load_remembered_values;
    }

    if (param 'delete_draft')
    {
        $layout = var('layout');
        if (process( sub { $record->delete_user_drafts }))
        {
            return forwardHome(
                { success => 'Draft has been deleted successfully' }, $layout->identifier.'/data' );
        }
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

    notice __"Values entered on this page will have their own value in the child "
            ."record. All other values will be inherited from the parent."
            if $child_rec;

    my $breadcrumbs = [Crumb($layout), Crumb( $layout, "/data" => 'records' )];
    if ($id)
    {
        push @$breadcrumbs, Crumb( "/record/$id" => "record $id" );
    }
    else {
        push @$breadcrumbs, Crumb( $layout, "/record/" => "new record" );
    }

    my $params = {
        edit_modal          => $modal,
        page                => 'edit',
        child               => $child_rec,
        layout_edit         => $layout,
        clone               => $clone_from,
        submission_token    => !$modal && $record->submission_token,
        breadcrumbs         => $breadcrumbs,
        record              => $record->presentation(edit => 1, new => !$id, child => $child, modal => $modal),
    };

    $params->{modal_field_ids} = encode_json $layout->column($modal)->curval_field_ids
        if $modal;

    my $options = $modal ? { layout => undef } : {};

    return ($params, $options);

}

true;
