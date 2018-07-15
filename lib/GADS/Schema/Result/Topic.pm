use utf8;
package GADS::Schema::Result::Topic;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("+GADS::DBIC");

__PACKAGE__->table("topic");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "instance_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "initial_state",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "click_to_edit",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "layouts",
  "GADS::Schema::Result::Layout",
  { "foreign.topic_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  "instance",
  "GADS::Schema::Result::Instance",
  { id => "instance_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

sub before_delete
{   my $self = shift;
    $self->result_source->schema->resultset('Layout')->search({
        topic_id => $self->id,
    })->update({ topic_id => undef });
}

1;
