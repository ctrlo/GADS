package GADS::MFA;

use DateTime;
use Session::Token;

use Dancer2 appname => 'GADS';
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport 'linkspace';

hook before => sub {

    if (my $user = logged_in_user())
    {
        my $mfa_cookie = cookie 'MFATOKEN';
        # MFA needed before access?
        redirect '/mfa' if request->uri !~ m!^/(mfa|logout)$!
            && $user->need_mfa && !$user->recent_mfa($mfa_cookie);
        # Prevent user being suddenly forced to enter MFA whilst logged in and
        # using the application. This continuously refreshes the recent MFA
        # cookie, as long it hasn't already expired (as per check above). This
        # means that whilst logged-in the user will not need to refresh it, as
        # it will always be recent. However, if they logout and remain
        # logged-out after the "recent" expiry, they will be forced to
        # re-enter.
        _refresh_recent_mfa_cookie($mfa_cookie->value)
            if $mfa_cookie;
    }

};

any ['get', 'post'] => '/mfa' => require_login sub {

    my $schema  = schema;
    my $user    = logged_in_user;

    $user->need_mfa
        or return redirect '/';

    my $params = {};

    if ($user->need_mfa_setup)
    {
        # Does user need to choose their MFA?
        if (!$user->mfa_type_effective)
        {
            if (my $submitted = body_parameters->get('choose_mfa'))
            {
                $user->update({ mfa_type => $submitted });
            }
            else {
                $params->{choose_mfa} = 1;
            }
        }
        if ($user->mfa_type_effective)
        {
            if ($user->mfa_type_effective eq 'otp')
            {
                # At this stage, we need to ensure the user can successfully
                # generate an OTP token before saving it persistently to the
                # database. Store in the session initially, and then once it is
                # correct save to their login
                my $key = session('otp_key') || $user->seed_key;
                session 'otp_key' => $key;
                if (my $submitted = body_parameters->get('get_key'))
                {
                    if ($user->check_token($submitted, $key))
                    {
                        $user->update({
                            mfa_secret => $key,
                        });
                        success __"Key has been added successfully";
                        redirect '/mfa/';
                    }
                    error __"Incorrect key submitted";
                }
                $params->{qr}        = $user->key_qr_base64($key);
                $params->{key}       = $key;
                $params->{setup_mfa} = 'otp';
            }
            elsif ($user->mfa_type_effective eq 'yub')
            {
                # For Yubikey we simply make sure we have a valid key before saving
                if (my $submitted = body_parameters->get('get_key'))
                {
                    if (my $yubi_id = $user->get_yubikey($submitted))
                    {
                        $user->update({
                            mfa_secret => $yubi_id,
                        });
                        success __"Key has been added successfully";
                        redirect '/mfa/';
                    }
                    error __"Incorrect key submitted";
                }
                $params->{setup_mfa} = 'yub';
            }
            elsif ($user->mfa_type_effective eq 'sms')
            {
                if (body_parameters->get('mobile'))
                {
                    # Mobile number submitted for update
                    if (my $mobile = body_parameters->get('mobile'))
                    {
                        if (process sub { $user->update({ mobile => $mobile }) })
                        {
                            success __"Mobile number has been added successfully";
                            redirect '/mfa/';
                        }
                    }
                    else {
                        $params->{get_mobile} = 1;
                    }
                }
                elsif (body_parameters->get('sms-not-received'))
                {
                    notice __"Please re-enter your mobile number and try again";
                    $user->update({ mobile => undef });
                    redirect '/mfa/';
                }
                elsif (my $token = body_parameters->get('token'))
                {
                    if ($user->verify_mobile($token))
                    {
                        success __"Mobile number has been verified successfully";
                        # Also use this token as a valid MFA validation and log the
                        # user straight in. Otherwise they would need to go through
                        # the same process again for the MFA token
                        return _mfa_token_success($user, $token); # Redirects
                    }
                    else {
                        report {is_fatal=>0}, ERROR => __"The token entered was not valid. Please re-enter your mobile number.";
                        redirect '/mfa/';
                    }
                }

                $params->{setup_mfa} = 'sms';
            }
            else {
                panic "Unexpected MFA type: ".$user->mfa_type_effective;
            }
        }
    }
    else {
        # Ask user to authenticate
        if (my $token = body_parameters->get('token'))
        {
            # Check for brute-force lockout
            if ($user->mfa_failcount > 5 && $user->mfa_lastfail->add(minutes => 15) > DateTime->now)
            {
                error __"Multi-factor authentication is currently unavailable, please try again shortly.";
            }
            # Submitted token correct?
            elsif ($user->check_token($token))
            {
                return _mfa_token_success($user, $token); # Redirects
            }
            else {
                # Failure, will be prompted again
                report WARNING => __"Incorrect or invalid token entered";
                $user->update({
                    mfa_failcount => $user->mfa_failcount + 1,
                    mfa_lastfail  => DateTime->now,
                });
            }
        }
        $user->send_mfa_sms
            if $user->mfa_type_effective eq 'sms';
        $params->{mfa_type} = $user->mfa_type_effective;
        $params->{get_code} = 1;
    }

    template 'mfa', $params;
};

sub _mfa_token_success
{   my ($user, $token) = @_;
    # Has the same token already been used recently, maybe by
    # an attacker, so warn user
    warning "The authentication token has already been used in the last 5 minutes, possibly an attacker?"
        if $user->mfa_token_previous && $user->mfa_token_previous eq $token
            && $user->mfa_token_previous_used->clone->add(minutes => 5) > DateTime->now;
    # Allow a token to be reused. Generate a random token and
    # store it in both a cookie and the database, to check for
    # validity and stop it being faked
    my $key = Session::Token->new(length => 32)->get;
    $user->update({
        mfa_failcount           => 0,
        mfa_lastfail            => undef,
        mfa_token_previous      => $token,
        mfa_token_previous_type => $user->mfa_type_effective,
        mfa_token_previous_used => DateTime->now,
        mfa_token_previous_key  => $key,
    });
    _refresh_recent_mfa_cookie($key);
    return redirect '/';
}

sub _refresh_recent_mfa_cookie
{   my $key = shift;
    cookie MFATOKEN => $key, expires => '7d', secure => 1, http_only => 1;
}

1;
