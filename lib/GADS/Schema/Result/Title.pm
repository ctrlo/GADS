use utf8;

package GADS::Schema::Result::Title;

=head1 NAME

GADS::Schema::Result::Title

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Log::Report 'linkspace';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("+GADS::DBIC");

=head1 TABLE: C<title>

=cut

__PACKAGE__->table("title");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 site_id

  date_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "varchar", is_nullable => 1, size => 128 },
    "site_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "deleted",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 users

Type: has_many

Related object: L<GADS::Schema::Result::User>

=head2 site

Type: belongs_to

Related object: L<GADS::Schema::Result::Site>

=cut

__PACKAGE__->has_many(
    "users", "GADS::Schema::Result::User",
    { "foreign.title" => "self.id" },
    { cascade_copy    => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
    "site",
    "GADS::Schema::Result::Site",
    { id => "site_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

sub delete_title
{   my $self   = shift;
    my $schema = $self->result_source->schema;
    my $count  = $schema->resultset('User')->active->search({
        title => $self->id,
    })->count;
    if ($count)
    {
        error __xn
"This title cannot be deleted as it is in use by 1 user on the system",
"This title cannot be deleted as it is in use by {count} users on the system",
            $count, count => $count;
    }
    my $count_deleted = $schema->resultset('User')->search({
        deleted => { '!=' => undef },
        title   => $self->id,
    })->count;
    if ($count_deleted)
    {
        $self->update({ deleted => 1 });
    }
    else
    {
        $self->delete;
    }
}

1;
