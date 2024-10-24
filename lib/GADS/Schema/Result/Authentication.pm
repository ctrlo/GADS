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
  "error_messages",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("authentication_ux_saml2_relaystate", ["saml2_relaystate"]);

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

1;
