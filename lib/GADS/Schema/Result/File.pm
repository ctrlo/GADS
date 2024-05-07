use utf8;
package GADS::Schema::Result::File;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GADS::Schema::Result::File

=cut

use strict;
use warnings;

use Moo;

extends 'DBIx::Class::Core';
sub BUILDARGS { $_[2] || {} }

with 'GADS::Role::Purgable';

use MIME::Base64;

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<file>

=cut

__PACKAGE__->table("file");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 record_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 layout_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 child_unique

  data_type: 'smallint'
  default_value: 1
  is_nullable: 0

=head2 value

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "record_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "child_unique",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "value",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 layout

Type: belongs_to

Related object: L<GADS::Schema::Result::Layout>

=cut

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

=head2 value

Type: belongs_to

Related object: L<GADS::Schema::Result::Fileval>

=cut

__PACKAGE__->belongs_to(
  "value",
  "GADS::Schema::Result::Fileval",
  { id => "value" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "value_alternative",
  "GADS::Schema::Result::Fileval",
  { id => "value" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

sub export_hash
{   my $self = shift;
    my $val = $self->value;
    +{
        layout_id    => $self->layout_id,
        child_unique => $self->child_unique,
        content      => $val && encode_base64($val->content),
        name         => $val && $val->name,
        mimetype     => $val && $val->mimetype,
    };
}


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-13 16:02:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:266q8eJmPiCjcNhwddaUkw

sub _build_recordsource { 'File'; }
sub _build_valuefield { undef; }

# I've done this to override the role - I don't know how else to best implement this!
sub purge {
    my $self = shift;

    my $source = $self->recordsource or error __"No recordsource defined";
    my $schema = $self->result_source->schema;

    $schema->txn_do(sub {
      my $file = $schema->resultset($source)->search({},{prefetch=>'value'})->find($self->id);
      my $value = $file->value;
      $value->update({
          name=>'purged',
          mimetype=>'text/plain',
          content=>encode('utf-8', 'purged'),
      });
    });
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
