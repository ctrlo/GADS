use utf8;
package GADS::Schema::Result::Current;

=head1 NAME

GADS::Schema::Result::Current

=cut

use strict;
use warnings;

use Moo;

extends 'DBIx::Class::Core';
sub BUILDARGS { $_[2] || {} }

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<current>

=cut

__PACKAGE__->table("current");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 serial

  data_type: 'bigint'
  is_nullable: 1

=head2 parent_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 instance_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 linked_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 deleted

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 deletedby

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 draftuser_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "serial",
  { data_type => "bigint", is_nullable => 1 },
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

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("current_ux_instance_serial", ["instance_id", "serial"]);

=head1 RELATIONS

=head2 alert_caches

Type: has_many

Related object: L<GADS::Schema::Result::AlertCache>

=cut

__PACKAGE__->has_many(
  "alert_caches",
  "GADS::Schema::Result::AlertCache",
  { "foreign.current_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 alerts_send

Type: has_many

Related object: L<GADS::Schema::Result::AlertSend>

=cut

__PACKAGE__->has_many(
  "alerts_send",
  "GADS::Schema::Result::AlertSend",
  { "foreign.current_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 currents

Type: has_many

Related object: L<GADS::Schema::Result::Current>

=cut

__PACKAGE__->has_many(
  "currents",
  "GADS::Schema::Result::Current",
  { "foreign.parent_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 currents_linked

Type: has_many

Related object: L<GADS::Schema::Result::Current>

=cut

__PACKAGE__->has_many(
  "currents_linked",
  "GADS::Schema::Result::Current",
  { "foreign.linked_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 curvals

Type: has_many

Related object: L<GADS::Schema::Result::Curval>

=cut

__PACKAGE__->has_many(
  "curvals",
  "GADS::Schema::Result::Curval",
  { "foreign.value" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 instance

Type: belongs_to

Related object: L<GADS::Schema::Result::Instance>

=cut

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

=head2 linked

Type: belongs_to

Related object: L<GADS::Schema::Result::Current>

=cut

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

=head2 parent

Type: belongs_to

Related object: L<GADS::Schema::Result::Current>

=cut

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

=head2 deletedby

Type: belongs_to

Related object: L<GADS::Schema::Result::User>

=cut

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

=head2 records

Type: has_many

=head2 draftuser

Type: belongs_to

Related object: L<GADS::Schema::Result::User>

=cut

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

=head2 records

Type: has_many

Related object: L<GADS::Schema::Result::Record>

=cut

__PACKAGE__->has_many(
  "records",
  "GADS::Schema::Result::Record",
  { "foreign.current_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-13 16:02:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rxAxdyOBz/25FzoaWbC+Bg

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
    my ($self, @layouts) = @_;

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

    print STDERR $_->purge foreach @values;
}

1;
