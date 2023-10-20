use utf8;
package GADS::Schema::Result::Report;

=head1 NAME

GADS::Schema::Result::Report

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

=head1 TABLE: C<report>

=cut

__PACKAGE__->table("report");

=head1 ACCESSORS

=head2 id

    data_type: 'bigint'
    is_auto_increment: 1
    is_nullable: 0

=head2 name

    data_type: 'varchar'
    is_nullable: 0
    size: 128

=head2 user_id

    data_type: 'bigint'
    is_foreign_key: 1
    is_nullable: 1

=head2 group_id

    data_type: 'bigint'
    is_foreign_key: 1
    is_nullable: 1

=head2 createby

    data_type: 'bigint'
    is_foreign_key: 1
    is_nullable: 1

=head2 created

    data_type: 'datetime'
    datetime_undef_if_invalid: 1
    is_nullable: 1

=head2 instance_id

    data_type: 'bigint'
    is_foreign_key: 1
    is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "user_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "group_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "createdby",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "created",
    { data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
    "instance_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<GADS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
    "user",
    "GADS::Schema::Result::User",
    { id => "user_id" },
    {
        is_deferrable => 1,
        join_type => "LEFT",
        on_delete => "NO ACTION",
        on_update => "NO ACTION"
    },
);

__PACKAGE__->belongs_to(
    "createdby",
    "GADS::Schema::Result::User",
    { id => "createdby" },
    {
        is_deferrable => 1,
        join_type => "LEFT",
        on_delete => "NO ACTION",
        on_update => "NO ACTION"
    },
);

=head2 group

Type: belongs_to

Related object: L<GADS::Schema::Result::Group>

=cut

__PACKAGE__->belongs_to(
    "group",
    "GADS::Schema::Result::Group",
    { id => "group_id" },
    {
        is_deferrable => 1,
        join_type => "LEFT",
        on_delete => "NO ACTION",
        on_update => "NO ACTION"
    },
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
        join_type => "LEFT",
        on_delete => "NO ACTION",
        on_update => "NO ACTION"
    },
);

=head2 report_layouts

Type: has_many

Related object: L<GADS::Schema::Result::ReportLayout>

=cut

__PACKAGE__->has_many(
    "report_layouts",
    "GADS::Schema::Result::ReportLayout",
    { "foreign.report_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 0 },
);

1;