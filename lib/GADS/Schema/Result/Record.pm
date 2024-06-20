use utf8;

package GADS::Schema::Result::Record;

=head1 NAME

GADS::Schema::Result::Record

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<record>

=cut

__PACKAGE__->table("record");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 created

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 current_id

  data_type: 'bigint'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 createdby

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 approvedby

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 record_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 approval

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
    "created",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
    "current_id",
    {
        data_type      => "bigint",
        default_value  => 0,
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "createdby",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "approvedby",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "record_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "approval",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 approvedby

Type: belongs_to

Related object: L<GADS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
    "approvedby",
    "GADS::Schema::Result::User",
    { id => "approvedby" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

=head2 calcvals

Type: has_many

Related object: L<GADS::Schema::Result::Calcval>

=cut

__PACKAGE__->has_many(
    "calcvals",
    "GADS::Schema::Result::Calcval",
    { "foreign.record_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 createdby

Type: belongs_to

Related object: L<GADS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
    "createdby",
    "GADS::Schema::Result::User",
    { id => "createdby" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

__PACKAGE__->belongs_to(
    "createdby_alternative",
    "GADS::Schema::Result::User",
    { id => "createdby" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

=head2 current

Type: belongs_to

Related object: L<GADS::Schema::Result::Current>

=cut

__PACKAGE__->belongs_to(
    "current",
    "GADS::Schema::Result::Current",
    { id => "current_id" },
    {
        is_deferrable => 1,
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION"
    },
);

__PACKAGE__->belongs_to(
    "current_alternative",
    "GADS::Schema::Result::Current",
    { id => "current_id" },
    {
        is_deferrable => 1,
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION"
    },
);

=head2 curvals

Type: has_many

Related object: L<GADS::Schema::Result::Curval>

=cut

__PACKAGE__->has_many(
    "curvals",
    "GADS::Schema::Result::Curval",
    { "foreign.record_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 dateranges

Type: has_many

Related object: L<GADS::Schema::Result::Daterange>

=cut

__PACKAGE__->has_many(
    "dateranges",
    "GADS::Schema::Result::Daterange",
    { "foreign.record_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 dates

Type: has_many

Related object: L<GADS::Schema::Result::Date>

=cut

__PACKAGE__->has_many(
    "dates", "GADS::Schema::Result::Date",
    { "foreign.record_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 enums

Type: has_many

Related object: L<GADS::Schema::Result::Enum>

=cut

__PACKAGE__->has_many(
    "enums", "GADS::Schema::Result::Enum",
    { "foreign.record_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 files

Type: has_many

Related object: L<GADS::Schema::Result::File>

=cut

__PACKAGE__->has_many(
    "files", "GADS::Schema::Result::File",
    { "foreign.record_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 intgrs

Type: has_many

Related object: L<GADS::Schema::Result::Intgr>

=cut

__PACKAGE__->has_many(
    "intgrs", "GADS::Schema::Result::Intgr",
    { "foreign.record_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 people

Type: has_many

Related object: L<GADS::Schema::Result::Person>

=cut

__PACKAGE__->has_many(
    "people",
    "GADS::Schema::Result::Person",
    { "foreign.record_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 ragvals

Type: has_many

Related object: L<GADS::Schema::Result::Ragval>

=cut

__PACKAGE__->has_many(
    "ragvals",
    "GADS::Schema::Result::Ragval",
    { "foreign.record_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 record

Type: belongs_to

Related object: L<GADS::Schema::Result::Record>

=cut

__PACKAGE__->belongs_to(
    "record",
    "GADS::Schema::Result::Record",
    { id => "record_id" },
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
    { "foreign.record_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 strings

Type: has_many

Related object: L<GADS::Schema::Result::String>

=cut

__PACKAGE__->has_many(
    "strings",
    "GADS::Schema::Result::String",
    { "foreign.record_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 user_lastrecords

Type: has_many

Related object: L<GADS::Schema::Result::UserLastrecord>

=cut

__PACKAGE__->has_many(
    "user_lastrecords",
    "GADS::Schema::Result::UserLastrecord",
    { "foreign.record_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 users

Type: has_many

Related object: L<GADS::Schema::Result::User>

=cut

__PACKAGE__->has_many(
    "users", "GADS::Schema::Result::User",
    { "foreign.lastrecord" => "self.id" },
    { cascade_copy         => 0, cascade_delete => 0 },
);

sub sqlt_deploy_hook
{   my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(
        name   => 'record_idx_approval',
        fields => ['approval']
    );
}

# Enable finding of latest record for current ID
our $REWIND;
my $join_sub = sub {
    my $args   = shift;
    my $return = {
        "$args->{foreign_alias}.current_id" =>
            { -ident => "$args->{self_alias}.current_id" },

        # Changed from using "id" as the key to see which record is later,
        # as after an import the IDs may be in a different order to that in
        # which the records were created. If the created date is the same,
        # use the IDs (primarily for tests, which sometimes have fixed times).
        -or => [
            {
                "$args->{foreign_alias}.created" =>
                    { '>' => \"$args->{self_alias}.created" },
            },
            {
                "$args->{foreign_alias}.created" =>
                    { '=' => \"$args->{self_alias}.created" },
                "$args->{foreign_alias}.id" =>
                    { '>' => \"$args->{self_alias}.id" },
            },
        ],
        "$args->{foreign_alias}.approval" => 0,
    };
    $return->{"$args->{foreign_alias}.created"} = { '<=' => $REWIND }
        if $REWIND;
    return $return;
};

__PACKAGE__->might_have("record_later", "GADS::Schema::Result::Record",
    $join_sub,);

__PACKAGE__->might_have("record_later_alternative",
    "GADS::Schema::Result::Record", $join_sub,);

our $RECORD_EARLIER_BEFORE;
__PACKAGE__->might_have(
    "record_earlier",
    "GADS::Schema::Result::Record",
    sub {
        my $args   = shift;
        my $return = {
            "$args->{foreign_alias}.current_id" =>
                { -ident => "$args->{self_alias}.current_id" },

          # Changed from using "id" as the key to see which record is later,
          # as after an import the IDs may be in a different order to that in
          # which the records were created. If the created date is the same,
          # use the IDs (primarily for tests, which sometimes have fixed times).
            -or => [
                {
                    "$args->{foreign_alias}.created" =>
                        { '<' => \"$args->{self_alias}.created" },
                },
                {
                    "$args->{foreign_alias}.created" =>
                        { '=' => \"$args->{self_alias}.created" },
                    "$args->{foreign_alias}.id" =>
                        { '<' => \"$args->{self_alias}.id" },
                },
            ],
            "$args->{foreign_alias}.approval" => 0,
        };
        $return->{"$args->{foreign_alias}.created"} =
            { '<' => $RECORD_EARLIER_BEFORE }
            if $RECORD_EARLIER_BEFORE;
        return $return;
    },
);

# XXX Temporary record earlier ID to identify records of problem fixed by 146bb73
__PACKAGE__->might_have(
    "record_earlier_id",
    "GADS::Schema::Result::Record",
    sub {
        my $args   = shift;
        my $return = {
            "$args->{foreign_alias}.current_id" =>
                { -ident => "$args->{self_alias}.current_id" },
            "$args->{foreign_alias}.id" =>
                { '<' => \"$args->{self_alias}.id" },
        };
        $return->{"$args->{foreign_alias}.created"} =
            { '<' => $RECORD_EARLIER_BEFORE }
            if $RECORD_EARLIER_BEFORE;
        return $return;
    },
);

1;
