=pod
GADS - Globally Accessible Data Store
Copyright (C) 2018 Ctrl O Ltd

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

package GADS::API;

use Crypt::SaltedHash;
use MIME::Base64 qw/decode_base64/;
use Net::OAuth2::AuthorizationServer::PasswordGrant;
use Session::Token;
use JSON qw(decode_json encode_json);
use POSIX qw(ceil);

use Dancer2 appname => 'GADS';
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport 'linkspace';

# Special error handler for JSON requests (as used in API)
fatal_handler sub {
    my ($dsl, $msg, $reason) = @_;
    return unless $dsl && $dsl->app->request && $dsl->app->request->uri =~ m!^/([0-9a-z]+/)?api/!i;
    my $is_exception = $reason eq 'PANIC';
    status $is_exception ? 'Internal Server Error' : 'Bad Request';
    $dsl->send_as(JSON => {
        is_error => \1,
        message  => $is_exception ? 'An unexexpected error has occurred' : $msg->toString },
    { content_type => 'application/json; charset=UTF-8' });
};

my $verify_user_password_sub = sub {
    my %args = @_;

    my $client = schema->resultset('Oauthclient')->search({
        client_id     => $args{client_id},
        client_secret => $args{client_secret},
    })->next
        or return (0, 'unauthorized_client');

    my $user = schema->resultset('User')->active->search({
        username => $args{username},
    })->next;

    $user && Crypt::SaltedHash->validate($user->password, $args{password})
        and return ($client->id, undef, undef, $user->id);

    return (0, 'access_denied');
};

my $store_access_token_sub = sub {
    my %args = @_;

    if (my $old_refresh_token = $args{old_refresh_token})
    {
        my $prev_rt = schema->resultset('Oauthtoken')->refresh_token($old_refresh_token);
        my $prev_at = schema->resultset('Oauthtoken')->access_token($prev_rt->related_token);
        $prev_at->delete;
    }

    # if the client has en existing refresh token we need to revoke it
    schema->resultset('Oauthtoken')->search({
        type           => 'refresh',
        oauthclient_id => $args{client_id},
        user_id        => $args{user_id},
    })->delete;

    my $access_token  = $args{access_token};
    my $refresh_token = $args{refresh_token};

    schema->resultset('Oauthtoken')->create({
        type           => 'access',
        token          => $access_token,
        expires        => time + $args{expires_in},
        related_token  => $refresh_token,
        oauthclient_id => $args{client_id},
        user_id        => $args{user_id},
    });

    schema->resultset('Oauthtoken')->create({
        type           => 'refresh',
        token          => $refresh_token,
        related_token  => $access_token,
        oauthclient_id => $args{client_id},
        user_id        => $args{user_id},
    });
};

my $verify_access_token_sub = sub {
    my %args = @_;

    my $access_token = $args{access_token};

    my $rt = schema->resultset('Oauthtoken')->refresh_token($access_token);
    return $rt
        if $args{is_refresh_token} && $rt;

    if (my $at = schema->resultset('Oauthtoken')->access_token($access_token))
    {
        if ( $at->expires <= time ) {
            # need to revoke the access token
            $at->delete;
        }
        else {
            return $at;
        }
    }

    return (0, 'invalid_grant');
};

my $Grant = Net::OAuth2::AuthorizationServer::PasswordGrant->new(
    verify_user_password_cb => $verify_user_password_sub,
    store_access_token_cb   => $store_access_token_sub,
    verify_access_token_cb  => $verify_access_token_sub,
);

hook before => sub {
    my ($client, $error) = $Grant->verify_token_and_scope(
        auth_header => request->header('authorization') || undef, # Otherwise treated as array
    );
    if ($client)
    {
        var api_user => $client->user;
    }
};

sub require_api_user {
    my $route = shift;
    return sub {
        return $route->()
            if var('api_user');
        status('Forbidden');
        error "Authentication needed to access this resource";
    };
};

sub _update_record
{   my ($record, $request) = @_;
    foreach my $field (keys %$request)
    {
        my $col = $record->layout->column_by_name_short($field)
            or error __x"Column not found: {name}", name => $field;
        $record->fields->{$col->id}->set_value($request->{$field});
    }
    $record->write; # borks on error
};

