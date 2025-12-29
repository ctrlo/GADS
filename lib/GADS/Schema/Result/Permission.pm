use utf8;
package GADS::Schema::Result::Permission;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("permission");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "order",
  { data_type => "integer", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "user_permissions",
  "GADS::Schema::Result::UserPermission",
  { "foreign.permission_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
