package GADS::Schema::ResultSet::User;

use strict;
use warnings;

use DateTime;
use DateTime::Format::ISO8601;
use File::BOM qw( open_bom );
use GADS::Audit;
use GADS::Config;
use GADS::Email;
use GADS::Users;
use GADS::Util;
use Log::Report;
use Session::Token;
use Text::CSV;

use Moo;
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;

extends 'DBIx::Class::ResultSet';
with 'GADS::Helper::ConditionBuilder';

sub BUILDARGS { $_[2] || {} }

__PACKAGE__->load_components(qw(Helper::ResultSet::CorrelateRelationship));

sub active
{   my ($self, %search) = @_;

    $self->search({
        account_request => 0,
        'me.deleted'    => undef,
        %search,
    });
}

sub summary
{   my $self = shift;
    $self->active->search_rs({},{
        columns => [
            'me.id', 'me.surname', 'me.firstname', 'title.name', 'me.email',
            'organisation.name', 'department.name', 'team.name', 'me.created',
            'me.freetext1', 'me.freetext2',
            'me.lastlogin', 'me.value',
        ],
        join     => [
            'organisation', 'department', 'team', 'title',
        ],
        order_by => 'me.value',
        collapse => 1,
    });
}

sub active_and_requests
{   my ($self, %search) = @_;

    $self->search({
        'me.deleted'    => undef,
        %search,
    });
}

has valid_fields => (
    is => 'lazy',
);

sub _build_valid_fields
{   my $self = shift;
    my $site = $self->result_source->schema->resultset('Site')->next;
    my %fields = map { $_->{name} => $_ } $site->user_fields;
    \%fields;
}

sub rule_to_condition
{   my ($self, $rule) = @_;

    my ($field_name, $operator, $value) = ($rule->{field}, $rule->{operator}, $rule->{value});

    # Check valid value
    my $field = $self->valid_fields->{$field_name}
        or error __x"Invalid user field {field}", field => $field_name;

    my $mappedOperator = $self->field_map->{$operator};
    my $mappedValue    = $self->get_filter_value($operator, $value);

    return (
        $field->{table} ? "$field->{table}.$field->{field}" : $field->{name} => { $mappedOperator => $mappedValue },
    );
}

sub with_filter
{   my ($self, $filter) = @_;
    $filter or return $self;
    $self->search_rs({$self->map_rules($filter->as_hash)});
}