# Create new record
post '/api/:sheet/record' => require_api_user sub {

    my $sheetname = param 'sheet';
    my $layout    = var('instances')->layout_by_shortname($sheetname); # borks on not found
    my $user      = var('api_user');

    my $request = decode_json request->body;

    error "Invalid field: id; Use the PUT method to update an existing record"
        if exists $request->{id};

    my $record = GADS::Record->new(
        user   => $user,
        layout => $layout,
        schema => schema,
    );

    $record->initialise;

    _update_record($record, $request);

    status 'Created';
    header 'Location' => request->base.'record/'.$record->current_id;

    return;
};

# Edit existing record or new record with non-Linkspace index ID
put '/api/:sheet/record/:id' => require_api_user sub {

    my $sheetname = param 'sheet';
    my $layout    = var('instances')->layout_by_shortname($sheetname); # borks on not found
    my $user      = var('api_user');
    my $id        = param 'id';

    my $request = decode_json request->body;

    my $record_find = GADS::Record->new(
        user   => $user,
        layout => $layout,
        schema => schema,
    );
    my $record_to_update;

    if (my $api_index = $layout->api_index_layout)
    {
        $record_to_update = $record_find->find_unique($api_index, $id);
        if (!$record_to_update)
        {
            $record_to_update = GADS::Record->new(
                user   => $user,
                layout => $layout,
                schema => schema,
            );
            $record_to_update->initialise;
            $request->{$api_index->name_short} = $id;
        }
    }
    else {
        $record_to_update = $record_find->find_serial_id($id);
    }

    _update_record($record_to_update, $request);

    status 'No Content';
    # Use supplied ID for return - will either have been created as that or
    # will have borked early with error and not got here
    header 'Location' => request->base."record/$id";

    return;
};

# Get existing record - table serial identifier
get '/api/:sheet/record/:id' => require_api_user sub {

    my $sheetname = param 'sheet';
    my $layout    = var('instances')->layout_by_shortname($sheetname); # borks on not found
    my $user      = var('api_user');
    my $id        = param 'id';

    my $record = GADS::Record->new(
        user   => $user,
        layout => $layout,
        schema => schema,
    );
    if (my $api_index = $layout->api_index_layout)
    {
        $record = $record->find_unique($api_index, $id)
            or error __x"Record ID {id} not found", id => $id; # XXX Would be nice to reuse GADS::Record error
        $record->find_current_id($record->current_id);
    }
    else {
        $record->find_serial_id($id);
    }

    content_type 'application/json; charset=UTF-8';
    return $record->as_json;
};

# Get existing record - using record ID
get '/api/record/:id' => require_api_user sub {

    my $user      = var('api_user');
    my $id        = param 'id';

    my $record = GADS::Record->new(
        user   => $user,
        schema => schema,
    );
    $record->find_serial_id($id);

    content_type 'application/json; charset=UTF-8';
    return $record->as_json;
};

# Get existing record - using record ID
get '/api/:sheet/records/view/:id' => require_api_user sub {

    my $sheetname = param 'sheet';
    my $user      = var('api_user');
    my $view_id   = route_parameters->get('id');
    my $layout    = var('instances')->layout_by_shortname($sheetname); # borks on not found

    my $view = GADS::View->new(
        id                       => $view_id,
        instance_id              => $layout->instance_id,
        schema                   => schema,
        layout                   => $layout,
    );
    $view->exists
        or error __x"View id {id} not found", id => $view_id;

    my $records = GADS::Records->new(
        user   => $user,
        schema => schema,
        view   => $view,
        rows   => 100,
        page   => query_parameters->get('page') || 1,
        layout => $layout,
    );

    my @return;
    foreach my $rec (@{$records->results})
    {
        push @return, $rec->as_json($view);
    }

    content_type 'application/json; charset=UTF-8';
    return encode_json \@return;
};

get '/clientcredentials/?' => require_any_role [qw/superadmin/] => sub {

    my $credentials = rset('Oauthclient')->next;
    $credentials ||= rset('Oauthclient')->create({
        client_id     => Session::Token->new( length => 12 )->get,
        client_secret => Session::Token->new( length => 12 )->get,
    });

    return template 'api/clientcredentials' => {
        credentials => $credentials,
    };
};

