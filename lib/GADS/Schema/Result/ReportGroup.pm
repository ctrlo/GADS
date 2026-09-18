use utf8;

package GADS::Schema::Result::ReportGroup;

use Moo;

extends 'DBIx::Class::Core';
sub BUILDARGS { $_[2] || {} }

__PACKAGE__->table("report_group");

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "report_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "group_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    "report",
    "GADS::Schema::Result::Report",
    { id            => "report_id" },
    { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
    "group",
    "GADS::Schema::Result::Group",
    { id            => "group_id" },
    { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
