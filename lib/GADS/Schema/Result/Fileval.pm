use utf8;
package GADS::Schema::Result::Fileval;

use strict;
use warnings;

use Path::Class qw(file dir);
use Moo;

use Log::Report 'linkspace';

use GADS::Config;

extends 'DBIx::Class::Core';

sub BUILDARGS { $_[2] || {} }

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("fileval");

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

__PACKAGE__->set_primary_key("id");

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

sub content {
  my $self = shift;
  my $target = $self->file_to_id;
  error __"File not found!" unless -r $target; # file may have been deleted
  return $target->slurp(iomode => '<:raw');
}

sub remove_file {
  my $self = shift;

  my $path = GADS::Config->instance->uploads;
  my $id = sprintf "%09d", $self->id;
  $id =~ s!(\d{3})!$1/!g;
  $id =~ s!/$!!g; # remove trailing slash
  $id =~ s!^/!!g; # remove leading slash
  my $filepath = "$path/$id";

  unlink $filepath if -f $filepath;
  
  $self->delete;
}

1;