post '/api/token' => sub {

    my ($client_id_submit, $client_secret);

    # RFC6749 says try auth header first, then fall back to body params
    if (my $auth = request->header('authorization'))
    {
        if (my ($encoded) = split 'Basic ', $auth)
        {
            if (my $decoded = decode_base64 $encoded)
            {
                ($client_id_submit, $client_secret) = split ':', $decoded;
            }
        }
    }
    else {
        $client_id_submit = param 'client_id';
        $client_secret    = param 'client_secret';
    }

    my ($client_id, $error, $scopes, $user_id, $json_response, $old_refresh_token);

    my $grant_type = param 'grant_type';

    if ($grant_type eq 'password')
    {
        ($client_id, $error, $scopes, $user_id) = $Grant->verify_user_password
        (
            client_id     => $client_id_submit,
            client_secret => $client_secret,
            username      => param('username'),
            password      => param('password'),
        );
    }
    elsif ($grant_type eq 'refresh_token')
    {
        my $refresh_token = param 'refresh_token';
        ($client_id, $error, $scopes, $user_id) = $Grant->verify_token_and_scope(
            refresh_token => $refresh_token,
            auth_header   => request->header('authorization'),
        );
        $old_refresh_token = $refresh_token;
    }
    else {
        $json_response = {
            error             => 'invalid_request',
            error_description => "Invalid grant type: ".param('grant_type'),
        };
    }

    if ($client_id)
    {
        my $access_token = $Grant->token(
            client_id  => param('client_id'),
            type       => 'access',
        );

        my $refresh_token = $Grant->token(
            client_id => param('client_id'),
            type      => 'refresh', # one of: access, refresh
        );

        my $expires_in = $Grant->access_token_ttl;

        $Grant->store_access_token(
          user_id           => $user_id,
          client_id         => $client_id,
          access_token      => $access_token,
          expires_in        => $expires_in,
          refresh_token     => $refresh_token,
          old_refresh_token => $old_refresh_token,
        );

        $json_response = {
            access_token  => $access_token,
            token_type    => 'Bearer',
            expires_in    => $expires_in,
            refresh_token => $refresh_token,
        };
    }
    elsif (!$json_response) {
        $json_response = {
            error => $error,
        };
    }

    header "Cache-Control" => 'no-store';
    header "Pragma"        => 'no-cache';
    content_type 'application/json;charset=UTF-8';

    return encode_json $json_response;
};

prefix '/:layout_name' => sub {

    get '/api/field/values/:id' => require_login sub {

        my $user   = logged_in_user;
        my $layout = var('layout') or pass;
        my $col_id = route_parameters->get('id');
        my $submission_token = query_parameters->get('submission-token')
            or panic "Submission ID missing";

        my $curval = $layout->column($col_id);

        my $record = GADS::Record->new(
            user   => $user,
            layout => $layout,
            schema => schema,
        );
        $record->initialise;

        try {
            foreach my $col (@{$curval->subvals_input_required})
            {
                my @vals = grep { $_ } query_parameters->get_all($col->field);
                my $datum = $record->fields->{$col->id};
                $datum->set_value(\@vals);
            }
            $record->write(
                dry_run           => 1,
                missing_not_fatal => 1,
                submitted_fields  => $curval->subvals_input_required,
                submission_token  => $submission_token,
            );
        } # Missing values are reporting as non-fatal errors, and would therefore
          # not be caught by the try block and would be reported as normal (including
          # to the message session). We need to hide these and report them now.
          hide => 'ERROR';

        # See whether any unexpected exceptions first, and if so throw them
        if (my ($fatal) = grep { $_->isFatal && $_->reason ne 'ERROR' } $@->exceptions)
        {
            $fatal->throw;
        }
        # Otherwise report any normal errors back to the caller
        elsif (my @excps = grep { $_->reason eq 'ERROR' } $@->exceptions)
        {
            my $msg = join ', ', map { $_->message->toString } @excps;
            return encode_json { error => 1, message => $msg };
        }

        return encode_json {
            "error"  => 0,
            "records"=> [
                map { +{ id => $_->{id}, label => $_->{value} } } @{$curval->filtered_values($submission_token)}
            ]
        };
    };

    post '/api/dashboard/:dashboard_id/widget' => require_login sub {
        my $layout = var('layout') or pass;
        _post_dashboard_widget($layout);
    };

    put '/api/dashboard/:dashboard_id/dashboard/:id' => require_login sub {
        my $layout = var('layout') or pass;
        _put_dashboard_dashboard($layout);
    };

    get '/api/dashboard/:dashboard_id/widget/:id' => require_login sub {
        my $layout = var('layout') or pass;
        _get_dashboard_widget($layout);
    };

    get '/api/dashboard/:dashboard_id/widget/:id/edit' => require_login sub {
        my $layout = var('layout') or pass;
        _get_dashboard_widget_edit($layout);
    };

    put '/api/dashboard/:dashboard_id/widget/:id/edit' => require_login sub {
        my $layout = var('layout') or pass;
        _put_dashboard_widget_edit($layout);
    };

    del '/api/dashboard/:dashboard_id/widget/:id' => require_login sub {
        my $layout = var('layout') or pass;
        _del_dashboard_widget($layout);
    };
};

