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

use Dancer2 appname => 'GADS';
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport 'linkspace';

# Special error handler for JSON requests (as used in API)
ctype_error_handler 'application/json' => sub {
    my ($dsl, $msg, $reason) = @_;
    status $reason eq 'PANIC' ? 'Internal Server Error' : 'Bad Request';
    $dsl->send_as(JSON => {
        error             => 1,
        error_description => $msg->toString },
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
        auth_header => request->header('authorization'),
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
post '/api/record/:sheet' => require_api_user sub {

    my $sheetname = param 'sheet';
    my $layout    = var('instances')->layout_by_shortname($sheetname); # borks on not found
    my $user      = var('api_user');

    my $request = decode_json request->body;

    error "Invalid field: id; Use the PUT method to update an existing record"
        if exists $request->{id};

    my $record = GADS::Record->new(
        user     => $user,
        layout   => $layout,
        schema   => schema,
        base_url => request->base,
    );

    $record->initialise;

    _update_record($record, $request);

    status 'Created';
    header 'Location' => request->base.'record/'.$record->current_id;

    return;
};

# Edit existing record
put '/api/record/:sheet/:id' => require_api_user sub {

    my $sheetname = param 'sheet';
    my $layout    = var('instances')->layout_by_shortname($sheetname); # borks on not found
    my $user      = var('api_user');

    my $request = decode_json request->body;

    my $record = GADS::Record->new(
        user     => $user,
        layout   => $layout,
        schema   => schema,
        base_url => request->base,
    );
    $record->find_current_id(param 'id');

    _update_record($record, $request);

    status 'No Content';
    header 'Location' => request->base.'record/'.$record->current_id;

    return;
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

1;
