use utf8;
package GADS::Schema::Result::User;

=head1 NAME

GADS::Schema::Result::User

=cut

use strict;
use warnings;

use DateTime;
use GADS::Audit;
use GADS::Config;
use GADS::Email;
use HTML::Entities qw/encode_entities/;
use Log::Report;
use Moo;

extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "+GADS::DBIC");

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 firstname

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 surname

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 email

  data_type: 'text'
  is_nullable: 1

=head2 username

  data_type: 'text'
  is_nullable: 1

=head2 title

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 organisation

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 department_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 team_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 freetext1

  data_type: 'text'
  is_nullable: 1

=head2 freetext2

  data_type: 'text'
  is_nullable: 1

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 pwchanged

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 resetpw

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 deleted

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 lastlogin

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 lastfail

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 failcount

  data_type: 'integer'
  is_nullable: 1

=head2 lastrecord

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 lastview

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 session_settings

  data_type: 'text'
  is_nullable: 1

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 account_request

  data_type: 'smallint'
  default_value: 0
  is_nullable: 1

=head2 account_request_notes

  data_type: 'text'
  is_nullable: 1

=head2 aup_accepted

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 limit_to_view

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 stylesheet

  data_type: 'text'
  is_nullable: 1

=head2 created

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 debug_login

  data_type: 'smallint'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "firstname",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "surname",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "email",
  { data_type => "text", is_nullable => 1 },
  "username",
  { data_type => "text", is_nullable => 1 },
  "title",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "organisation",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "department_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "team_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "freetext1",
  { data_type => "text", is_nullable => 1 },
  "freetext2",
  { data_type => "text", is_nullable => 1 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "pwchanged",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "resetpw",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "deleted",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "lastlogin",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "lastfail",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "failcount",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "lastrecord",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "lastview",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "session_settings",
  { data_type => "text", is_nullable => 1 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "account_request",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "account_request_notes",
  { data_type => "text", is_nullable => 1 },
  "aup_accepted",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "limit_to_view",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "stylesheet",
  { data_type => "text", is_nullable => 1 },
  "created",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "debug_login",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 alerts

Type: has_many

Related object: L<GADS::Schema::Result::Alert>

=cut

__PACKAGE__->has_many(
  "alerts",
  "GADS::Schema::Result::Alert",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 audits

Type: has_many

Related object: L<GADS::Schema::Result::Audit>

=cut

__PACKAGE__->has_many(
  "audits",
  "GADS::Schema::Result::Audit",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "audits_last_month",
    "GADS::Schema::Result::Audit",
    sub {
        my $args = shift;
        my $schema    = $args->{self_resultsource}->schema;
        my $month     = DateTime->now->subtract(months => 1);
        my $formatted = $schema->storage->datetime_parser->format_date($month);
        +{
            "$args->{foreign_alias}.user_id"  => { -ident => "$args->{self_alias}.id" },
            "$args->{foreign_alias}.datetime" => { '>'    => $formatted },
        };
    }
);

=head2 lastrecord

Type: belongs_to

Related object: L<GADS::Schema::Result::Record>

=cut

__PACKAGE__->belongs_to(
  "lastrecord",
  "GADS::Schema::Result::Record",
  { id => "lastrecord" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 lastview

Type: belongs_to

Related object: L<GADS::Schema::Result::View>

=cut

__PACKAGE__->belongs_to(
  "lastview",
  "GADS::Schema::Result::View",
  { id => "lastview" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 limit_to_view

Type: belongs_to

Related object: L<GADS::Schema::Result::View>

=cut

__PACKAGE__->belongs_to(
  "limit_to_view",
  "GADS::Schema::Result::View",
  { id => "limit_to_view" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 organisation

Type: belongs_to

Related object: L<GADS::Schema::Result::Organisation>

=cut

__PACKAGE__->belongs_to(
  "organisation",
  "GADS::Schema::Result::Organisation",
  { id => "organisation" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 department

Type: belongs_to

Related object: L<GADS::Schema::Result::Department>

=cut

__PACKAGE__->belongs_to(
  "department",
  "GADS::Schema::Result::Department",
  { id => "department_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 team

Type: belongs_to

Related object: L<GADS::Schema::Result::Team>

=cut

__PACKAGE__->belongs_to(
  "team",
  "GADS::Schema::Result::Team",
  { id => "team_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 site

Type: belongs_to

Related object: L<GADS::Schema::Result::Site>

=cut

__PACKAGE__->belongs_to(
  "site",
  "GADS::Schema::Result::Site",
  { id => "site_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 people

Type: has_many

Related object: L<GADS::Schema::Result::Person>

=cut

__PACKAGE__->has_many(
  "people",
  "GADS::Schema::Result::Person",
  { "foreign.value" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 view_limits

Type: has_many

Related object: L<GADS::Schema::Result::ViewLimit>

=cut

__PACKAGE__->has_many(
  "view_limits",
  "GADS::Schema::Result::ViewLimit",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 record_approvedbies

Type: has_many

Related object: L<GADS::Schema::Result::Record>

=cut

__PACKAGE__->has_many(
  "record_approvedbies",
  "GADS::Schema::Result::Record",
  { "foreign.approvedby" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 record_createdbies

Type: has_many

Related object: L<GADS::Schema::Result::Record>

=cut

__PACKAGE__->has_many(
  "record_createdbies",
  "GADS::Schema::Result::Record",
  { "foreign.createdby" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "current_deletedbies",
  "GADS::Schema::Result::Current",
  { "foreign.deletedby" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 imports

Type: has_many

Related object: L<GADS::Schema::Result::Import>

=cut

__PACKAGE__->has_many(
  "imports",
  "GADS::Schema::Result::Import",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 title

Type: belongs_to

Related object: L<GADS::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title",
  "GADS::Schema::Result::Title",
  { id => "title" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 user_graphs

Type: has_many

Related object: L<GADS::Schema::Result::UserGraph>

=cut

__PACKAGE__->has_many(
  "user_graphs",
  "GADS::Schema::Result::UserGraph",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_groups

Type: has_many

Related object: L<GADS::Schema::Result::UserGroup>

=cut

__PACKAGE__->has_many(
  "user_groups",
  "GADS::Schema::Result::UserGroup",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# Groups that this user should be able to see for the purposes of things like
# creating shared graphs
sub groups_viewable
{   my $self = shift;

    my $schema = $self->result_source->schema;

    # Superadmin, all groups
    if ($self->permission->{superadmin})
    {
        return $schema->resultset('Group')->all;
    }

    my %groups;

    # Layout admin, just groups in their layout(s)
    my $instance_ids = $schema->resultset('InstanceGroup')->search({
        'me.permission'       => 'layout',
        'user_groups.user_id' => $self->id,
    },{
        join => {
            group => 'user_groups',
        },
    })->get_column('me.instance_id');

    $groups{$_->group_id} = $_->group foreach $schema->resultset('LayoutGroup')->search({
        instance_id => { -in => $instance_ids->as_query },
    },{
        join => 'layout',
    })->all;

    # Normal users, just their groups
    $groups{$_->group_id} = $_->group foreach $self->user_groups;

    return values %groups;
}

=head2 user_lastrecords

Type: has_many

Related object: L<GADS::Schema::Result::UserLastrecord>

=cut

__PACKAGE__->has_many(
  "user_lastrecords",
  "GADS::Schema::Result::UserLastrecord",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_permissions

Type: has_many

Related object: L<GADS::Schema::Result::UserPermission>

=cut

__PACKAGE__->has_many(
  "user_permissions",
  "GADS::Schema::Result::UserPermission",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 views

Type: has_many

Related object: L<GADS::Schema::Result::View>

=cut

__PACKAGE__->has_many(
  "views",
  "GADS::Schema::Result::View",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "views_created",
  "GADS::Schema::Result::View",
  { "foreign.createdby" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'user_idx_value', fields => [ { name => 'value', prefix_length => 64 } ]);
    $sqlt_table->add_index(name => 'user_idx_email', fields => [ { name => 'email', prefix_length => 64 } ]);
    $sqlt_table->add_index(name => 'user_idx_username', fields => [ { name => 'username', prefix_length => 64 } ]);
}

has view_limits_with_blank => (
    is      => 'lazy',
    clearer => 1,
);

# Used to ensure an empty selector is available in the user edit page
sub _build_view_limits_with_blank
{   my $self = shift;
    return [$self->view_limits->all] if $self->view_limits->count;
    return [undef];
}

sub set_view_limits
{   my ($self, $view_ids) = @_;

    # remove blank string from form
    my @view_ids = grep { $_ } @$view_ids;

    foreach my $view_id (@view_ids)
    {
        $self->find_or_create_related('view_limits', { view_id => $view_id });
    }

    # Delete any groups that no longer exist
    my $search = {};
    $search->{view_id} = {
        '!=' => [ -and => @view_ids ]
    } if @view_ids;
    $self->search_related('view_limits', $search)->delete;
    # Rebuild view limits in case of form submission failures (see same
    # comments as permissions0
    $self->clear_view_limits_with_blank;
    $self->view_limits_with_blank;
}

sub graphs
{   my ($self, $instance_id, $graphs) = @_;

    ref $graphs eq 'ARRAY' or panic "Invalid call to graphs";

    foreach my $g (@$graphs)
    {
        unless($self->search_related('user_graphs', { graph_id => $g })->count)
        {
            $self->create_related('user_graphs', { graph_id => $g });
        }
    }

    # Delete any graphs that no longer exist
    my $search = { 'graph.instance_id' => $instance_id };
    $search->{graph_id} = {
        '!=' => [ -and => @$graphs ]
    } if @$graphs;
    $self->search_related('user_graphs', $search, { join => 'graph' })->delete;
}

# Used to check if a user has a group
has has_group => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_has_group
{   my $self = shift;
    +{
        map { $_->group_id => 1 } $self->user_groups
    };
}

sub groups
{   my ($self, $logged_in_user, $groups) = @_;

    if (!$logged_in_user && !$groups)
    {
        # Just return current value
        return map { $_->group } $self->user_groups;
    }

    foreach my $g (@$groups)
    {
        next unless !$logged_in_user || $logged_in_user->permission->{superadmin} || $logged_in_user->has_group->{$g};
        $self->find_or_create_related('user_groups', { group_id => $g });
    }

    # Delete any groups that no longer exist
    my @allowed = map { $_->id }  grep { !$logged_in_user || $logged_in_user->permission->{superadmin} || $logged_in_user->has_group->{$_->id} }
        $self->result_source->schema->resultset('Group')->all;

    my $search = {};
    $search->{group_id} = {
        '!=' => [ -and => @$groups ]
    } if @$groups;
    $self->search_related('user_groups', $search)->search({ group_id => [@allowed] })->delete;
}

# Used to check if a user has a permission
has permission => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_permission
{   my $self = shift;
    my %all = map { $_->id => $_->name } $self->result_source->schema->resultset('Permission')->all;
    +{
        map { $all{$_->permission_id} => 1 } $self->user_permissions
    };
}

sub value_html
{   my $self = shift;
    encode_entities $self->value;
}

sub update_user
{   my ($self, %params) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    my $current_user = delete $params{current_user}
        or panic "Current user not defined on user update";

    # Set null values where required for database insertions
    delete $params{organisation} if !$params{organisation};
    delete $params{department_id} if !$params{department_id};
    delete $params{team_id} if !$params{team_id};
    delete $params{title} if !$params{title};

    my $site = $self->result_source->schema->resultset('Site')->next;

    my $values = {
        account_request_notes => $params{account_request_notes},
    };

    if(defined $params{account_request}) {
        $values->{account_request} = $params{account_request};
    }

    my $original_username = $self->username;

    foreach my $field ($site->user_fields)
    {
        next if !exists $params{$field->{name}};
        my $fname = $field->{name};
        $self->$fname($params{$fname});
        $self->username($params{email})
            if $fname eq 'email';
    }

    my $audit = GADS::Audit->new(schema => $self->result_source->schema, user => $current_user);

    $audit->login_change("Username $original_username (id ".$self->id.") being changed to ".$self->username)
        if $original_username && $self->is_column_changed('username');

    # Coerce view_limits to value expected, ensure all removed if exists
    $params{view_limits} = []
        if exists $params{view_limits} && !$params{view_limits};
    # Same for groups
    $params{groups} = []
        if exists $params{groups} && !$params{groups};
    # Same for permissions
    $params{permissions} = []
        if exists $params{permissions} && !$params{permissions};

    $self->update($values);

    if ($params{groups})
    {
        $self->groups($current_user, $params{groups});
        $self->clear_has_group;
        $self->has_group;
    }

    if ($params{permissions} && ref $params{permissions} eq 'ARRAY')
    {
        error __"You do not have permission to set global user permissions"
            if !$current_user->permission->{superadmin};
        $self->permissions(@{$params{permissions}});
        # Clear and rebuild permissions, in case of form submission failure. We
        # need to rebuild now, otherwise the transaction may have rolled-back
        # to the old version by the time it is built in the template
        $self->clear_permission;
        $self->permission;
    }
    $self->set_view_limits($params{view_limits})
        if $params{view_limits};

    my $empty = 1;
    $empty = 0 if($params{organisation});

    my $required = 0;
    $required = 1 if $site->register_organisation_mandatory;
    $required = 0 if $params{edit_own_user};
    $required = 1 if $params{$site->user_field_is_editable('organisation')};

    error __x"Please select a {name} for the user", name => $site->organisation_name
        if $empty && $required;

    error __x"Please select a {name} for the user", name => $site->team_name
        if !$params{team_id} && $site->register_team_mandatory;

    error __x"Please select a {name} for the user", name => $site->department_name
        if !$params{department_id} && $site->register_department_mandatory;

    length $params{firstname} <= 128
        or error __"Forename must be less than 128 characters";
    length $params{surname} <= 128
        or error __"Surname must be less than 128 characters";
    !defined $params{organisation} || $params{organisation} =~ /^[0-9]+$/
        or error __x"Invalid organisation {id}", id => $params{organisation};
    !defined $params{department_id} || $params{department_id} =~ /^[0-9]+$/
        or error __x"Invalid department {id}", id => $params{department_id};
    !defined $params{team_id} || $params{team_id} =~ /^[0-9]+$/
        or error __x"Invalid team {id}", id => $params{team_id};
    GADS::Util->email_valid($params{email})
        or error __x"The email address \"{email}\" is invalid", email => $params{email};

    my $msg = __x"User updated: ID {id}, username: {username}",
        id => $self->id, username => $params{username};
    $msg .= __x", groups: {groups}", groups => join ', ', @{$params{groups}}
        if $params{groups};
    $msg .= __x", permissions: {permissions}", permissions => join ', ', @{$params{permissions}}
        if $params{permissions};

    $audit->login_change($msg);

    $guard->commit;

}

sub permissions
{   my ($self, @permissions) = @_;

    my %user_perms = map { $_ => 1 } @permissions;
    my %all_perms  = map { $_->name => $_->id } $self->result_source->schema->resultset('Permission')->all;

    foreach my $perm (qw/useradmin audit superadmin/)
    {
        my $pid = $all_perms{$perm};
        if ($user_perms{$perm})
        {
            $self->find_or_create_related('user_permissions', { permission_id => $pid });
        }
        else {
            $self->search_related('user_permissions', { permission_id => $pid })->delete;
        }
    }
}

sub retire
{   my ($self, %options) = @_;

    my $schema = $self->result_source->schema;
    my $site   = $schema->resultset('Site')->next;

    # Properly delete if account request - no record needed
    if ($self->account_request)
    {
        $self->delete;
        return unless $options{send_reject_email};
        my $email = GADS::Email->instance;
        $email->send({
            subject => $site->email_reject_subject || "Account request rejected",
            emails  => [$self->email],
            text    => $site->email_reject_text || "Your account request has been rejected",
        });

        return;
    }
    else {
        $self->search_related('user_graphs', {})->delete;
        my $alerts = $self->search_related('alerts', {});
        my @alert_sends = map { $_->id } $alerts->all;
        $self->result_source->schema->resultset('AlertSend')->search({ alert_id => \@alert_sends })->delete;
        $alerts->delete;

        # Delete dashboards
        my $dashboard_rs = $self->result_source->schema->resultset('Dashboard')->search({ user_id => $self->id });
        $self->result_source->schema->resultset('Widget')->search({
            dashboard_id => [$dashboard_rs->get_column('id')->all],
        })->delete;
        $dashboard_rs->delete;

        $self->update({ lastview => undef });
        my $views = $self->search_related('views', {});
        my @views;
        foreach my $v ($views->all)
        {
            push @views, $v->id;
        }
        $self->result_source->schema->resultset('Filter')->search({ view_id => \@views })->delete;
        $self->result_source->schema->resultset('ViewLayout')->search({ view_id => \@views })->delete;
        $self->result_source->schema->resultset('Sort')->search({ view_id => \@views })->delete;
        $self->result_source->schema->resultset('AlertCache')->search({ view_id => \@views })->delete;
        $self->result_source->schema->resultset('Alert')->search({ view_id => \@views })->delete;
        $self->result_source->schema->resultset('ViewGroup')->search({ view_id => \@views })->delete;
        $views->delete;

        $self->update({ deleted => DateTime->now });

        if (my $msg = $site->email_delete_text)
        {
            my $email = GADS::Email->instance;
            $email->send({
                subject => $site->email_delete_subject || "Account deleted",
                emails  => [$self->email],
                text    => $msg,
            });
        }
    }
}

sub has_draft
{   my ($self, $instance_id) = @_;
    $instance_id or panic "Need instance ID for draft test";
    $self->result_source->schema->resultset('Current')->search({
        instance_id  => $instance_id,
        draftuser_id => $self->id,
        'curvals.id' => undef,
    }, {
        join => 'curvals',
    })->next;
}

sub update_attributes
{   my ($self, $attributes) = @_;
    my $authentication = $self->result_source->schema->resultset('Authentication')->saml2_provider;
    if (my $at = $authentication->saml2_firstname)
    {
        $self->update({ firstname => $attributes->{$at}->[0] });
    }
    if (my $at = $authentication->saml2_surname)
    {
        $self->update({ surname => $attributes->{$at}->[0] });
    }
    my $value = _user_value({firstname => $self->firstname, surname => $self->surname});
    $self->update({ value => $value });
}

sub _user_value
{   my $user = shift;
    return unless $user;
    my $firstname = $user->{firstname} || '';
    my $surname   = $user->{surname}   || '';
    my $value     = "$surname, $firstname";
    $value;
}

sub for_data_table
{   my ($self, %params) = @_;
    my $site = $params{site};
    my $return = {
        _id => $self->id,
        ID => {
            type   => 'id',
            name   => 'ID',
            values => [$self->id]
        },
        Surname => {
            type   => 'string',
            name   => 'Surname',
            values => [$self->surname],
        },
        Forename => {
            type   => 'string',
            name   => 'Forename',
            values => [$self->firstname],
        },
        Email => {
            type   => 'string',
            name   => 'Email',
            values => [$self->email],
        },
        Created => {
            type   => 'string',
            name   => 'Created',
            values => [$self->created ? $self->created->ymd : 'Unknown'],
        },
        'Last login' => {
            type   => 'string',
            name   => 'Last login (GMT)',
            values => [$self->lastlogin ? $self->lastlogin->ymd : 'Never logged in'],
        },
    };
    $return->{Title} = {
        type   => 'string',
        name   => 'Title',
        values => [$self->title && $self->title->name],
    } if $site->register_show_title;
    $return->{$site->organisation_name} = {
        type   => 'string',
        name   => $site->organisation_name,
        values => [$self->organisation && $self->organisation->name],
    } if $site->register_show_organisation;
    $return->{$site->department_name} = {
        type   => 'string',
        name   => $site->department_name,
        values => [$self->department && $self->department->name],
    } if $site->register_show_department;
    $return->{$site->team_name} = {
        type   => 'string',
        name   => $site->team_name,
        values => [$self->team && $self->team->name],
    } if $site->register_show_team;
    $return->{$site->register_freetext1_name} = {
        type   => 'string',
        name   => $site->register_freetext1_name,
        values => [$self->freetext1],
    } if $site->register_freetext1_name;

    $return;
}

sub validate
{   my $self = shift;
    # Update value field
    $self->value(_user_value({firstname => $self->firstname, surname => $self->surname}));

    $self->username
        or error "Username required";
    $self->email
        or error "Email required";

    # Check existing user rename, check both email address and username
    foreach my $f (qw/username email/)
    {
        if ($self->is_column_changed($f) || !$self->id)
        {
            my $search = { $f => $self->$f };
            $search->{id} = { '!=' => $self->id }
                if $self->id;
            $self->result_source->resultset->active->search($search)->next
                and error __x"{username} already exists as an active user", username => $self->$f;
        }
    }
}

sub export_hash
{   my $self = shift;
    # XXX Department, organisation etc not currently exported
    +{
        id                    => $self->id,
        firstname             => $self->firstname,
        surname               => $self->surname,
        value                 => $self->value,
        email                 => $self->email,
        username              => $self->username,
        freetext1             => $self->freetext1,
        freetext2             => $self->freetext2,
        password              => $self->password,
        pwchanged             => $self->pwchanged && $self->pwchanged->datetime,
        deleted               => $self->deleted && $self->deleted->datetime,
        lastlogin             => $self->lastlogin && $self->lastlogin->datetime,
        account_request       => $self->account_request,
        account_request_notes => $self->account_request_notes,
        created               => $self->created && $self->created->datetime,
        groups                => [map $_->id, $self->groups],
        permissions           => [map $_->permission->name, $self->user_permissions],
    };
}

1;
