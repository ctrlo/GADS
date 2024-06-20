use utf8;

package GADS::Schema::Result::Widget;

use strict;
use warnings;

__PACKAGE__->mk_group_accessors('simple' => qw/layout/);

use base 'DBIx::Class::Core';

use JSON qw(decode_json);
use Log::Report 'linkspace';
use MIME::Base64 qw/encode_base64/;
use Session::Token;
use Template;

use JSON qw(decode_json encode_json);

__PACKAGE__->load_components("InflateColumn::DateTime", "+GADS::DBIC");

__PACKAGE__->table("widget");

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "grid_id",
    { data_type => "varchar", is_nullable => 1, size => 64 },
    "dashboard_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "type",
    { data_type => "varchar", is_nullable => 1, size => 16 },
    "title",
    { data_type => "text", is_nullable => 1 },
    "static",
    { data_type => "smallint", default_value => 0, is_nullable => 0 },
    "h",
    { data_type => "smallint", default_value => 0, is_nullable => 1 },
    "w",
    { data_type => "smallint", default_value => 0, is_nullable => 1 },
    "x",
    { data_type => "smallint", default_value => 0, is_nullable => 1 },
    "y",
    { data_type => "smallint", default_value => 0, is_nullable => 1 },
    "content",
    { data_type => "text", is_nullable => 1 },
    "view_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "graph_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "rows",
    { data_type => "integer", is_nullable => 1 },
    "tl_options",
    { data_type => "text", is_nullable => 1 },
    "globe_options",
    { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("widget_ux_dashboard_grid",
    [ "dashboard_id", "grid_id" ]);

__PACKAGE__->belongs_to(
    "dashboard",
    "GADS::Schema::Result::Dashboard",
    { id => "dashboard_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

__PACKAGE__->belongs_to(
    "view",
    "GADS::Schema::Result::View",
    { id => "view_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

__PACKAGE__->belongs_to(
    "graph",
    "GADS::Schema::Result::Graph",
    { id => "graph_id" },
    {
        is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

sub tl_options_inflated
{   my $self = shift;
    return undef if !$self->tl_options;
    decode_json $self->tl_options;
}

sub globe_options_inflated
{   my $self = shift;
    return undef if !$self->globe_options;
    decode_json $self->globe_options;
}

sub before_create
{   my $self = shift;
    if (!$self->grid_id)
    {
        # Potential race condition, but unlikely and unique constrant will
        # catch anyway
        my $schema = $self->result_source->schema;
        my $grid_id;
        my $existing = $schema->resultset('Widget')->search({
            dashboard_id => $self->dashboard_id,
        });
        while (!$grid_id || $existing->search({ grid_id => $grid_id })->count)
        {
            $grid_id = Session::Token->new(length => 32)->get;
        }
        $self->grid_id($grid_id);
    }
}

sub is_integer
{   $_[0] =~ /^[0-9]+$/;
}

sub validate
{   my $self = shift;
    $self->type('notice')
        if !$self->type;    # XXX Temp until widget type can be defined
    $self->type =~ /^(notice|table|graph|timeline|globe)$/
        or error __x "Invalid widget type: {type}", type => $self->type;
    !defined $self->h || is_integer($self->h)
        or error __x "Invalid h value {value}", value => $self->h;
    !defined $self->w || is_integer($self->w)
        or error __x "Invalid w value {value}", value => $self->w;
    !defined $self->x || is_integer($self->x)
        or error __x "Invalid x value {value}", value => $self->x;
    !defined $self->y || is_integer($self->y)
        or error __x "Invalid y value {value}", value => $self->y;
    !defined $self->rows || is_integer($self->rows)
        or error __x "Invalid rows value {value}", value => $self->rows;
}

sub html
{   my $self = shift;

    my $params = {
        type  => $self->type,
        title => $self->title,
    };

    if ($self->type eq 'notice')
    {
        $params->{content} = $self->content;
    }
    else
    {
        my $layout = $self->layout
            or panic "Missing layout";

        my $user   = $layout->user;
        my $schema = $self->result_source->schema;

        my $view = GADS::View->new(
            id          => $self->view_id,
            instance_id => $layout->instance_id,
            schema      => $schema,
            layout      => $self->layout,
        );

        if ($self->type eq 'table')
        {
            if (!$self->view_id || !$self->rows)
            {
                $params->{type}    = 'notice';
                $params->{content} = 'Configuration required';
            }
            elsif ($view->current_user_has_access)
            {
                my $records = GADS::Records->new(
                    user   => $user,
                    layout => $layout,
                    schema => $schema,
                    page   => 1,
                    view   => $view,
                    rows   => $self->rows,

                    #rewind => session('rewind'), # Maybe add in the future
                );
                my @columns = @{ $records->columns_render };
                $params->{records} = $records->presentation;
                $params->{layout}  = $layout,
                    $params->{columns} = [
                        map $_->presentation(sort => $records->sort_first),
                        @columns
                    ];
            }
            else
            {
                # Fail cleanly with useful message. If attempting previous step
                # using a view with no access, then a Log::Report error will be
                # thrown instead.
                $params->{type} = 'notice';
                $params->{content} =
'You do not have access to the configured view for this widget';
            }
        }
        elsif ($self->type eq 'graph')
        {
            return 'Configuration required'
                if !$self->view_id || !$self->graph_id;
            my $records = GADS::RecordsGraph->new(
                user   => $user,
                layout => $layout,
                schema => $schema,
            );
            my $gdata = GADS::Graph::Data->new(
                id      => $self->graph_id,
                records => $records,
                schema  => $schema,
                view    => $view,
            );
            my $plot_data = encode_base64 $gdata->as_json, ''
                ; # base64 plugin does not like new lines in content $gdata->as_json;
            my $graph = GADS::Graph->new(
                id     => $self->graph_id,
                layout => $layout,
                schema => $schema,
            );
            my $options_in = encode_base64 $graph->as_json, '';

            $params->{graph_id}     = $self->graph_id;
            $params->{plot_data}    = $plot_data;
            $params->{plot_options} = $options_in;
        }
        elsif ($self->type eq 'timeline')
        {
            return 'Configuration required' if !$self->view_id;
            my $records = GADS::Records->new(
                user   => $user,
                view   => $view,
                layout => $layout,

                # No "to" - will take appropriate number from today
                from   => DateTime->now,    # Default
                schema => $schema,
            );
            my $tl_options = $self->tl_options_inflated;
            my $timeline   = $records->data_timeline(%{$tl_options});

            $params->{records} =
                encode_base64(encode_json(delete $timeline->{items}), '');
            $params->{groups} =
                encode_base64(encode_json(delete $timeline->{groups}), '');
            $params->{dashboard} = 1;
            $params->{view_id}   = $view->id;
            $params->{timeline}  = $timeline;
        }
        elsif ($self->type eq 'globe')
        {
            return 'Configuration required' if !$self->view_id;
            my $records_options = {
                user   => $user,
                view   => $view,
                layout => $layout,
                schema => $schema,
            };
            my $globe_options = $self->globe_options_inflated;
            my $globe         = GADS::Globe->new(
                group_col_id    => $globe_options->{group},
                color_col_id    => $globe_options->{color},
                label_col_id    => $globe_options->{label},
                records_options => $records_options,
            );
            $params->{globe_data} =
                encode_base64(encode_json($globe->data), '');
        }
    }

    my $config   = GADS::Config->instance;
    my $template = Template->new(INCLUDE_PATH => $config->template_location);
    my $output;
    my $t = $template->process('snippets/widget_content.tt', $params, \$output)
        or panic $template->error;
    return $output;
}

1;