sub create_user
{   my ($self, %params) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    my $site = $self->result_source->schema->resultset('Site')->next;

    error __"An email address must be specified for the user"
        if !$params{email};
    panic "username is no longer accepted for create_user - use email instead"
        if $params{username};

    error __x"User {email} already exists", email => $params{email}
        if $self->active(email => $params{email})->count;

    my $code         = Session::Token->new( length => 32 )->get;
    my $request_base = $params{request_base};

    my $user = $self->create({
        email                 => $params{email},
        username              => $params{email},
        resetpw               => $code,
        created               => DateTime->now,
        account_request_notes => $params{notes},
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

    $guard->commit;

    $user->send_welcome_email(%params, code => $code)
        unless $params{no_welcome_email};

    return $user;
}

sub upload
{   my ($self, $file, %options) = @_;

    $file or error __"Please select a file to upload";

    my $fh;
    # Use Open::BOM to deal with BOM files being imported
    try { open_bom($fh, $file) }; # Can raise various exceptions which would cause panic
    error __"Unable to open CSV file for reading: ".$@->wasFatal->message if $@; # Make any error user friendly

    my $schema = $self->result_source->schema;
    my $guard  = $schema->txn_scope_guard;

    my $csv = Text::CSV->new({ binary => 1 }) # should set binary attribute?
        or error "Cannot use CSV: ".Text::CSV->error_diag ();

    my $userso = GADS::Users->new(schema => $schema);
    my $site   = $schema->resultset('Site')->next;

    # Get first row for column headings
    my $row = $csv->getline($fh);
    # Valid headings
    my %user_fields = map { lc $_->{description} => 1 } $site->user_fields;
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
        my $invalid = join ', ', map qq("$_"), @invalid;
        my $valid = join ', ', keys %user_fields;
        error __x"The following column headings were found which are invalid: {invalid}. "
            ."Only the following fields can be used: {valid}",
                invalid => $invalid, valid => $valid;
    }

    defined $user_mapping{'email address'}
        or error __"There must be an email address column in the uploaded CSV";

    my $freetext1 = lc $site->register_freetext1_name;
    my $freetext2 = lc $site->register_freetext2_name;
    my $org_name  = lc $site->organisation_name;
    my $dep_name  = lc $site->department_name;
    my $team_name = lc $site->team_name;

    # Map out titles and organisations for conversion to ID
    my %titles        = map { lc $_->name => $_->id } $schema->resultset('Title')->ordered->all;
    my %organisations = map { lc $_->name => $_->id } $schema->resultset('Organisation')->ordered->all;
    my %departments   = map { lc $_->name => $_->id } $schema->resultset('Department')->ordered->all;
    my %teams         = map { lc $_->name => $_->id } $schema->resultset('Team')->ordered->all;

    $count = 0; my @errors;
    my @welcome_emails;
    while (my $row = $csv->getline($fh))
    {
        my $org_id;
        if (defined $user_mapping{$org_name})
        {
            my $name = $row->[$user_mapping{$org_name}];
            $org_id  = $organisations{lc $name};
            push @errors, {
                row   => join (',', @$row),
                error => qq($org_name "$name" not found),
            } if !$org_id;
        }
        my $dep_id;
        if (defined $user_mapping{$dep_name})
        {
            my $name = $row->[$user_mapping{$dep_name}];
            $dep_id  = $departments{lc $name};
            push @errors, {
                row   => join (',', @$row),
                error => qq($dep_name "$name" not found),
            } if !$dep_id;
        }
        my $team_id;
        if (defined $user_mapping{$team_name})
        {
            my $name = $row->[$user_mapping{$team_name}];
            $team_id = $teams{lc $name};
            push @errors, {
                row   => join (',', @$row),
                error => qq($team_name "$name" not found),
            } if !$team_id;
        }
        my $title_id;
        if (defined $user_mapping{title})
        {
            my $name  = $row->[$user_mapping{title}];
            $title_id = $titles{lc $name};
            push @errors, {
                row   => join (',', @$row),
                error => qq(Title "$name" not found),
            } if !$title_id;
        }
        my %values = (
            firstname             => defined $user_mapping{forename} ? $row->[$user_mapping{forename}] : '',
            surname               => defined $user_mapping{surname} ? $row->[$user_mapping{surname}] : '',
            email                 => defined $user_mapping{'email address'} ? $row->[$user_mapping{'email address'}] : '',
            freetext1             => defined $user_mapping{$freetext1} ? $row->[$user_mapping{$freetext1}] : '',
            freetext2             => defined $user_mapping{$freetext2} ? $row->[$user_mapping{$freetext2}] : '',
            title                 => $title_id,
            organisation          => $org_id,
            department_id         => $dep_id,
            team_id               => $team_id,
            view_limits           => $options{view_limits},
            groups                => $options{groups},
            permissions           => $options{permissions},
        );
        $values{value} = _user_value(\%values);

        my $u = try { $self->create_user(
            current_user     => $options{current_user},
            request_base     => $options{request_base},
            no_welcome_email => 1, # Send at end in case of failures
            %values);
        };
        if($@)
        {   push @errors, {
                row   => join (',', @$row),
                error => $@->wasFatal,
            };
        }
        else
        {   $values{code} = $u->resetpw,
            $count++;
        }

        push @welcome_emails, $u
            unless @errors; # No point collecting if we're not going to send
    }

    if (@errors)
    {
        my @e = map { "$_->{row} ($_->{error})" } @errors;
        error __x"The upload failed with errors on the following lines: {errors}",
            errors => join '; ', @e;
    }

    # Won't get this far if we have any errors in the previous statement
    $guard->commit;

    $_->send_welcome_email(code=>$_->resetpw, request_base => $options{request_base})
        foreach @welcome_emails;

    $count;
}

sub match
{   my ($self, $query) = @_;

    my @ids;

    $query = "%$query%";

    my $result = $self->active->search([
        firstname => { -like => $query },
        surname   => { -like => $query },
        email     => { -like => $query },
        username  => { -like => $query },
    ],{
        columns => [qw/id firstname surname username/],
    });

    return map {
        +{
            id   => $_->id,
            name => $_->surname.", ".$_->firstname." (".$_->username.")",
        }
    } $result->all;
}

sub _user_value
{   my $user = shift;
    return unless $user;
    my $firstname = $user->{firstname} || '';
    my $surname   = $user->{surname}   || '';
    my $value     = "$surname, $firstname";
    $value;
}

sub import_hash
{   my ($self, $user) = @_;

    my $u = !$user->{deleted} && $self->active(email => $user->{email})->next;

    if (!$u)
    {
        $u = $self->create({
            firstname             => $user->{firstname},
            surname               => $user->{surname},
            value                 => $user->{value},
            email                 => $user->{email},
            username              => $user->{username},
            freetext1             => $user->{freetext1},
            freetext2             => $user->{freetext2},
            password              => $user->{password},
            pwchanged             => $user->{pwchanged} && DateTime::Format::ISO8601->parse_datetime($user->{pwchanged}),
            deleted               => $user->{deleted} && DateTime::Format::ISO8601->parse_datetime($user->{deleted}),
            lastlogin             => $user->{lastlogin} && DateTime::Format::ISO8601->parse_datetime($user->{lastlogin}),
            account_request       => $user->{account_request},
            account_request_notes => $user->{account_request_notes},
            created               => $user->{created} && DateTime::Format::ISO8601->parse_datetime($user->{created}),
        });
    }

    $u->groups(undef, $user->{groups});
    $u->permissions(@{$user->{permissions}});

    return $u;
}

1;
