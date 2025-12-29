use utf8;

package GADS::Schema::Result::Instance;

use strict;
use warnings;

use HTML::Scrubber;
use Log::Report 'linkspace';

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "+GADS::DBIC", "FilterColumn");

__PACKAGE__->table("instance");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "name_short",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "site_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sort_layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sort_type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "view_limit_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "default_view_limit_extra_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "homepage_text",
  { data_type => "text", is_nullable => 1 },
  "homepage_text2",
  { data_type => "text", is_nullable => 1 },
  "record_name",
  { data_type => "text", is_nullable => 1 },
  "forget_history",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "no_overnight_update",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "api_index_layout_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "forward_record_after_create",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "no_hide_blank",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "no_download_pdf",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "no_copy_record",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "hide_in_selector",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "security_marking",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "currents",
  "GADS::Schema::Result::Current",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "imports",
  "GADS::Schema::Result::Import",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "graphs",
  "GADS::Schema::Result::Graph",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "alert_columns",
  "GADS::Schema::Result::AlertColumn",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "layouts",
  "GADS::Schema::Result::Layout",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "metric_groups",
  "GADS::Schema::Result::MetricGroup",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "instance_groups",
  "GADS::Schema::Result::InstanceGroup",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

__PACKAGE__->belongs_to(
  "sort_layout",
  "GADS::Schema::Result::Layout",
  { id => "sort_layout_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "view_limit",
  "GADS::Schema::Result::View",
  { id => "view_limit_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "default_view_limit_extra",
  "GADS::Schema::Result::View",
  { id => "default_view_limit_extra_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "api_index_layout",
  "GADS::Schema::Result::Layout",
  { id => "api_index_layout_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->has_many(
  "user_lastrecords",
  "GADS::Schema::Result::UserLastrecord",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "views",
  "GADS::Schema::Result::View",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "instance_rags",
  "GADS::Schema::Result::InstanceRag",
  { "foreign.instance_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# The following code is now removed: it is too difficult to scrub whilst still
# retaining the required functionality and formatting (and being completely
# safe). Given that only an administrator has access to update HTML code, this
# is an acceptable risk.
#
# Sanitise HTML input. This will be from an administrator so should be
# safe, but scrube anyway just in case.
#__PACKAGE__->filter_column( homepage_text => {
#    filter_to_storage => '_scrub',
#    filter_from_storage => '_scrub',
#});
#
#__PACKAGE__->filter_column( homepage_text2 => {
#    filter_to_storage => '_scrub',
#    filter_from_storage => '_scrub',
#});

sub identifier
{   my $self = shift;
    $self->name_short || "table".$self->id;
}

sub delete
{   my $self = shift;
    $self->result_source->schema->resultset('Layout')->search({
        instance_id => $self->id,
    })->count
        and error __"All fields must be deleted from this table before it can be deleted";
    $self->next::method(@_);
}

sub validate {
    my $self = shift;
    !defined $self->sort_layout_id || $self->sort_layout_id =~ /^[0-9]+$/
        or error __x"Invalid sort_layout_id {id}", id => $self->sort_layout_id;
    !defined $self->sort_type || $self->sort_type eq 'asc' || $self->sort_type eq 'desc'
        or error __x"Invalid sort type {type}", type => $self->sort_type;
}

sub _scrub
{   my ($self, $html) = @_;
    my $scrubber = HTML::Scrubber->new(
        allow => [ qw[ p b i u hr br img h1 h2 h3 h4 h5 h6 font span ul ol li a] ],
        rules => [
            p => {
                align => 1,
            },
            font => {
                face => 1,
            },
            span => {
                style => 1,
            },
            a => {
                href => 1,
            },
            img => {
                style => qr{^((?!expression).)*$}i,
                src   => 1,
            },
        ],
    );
    $scrubber->scrub($html);
}

sub read_security_marking {
    my $self = shift;
    $self->security_marking || $self->site->read_security_marking;
}

1;
