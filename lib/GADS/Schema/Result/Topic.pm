use utf8;
package GADS::Schema::Result::Topic;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use HTML::Entities qw/encode_entities/;
use Log::Report 'linkspace';
use Text::Markdown qw/markdown/;

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

sub description_html
{   my $self = shift;
    markdown encode_entities $self->description;
}

sub before_delete
{   my $self = shift;
    $self->result_source->schema->resultset('Layout')->search({
        topic_id => $self->id,
    })->update({ topic_id => undef });
}

sub import_hash
{   my ($self, $values, %options) = @_;

    my $report = $options{report_only} && $self->id;

    notice __x"Update: name from {old} to {new} for topic {name}",
        old => $self->name, new => $values->{name}, name => $self->name
            if $report && $self->name ne $values->{name};
    $self->name($values->{name});

    notice __x"Update: description from {old} to {new} for topic {name}",
        old => $self->description, new => $values->{description}, name => $self->name
            if $report && ($self->description || '') ne ($values->{description} || '');
    $self->description($values->{description});

    notice __x"Update: initial_state from {old} to {new} for topic {name}",
        old => $self->initial_state, new => $values->{initial_state}, name => $self->name
            if $report && ($self->initial_state || '') ne ($values->{initial_state} || '');
    $self->initial_state($values->{initial_state});

    notice __x"Update: click_to_edit from {old} to {new} for topic {name}",
        old => $self->click_to_edit, new => $values->{click_to_edit}, name => $self->name
            if $report && $self->click_to_edit != $values->{click_to_edit};
    $self->click_to_edit($values->{click_to_edit});

    notice __x"Update: prevent_edit_topic_id from {old} to {new} for topic {name}",
        old => $self->prevent_edit_topic_id, new => $values->{prevent_edit_topic_id}, name => $self->name
            if $report
                && ($self->prevent_edit_topic_id xor $values->{prevent_edit_topic_id})
                && $self->prevent_edit_topic_id != $values->{prevent_edit_topic_id};
    $self->prevent_edit_topic_id($values->{prevent_edit_topic_id});
}

1;
