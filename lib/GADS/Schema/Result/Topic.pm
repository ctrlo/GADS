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
  "description",
  { data_type => "text", is_nullable => 1 },
  "initial_state",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "click_to_edit",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "prevent_edit_topic_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "fields",
  "GADS::Schema::Result::Layout",
  { "foreign.topic_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "need_completed_topics",
  "GADS::Schema::Result::Topic",
  { "foreign.prevent_edit_topic_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub need_completed_topics_as_string
{   my $self = shift;
    return '' if !$self->need_completed_topics->count;
    if ($self->need_completed_topics > 1)
    {
        my @topics = $self->need_completed_topics;
        my $final = pop @topics;
        my $text = join ', ', map { $_->name } @topics;
        return "$text and ".$final->name;
    }
    return $self->need_completed_topics->next->name;
}

sub need_completed_topics_count
{   my $self = shift;
    $self->need_completed_topics->count;
}

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

__PACKAGE__->belongs_to(
  "prevent_edit_topic",
  "GADS::Schema::Result::Topic",
  { id => "prevent_edit_topic_id" },
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
