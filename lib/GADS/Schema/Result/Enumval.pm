use utf8;
package GADS::Schema::Result::Enumval;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("enumval");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "deleted",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "parent",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "position",
  { data_type => "integer", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "enums",
  "GADS::Schema::Result::Enum",
  { "foreign.value" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "enumvals",
  "GADS::Schema::Result::Enumval",
  { "foreign.parent" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  "layout",
  "GADS::Schema::Result::Layout",
  { id => "layout_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "parent",
  "GADS::Schema::Result::Enumval",
  { id => "parent" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'enumval_idx_value', fields => [ { name => 'value', prefix_length => 64 } ]);
}

1;
