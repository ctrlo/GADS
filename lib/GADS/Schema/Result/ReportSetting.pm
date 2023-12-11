use utf8;

package GADS::Schema::Result::ReportSetting;

=head1 NAME
GADS::Schema::Result::ReportSettings
=cut

use strict;
use warnings;

use Log::Report 'linkspace';
use Moo;

extends 'DBIx::Class::Core';
sub BUILDARGS { $_[2] || {} }

=head1 COMPONENTS LOADED
=over 4
=item * L<DBIx::Class::InflateColumn::DateTime>
=item * L<GADS::DBIC>
=back
=cut

__PACKAGE__->load_components( "InflateColumn::DateTime", "+GADS::DBIC" );

=head1 TABLE: C<report_defaults>
=cut

__PACKAGE__->table("report_defaults");

=head1 ACCESSORS
=head2 id
    data_type: 'bigint'
    is_auto_increment: 1
    is_nullable: 0
=head2 name
    data_type: 'varchar'
    is_nullable: 0
    size: 128
=head2 value
    data_type: 'varchar'
    is_nullable: 1
    size: 128
=head2 data
    data_type: 'longblob'
    is_nullable: 1
=head2 type
    data_type: 'varchar'
    size: 128
=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "value",
    { data_type => "varchar", is_nullable => 1, size => 128 },
    "data",
    { data_type => "longblob", is_nullable => 1 },
    "type",
    { data_type => "varchar", is_nullable => 1, size => 128 },
);

=head1 PRIMARY KEY
=over 4
=item * L</id>
=back
=cut

__PACKAGE__->set_primary_key("id");

sub sqlt_deploy_hook {
    my ( $self, $sqlt_table ) = @_;
    $sqlt_table->add_index( name => 'name_idx', fields => ['name'] );
}

1;
