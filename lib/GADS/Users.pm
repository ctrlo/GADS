=pod
GADS - Globally Accessible Data Store
Copyright (C) 2014 Ctrl O Ltd

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

package GADS::Users;

use GADS::Email;
use GADS::Util;
use Log::Report 'linkspace';
use POSIX ();
use Scope::Guard qw(guard);
use Text::CSV;
use GADS::Helper::ConditionBuilder;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has filter => (
    is => 'ro',
);

has schema => (
    is       => 'ro',
    required => 1,
);

has config => (
    is       => 'ro',
);

has all => (
    is  => 'lazy',
    isa => ArrayRef,
);

has all_admins => (
    is  => 'lazy',
    isa => ArrayRef,
);

has titles => (
    is  => 'lazy',
    isa => ArrayRef,
);

has organisations => (
    is  => 'lazy',
    isa => ArrayRef,
);

has departments => (
    is  => 'lazy',
    isa => ArrayRef,
);

has teams => (
    is  => 'lazy',
    isa => ArrayRef,
);

has permissions => (
    is  => 'lazy',
    isa => ArrayRef,
);

has register_requests => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub user_rs
{   my $self = shift;
    $self->schema->resultset('User')->active;
}

sub user_summary_rs
{   my $self = shift;
    $self->user_rs->search_rs({},{
        columns => [
            'me.id', 'me.surname', 'me.firstname', 'title.name', 'me.email',
            'organisation.name', 'department.name', 'team.name', 'me.created',
            'me.freetext1', 'me.freetext2',
            'me.lastlogin', 'me.value',
        ],
        join     => [
            'organisation', 'department', 'team', 'title',
        ],
        order_by => 'surname',
        collapse => 1,
    });
}

sub _build_all
{   my $self = shift;
    my $users = $self->user_summary_rs->with_filter($self->filter);
    [$users->all];
}

sub user_exists
{   my ($self, $email) = @_;
    $self->user_rs->search({ email => $email })->count;
}

sub all_in_org
{   my ($self, $org_id) = @_;
    my $search = {
    };
    my @users = $self->schema->resultset('User')->search({
        deleted         => undef,
        account_request => 0,
        organisation    => $org_id,
    })->all;
    \@users;
}

sub all_in_groups
{   my ($self, $group_ids) = @_;
    my @users = $self->user_rs->search({
        'user_groups.group_id' => $group_ids,
    },{
        join     => 'user_groups',
        collapse => 1,
    })->all;
    \@users;
}

sub _build_all_admins
{   my $self = shift;
    my $search = {
        deleted           => undef,
        account_request   => 0,
        'permission.name' => 'useradmin',
    };
    my @users = $self->schema->resultset('User')->search($search,{
        join     => { user_permissions => 'permission' },
        order_by => 'surname',
        collapse => 1,
    })->all;
    \@users;
}

sub _build_titles
{   my $self = shift;
    my @titles = $self->schema->resultset('Title')->ordered->all;
    [map {+{label_plain => $_->name, value => $_->id}} @titles];
}

sub _build_organisations
{   my $self = shift;
    my @organisations = $self->schema->resultset('Organisation')->ordered->all;
    [map {+{label_plain => $_->name, value => $_->id}} @organisations];
}

sub _build_departments
{   my $self = shift;
    my @departments = $self->schema->resultset('Department')->ordered->all;
    [map {+{label_plain => $_->name, value => $_->id}} @departments];
}

sub _build_teams
{   my $self = shift;
    my @teams = $self->schema->resultset('Team')->ordered->all;
    [map {+{label_plain => $_->name, value => $_->id}} @teams];
}

sub _build_permissions
{   my $self = shift;
    my @permissions = $self->schema->resultset('Permission')->search({},{
        order_by => 'order',
    })->all;
    \@permissions;
}

sub _build_register_requests
{   my $self = shift;
    my @users = $self->schema->resultset('User')->search({ account_request => 1 })->all;
    \@users;
}

sub title_new
{   my ($self, $params) = @_;
    $self->schema->resultset('Title')->create({ name => $params->{name} });
}

sub organisation_new
{   my ($self, $params) = @_;
    $self->schema->resultset('Organisation')->create({ name => $params->{name} });
}

sub department_new
{   my ($self, $params) = @_;
    $self->schema->resultset('Department')->create({ name => $params->{name} });
}

sub team_new
{   my ($self, $params) = @_;
    $self->schema->resultset('Team')->create({ name => $params->{name} });
}

