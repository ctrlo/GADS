use utf8;
package GADS::Schema::Result::Fileval;

=head1 NAME

GADS::Schema::Result::Fileval

=cut

use strict;
use warnings;

use Path::Class qw(file dir);
use Moo;

use GADS::Config;

extends 'DBIx::Class::Core';

sub BUILDARGS { $_[2] || {} }

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<fileval>

=cut

__PACKAGE__->table("fileval");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 mimetype

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "mimetype",
  { data_type => "text", is_nullable => 1 },
  "is_independent",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "edit_user_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 files

Type: has_many

Related object: L<GADS::Schema::Result::File>

=cut

__PACKAGE__->has_many(
  "files",
  "GADS::Schema::Result::File",
  { "foreign.value" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  "user",
  "GADS::Schema::Result::User",
  { id => "edit_user_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'fileval_idx_name', fields => [ { name => 'name', prefix_length => 64 } ]);
}

sub create_file {
  my ($self, $content) = @_;
  my $target = $self->file_to_id;
  $target->dir->mkpath;
  $target->spew(iomode => '>:raw', $content);
}

sub file_to_id {
  my $self = shift;
  my $path = GADS::Config->instance->uploads;
  my $id = sprintf "%09d", $self->id;
  $id =~ s!(\d{3})!$1/!g;
  $id =~ s!/$!!g; # remove trailing slash
  $id =~ s!^/!!g; # remove leading slash
  file($path, $id);
};

sub _filepath {
  my $self = shift;
  my $path = GADS::Config->instance->uploads;
  my $id = sprintf "%09d", $self->id;
  $id =~ s!(\d{3})!$1/!g;
  $id =~ s!/$!!g; # remove trailing slash
  $id =~ s!^/!!g; # remove leading slash
  "$path/$id"
}

sub content {
  my $self = shift;
  my $target = $self->file_to_id;
  error __"File not found!" unless -e $target; # file may have been deleted
  return $target->slurp(iomode => '<:raw');
}

sub remove {
  my $self = shift;

  my $filepath = $self->filepath;

  unlink $filepath if -f $filepath;

  $self->delete;
}

1;
