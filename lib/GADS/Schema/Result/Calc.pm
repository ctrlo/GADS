use utf8;
package GADS::Schema::Result::Calc;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("calc");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "calc",
  { data_type => "mediumtext", is_nullable => 1 },
  "code",
  { data_type => "mediumtext", is_nullable => 1 },
  "return_format",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "decimal_places",
  { data_type => "smallint", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

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

1;