sub register
{   my ($self, $params) = @_;

    my %new;
    my %params = %$params;

    my $site = $self->schema->resultset('Site')->next;

    error __"Please enter a valid email address"
        unless GADS::Util->email_valid($params{email});

    my @fields = qw(firstname surname email account_request_notes);
    push @fields, 'organisation' if $site->register_show_organisation;
    push @fields, 'department_id' if $site->register_show_department;
    push @fields, 'team_id' if $site->register_show_team;
    push @fields, 'title' if $site->register_show_title;
    push @fields, 'freetext1' if $site->register_freetext1_name;
    push @fields, 'freetext2' if $site->register_freetext2_name;
    @new{@fields} = @params{@fields};
    $new{firstname} = ucfirst $new{firstname};
    $new{surname} = ucfirst $new{surname};
    $new{username} = $params->{email};
    $new{account_request} = 1;
    $new{freetext1} or delete $new{freetext1};
    $new{freetext2} or delete $new{freetext2};
    $new{title} or delete $new{title};
    $new{organisation} or delete $new{organisation};
    $new{department_id} or delete $new{department_id};
    $new{team_id} or delete $new{team_id};

    my $user;
    try { $user = $self->schema->resultset('User')->create(\%new) };
    if(my $exception = $@->wasFatal)
    {
        # For some reason, exceptions in the create() above are thrown as ERROR
        $exception->throw(reason => 'PANIC');
    }
    $user->discard_changes; # Ensure that relations such as department() are resolved

    # Email admins with account request
    my $admins = $self->all_admins;
    my @emails = map { $_->email } @$admins;
    my $text;
    $text = "A new account request has been received from the following person:\n\n";
    $text .= "First name: $new{firstname}, ";
    $text .= "surname: $new{surname}, ";
    $text .= "email: $new{email}, ";
    $text .= "title: ".$user->title->name.", " if $user && $user->title;
    $text .= $site->register_freetext1_name.": $new{freetext1}, " if $new{freetext1};
    $text .= $site->register_freetext2_name.": $new{freetext2}, " if $new{freetext2};
    $text .= $site->register_organisation_name.": ".$user->organisation->name.", " if $user && $user->organisation;
    $text .= $site->register_department_name.": ".$user->department->name.", " if $user && $user->department;
    $text .= $site->register_team_name.": ".$user->team->name.", " if $user && $user->team;
    $text .= "\n\n";
    $text .= "User notes: $new{account_request_notes}\n";
    my $config = $self->config
        or panic "Config needs to be defined";
    my $email = GADS::Email->instance;
    $email->send({
        emails  => \@emails,
        subject => "New account request",
        text    => $text,
    });
}

sub csv
{   my ($self, $user) = @_;

    my $export = $self->schema->resultset('Export')->create({
        user_id => $user->id,
        type    => 'users',
        started => DateTime->now,
    });

    if (my $kid = fork)
    {
        # will fire off a worker and then abandon it, thus making reaping
        # the long running process (the grndkid) init's (pid1) problem
        waitpid($kid, 0); # wait for child to start grandchild and clean up
    }
    else {
        if (my $grandkid = fork) {
            POSIX::_exit(0); # the child dies here
        }
        else {
            # We must catch exceptions here, otherwise we will never
            # reap the process. Set up a guard to be doubly-sure this
            # happens.
            my $guard = guard { POSIX::_exit(0) };
            # Despite the guard, we still operate in a try block, so as to catch
            # the messages from any exceptions and report them accordingly.
            # Only collect messages at warning or higher, otherwise
            # thousands of trace messages are stored which use lots of
            # memory.
            try { $self->_produce_csv($user, $export) } hide => 'ALL', accept => 'WARNING-'; # This takes a long time
            if ($@)
            {
                $@->reportAll(is_fatal => 0);
                my $result = $@ && $@->wasFatal->message;
                # If produce_csv failed during the update of the export row,
                # then it will still have the unwritten changes and another
                # update will cause the same problem. Therefore, discard any
                # changes before trying another update.
                $export->discard_changes;
                $export->update({ result => 'Failed', result_internal => $result, completed => DateTime->now });
            }
        }
    }
}

