use utf8;

package GADS::Schema::Result::Dashboard;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use JSON qw(decode_json encode_json);

__PACKAGE__->mk_group_accessors('simple' => qw/layout/);

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("dashboard");

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "site_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "instance_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "user_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

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

__PACKAGE__->belongs_to(
    "user",
    "GADS::Schema::Result::User",
    { id => "user_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

__PACKAGE__->has_many(
    "widgets",
    "GADS::Schema::Result::Widget",
    { "foreign.dashboard_id" => "self.id" },
    { cascade_copy           => 0, cascade_delete => 0 },
);

sub display_widgets
{   my $self = shift;

    my @widgets;

    # Add static widgets first, to ensure they appear first
    push @widgets,
        $self->result_source->schema->resultset('Widget')->search(
            {
                'dashboard.instance_id' => $self->instance_id,
                'dashboard.user_id'     => undef,
                'me.static'             => 1,
            },
            {
                join => 'dashboard',
            },
        )->all
        if !$self->is_shared;

    # Then widgets part of the specific dashboard
    push @widgets, $self->widgets;

    $_->layout($self->layout) foreach @widgets;

    return [
        map {
            +{
                html => $_->html,
                grid => encode_json {
                    i      => $_->grid_id,
                    static => !$self->is_shared && $_->static ? \1 : \0,
                    h      => $_->h,
                    w      => $_->w,
                    x      => $_->x,
                    y      => $_->y,
                },
            };
        } @widgets
    ];
}

sub as_json
{   my $self = shift;
    encode_json {
        name         => $self->name,
        download_url => $self->download_url,
    };
}

sub name
{   my $self = shift;
    $self->user_id
        && $self->instance_id ? $self->instance->name . " dashboard (personal)"
        : $self->instance_id  ? $self->instance->name . " dashboard (shared)"
        : $self->user_id      ? 'Home dashboard (personal)'
        :                       'Home dashboard (shared)';
}

sub url
{   my $self = shift;
    $self->instance
        ? "/" . $self->instance->identifier . "?did=" . $self->id
        : "/?did=" . $self->id;
}

sub download_url
{   my $self = shift;
    $self->instance
        ? "/"
        . $self->instance->identifier . "?did="
        . $self->id
        . '&download=pdf'
        : "/?did=" . $self->id . '&download=pdf';
}

sub is_shared
{   my $self = shift;
    !$self->user_id;
}

sub is_empty
{   my $self = shift;
    !$self->widgets->count;
}

1;
