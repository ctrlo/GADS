use utf8;
package GADS::Schema::Result::User;

=head1 NAME

GADS::Schema::Result::User

=cut

use strict;
use warnings;

use DateTime;
use GADS::Config;
use GADS::Email;
use GADS::Instance;
use Moo;

extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

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

=head2 telephone

  data_type: 'varchar'
  is_nullable: 1
  size: 128

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
  "telephone",
  { data_type => "varchar", is_nullable => 1, size => 128 },
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

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'user_idx_value', fields => [ { name => 'value', size => 64 } ]);
    $sqlt_table->add_index(name => 'user_idx_email', fields => [ { name => 'email', size => 64 } ]);
    $sqlt_table->add_index(name => 'user_idx_username', fields => [ { name => 'username', size => 64 } ]);
}

# Used to ensure an empty selector is available in the user edit page
sub view_limits_with_blank
{   my $self = shift;
    return $self->view_limits if $self->view_limits->count;
    return [undef];
}

sub set_view_limits
{   my ($self, @view_ids) = @_;

    # remove blank string from form
    @view_ids = grep { $_ } @view_ids;

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
}

sub instance
{   my $self = shift;
    my $config = GADS::Config->instance;
    GADS::Instance->new(
        id     => $config->login_instance,
        schema => $self->schema,
    );
}

sub graphs
{   my ($self, $graphs) = @_;

    # Will be a scalar if only one value submitted. If so,
    # convert to array
    my @graphs = !$graphs
               ? ()
               : ref $graphs eq 'ARRAY'
               ? @$graphs
               : ( $graphs );

    foreach my $g (@graphs)
    {
        unless($self->search_related('user_graphs', { graph_id => $g })->count)
        {
            $self->create_related('user_graphs', { graph_id => $g });
        }
    }

    # Delete any graphs that no longer exist
    my $search = {};
    $search->{graph_id} = {
        '!=' => [ -and => @graphs ]
    } if @graphs;
    $self->search_related('user_graphs', $search)->delete;
}

# Used to check if a user has a group
has has_group => (
    is => 'lazy',
);

sub _build_has_group
{   my $self = shift;
    +{
        map { $_->group_id => 1 } $self->user_groups
    }
}

sub groups
{   my ($self, $groups) = @_;

    foreach my $g (@$groups)
    {
        unless($self->search_related('user_groups', { group_id => $g })->count)
        {
            $self->create_related('user_groups', { group_id => $g });
        }
    }

    # Delete any groups that no longer exist
    my $search = {};
    $search->{group_id} = {
        '!=' => [ -and => @$groups ]
    } if @$groups;
    $self->search_related('user_groups', $search)->delete;
}

# Used to check if a user has a permission
has permission => (
    is => 'lazy',
);

sub _build_permission
{   my $self = shift;
    my %all = map { $_->id => $_->name } $self->result_source->schema->resultset('Permission')->all;
    +{
        map { $all{$_->permission_id} => 1 } $self->user_permissions
    }
}

sub permissions
{   my ($self, $permissions) = @_;

    foreach my $p (@$permissions)
    {
        $self->find_or_create_related('user_permissions', { permission_id => $p });
    }

    # Delete any groups that no longer exist
    my $search = {};
    $search->{permission_id} = {
        '!=' => [ -and => @$permissions ]
    } if @$permissions;
    $self->search_related('user_permissions', $search)->delete;
}

sub retire
{   my ($self, %options) = @_;

    # Properly delete if account request - no record needed
    if ($self->account_request)
    {
        $self->delete;
        return unless $options{send_reject_email};
        my $email = GADS::Email->instance;
        my $instance = $self->instance;
        $email->send({
            subject => $instance->email_reject_subject || "Account request rejected",
            emails  => [$self->email],
            text    => $instance->email_reject_text || "Your account request has been rejected",
        });

        return;
    }
    else {
        $self->search_related('user_graphs', {})->delete;
        my $alerts = $self->search_related('alerts', {});
        my @alert_sends = map { $_->id } $alerts->all;
        $self->schema->resultset('AlertSend')->search({ alert_id => \@alert_sends })->delete;
        $alerts->delete;

        $self->update({ lastview => undef });
        my $views = $self->search_related->('views', {});
        my @views;
        foreach my $v ($views->all)
        {
            push @views, $v->id;
        }
        $self->schema->resultset('Filter')->search({ view_id => \@views })->delete;
        $self->schema->resultset('ViewLayout')->search({ view_id => \@views })->delete;
        $self->schema->resultset('Sort')->search({ view_id => \@views })->delete;
        $self->schema->resultset('AlertCache')->search({ view_id => \@views })->delete;
        $views->delete;

        $self->update({ deleted => DateTime->now });

        if (my $msg = $self->instance->email_delete_text)
        {
            my $email = GADS::Email->instance;
            $email->send({
                subject => $self->instance->email_delete_subject || "Account deleted",
                emails  => [$self->email],
                text    => $msg,
            });
        }
    }
}

1;