# Same as prefix routes above, but without layout identifier - these are for
# site dashboard configuration
post '/api/dashboard/:dashboard_id/widget' => require_login sub {
    _post_dashboard_widget();
};

put '/api/dashboard/:dashboard_id/dashboard/:id' => require_login sub {
    _put_dashboard_dashboard();
};

get '/api/dashboard/:dashboard_id/widget/:id' => require_login sub {
    _get_dashboard_widget();
};

get '/api/dashboard/:dashboard_id/widget/:id/edit' => require_login sub {
    _get_dashboard_widget_edit();
};

put '/api/dashboard/:dashboard_id/widget/:id/edit' => require_login sub {
    _put_dashboard_widget_edit();
};

del '/api/dashboard/:dashboard_id/widget/:id' => require_login sub {
    _del_dashboard_widget();
};

# Wizard endpoints
post '/api/user_account/?:id?' => require_login sub {
    _post_add_user_account();
};

post '/api/user_account_request/:id' => require_login sub {
    _post_request_account();
};

post '/api/table_request' => require_login sub {
    _post_table_request();
};

get '/api/:sheet/records' => require_login sub {
    _get_records();
};

sub _post_dashboard_widget {
    my $layout = shift;
    my $user   = logged_in_user;

    my $type = query_parameters->get('type');

    # Check access
    my $dashboard = _get_dashboard_write(route_parameters->get('dashboard_id'), $layout, $user);

    my $content = "This is a new notice widget - click edit to update the contents";
    my $widget = schema->resultset('Widget')->create({
        dashboard_id => $dashboard->id,
        type         => $type,
        content      => $type eq 'notice' ? $content : undef,
    });

    return _success($widget->grid_id);
}

sub _put_dashboard_dashboard {
    my $layout = shift;
    my $user   = logged_in_user;
    return  _update_dashboard($layout, $user);
}

sub _get_dashboard_widget {
    my $layout = shift;
    my $user   = logged_in_user;
    # _get_widget will raise an exception if it does not exist
    return  _get_widget(route_parameters->get('id'), route_parameters->get('dashboard_id'), $layout, $user)->html;
}

sub _get_dashboard_widget_edit {
    my $layout = shift;
    my $user   = logged_in_user;
    my $widget = _get_widget_write(route_parameters->get('id'), route_parameters->get('dashboard_id'), $layout, $user);

    my $params = {
        widget          => $widget,
        tl_options      => $widget->tl_options_inflated,
        globe_options   => $widget->globe_options_inflated,
    };

    unless ($widget->type eq 'notice')
    {
        my $views = GADS::Views->new(
            user          => $user,
            schema        => schema,
            layout        => $layout,
            instance_id   => $layout->instance_id,
        );
        $params->{user_views}   = $views->user_views;
        $params->{columns_read} = [$layout->all(user_can_read => 1)];
    }

    if ($widget->type eq 'graph')
    {
        my $graphs = GADS::Graphs->new(
            current_user => $user,
            schema       => schema,
            layout       => $layout,
        );
        $params->{graphs} = $graphs;
    }

    my $content = template 'widget' => $params, {
        layout => undef, # Do not render page header, footer etc
    };

    # Keep consistent with return type generated on error
    return encode_json {
        is_error => 0,
        content  => $content,
    };
}