sub _produce_csv
{   my ($self, $user, $export) = @_;
    my $csv  = Text::CSV->new({ binary => 1 });

    my $instances = GADS::Instances->new(schema => $self->schema, user => $user);
    my $site = $self->schema->resultset('Site')->find($self->schema->site_id);

    # Column names
    my @columns = qw/ID Surname Forename Email Lastlogin Created/;
    push @columns, 'Title' if $site->register_show_title;
    push @columns, 'Organisation' if $site->register_show_organisation;
    push @columns, $site->department_name if $site->register_show_department;
    push @columns, $site->team_name if $site->register_show_team;
    push @columns, $site->register_freetext1_name if $site->register_freetext1_name;
    push @columns, $site->register_freetext2_name if $site->register_freetext2_name;
    push @columns, 'Notes', 'Permissions', 'Groups';
    push @columns, 'Page hits last month';
    push @columns, 'Last hit to table "'.$_->name.'"' foreach @{$instances->all};

    $csv->combine(@columns)
        or error __x"An error occurred producing the CSV headings: {err}", err => $csv->error_input;
    my $csvout = $csv->string."\n";

    # Need to run this query as 2 separate queries. Running them as one query
    # takes far too long on a system with a lot of users

    my @common_columns = (
        {
            max => 'me.id',
            -as => 'id_max',
        },
        {
            max => 'surname',
            -as => 'surname_max',
        },
    );

    # All the data values
    my @select_columns = (
        {
            max => 'firstname',
            -as => 'firstname_max',
        },
        {
            max => 'email',
            -as => 'email_max',
        },
        {
            max => 'lastlogin',
            -as => 'lastlogin_max',
        },
        {
            max => 'created',
            -as => 'created_max',
        },
        {
            max => 'title.name',
            -as => 'title_max',
        },
        {
            max => 'organisation.name',
            -as => 'organisation_max',
        },
        {
            max => 'department.name',
            -as => 'department_max',
        },
        {
            max => 'team.name',
            -as => 'team_max',
        },
        {
            max => 'freetext1',
            -as => 'freetext1_max',
        },
        {
            max => 'freetext2',
            -as => 'freetext2_max',
        },
        {
            max => 'account_request_notes',
            -as => 'account_request_notes_max',
        },
    );

    my @select_columns2 = (
        {
            count => 'audits_last_month.id',
            -as   => 'audit_count',
        },
    );

    my $guard = $self->schema->txn_scope_guard; # Try to ensure consistent data between queries

    push @select_columns, +{
        max => $self->schema->resultset('User')
            ->correlate('audits')
            ->search({ instance_id => $_->instance_id})
            ->get_column('datetime')
            ->max_rs->as_query,
        -as => 'last_'.$_->instance_id,
    } foreach @{$instances->all};

    my (@users, @users2);

    my $page = 1;
    while ($page)
    {
        my @ids = map $_->get_column('id_max'), $self->user_rs->search({},{
            select   => \@common_columns,
            page     => $page,
            rows     => 100,
            order_by => ['surname_max', 'id_max'],
            group_by => 'me.id',
        })->all;

        push @users, $self->user_rs->search({
            'me.id' => { -in => \@ids },
        },{
            select => [@common_columns, @select_columns],
            join   => [
                'organisation', 'department', 'team', 'title',
            ],
            order_by => ['surname_max', 'id_max'],
            group_by => 'me.id',
        })->all;

        push @users2, $self->user_rs->search({
            'me.id' => { -in => \@ids },
        },{
            select => [@common_columns, @select_columns2],
            join   => [
                'audits_last_month',
            ],
            order_by => ['surname_max', 'id_max'],
            group_by => 'me.id',
        })->all;

        $page = @ids == 100 ? $page + 1 : undef;
    }

    my %user_groups = map { $_->id => [$_->user_groups] }
        $self->user_rs->search({}, { prefetch => { user_groups => 'group' }})->all;

    my %user_permissions = map { $_->id => [$_->user_permissions] }
        $self->user_rs->search({}, { prefetch => { user_permissions => 'permission' }})->all;

    foreach my $user (@users)
    {
        my $user2 = shift @users2;

        # Make sure both queries are in sync
        my $surname = $user->get_column('surname_max');
        $surname eq $user2->get_column('surname_max')
            or panic "Sync problem with user download";

        my $id = $user->get_column('id_max');
        my @csv = (
            $id,
            $surname,
            $user->get_column('firstname_max'),
            $user->get_column('email_max'),
            $user->get_column('lastlogin_max'),
            $user->get_column('created_max'),
        );
        push @csv, $user->get_column('title_max') if $site->register_show_title;
        push @csv, $user->get_column('organisation_max') if $site->register_show_organisation;
        push @csv, $user->get_column('department_max') if $site->register_show_department;
        push @csv, $user->get_column('team_max') if $site->register_show_team;
        push @csv, $user->get_column('freetext1_max') if $site->register_freetext1_name;
        push @csv, $user->get_column('freetext2_max') if $site->register_freetext2_name;
        push @csv, $user->get_column('account_request_notes_max');
        push @csv, join '; ', map { $_->permission->description } @{$user_permissions{$id}};
        push @csv, join '; ', map { $_->group->name } @{$user_groups{$id}};
        push @csv, $user2->get_column('audit_count');
        push @csv, $user->get_column('last_'.$_->instance_id) foreach @{$instances->all};

        # Remove CSV vulberabilies for Excel. None of these characters should be
        # used in username properties
        @csv = map { $_ ? s/^[-+=@]+//r : '' } @csv;

        $csv->combine(@csv)
            or error __x"An error occurred producing a line of CSV: {err}",
                err => "".$csv->error_diag;
        $csvout .= $csv->string."\n";
    }

    $guard->commit;

    utf8::encode($csvout);
    $export->update({
        completed => DateTime->now,
        result    => 'Success',
        mimetype  => 'text/csv',
        content   => $csvout,
    });
}

1;

