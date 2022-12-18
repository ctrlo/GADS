use utf8;
package GADS::Schema::Result::Authentication;

use strict;
use warnings;

use base 'DBIx::Class::Core';

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
  "saml2_firstname",
  { data_type => "text", is_nullable => 1 },
  "saml2_surname",
  { data_type => "text", is_nullable => 1 },
  "enabled",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

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

1;