sub _put_dashboard_widget_edit {
    my $layout = shift;
    my $user   = logged_in_user;
    my $widget = _get_widget_write(route_parameters->get('id'), route_parameters->get('dashboard_id'), $layout, $user);

    $widget->title(query_parameters->get('title'));
    $widget->static(query_parameters->get('static') ? 1 : 0)
        if $widget->dashboard->is_shared;
    if ($widget->type eq 'notice')
    {
        $widget->set_columns({
            content => query_parameters->get('content'),
        });
    }
    elsif ($widget->type eq 'graph')
    {
        $widget->set_columns({
            graph_id => query_parameters->get('graph_id'),
            view_id  => query_parameters->get('view_id'),
        });
    }
    elsif ($widget->type eq 'table')
    {
        $widget->set_columns({
            rows     => query_parameters->get('rows'),
            view_id  => query_parameters->get('view_id'),
        });
    }
    elsif ($widget->type eq 'timeline')
    {
        my $tl_options = {
            label   => query_parameters->get('tl_label'),
            group   => query_parameters->get('tl_group'),
            color   => query_parameters->get('tl_color'),
            overlay => query_parameters->get('tl_overlay'),
        };
        $widget->set_columns({
            tl_options => encode_json($tl_options),
            view_id    => query_parameters->get('view_id'),
        });
    }
    elsif ($widget->type eq 'globe')
    {
        my $globe_options = {
            label   => query_parameters->get('globe_label'),
            group   => query_parameters->get('globe_group'),
            color   => query_parameters->get('globe_color'),
        };
        $widget->set_columns({
            globe_options => encode_json($globe_options),
            view_id       => query_parameters->get('view_id'),
        });
    }
    $widget->update;

    return _success("Widget updated successfully");
}

sub _del_dashboard_widget {
    my $layout = shift;
    my $user   = logged_in_user;
    _get_widget_write(route_parameters->get('id'), route_parameters->get('dashboard_id'), $layout, $user)->delete;
    return _success("Widget deleted successfully");
}

sub _post_add_user_account
{   my $body = _decode_json_body();

    my $logged_in_user = logged_in_user;

    my $id = route_parameters->get('id');
    my $update_user;
    if ($id)
    {
        $update_user = schema->resultset('User')->find($id)
            or error __x"User id {id} not found", id => $id;
    }

    error __"Unauthorised access"
        unless $logged_in_user->permission->{superadmin} || $logged_in_user->permission->{useradmin};

    my %values = (
        firstname             => $body->{firstname},
        surname               => $body->{surname},
        email                 => $body->{email},
        username              => $body->{email},
        freetext1             => $body->{freetext1},
        freetext2             => $body->{freetext2},
        title                 => $body->{title},
        organisation          => $body->{organisation},
        department_id         => $body->{department_id},
        team_id               => $body->{team_id},
        account_request       => 0,
        account_request_notes => $body->{notes},
        view_limits           => $body->{view_limits},
        groups                => $body->{groups},
    );

    $values{permissions} = $body->{permissions}
        if $logged_in_user->permission->{superadmin};

    # Any exceptions/errors generated here will be automatically sent back as JSON error
    $id ? $update_user->update_user(%values, current_user => $logged_in_user)
        : schema->resultset('User')->create_user(%values, current_user => $logged_in_user, request_base => request->base);

    my $msg = __x"User {type} successfully", type => $id ? 'updated' : 'created';
    return _success("$msg");
}

sub _post_request_account {
    if (request->content_type ne 'application/json') # Try in body of JSON
    {
        return;
    }

    my $body = try { decode_json(request->body) };

    if (!$body)
    {
        return;
    }

    my %values = (
        firstname             => $body->{'firstname'},
        surname               => $body->{'surname'},
        email                 => $body->{'email'},
        username              => $body->{'email'},
        freetext1             => $body->{'freetext1'},
        freetext2             => $body->{'freetext2'},
        title                 => $body->{'title'} || undef,
        organisation          => $body->{'organisation'} || undef,
        department_id         => $body->{'department_id'} || undef,
        team_id               => $body->{'team_id'} || undef,
        account_request       => $body->{'approve-account'},
        account_request_notes => $body->{'notes'} || '',
        view_limits           => $body->{'view_limits'} || [],
        groups                => $body->{'groups'} || [],
    );

    if(logged_in_user->permission->{superadmin})
    {
        $values{permissions} = $body->{'permissions'} || [];
    }

    my $id = route_parameters->get('id');

    if (process sub {
        my $user = rset('User')->active->search({ id => $id })->next
            or error __x"User ID {id} not found", id => $id;
        # Don't use DBIC update directly, so that permissions etc are updated properly
        $user->update_user(current_user => logged_in_user, %values);
    }) {
        return _success("User updated successfully");
    }
}

