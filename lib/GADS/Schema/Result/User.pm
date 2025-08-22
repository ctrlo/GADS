use utf8;
package GADS::Schema::Result::User;

use strict;
use warnings;

use Auth::Yubikey_WebClient;
use Authen::OATH;
use Convert::Base32 qw/encode_base32 decode_base32/;
use Cpanel::JSON::XS;
use DateTime;
use Digest::SHA  qw/hmac_sha256 sha256/;
use GADS::Audit;
use GADS::Config;
use GADS::Email;
use HTML::Entities qw/encode_entities/;
use HTTP::Request::Common;
use Imager::Color;
use Imager::QRCode;
use Log::Report;
use LWP::UserAgent;
use MIME::Base64 qw/encode_base64url decode_base64 encode_base64/;
use Moo;
use Session::Token;
use URI::Escape qw/uri_escape/;

extends 'DBIx::Class::Core';

sub BUILDARGS { $_[2] || {} }

__PACKAGE__->load_components("InflateColumn::DateTime", "+GADS::DBIC");

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

=head2 provider

  data_type: 'integer'
  is_foreign_key: 1
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
  # All the following for MFA
  "mfa_type",
  { data_type => "char", is_nullable => 1, size => 3 },
  "mobile",
  { data_type => "text", is_nullable => 1 },
  "mobile_verified",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "mfa_secret",
  { data_type => "text", is_nullable => 1 },
  "mfa_sms_token",
  { data_type => "text", is_nullable => 1 },
  "mfa_sms_created",
  {data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "mfa_token_previous",
  { data_type => "text", is_nullable => 1 },
  "mfa_token_previous_type",
  { data_type => "char", is_nullable => 1, size => 3 },
  "mfa_token_previous_used",
  {data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "mfa_token_previous_key",
  { data_type => "text", is_nullable => 1 },
  "mfa_lastfail",
  {data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "mfa_failcount",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "provider",
  { data_type => "integer", default_value => 1, is_foreign_key => 1, is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "alerts",
  "GADS::Schema::Result::Alert",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

__PACKAGE__->has_many(
  "people",
  "GADS::Schema::Result::Person",
  { "foreign.value" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "view_limits",
  "GADS::Schema::Result::ViewLimit",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "record_approvedbies",
  "GADS::Schema::Result::Record",
  { "foreign.approvedby" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

__PACKAGE__->has_many(
  "imports",
  "GADS::Schema::Result::Import",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

=head2 provider

Type: belongs_to

Related object: L<GADS::Schema::Result::Authentication>

=cut

__PACKAGE__->belongs_to(
  "provider",
  "GADS::Schema::Result::Authentication",
  { "id" => "provider" },
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

__PACKAGE__->has_many(
  "user_lastrecords",
  "GADS::Schema::Result::UserLastrecord",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "user_permissions",
  "GADS::Schema::Result::UserPermission",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

# Used to ensure an empty selector is available in the user edit page
has view_limits_with_blank => (
    is      => 'lazy',
    clearer => 1,
);

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
    my $request = 0;

    my $guard = $self->result_source->schema->txn_scope_guard;

    # This was originally a delete call, does this now create an issue as it's required for the internal "update" call within `create user`
    my $current_user = $params{current_user};

    my $site = $self->result_source->schema->resultset('Site')->next;

    # Set null values where required for database insertions
    delete $params{organisation} if !$params{organisation} && !$site->user_field_is_editable('organisation');
    delete $params{department_id} if !$params{department_id} && !$site->user_field_is_editable('department_id');
    delete $params{team_id} if !$params{team_id} && !$site->user_field_is_editable('team_id');
    delete $params{title} if !$params{title} && !$site->user_field_is_editable('title');
    delete $params{provider} if !$params{provider} && !$site->user_field_is_editable('provider');

    my $values = {
        account_request_notes => $params{account_request_notes},
    };

    if(defined $params{account_request}) {
        $values->{account_request} = $params{account_request};
        $request = 1 if $self->account_request && !$params{account_request};
    }

    if($request) {

      $self->result_source->schema->resultset('User')->create_user(%params);
      $self->result_source->schema->resultset('User')->find($self->id)->delete;

      $guard->commit;

    } else {

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
          # FIXME: SAML should be able to set groups
          # error __"You do not have permission to set global user permissions"
          #    if !$current_user->permission->{superadmin};
          #
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

      $required = $site->register_team_mandatory;
      $required = 0 if $params{edit_own_user};
      $required = 1 if $params{$site->user_field_is_editable('team_id')};

      error __x"Please select a {name} for the user", name => $site->team_name
          if !$params{team_id} && $required;

      $required = $site->register_department_mandatory;
      $required = 0 if $params{edit_own_user};
      $required = 1 if $params{$site->user_field_is_editable('department_id')};

      error __x"Please select a {name} for the user", name => $site->department_name
          if !$params{department_id} && $required;

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
}

sub send_welcome_email
{   my ($self, %params) = @_;

    $params{email} ||= $self->email;
    
    my %welcome_email = GADS::welcome_text(undef, %params);

    my $email = GADS::Email->instance;

    $email->send({
        subject => $welcome_email{subject},
        text    => $welcome_email{plain},
        html    => $welcome_email{html},
        emails  => [$params{email}],
    });
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

sub _map_fields 
{   my ($self, $text) = @_;
    my @fields = ('firstname', 'surname', 'email', 'title', 'organisation', 'department', 'team');
  
    if ($text) 
    {
        foreach my $field (@fields) 
        {
            my $value = $self->$field || '';
            $text =~ s/\{$field\}/$value/g;
        }
        my $notes = $self->account_request_notes || '';
        $text =~ s/\{notes\}/$notes/g;
    }

    return $text;
}

sub retire
{   my ($self, %options) = @_;

    my $schema = $self->result_source->schema;
    my $site   = $schema->resultset('Site')->next;

    # Properly delete if account request - no record needed
    if ($self->account_request)
    {
        if ($options{send_reject_email})
        {
            my $email_body = $options{email_reject_text} || $site->email_reject_text || "Your account request has been rejected";
            $email_body = $self->_map_fields($email_body);

            my $email = GADS::Email->instance;
            $email->send({
                subject => $site->email_reject_subject || "Account request rejected",
                emails  => [$self->email],
                text    => $email_body,
            });
        }
        $self->delete;

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
    my $authentication = $self->provider;
    my $site = $self->result_source->schema->resultset('Site')->next;

    # Automatically update the firstname and surname if the
    # SAML provider has the proper attributes set
    # How do we know if this provider is used for this user???
    if (my $at = $authentication->saml2_firstname)
    {
        $self->update({ firstname => $attributes->{$at}->[0] });
    }
    if (my $at = $authentication->saml2_surname)
    {
        $self->update({ surname => $attributes->{$at}->[0] });
    }

    # Automatically update the groups and permissions for the user from the SAML2 attributes
    if (my $at = $authentication->saml2_groupname)
    {
        #FIXME - Move this to the UI and allow users to map
        my %permission_map = (
                'GADS-SuperAdmin' => 'superadmin',
                'GADS-UserAdmin'  => 'useradmin',
                'GADS-Audit'      => 'audit',
                );

        my @permissions;
        for my $permission (@{$attributes->{$at}}) {
            # FIXME: hard coded permission?
            push @permissions, $permission_map{$permission} if defined $permission_map{$permission} and $permission =~ /^GADS-/;
        }
        if (@permissions)
        {
            # FIXME: SAML should be able to set groups
            # error __"You do not have permission to set global user permissions"
            #    if !$self->permission->{superadmin};
            $self->permissions(@permissions);
            # Clear and rebuild permissions, in case of form submission failure. We
            # need to rebuild now, otherwise the transaction may have rolled-back
            # to the old version by the time it is built in the template
            $self->clear_permission;
            $self->permission;
        }

        my $schema = $self->result_source->schema;

        my @groups;
        # Automatically update the groups for the user from the SAML2 attributes
        for my $group (@{$attributes->{$at}}) {
            next if defined $permission_map{$group};
            #FIXME: There is likely a much better way to do this
            my @groups1 = $schema->resultset('Group')->search({name => $group}, {order_by => 'me.name'})->first;
            next if ! defined $groups1[0];
            push @groups, $groups1[0]->id if $groups1[0]->name eq $group;
        }
        if (@groups)
        {
            $self->groups($self, \@groups);
            $self->clear_has_group;
            $self->has_group;
        }
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
    $return->{Authentication} = {
        type   => 'string',
        name   => 'Authentication Provider',
        values => [$self->provider && $self->provider->name],
    } if $site->register_show_provider;

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
            $self->result_source->schema->resultset('User')->active->search($search)->next
             and error __x"{username} already exists as an active user", username => $self->$f;
        }
    }

    !$self->mobile || validate_mobile($self->mobile)
        or error __x"The mobile number {number} is invalid. Please enter as international format (e.g. +1444555666)",
            number => $self->mobile;

    !$self->mfa_type || $self->mfa_type =~ /^(otp|yub|sms)$/
        or error __x"Invalid MFA type: {type}", type => $self->mfa_type;
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

has encryption_key => (
    is      => 'lazy',
);

sub _build_encryption_key {
    my $self = shift;
    
    my $header_json  = '{"typ":"JWT","alg":"HS256"}';
    # This is a string because encode_json created the JSON string in an arbitrary order and we need the same key _every time_!
    my $payload_json = '{"sub":"' . $self->id . '","user":"' . $self->username . '"}';
    my $header_b64   = encode_base64url($header_json);
    my $payload_b64  = encode_base64url($payload_json);
    my $input        = "$header_b64.$payload_b64";
    my $secret       = sha256($self->password);
    my $sig          = encode_base64url(hmac_sha256($input, $secret));
    
    return encode_base64url(sha256("$input.$sig"));
}

# All the following for MFA

# Forced site MFA if applicable, otherwise user's chosen MFA. If forced type is
# "any" then return the user's chosen MFA, which may be undefined at this
# point.
sub mfa_type_effective
{   my $self = shift;
    my $force = $self->site->force_mfa;
    return $force if $force && $force ne 'any';
    return $self->mfa_type;
}

sub need_mfa
{   my $self = shift;
    # mfa_type_effective may return false even if MFA is forced (in the case of
    # it being "any"
    !! $self->site->force_mfa || $self->mfa_type_effective;
}

sub seed_key
{   my $self = shift;
    my $len_secret_bytes = 26;
    open my $RNG, '<', '/dev/urandom'
        or panic "Cannot open /dev/urandom for reading";
    sysread $RNG, my $secret_bytes, $len_secret_bytes
        or panic "Cannot read $len_secret_bytes from /dev/urandom";
    close $RNG
        or panic "Cannot close /dev/urandom";
    encode_base32($secret_bytes);
}

sub key_qr_base64
{   my ($self, $key) = @_;
    my $qrcode = Imager::QRCode->new(
        size          => 10,
        margin        => 2,
        version       => 1,
        level         => 'M',
        casesensitive => 1,
        lightcolor    => Imager::Color->new(255, 255, 255),
        darkcolor     => Imager::Color->new(0, 0, 0),
    );
    my $issuer = "LinkSpace";
    $issuer .= " – ".$self->site->name
        if $self->site->name;
    my $uri = "otpauth://totp/".uri_escape($self->username)."?secret=".uri_escape($key || $self->mfa_secret)."&issuer=$issuer";
    my $img = $qrcode->plot($uri);
    my $string;
    open my $fh, ">", \$string;
    $img->write(fh => $fh, type => 'png')
        or panic "Failed to write QR image";
    encode_base64 $string;
}

sub get_yubikey
{   my ($self, $otp) = @_;
    $otp or return undef;
    my $yubi_config = GADS::Config->instance->yubi_config;
    my $id = $yubi_config->{id};
    my $api = $yubi_config->{key};
    my $nonce = Session::Token->new(length => 32)->get;
    my $yubi_id = substr $otp, 0, 12;
    my $result = Auth::Yubikey_WebClient::yubikey_webclient($otp, $id, $api, $nonce);
    return $result eq 'OK' ? $yubi_id : undef;
}

sub check_token
{   my ($self, $token, $secret) = @_;
    if ($self->mfa_type_effective eq 'sms')
    {
        return 0 if !$self->mfa_sms_token; # Safety check in case both blank
        return 0 if $self->mfa_sms_created < DateTime->now->subtract(minutes => 15);
        return $token eq $self->mfa_sms_token;
    }
    elsif ($self->mfa_type_effective eq 'yub')
    {
        return 0 if !$self->mfa_secret;
        $self->get_yubikey($token) eq $self->mfa_secret;
    }
    elsif ($self->mfa_type_effective eq 'otp')
    {
        my $oath = Authen::OATH->new;
        my $otp = $oath->totp(decode_base32 ($self->mfa_secret || $secret));
        return $otp eq $token;
    }
    else {
        panic __x"Unknown MFA type {type}", type => $self->mfa_type_effective;
    }
}

# Whether the user has recently verified MFA
sub recent_mfa
{   my ($self, $key_from_cookie) = @_;
    return 0 unless $key_from_cookie
        && $self->mfa_token_previous_used
        && ("$key_from_cookie" eq $self->mfa_token_previous_key)
        && $self->mfa_type_effective eq $self->mfa_token_previous_type;
    return 1 if $self->mfa_token_previous_used > DateTime->now->subtract(days => 7);
    return 0;
}

sub send_mfa_sms
{   my $self = shift;

    my $code = Session::Token->new(alphabet => [0..9], length => 6)->get;
    $self->update({ mfa_sms_token => $code, mfa_sms_created => DateTime->now });
    # Force utf-8 in SMS message - needed to route Chinese SMS via correct
    # route (advised by Twilio)
    my $message = __x"“{code}” is your LinkSpace access code", code => $code;

    send_sms($self->mobile, $message);
}

sub need_mfa_setup
{   my $self = shift;
    return 1 if !$self->mfa_type_effective; # User not chosen MFA type
    return 0 if ($self->mfa_type_effective eq 'otp' && $self->mfa_secret)
        || ($self->mfa_type_effective eq 'yub' && $self->mfa_secret)
        || ($self->mfa_type_effective eq 'sms' && $self->mobile && $self->mobile_verified);
    return 1;
}

sub need_mobile_verification
{   my $self = shift;
    # Need to use validate_mobile() here, otherwise this object may be used
    # when it has an invalid mobile number (following an unsuccessful
    # submission and validate error)
    if ($self->mobile && validate_mobile($self->mobile) && !$self->mobile_verified)
    {
        $self->send_mfa_sms;
        return 1;
    }
    return 0;
}

sub verify_mobile
{   my ($self, $token) = @_;
    if ($token eq $self->mfa_sms_token)
    {
        $self->update({ mobile_verified => 1 });
        return 1;
    }
    else {
        $self->update({ mobile => undef });
        return 0;
    }
}

sub reset_mfa
{   my $self = shift;
    $self->update({
        mobile                  => undef,
        mfa_secret              => undef,
        mfa_sms_token           => undef,
        mfa_sms_created         => undef,
        mfa_token_previous      => undef,
        mfa_token_previous_type => undef,
        mfa_token_previous_used => undef,
        mfa_token_previous_key  => undef,
        mfa_failcount           => 0,
    });
}

sub validate_mobile
{   my $mobile = shift;
    $mobile =~ /^\+[0-9]{4,}$/;
}

sub send_sms
{   my ($to, $body) = @_;

    my $sms_config = GADS::Config->instance->sms_config;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    my $json = Cpanel::JSON::XS->new->utf8->encode({
        from     => $sms_config->{from},
        to       => $to,
        body     => "$body",
        encoding => 'UNICODE',
    });

    my $request = POST $sms_config->{url}, 'Content-Type' => 'application/json', Content => $json;

    $request->authorization_basic($sms_config->{username}, $sms_config->{password});

    my $response = $ua->request($request);

    my $return = try { decode_json $response->decoded_content };

    $return
        or panic "Failed to send SMS message - unknown response";

    # Assume that hash return means failed sending (success should return array
    # for each message status, see below)
    panic __x"Failed to send SMS message: {title} ({err})",
        title => $return->{title}, err => $return->{detail}
            if ref $return eq 'HASH';

    # See https://www.bulksms.com/developer/json/v1/#tag/Message%2Fpaths%2F~1messages%2Fpost
    # (type should be ACCEPTED on submission and will subsequently change)
    # Status of the first message
    $return->[0]->{status}->{type} eq 'ACCEPTED'
        or panic __"Failed to send SMS message - unknown reason";
}

1;
