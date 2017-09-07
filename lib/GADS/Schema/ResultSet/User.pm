package GADS::Schema::ResultSet::User;

use strict;
use warnings;

use GADS::Audit;
use GADS::Config;
use GADS::Email;
use GADS::Users;
use GADS::Util;
use Log::Report;
use Session::Token;
use Text::CSV;

use base qw(DBIx::Class::ResultSet);

sub active
{   my ($self, %search) = @_;

    $self->search({
        account_request => 0,
        deleted         => undef,
        %search,
    });
}

sub create_user
{   my ($self, %params) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    error __"An email address must be specified for the user"
        if !$params{email};

    error __"Please enter a valid email address for the new user"
        if !GADS::Util->email_valid($params{email});

    error __x"User {email} already exists", email => $params{email}
        if $self->active(email => $params{email})->count;

    my $code         = Session::Token->new( length => 32 )->get;
    my $request_base = $params{request_base};

    my $user = $self->create({
        username => $params{username},
        resetpw  => $code,
    });

    my $audit = GADS::Audit->new(schema => $self->result_source->schema, user => $params{current_user});

    $audit->login_change(
        __x"User created, id: {id}, username: {username}",
            id => $user->id, username => $params{username}
    );

    $user->update_user(%params);

    # Delete account request user if this is a new account request
    if (my $id = $params{account_request})
    {
        $self->find($id)->delete;
    }

    # Email user welcome email
    my $config      = GADS::Config->instance->config;
    my $name        = $config->{gads}->{name};
    my $url         = $request_base . "resetpw/$code";
    my $new_account = $config->{gads}->{new_account};
    my $subject     = $new_account && $new_account->{subject}
        || "Your new account details";
    my $body = $new_account && $new_account->{body} || <<__BODY;

An account for $name has been created for you. Please
click on the following link to retrieve your password:

[URL]
__BODY

    $body =~ s/\Q[URL]/$url/;

    my $email = GADS::Email->instance;
    $email->send({
        subject => $subject,
        text    => $body,
        emails  => [$params{email}],
    });

    $guard->commit;

    return $user;
}

sub upload
{   my ($self, $file, %options) = @_;

    my $csv = Text::CSV->new({ binary => 1 }) # should set binary attribute?
        or error "Cannot use CSV: ".Text::CSV->error_diag ();

    my $userso = GADS::Users->new(schema => $self->result_source->schema);
    my $fh     = $file->file_handle;

    # Get first row for column headings
    my $row = $csv->getline($fh);
    # Valid headings
    my %user_fields = map { lc $_ => 1 } @{$userso->user_fields};
    my %user_mapping;
    my @invalid;
    my $count = 0;
    foreach (@$row)
    {
        if ($user_fields{lc $_})
        {
            $user_mapping{lc $_} = $count;
        }
        else {
            push @invalid, $_;
        }
        $count++;
    }

    if (@invalid)
    {
        my $invalid = join ', ', @invalid;
        error __x"The following column headings were found which are invalid: {invalid}",
            invalid => $invalid;
    }

    defined $user_mapping{email}
        or error __"There must be an email column in the uploaded CSV";

    my $site = $self->result_source->schema->resultset('Site')->next;
    my $freetext1 = lc $site->register_freetext1_name;
    my $freetext2 = lc $site->register_freetext2_name;
    my $org_name  = lc $site->register_organisation_name;

    # Map out titles and organisations for conversion to ID
    my %titles        = map { lc $_->name => $_->id } @{$userso->titles};
    my %organisations = map { lc $_->name => $_->id } @{$userso->organisations};

    $count = 0; my @errors;
    while (my $row = $csv->getline($fh))
    {
        my $org_id;
        if (defined $user_mapping{$org_name})
        {
            my $name = $row->[$user_mapping{$org_name}];
            $org_id  = $organisations{lc $name};
            mistake __x"Organisation name {org} not found", org => $name
                if !$org_id;
        }
        my $title_id;
        if (defined $user_mapping{title})
        {
            my $name  = $row->{$user_mapping{title}};
            $title_id = $titles{lc $name};
            mistake __x"Organisation name {org} not found", org => $name
                if !$title_id;
        }
        my %values = (
            firstname             => defined $user_mapping{forename} ? $row->[$user_mapping{forename}] : '',
            surname               => defined $user_mapping{surname} ? $row->[$user_mapping{surname}] : '',
            email                 => defined $user_mapping{email} ? $row->[$user_mapping{email}] : '',
            username              => defined $user_mapping{email} ? $row->[$user_mapping{email}] : '',
            freetext1             => defined $user_mapping{$freetext1} ? $row->[$user_mapping{$freetext1}] : '',
            freetext2             => defined $user_mapping{$freetext2} ? $row->[$user_mapping{$freetext2}] : '',
            title                 => defined $user_mapping{title} ? $row->[$user_mapping{title}] : '',
            organisation          => $org_id,
            view_limits           => $options{view_limits},
            groups                => $options{groups},
            permissions           => $options{permissions},
        );
        $values{value} = _user_value(\%values);

        try { $self->create_user(current_user => $options{current_user}, request_base => $options{request_base}, %values) };
        if ($@)
        {
            # ->wasFatal returns the trace message from the DBIC rollback
            my ($error) = grep { $_->isFatal } $@->exceptions;
            push @errors, {
                row   => join (',', @$row),
                error => $error,
            };
        }
        else {
            $count++;
        }
    }

    +{
        count  => $count,
        errors => \@errors,
    }
}

sub _user_value
{   my $user = shift;
    return unless $user;
    my $firstname = $user->{firstname} || '';
    my $surname   = $user->{surname}   || '';
    my $value     = "$surname, $firstname";
    $value;
}

1;