sub _create_table
{   my $params = shift;

    my $guard = schema->txn_scope_guard;

    my $user = logged_in_user;
    my $table = GADS::Layout->new(
        user   => $user,
        schema => schema,
        config => config,
    );
    $table->name($params->{name});
    $table->name_short($params->{shortName});
    $table->hide_in_selector($params->{hide_in_selector});

    my @group_perms;
    foreach my $perm (@{$params->{table_permissions}})
    {
        my %pmap = (
                delete_records           => {
                    name => 'delete',
                    type => 'records',
                },
                purge_deleted_records    => {
                    name => 'purge',
                    type => 'records',
                },
                download_records         => {
                    name => 'download',
                    type => 'records',
                },
                bulk_import_records      => {
                    name => 'bulk_import',
                    type => 'records',
                },
                bulk_update_records      => {
                    name => 'bulk_update',
                    type => 'records',
                },
                bulk_delete_records      => {
                    name => 'bulk_delete',
                    type => 'records',
                },
                manage_linked_records    => {
                    name => 'link',
                    type => 'records',
                },
                manage_child_records     => {
                    name => 'create_child',
                    type => 'records',
                },
                manage_views             => {
                    name => 'view_create',
                    type => 'views',
                },
                manage_group_views       => {
                    name => 'view_group',
                    type => 'views',
                },
                select_extra_view_limits => {
                    name => 'view_limit_extra',
                    type => 'views',
                },
                manage_fields            => {
                    name => 'layout',
                    type => 'fields',
                },
        );
        my $group_id = $perm->{group_id};
        foreach my $key (keys %pmap)
        {
            my $type = $pmap{$key}->{type};
            my $name = $pmap{$key}->{name};
            push @group_perms, "${group_id}_$name"
                if $perm->{$type}->{$key};
        }
    }
    $table->set_groups(\@group_perms);
    $table->write;

    my %topics;
    foreach my $top (@{$params->{topics}})
    {
        my $topic = schema->resultset('Topic')->new({ instance_id => $table->instance_id });
        $topic->name($top->{name});
        $topic->description($top->{description});
        $topic->initial_state($top->{expanded} ? 'open' : 'collapsed');
        $topic->insert;
        $topics{$top->{tempId}} = $topic;
    }

    my %fields;
    foreach my $f (@{$params->{fields}})
    {
        my %args = (
            type   => $f->{field_type},
            schema => schema,
            user   => $user,
            layout => $table,
        );
        my $field = $f->{field_type} eq 'string'
            ? GADS::Column::String->new(%args)
            : $f->{field_type} eq 'intgr'
            ? GADS::Column::Intgr->new(%args)
            : $f->{field_type} eq 'date'
            ? GADS::Column::Date->new(%args)
            : $f->{field_type} eq 'daterange'
            ? GADS::Column::Daterange->new(%args)
            : $f->{field_type} eq 'enum'
            ? GADS::Column::Enum->new(%args)
            : $f->{field_type} eq 'tree'
            ? GADS::Column::Tree->new(%args)
            : $f->{field_type} eq 'file'
            ? GADS::Column::File->new(%args)
            : $f->{field_type} eq 'person'
            ? GADS::Column::Person->new(%args)
            : $f->{field_type} eq 'rag'
            ? GADS::Column::Rag->new(%args)
            : $f->{field_type} eq 'calc'
            ? GADS::Column::Calc->new(%args)
            : $f->{field_type} eq 'curval'
            ? GADS::Column::Curval->new(%args)
            : $f->{field_type} eq 'autocur'
            ? GADS::Column::Autocur->new(%args)
            : $f->{field_type} eq 'filval'
            ? GADS::Column::Filval->new(%args)
            : error(__x"Invalid field type: {type}", type => $f->{field_type});
        $field->name($f->{name});
        $field->type($f->{field_type});
        $field->optional($f->{optional});

        if ($f->{topic_tempid}) {
            $field->topic_id($topics{$f->{topic_tempid}}->id);
        }

        # Permissions
        my %permissions;
        foreach my $perm (@{$f->{custom_field_permissions}})
        {
            my $group_id = $perm->{group_id};
            $permissions{$group_id} ||= [];
            # Approval permissions to be added later
            foreach my $p (qw/create read update/)
            {
                if ($perm->{permissions}->{create})
                {
                    push @{$permissions{$group_id}}, 'write_new';
                }
                if ($perm->{permissions}->{read})
                {
                    push @{$permissions{$group_id}}, 'read';
                }
                if ($perm->{permissions}->{update})
                {
                    push @{$permissions{$group_id}}, 'write_existing';
                }
            }
        }
        $field->set_permissions(\%permissions);

        my $settings = $f->{field_type_settings};
        if ($field->type eq 'string')
        {
            $field->textbox($f->{field_type_settings}->{textbox});
            $field->force_regex($f->{field_type_settings}->{force_regex});
        }
        elsif ($field->type eq 'intgr')
        {
            $field->show_calculator($f->{field_type_settings}->{show_calculator});
        }
        elsif ($field->type eq 'date')
        {
            $field->show_datepicker($f->{field_type_settings}->{show_datepicker});
            $field->default_today($f->{field_type_settings}->{default_today});
        }
        elsif ($field->type eq 'daterange')
        {
            $field->show_datepicker($f->{field_type_settings}->{show_datepicker});
        }
        elsif ($field->type eq 'enum')
        {
            $field->enumvals({
                enumvals    => [map $_->{enumval}, @{$f->{field_type_settings}->{dropdown_values}}],
                enumval_ids => [],
            });
            $field->ordering($f->{field_type_settings}->{ordering} || undef);
        }
        elsif ($field->type eq 'tree')
        {
            $field->end_node_only($f->{field_type_settings}->{end_node_only});
        }
        elsif ($field->type eq 'file')
        {
            $field->filesize($f->{field_type_settings}->{filesize} || undef);
        }
        elsif ($field->type eq 'person')
        {
            $field->default_to_login($f->{field_type_settings}->{default_to_login});
            $field->notify_on_selection($f->{field_type_settings}->{notify_on_selection});
            $field->notify_on_selection_message($f->{field_type_settings}->{notify_on_selection_message});
            $field->notify_on_selection_subject($f->{field_type_settings}->{notify_on_selection_subject});
        }
        elsif ($field->type eq 'rag')
        {
            $field->code($f->{field_type_settings}->{code_rag});
        }
        elsif ($field->type eq 'calc')
        {
            $field->code($f->{field_type_settings}->{code_calc});
            $field->return_type($f->{field_type_settings}->{return_type});
            $field->show_in_edit($f->{field_type_settings}->{show_in_edit});
        }
        elsif ($field->type eq 'curval')
        {
            $field->refers_to_instance_id($settings->{refers_to_instance_id});
            # $column->filter->as_json($f->{field_type_settings});
            $field->curval_field_ids($settings->{curval_field_ids});
            $field->override_permissions($settings->{override_permissions});
            $field->value_selector($settings->{value_selector});
            $field->show_add($settings->{show_add});
            $field->delete_not_used($settings->{delete_not_used});
            $field->limit_rows($settings->{limit_rows});
        }
        elsif ($field->type eq 'autocur')
        {
            $field->curval_field_ids($settings->{curval_field_ids});
            $field->related_field_id($settings->{related_field_id});
        }
        elsif ($field->type eq 'filval')
        {
            $field->curval_field_ids($settings->{curval_field_ids});
            $field->related_field_id($settings->{filval_related_field_id});
        }
        else {
            panic __x"Unexpected field type: {type}", type => $field->type;
        }

        $field->write(no_alerts => 1, no_cache_update => 1);

        # ID needs to be set before writing tree
        if ($field->type eq 'tree')
        {
            $field->update($settings->{dataJson});
        }

        $fields{$f->{tempId}} = $field;
    }

    $guard->commit;
};

