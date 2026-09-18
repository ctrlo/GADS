use utf8;
package GADS::Schema::Result::Current;

use strict;
use warnings;

use Moo;

extends 'DBIx::Class::Core';
sub BUILDARGS { $_[2] || {} }

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("current");

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "serial",
  { data_type => "bigint", is_nullable => 1 },
  "current_version_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "parent_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "instance_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "linked_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "deleted",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "deletedby",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "draftuser_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("current_ux_instance_serial", ["instance_id", "serial"]);

__PACKAGE__->has_many(
  "alert_caches",
  "GADS::Schema::Result::AlertCache",
  { "foreign.current_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "alerts_send",
  "GADS::Schema::Result::AlertSend",
  { "foreign.current_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  "current_version",
  "GADS::Schema::Result::Record",
  { id => "current_version_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

# See comments below regarding record_single_alternative
__PACKAGE__->belongs_to(
  "current_version_alternative",
  "GADS::Schema::Result::Record",
  { id => "current_version_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->has_many(
  "currents",
  "GADS::Schema::Result::Current",
  { "foreign.parent_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "currents_linked",
  "GADS::Schema::Result::Current",
  { "foreign.linked_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "curvals",
  "GADS::Schema::Result::Curval",
  { "foreign.value" => "self.id" },
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

__PACKAGE__->belongs_to(
  "linked",
  "GADS::Schema::Result::Current",
  { id => "linked_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "parent",
  "GADS::Schema::Result::Current",
  { id => "parent_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "deletedby",
  "GADS::Schema::Result::User",
  { id => "deletedby" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "draftuser_id",
  "GADS::Schema::Result::User",
  { id => "draftuser_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->has_many(
  "records",
  "GADS::Schema::Result::Record",
  { "foreign.current_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->might_have(
  "record_single",
  "GADS::Schema::Result::Record",
  { "foreign.current_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# Same join but with different names, when needing to differentiate (e.g.
# correlated queries where the main record needs to be referred to)
__PACKAGE__->might_have(
  "record_single_alternative",
  "GADS::Schema::Result::Record",
  { "foreign.current_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub export_hash
{   my $self = shift;

    my $current = {
        id        => $self->id,
        serial    => $self->serial,
        parent_id => $self->parent_id,
        linked_id => $self->linked_id,
        deleted   => $self->deleted && $self->deleted->datetime,
        deletedby => $self->deletedby && $self->deletedby->id,
    };

    my @records;
    foreach my $rec ($self->records)
    {
        my @values;

        push @values, $_->export_hash
            foreach $rec->curvals;
        push @values, $_->export_hash
            foreach $rec->dates;
        push @values, $_->export_hash
            foreach $rec->dateranges;
        push @values, $_->export_hash
            foreach $rec->enums;
        push @values, $_->export_hash
            foreach $rec->intgrs;
        push @values, $_->export_hash
            foreach $rec->people;
        push @values, $_->export_hash
            foreach $rec->strings;
        push @values, $_->export_hash
            foreach $rec->files;

        push @records, {
            created    => $rec->created->datetime,
            createdby  => $rec->createdby && $rec->createdby->id,
            approvedby => $rec->approvedby && $rec->approvedby->id,
            record_id  => $rec->record_id,
            approval   => $rec->approval,
            values     => \@values,
        };
    };
    $current->{records} = \@records;

    return $current;
}

sub historic_purge {
    my ($self, $user, @layouts) = @_;

    my @records = $self->records->all;
    my @values;
    foreach my $layout (@layouts) {
        push @values, $_->calcvals->search({ layout_id => $layout })->all foreach @records;
        push @values, $_->dateranges->search({ layout_id => $layout })->all foreach @records;
        push @values, $_->dates->search({ layout_id => $layout })->all foreach @records;
        push @values, $_->enums->search({ layout_id => $layout })->all foreach @records;
        push @values, $_->files->search({ layout_id => $layout })->all foreach @records;
        push @values, $_->intgrs->search({ layout_id => $layout })->all foreach @records;
        push @values, $_->people->search({ layout_id => $layout })->all foreach @records;
        push @values, $_->ragvals->search({ layout_id => $layout })->all foreach @records;
        push @values, $_->strings->search({ layout_id => $layout })->all foreach @records;
    }

    $_->purge($user) foreach @values;
}

1;
