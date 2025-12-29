use utf8;
package GADS::Schema::Result::Group;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("group");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "default_read",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "default_write_new",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "default_write_existing",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "default_approve_new",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "default_approve_existing",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "default_write_new_no_approval",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "default_write_existing_no_approval",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "site_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "layout_groups",
  "GADS::Schema::Result::LayoutGroup",
  { "foreign.group_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "user_groups",
  "GADS::Schema::Result::UserGroup",
  { "foreign.group_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "instance_groups",
  "GADS::Schema::Result::InstanceGroup",
  { "foreign.group_id" => "self.id" },
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

__PACKAGE__->has_many(
  "report_groups",
  "GADS::Schema::Result::ReportGroup",
  { "foreign.group_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