sub _post_table_request {

    error __"Body content must be application/json"
        if request->content_type ne 'application/json';

    my $body = try { decode_json(request->body) }
        or error __"No body content received";

    logged_in_user->permission->{superadmin}
        or error __"You must be a super-administrator to create tables";

    if (process sub { _create_table($body) } )
    {
        return _success("Table created successfully");
    }
}

# XXX Copied from GADS.pm
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

sub _get_records {

    my $sheetname = param 'sheet';
    my $user      = logged_in_user;
    my $layout    = var('instances')->layout_by_shortname($sheetname); # borks on not found
    my $view      = current_view($user, $layout);

    # Need to build records first, so that we can access rendered column
    # information (not necessarily same as view columns)
    my $start  = query_parameters->get('start') || 0;
    my $length = query_parameters->get('length') || 25;
    my $records = GADS::Records->new(
        user   => $user,
        schema => schema,
        view   => $view,
        rows   => $length,
        page   => 1 + ceil($start / $length),
        layout => $layout,
    );

    # Look for column filters
    my @additional_filters;
    foreach my $key (query_parameters->keys)
    {
        # E.g. 'columns[1][search][value]' => 'my_search'
        next unless $key =~ /^columns\[([0-9]+)\Q][search][value]\E$/;
        my $index = $1;
        my $search = query_parameters->get($key)
            or next;
        my $col = $records->columns_render->[$index]
            or next;
        my @values = query_parameters->get_all($key);
        push @additional_filters, {
            id    => $col->id,
            value => [$search],
        };
    }
    $records->additional_filters(\@additional_filters);

    if (my $search = query_parameters->get('search[value]'))
    {
        $search =~ s/\h+$//;
        $search =~ s/^\h+//;
        $records->search("*$search*");
    }

    # Configure table sort
    my $order_index = query_parameters->get('order[0][column]');
    my $col_order   = $records->columns_render->[$order_index];
    # Check user has access
    error __"Invalid column ID for sort"
        unless $col_order && $col_order->user_can('read');
    my $sort = { type => query_parameters->get('order[0][dir]'), id => $col_order->id };

    $records->clear_sorts;
    $records->sort($sort);

    my $return = {
        draw            => query_parameters->get('draw'),
        recordsTotal    => $records->count,
        recordsFiltered => $records->count, # XXX update
        data            => [],
    };

    foreach my $rec (@{$records->results})
    {
        my $data;
        $data->{$_->name} = $rec->fields->{$_->id}->for_table
            foreach @{$records->columns_render};
        push @{$return->{data}}, $data;
    }

    content_type 'application/json; charset=UTF-8';
    return encode_json $return;
};

