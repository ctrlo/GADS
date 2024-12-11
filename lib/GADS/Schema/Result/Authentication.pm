use utf8;
package GADS::Schema::Result::Authentication;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use JSON qw(decode_json);
use Log::Report 'linkspace';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("authentication");

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "xml",
  { data_type => "text", is_nullable => 1 },
  "cacert",
  { data_type => "text", is_nullable => 1 },
  "sp_cert",
  { data_type => "text", is_nullable => 1 },
  "sp_key",
  { data_type => "text", is_nullable => 1 },
  "saml2_firstname",
  { data_type => "text", is_nullable => 1 },
  "saml2_surname",
  { data_type => "text", is_nullable => 1 },
  "saml2_groupname",
  { data_type => "text", is_nullable => 1 },
  "saml2_relaystate",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "enabled",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "saml2_unique_id",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "error_messages",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("authentication_ux_saml2_relaystate", ["saml2_relaystate"]);
__PACKAGE__->add_unique_constraint("authentication_ux_saml2_unique_id", ["saml2_unique_id"]);

__PACKAGE__->has_many(
  "users",
  "GADS::Schema::Result::User",
  { "foreign.provider" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

# FIXME
my $www     = 'sandbox.linkspace.uk';

sub sso_unique_url
{   my $self = shift;
    my $id   = $self->saml2_unique_id;
    "https://$www/$id/saml";
}

sub sso_url
{   my $self = shift;
    my $id   = $self->saml2_unique_id;
    return $self->sso_unique_url; # if $self->saml2_use_unique_id;
    #return $self->sso_standard_url;
}

sub sso_unique_xml
{   my $self = shift;
    my $id   = $self->saml2_unique_id;
    "https://$www/$id/saml/xml";
}

sub sso_xml
{   my $self = shift;
    my $id   = $self->saml2_unique_id;
    return $self->sso_unique_xml; # if $self->saml2_use_unique_id;
    #return $self->sso_standard_xml;
}

sub get_saml2_unique_id
{   my $self = shift;
    return $self->saml2_unique_id
        if $self->saml2_unique_id;
    my $code = Session::Token->new(length => 32)->get;
    {
        local $SL::Schema::NO_USERID = 1;
        while ($self->result_source->resultset->search({ saml2_unique_id => $code })->next)
        {
            $code = Session::Token->new(length => 32)->get;
        }
    }

    $self->update({
        saml2_unique_id => $code,
    });
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
        "Site ID" => {
            type   => 'string',
            name   => 'Site ID',
            values => [$self->site_id],
        },
        Type => {
            type   => 'string',
            name   => 'Type',
            values => [$self->type],
        },
        Name => {
            type   => 'string',
            name   => 'Name',
            values => [$self->name],
        },
        enabled => {
            type   => 'string',
            name   => 'enabled',
            values => [$self->enabled ? "Enabled" : "Disabled"],
        },
    };

    $return;
}

sub error_messages_decoded
{   my $self = shift;
    my $json = $self->error_messages
        or return {};
    decode_json $json;
}

sub user_not_found_error
{   my $self = shift;
    $self->error_messages_decoded->{user_not_found}
        || "Username {username} not found";
}

sub saml_provider_match_error
{   my $self = shift;
    $self->error_messages_decoded->{saml_provider_match}
        || "SAML provider does not match the authentication provider for {username}";
}

sub update_provider
{   my ($self, %params) = @_;
    my $request = 0;

    my $guard = $self->result_source->schema->txn_scope_guard;

    # FIXME: Is this comment required
    # This was originally a delete call, does this now create an issue as
    # it's required for the internal "update" call within `create user`
    my $current_user = $params{current_user};

    my $site = $self->result_source->schema->resultset('Site')->next;

    # FIXME: may need this for provider
    # Set null values where required for database insertions
    #delete $params{title} if !$params{title} && !$site->user_field_is_editable('title');

    my $values;

    if($request) {
	#FIXME: Remove
      $self->result_source->schema->resultset('Authentication')->create_provider(%params);
      #$self->result_source->schema->resultset('Authentication')->find($self->id)->delete;

      $guard->commit;

    } else {

      my $original_name = $self->name;

      foreach my $field ($site->provider_fields)
      {
          next if !exists $params{$field->{name}};
          my $fname = $field->{name};
          $self->$fname($params{$fname});
      }

      my $audit = GADS::Audit->new(schema => $self->result_source->schema, user => $current_user);

      $audit->auth_provider_change("Provider $original_name (id ".$self->id.") being changed to ".$self->name)
          if $original_name && $self->is_column_changed('name');

      error __"You do not have permission to update an authentication provider"
              if !$current_user->permission->{superadmin};

      $self->update($values);

      my $required = 0;

      length $params{name} <= 128
          or error __"Name must be less than 128 characters";
      length $params{saml2_surname} <= 128
          or error __"Surname attribute must be less than 128 characters"
          if defined $params{saml2_surname};
      length $params{saml2_firstname} <= 128
          or error __"Firstname attribute must be less than 128 characters"
          if defined $params{saml2_firstname};
      length $params{saml2_groupname} <= 128
          or error __"Groupname attribute must be less than 128 characters"
          if defined $params{saml2_groupname};
      !defined $params{organisation} || $params{organisation} =~ /^[0-9]+$/
          or error __x"Invalid organisation {id}", id => $params{organisation};

      my $msg = __x"Authentication Provider updated: ID {id}, name: {name}",
          id => $self->id, name => $params{name};

      $audit->auth_provider_change(description => $msg);

      $guard->commit;
    }
}

sub retire
{   my ($self, %options) = @_;

    my $schema = $self->result_source->schema;
    my $current_user = $options{current_user};

    error __"You do not have permission to delete an authentication provider"
        if !$current_user->permission->{superadmin};

    my $audit = GADS::Audit->new(schema => $self->result_source->schema, user => $current_user);

    my $msg = __x"Authentication Provider: ID {id}, name: {name} was deleted",
        id => $self->id, name => $self->name;
    $audit->auth_provider_change(description => $msg);

    $self->delete();
}

1;