sub _get_widget_write
{   my ($widget_id, $dashboard_id, $layout, $user) = @_;
    my $widget = _get_widget($widget_id, $dashboard_id, $layout, $user);

    # Check write access to dashboard, borks on unauth
    _get_dashboard_write($widget->dashboard_id, $layout, $user);

    return $widget;
}

sub _get_widget
{   my ($widget_id, $dashboard_id, $layout, $user) = @_;
    my $widget = schema->resultset('Widget')->search({
        dashboard_id => $dashboard_id,
        grid_id      => route_parameters->get('id'),
    })->next;
    if (!$widget)
    {
        status 404;
        error __x"Widget ID {id} not found", id => $widget_id;
    }

    # Check access. Borks if no access
    _get_dashboard($widget->dashboard->id, $layout, $user);

    $widget->layout($layout);
    return $widget;
}

sub _get_dashboard
{   my ($id, $layout, $user) = @_;
    my $dashboard = schema->resultset('Dashboard')->find($id);
    if (!$dashboard)
    {
        status 404;
        error __x"Dashboard {id} not found", id => $id;
    }
    return $dashboard;
}

sub _get_dashboard_write
{   my ($id, $layout, $user) = @_;
    my $dashboard = _get_dashboard($id, $layout, $user);
    return $dashboard
        if logged_in_user->permission->{superadmin} # For site dashboard
            || ($layout && $layout->user_can('layout'));
    return $dashboard
        if $dashboard->user_id && $dashboard->user_id == $user->id;
    status 403;
    error __x"User does not have write access to dashboard ID {id}", id => $id;
}

sub _update_dashboard
{   my ($layout, $user) = @_;

    my $id = route_parameters->get('id');

    my $dashboard = _get_dashboard_write($id, $layout, $user);

    my $widgets = decode_json request->body;

    foreach my $widget (@$widgets)
    {
        # Static widgets added to personal dashboards will be passed in, but we
        # don't want to include these in the personal dashboard as they are
        # added anyway on dashboard render
        next if $widget->{static} && !$dashboard->is_shared;
        # Do not update widget static status, as this does not seem to be
        # passed in
        my $w = schema->resultset('Widget')->update_or_create({
            dashboard_id => $dashboard->id,
            grid_id      => $widget->{i},
            h            => $widget->{h},
            w            => $widget->{w},
            x            => $widget->{x},
            y            => $widget->{y},
        }, {
            key => 'widget_ux_dashboard_grid',
        });
    }

    return _success("Dashboard updated successfully");
}

sub _error
{
    my $code = shift || 500;
    my $msg  = shift || "Internal server error";

    status $code;
    error __x $msg;
}

sub _success
{   my $msg = shift;
    send_as JSON => {
        is_error => 0,
        message  => $msg,
    }, { content_type => 'application/json; charset=UTF-8' };
}

sub _decode_json_body
{   my $json = shift;

    error __"Request must be of type application/json"
        if request->content_type ne 'application/json';

    my $body = try { decode_json request->body }
        or error __"Failed to decode JSON";
    $body;
}

1;
